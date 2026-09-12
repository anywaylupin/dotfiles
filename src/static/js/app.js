// ╭────────────────────────────────────────────────────────────────────────────╮
// │  CLIENT BEHAVIOUR                                                          │
// ╰────────────────────────────────────────────────────────────────────────────╯
//
// Progressive enhancement only. Both forms are plain POSTs that work without
// any of this; the server validates and detects conflicts again regardless.

// ── slider readouts ─────────────────────────────────────────────────────────

document.querySelectorAll('input[type="range"][data-readout]').forEach((input) => {
  const out = document.getElementById(input.dataset.readout);
  if (!out) return;
  const sync = () => { out.textContent = input.value; };
  input.addEventListener('input', sync);
  sync();
});

// ── search ──────────────────────────────────────────────────────────────────
// Filters rows by their data-search text. Works for both the settings fields
// and the keybind rows; the input says which selector it owns.

document.querySelectorAll('.search__input').forEach((box) => {
  const selector = box.dataset.target;
  const emptyEl = box.dataset.empty ? document.querySelector(box.dataset.empty) : null;
  const countEl = document.getElementById(box.id.replace('-search', '-count'));
  const rows = Array.from(document.querySelectorAll(selector));

  const groupOf = (row) => row.closest('.panel');

  const apply = () => {
    const q = box.value.trim().toLowerCase();
    let shown = 0;

    rows.forEach((row) => {
      const haystack = (row.dataset.search || row.textContent || '').toLowerCase();
      const match = q === '' || haystack.includes(q);
      row.hidden = !match;
      if (match) shown += 1;
    });

    // Hide a section whose every row is filtered out.
    const groups = new Set(rows.map(groupOf).filter(Boolean));
    groups.forEach((group) => {
      const anyVisible = Array.from(group.querySelectorAll(selector)).some((r) => !r.hidden);
      group.hidden = !anyVisible;
    });

    if (emptyEl) emptyEl.hidden = shown !== 0;
    if (countEl) countEl.textContent = q === '' ? `${rows.length} total` : `${shown} of ${rows.length}`;
  };

  box.addEventListener('input', apply);
  box.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { box.value = ''; apply(); }
  });
  apply();
});

// Focus search with "/" from anywhere on the page.
document.addEventListener('keydown', (e) => {
  if (e.key !== '/' || e.metaKey || e.ctrlKey || e.altKey) return;
  const tag = document.activeElement && document.activeElement.tagName;
  if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') return;
  const box = document.querySelector('.search__input');
  if (box) { e.preventDefault(); box.focus(); box.select(); }
});

// ── keybind capture ─────────────────────────────────────────────────────────

const captureOverlay = document.getElementById('capture');

