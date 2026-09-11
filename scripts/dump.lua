-- Snapshot the resolved config: plugins, keymaps, LSP servers.
--
--   nvim --headless -l scripts/dump.lua > /tmp/before.txt
--
-- Config-agnostic: it only ever touches vim.fn.stdpath "config", so the same
-- script snapshots any tree. Pair it with NVIM_APPNAME so each tree resolves
-- its own data dir, otherwise one config enumerates the other's plugin set and
-- the diff is meaningless.
--
-- Regenerates scripts/expected/keymaps.txt for smoke.lua:
--   nvim --headless -l scripts/dump.lua \
--     | awk '/^## keymaps/{f=1;next} /^## /{f=0} f && NF' > scripts/expected/keymaps.txt

local lib = dofile(vim.fn.stdpath "config" .. "/scripts/lib.lua")

local errors = lib.boot()
local out = {}

local function section(title)
  out[#out + 1] = ""
  out[#out + 1] = "## " .. title
end

section "plugins"
local ok, lz = pcall(require, "lazy.core.config")

if ok then
  local names = vim.tbl_keys(lz.spec.plugins)
  table.sort(names)
  vim.list_extend(out, names)
else
  out[#out + 1] = "!! lazy.core.config unavailable"
end

section "keymaps"
vim.list_extend(out, lib.keymaps())

section "lsp"
local enabled = vim.tbl_keys(vim.lsp._enabled_configs or {})
table.sort(enabled)

for _, name in ipairs(enabled) do
  out[#out + 1] = "enabled\t" .. name
end

section "errors"

if #errors == 0 then
  out[#out + 1] = "(none)"
else
  vim.list_extend(out, errors)
end

-- io.stdout, not print: under `nvim -l` print() routes through the message
-- system, which headless sends to stderr.
io.stdout:write(table.concat(out, "\n"), "\n")
