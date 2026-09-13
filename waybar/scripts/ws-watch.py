#!/usr/bin/env python3
"""Keeps a workspace state cache warm and nudges waybar when it changes.

Waybar's own hyprland/workspaces module cannot switch workspaces under a Lua
config: its built-in `activate` sends the hyprlang string `dispatch workspace N`
over Hyprland's IPC, which a Lua-configured Hyprland rejects with

    error: [string "return hl.dispatch(workspace 7)"]:1: ')' expected near '7'

So the bar uses ten `custom/wsN` buttons instead, each dispatching the Lua form
on click. They need to know which workspace is active, which is what this
provides.

Design: one long-lived listener on Hyprland's event socket writes a one-line
cache, then signals waybar. Modules re-read on the signal rather than polling,
so nothing runs on a timer and the ten buttons cost no CPU while idle.
"""

import os
import signal
import socket
import subprocess
import time
import sys
from pathlib import Path

RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
CACHE = RUNTIME / "waybar-workspaces"
PIDFILE = RUNTIME / "ws-watch.pid"
PIDFILE = RUNTIME / "ws-watch.pid"
REFRESH_SIGNAL = 1                      # waybar module `signal` number


def hypr_socket(name):
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        sys.exit("HYPRLAND_INSTANCE_SIGNATURE is not set")
    return RUNTIME / "hypr" / sig / name


def query(command):
    try:
        return subprocess.run(["hyprctl", "-j", command],
                              capture_output=True, text=True, timeout=3).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def snapshot():
    """active id, plus which workspaces hold windows."""
    import json
    try:
        active = json.loads(query("activeworkspace") or "{}").get("id", 0)
    except ValueError:
        active = 0
    occupied = []
    try:
        for w in json.loads(query("workspaces") or "[]"):
            if w.get("windows", 0) > 0:
                occupied.append(str(w["id"]))
    except ValueError:
        pass
    return f"active={active} occupied={','.join(occupied)}\n"


def publish():
    # Hyprland emits the event before its own state settles, so querying
    # immediately can read the workspace you just left. A short beat costs
    # nothing here - this only runs on an actual change - and is what stops the
    # pill lagging one workspace behind.
    time.sleep(0.05)
    try:
        CACHE.write_text(snapshot())
    except OSError:
        return
    # SIGRTMIN is 34 on Linux; waybar maps `signal: N` to SIGRTMIN+N.
    subprocess.run(["pkill", f"-{34 + REFRESH_SIGNAL}", "-x", "waybar"],
                   capture_output=True)


def main():
    # A PID file, not a pkill pattern. `pkill -f ws-watch.py` matches any
    # process whose command line merely mentions the path - an editor, a grep,
    # or the shell running the restart command itself. That is how SUPER +
    # SHIFT + R kept killing itself before it reached the restarts.
    try:
        PIDFILE.write_text("%d\n" % os.getpid())
    except OSError:
        pass

    publish()                            # seed before any event arrives

    path = hypr_socket(".socket2.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(str(path))
        buffer = ""
        while True:
            chunk = sock.recv(4096).decode("utf-8", "replace")
            if not chunk:
                break
            buffer += chunk
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                event = line.split(">>", 1)[0]
                if event in ("workspace", "workspacev2", "createworkspace",
                             "destroyworkspace", "focusedmon", "openwindow",
                             "closewindow", "movewindow", "urgent"):
                    publish()


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        main()
    except (OSError, KeyboardInterrupt):
        sys.exit(0)
    finally:
        try:
            if PIDFILE.read_text().strip() == str(os.getpid()):
                PIDFILE.unlink()
        except OSError:
            pass