if (captureOverlay) {
  const captureText = document.getElementById('capture-combo');
  const form = document.getElementById('binds-form');
  const dirtyNote = document.getElementById('dirty-note');
  const acceptField = document.getElementById('accept-conflicts');
  const conflictBadge = document.getElementById('conflict-count');

  // event.code -> the token Hyprland expects. Anything not listed falls back to
  // the code with its DOM prefix stripped, which covers letters and digits.
  const KEY_NAMES = {
    Space: 'Space', Enter: 'RETURN', Tab: 'TAB', Escape: 'Escape',
    ArrowLeft: 'Left', ArrowRight: 'Right', ArrowUp: 'Up', ArrowDown: 'Down',
    Backslash: 'backslash', Slash: 'slash', Period: 'period', Comma: 'comma',
    Semicolon: 'semicolon', Quote: 'apostrophe', BracketLeft: 'bracketleft',
    BracketRight: 'bracketright', Minus: 'minus', Equal: 'equal', Backquote: 'grave',
    Delete: 'Delete', Insert: 'Insert', Home: 'Home', End: 'End',
    PageUp: 'Prior', PageDown: 'Next', PrintScreen: 'Print', Backspace: 'BackSpace',
  };

  // e.key names, for events that carry no e.code.
  const KEY_FALLBACK = {
    ' ': 'Space', Enter: 'RETURN', Tab: 'TAB',
    ArrowLeft: 'Left', ArrowRight: 'Right', ArrowUp: 'Up', ArrowDown: 'Down',
    '\\': 'backslash', '/': 'slash', '.': 'period', ',': 'comma',
    ';': 'semicolon', "'": 'apostrophe', '[': 'bracketleft', ']': 'bracketright',
    '-': 'minus', '=': 'equal', '`': 'grave',
    PageUp: 'Prior', PageDown: 'Next', PrintScreen: 'Print', Backspace: 'BackSpace',
  };

  // Prefer e.code: it is the physical key, so a bind survives a layout change.
  // Fall back to e.key for events that do not carry a code.
  const keyToken = (e) => {
    if (e.code) {
      if (KEY_NAMES[e.code]) return KEY_NAMES[e.code];
      const code = e.code.replace(/^Key/, '').replace(/^Digit/, '').replace(/^Numpad/, 'KP_');
      if (code) return code;
    }
    const key = e.key;
    if (!key) return '';
    if (KEY_FALLBACK[key]) return KEY_FALLBACK[key];
    if (key.length === 1) return key.toUpperCase();
    return key;   // Delete, Home, F5, XF86... arrive already named
  };

  const MODIFIER_CODES = /^(Control|Shift|Alt|Meta|Super|OS)/;

  const buildCombo = (e) => {
    const mods = [];
    if (e.metaKey) mods.push('SUPER');
    if (e.ctrlKey) mods.push('CTRL');
    if (e.altKey) mods.push('ALT');
    if (e.shiftKey) mods.push('SHIFT');
    const modifierOnly = MODIFIER_CODES.test(e.code || '') || MODIFIER_CODES.test(e.key || '');
    if (modifierOnly) return mods.length ? mods.join(' + ') + ' + ...' : '...';

    const token = keyToken(e);
    // No usable key name: stay in capture rather than committing a bare chord.
    if (!token) return mods.length ? mods.join(' + ') + ' + ...' : '...';
    return [...mods, token].join(' + ');
  };

  let active = null;   // the hidden input being edited

  const markDirty = () => {
    if (dirtyNote) dirtyNote.hidden = false;
    // A fresh edit invalidates any previous "keep the duplicates" decision.
    if (acceptField) acceptField.value = '0';
  };

  // Live conflict check, so the warning appears while editing rather than only
  // after a round trip. The server checks again on save.
  const refreshConflicts = () => {
    const inputs = Array.from(document.querySelectorAll('input[name^="combo."]'));
    const seen = new Map();

    inputs.forEach((input) => {
      const key = input.value.trim().toUpperCase();
      if (!seen.has(key)) seen.set(key, []);
      seen.get(key).push(input);
    });

    let clashing = 0;
    inputs.forEach((input) => {
      const row = input.closest('.bind-row');
      if (!row) return;
      const shared = seen.get(input.value.trim().toUpperCase()) || [];
      const isClash = shared.length > 1;
      row.classList.toggle('is-clashing', isClash);
      if (isClash) clashing += 1;
    });

    if (conflictBadge) {
      conflictBadge.textContent = `${clashing} conflicting`;
      conflictBadge.classList.toggle('is-on', clashing > 0);
    }
    return clashing;
  };

  const stopCapture = () => {
    captureOverlay.hidden = true;
    active = null;
    document.removeEventListener('keydown', onKeyDown, true);
    document.removeEventListener('keyup', onKeyUp, true);
  };

  const commit = (combo) => {
    if (!active) return;
    const input = active;
    input.value = combo;
    const button = document.querySelector(`.combo[data-input="${input.id}"] .combo__text`);
    if (button) button.textContent = combo;
    const reset = document.querySelector(`.combo__reset[data-reset="${input.id}"]`);
    if (reset) reset.hidden = reset.dataset.original === combo;
    markDirty();
    refreshConflicts();
    stopCapture();
  };

  function onKeyDown(e) {
    e.preventDefault();
    e.stopPropagation();

    if (e.code === 'Escape' || e.key === 'Escape') { stopCapture(); return; }
    if ((e.code === 'Backspace' || e.key === 'Backspace') && !e.metaKey && !e.ctrlKey && !e.altKey) {
      commit('');
      return;
    }
    captureText.textContent = buildCombo(e);
  }

  // Accepting on keyup is what makes holding work: press and hold the chord,
  // let go, and whatever was down at that moment is the combo.
  function onKeyUp(e) {
    e.preventDefault();
    e.stopPropagation();
    const text = captureText.textContent;
    if (!text || text.endsWith('...')) return;   // modifiers only, keep waiting
    commit(text);
  }

  document.querySelectorAll('.combo').forEach((button) => {
    button.addEventListener('click', () => {
      active = document.getElementById(button.dataset.input);
      if (!active) return;
      captureText.textContent = '...';
      captureOverlay.hidden = false;
      document.addEventListener('keydown', onKeyDown, true);
      document.addEventListener('keyup', onKeyUp, true);
    });
  });

  captureOverlay.addEventListener('click', stopCapture);

  document.querySelectorAll('.combo__reset').forEach((reset) => {
    reset.addEventListener('click', () => {
      const input = document.getElementById(reset.dataset.reset);
      if (!input) return;
      input.value = reset.dataset.original;
      const text = document.querySelector(`.combo[data-input="${input.id}"] .combo__text`);
      if (text) text.textContent = reset.dataset.original;
      reset.hidden = true;
      refreshConflicts();
    });
  });

  // Saving with conflicts present needs a second press, matching the server.
  if (form) {
    form.addEventListener('submit', (e) => {
      if (!acceptField || acceptField.value === '1') return;
      if (refreshConflicts() === 0) return;
      e.preventDefault();
      acceptField.value = '1';
      const save = document.getElementById('binds-save');
      if (save) save.textContent = 'Save anyway';
      const badge = document.getElementById('conflict-count');
      if (badge) badge.scrollIntoView({ block: 'center' });
    });
  }

  refreshConflicts();
}

// ── settings form ───────────────────────────────────────────────────────────

const settingsForm = document.querySelector('form.form:not(#binds-form)');
if (settingsForm) {
  settingsForm.addEventListener('input', () => {
    const note = document.getElementById('dirty-note');
    if (note) note.hidden = false;
  });
}
