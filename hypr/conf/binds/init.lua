-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  BINDS                                                                   │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Joins the combos in ../../keybinds.lua to the dispatchers in dispatch.lua.
--
-- An entry whose id has no dispatcher is skipped with a notice rather than
-- killing the config, so a bad hand edit or a stale id costs you one bind
-- instead of the session.
--
-- hyprlang equivalents, for reference:
--   bind   -> hl.bind(combo, dispatcher)
--   bindd  -> opts.desc        (a real field now, not a comment hack)
--   binde  -> opts.repeating   fires while held
--   bindl  -> opts.locked      still fires on the lock screen
--   bindm  -> opts.mouse       hold-to-drag, released on button up

local entries  = require("hypr.keybinds")
local dispatch = require("hypr.conf.binds.dispatch")

local orphans = {}

for _, entry in ipairs(entries) do
  local dispatcher = dispatch(entry.id)

  if dispatcher then
    hl.bind(entry.combo, dispatcher, {
      desc      = entry.desc,
      locked    = entry.locked,
      repeating = entry.repeating,
      mouse     = entry.mouse,
    })
  else
    orphans[#orphans + 1] = entry.id
  end
end

if #orphans > 0 then
  print(("[hypr] %d keybind(s) have no dispatcher and were skipped: %s")
    :format(#orphans, table.concat(orphans, ", ")))
end
