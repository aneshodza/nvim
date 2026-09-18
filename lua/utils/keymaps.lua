-- :DuplicateKeybinds - find keybinds that collide.
--
-- Two distinct problems, both of which this config has had:
--
--   shadowed  the same lhs bound globally AND buffer-locally. The buffer-local
--             one always wins, silently. <leader>td was Search TODOs globally
--             and gitsigns' toggle_deleted buffer-locally, so in any git file
--             it never opened the TODO picker.
--
--   prefix    an lhs that is also the start of a longer one, e.g. <leader>rh
--             alongside <leader>rhm. The short one still works but only after
--             'timeoutlen' expires, so it feels broken rather than slow.
--
-- Two *global* maps on the same lhs cannot be detected here: the second
-- silently replaces the first at definition time and only the winner is left
-- in the keymap table.

local M = {}

local MODES = { "n", "i", "v", "x", "s", "o", "t" }

local function describe(m)
  return m.desc or (type(m.rhs) == "string" and m.rhs ~= "" and m.rhs) or "<function>"
end

--- Placeholder maps that exist only to load something, not to do anything.
---
--- lazy.nvim installs one per entry in a plugin's `keys` and deletes it once
--- the plugin loads, so bare <leader>, "c", "v" and friends appear as maps with
--- no desc, no rhs and a callback - and prefix basically everything. which-key
--- registers described triggers of its own. Neither is a real collision.
local function is_trigger(m)
  if (m.desc or ""):lower():find "which%-key" then
    return true
  end

  return m.desc == nil and m.rhs == nil
end

--- Operator-pending style idioms - gc/gcc, ys/yss, gb/gbc - where the shorter
--- map is an operator that waits for a motion anyway, so the timeout is
--- expected rather than a bug. Reported separately from the leader namespace,
--- where a stall is almost always unintended.
local function is_leader(lhs)
  return vim.startswith(lhs, vim.g.mapleader or " ")
end

--- @param bufnr integer
--- @return { shadowed: table[], prefixes: table[] }
function M.collisions(bufnr)
  bufnr = bufnr or 0

  local shadowed, prefixes = {}, {}

  for _, mode in ipairs(MODES) do
    local globals, buffers = {}, {}

    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      if not is_trigger(m) then
        globals[m.lhs] = m
      end
    end

    for _, m in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
      if not is_trigger(m) then
        buffers[m.lhs] = m
      end
    end

    for lhs, buffer_map in pairs(buffers) do
      if globals[lhs] then
        table.insert(shadowed, {
          mode = mode,
          lhs = lhs,
          winner = describe(buffer_map),
          loser = describe(globals[lhs]),
        })
      end
    end

    -- prefix stalls, considering global and buffer-local together since both
    -- are live in this buffer
    local all = {}

    for lhs, m in pairs(globals) do
      all[lhs] = m
    end

    for lhs, m in pairs(buffers) do
      all[lhs] = m
    end

    for lhs, m in pairs(all) do
      local longer = {}

      for other in pairs(all) do
        if other ~= lhs and vim.startswith(other, lhs) then
          table.insert(longer, other)
        end
      end

      if #longer > 0 then
        table.sort(longer)

        table.insert(prefixes, {
          mode = mode,
          lhs = lhs,
          desc = describe(m),
          longer = longer,
          leader = is_leader(lhs),
        })
      end
    end
  end

  local function by_key(a, b)
    return a.mode .. a.lhs < b.mode .. b.lhs
  end

  table.sort(shadowed, by_key)
  table.sort(prefixes, by_key)

  return { shadowed = shadowed, prefixes = prefixes }
end

--- Render `lhs` the way the cheatsheet does, so <leader> is readable.
local function pretty(lhs)
  local leader = vim.g.mapleader or "\\"
  return (lhs:gsub("^" .. vim.pesc(leader), "<leader>"))
end

function M.report()
  local found = M.collisions(0)
  local lines = {}

  table.insert(lines, ("Shadowed - buffer-local wins over global (%d)"):format(#found.shadowed))

  if #found.shadowed == 0 then
    table.insert(lines, "  none")
  end

  for _, c in ipairs(found.shadowed) do
    table.insert(lines, ("  [%s] %-18s %s"):format(c.mode, pretty(c.lhs), c.winner))
    table.insert(lines, ("      %-18s %s  (never fires)"):format("", c.loser))
  end

  local leader_stalls, other_stalls = {}, {}

  for _, c in ipairs(found.prefixes) do
    table.insert(c.leader and leader_stalls or other_stalls, c)
  end

  local function render(list)
    for _, c in ipairs(list) do
      table.insert(lines, ("  [%s] %-16s %s"):format(c.mode, pretty(c.lhs), c.desc))

      for _, longer in ipairs(c.longer) do
        table.insert(lines, ("      shadowed by %s"):format(pretty(longer)))
      end
    end
  end

  table.insert(lines, "")
  table.insert(
    lines,
    ("Prefix stalls in the leader namespace - waits %dms (%d)"):format(vim.o.timeoutlen, #leader_stalls)
  )

  if #leader_stalls == 0 then
    table.insert(lines, "  none")
  end

  render(leader_stalls)

  table.insert(lines, "")
  table.insert(lines, ("Prefix stalls elsewhere - usually operator idioms (%d)"):format(#other_stalls))
  render(other_stalls)

  table.insert(lines, "")
  table.insert(lines, "Note: two *global* maps on one lhs are invisible here -")
  table.insert(lines, "the second silently replaces the first when it is defined.")

  require("utils.float").open("Duplicate keybinds", lines)
end

return M
