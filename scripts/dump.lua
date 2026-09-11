-- Snapshot the resolved config: plugins, keymaps, LSP servers.
--
--   nvim --headless -l scripts/dump.lua > /tmp/before.txt
--
-- Deliberately config-agnostic: it only ever touches `vim.fn.stdpath "config"`,
-- so the same script snapshots the old v2.0 tree and the migrated one. Pair it
-- with NVIM_APPNAME so each tree resolves its own data dir, otherwise the old
-- config enumerates the new plugin set and the diff is meaningless.
--
-- `nvim -l` sets loadplugins = false and does NOT source init.lua, so we have
-- to bootstrap the config ourselves.

vim.go.loadplugins = true

local config_dir = vim.fn.stdpath "config"

-- lazy.nvim wraps every plugin init/config in Util.try, whose handler defers to
-- vim.notify. Plugin errors therefore never propagate - capture them instead.
local errors = {}
local raw_notify = vim.notify

vim.notify = function(msg, level, opts)
  if level and level >= vim.log.levels.ERROR then
    errors[#errors + 1] = tostring(msg)
  end
  return raw_notify(msg, level, opts)
end

vim.notify_once = vim.notify

local function drain(ms)
  vim.wait(ms, function()
    return false
  end)
end

local ok, err = pcall(dofile, config_dir .. "/init.lua")
if not ok then
  errors[#errors + 1] = "init.lua raised: " .. tostring(err)
end
drain(1500)

-- UIEnter never fires headless, so VeryLazy and User FilePost never fire and
-- everything event-gated stays dormant. Force the ones we want to inspect.
for _, name in ipairs {
  "nvim-lspconfig",
  "conform.nvim",
  "nvim-cmp",
  "telescope.nvim",
  "nvim-tree.lua",
  "gitsigns.nvim",
  "nvim-treesitter",
  "which-key.nvim",
  "aerial.nvim",
  "todo-comments.nvim",
  "nvim-surround",
  "null-ls.nvim",
} do
  pcall(function()
    require("lazy").load { plugins = { name } }
  end)
end
drain(2000)

local out = {}
local function section(title)
  out[#out + 1] = ""
  out[#out + 1] = "## " .. title
end

-- plugins ------------------------------------------------------------------
section "plugins"
local lz_ok, lz = pcall(require, "lazy.core.config")
if lz_ok then
  local names = vim.tbl_keys(lz.spec.plugins)
  table.sort(names)
  vim.list_extend(out, names)
else
  out[#out + 1] = "!! lazy.core.config unavailable"
end

-- keymaps ------------------------------------------------------------------
section "keymaps"
local maps = {}
for _, mode in ipairs { "n", "i", "v", "x", "t" } do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    -- <SNR>NN_ script ids depend on how many scripts happened to be sourced and
    -- vary run to run; normalise or every snapshot differs from the last.
    local lhs = tostring(m.lhs):gsub("<SNR>%d+_", "<SNR>_")
    maps[#maps + 1] = ("%s\t%s\t%s"):format(mode, lhs, m.desc or "")
  end
end
table.sort(maps)
vim.list_extend(out, maps)

-- lsp ----------------------------------------------------------------------
section "lsp"
local enabled = vim.tbl_keys(vim.lsp._enabled_configs or {})
table.sort(enabled)
for _, name in ipairs(enabled) do
  out[#out + 1] = "enabled\t" .. name
end

-- errors -------------------------------------------------------------------
section "errors"
if #errors == 0 then
  out[#out + 1] = "(none)"
else
  vim.list_extend(out, errors)
end

-- io.stdout, not print: in `nvim -l` print() routes through the message system,
-- which headless sends to stderr.
io.stdout:write(table.concat(out, "\n"), "\n")
