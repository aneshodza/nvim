-- Shared bootstrap for scripts/dump.lua and scripts/smoke.lua.
--
-- These must boot the config identically or their keymap snapshots are not
-- comparable: lazy.nvim installs placeholder trigger mappings for any plugin
-- with `keys`, and deletes them once the plugin loads. Force-loading different
-- plugin sets therefore produces different keymap tables - which-key alone
-- accounts for 8 phantom entries.
--
-- Lives in scripts/ rather than lua/ so it is not part of the config runtime;
-- load it with dofile.

local M = {}

-- Anything event- or cmd-gated that we want reflected in a snapshot. UIEnter
-- never fires headless, so VeryLazy and User FilePost never fire either and
-- none of these load on their own.
M.force_load = {
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
  "Comment.nvim",
  "null-ls.nvim",
}

local function drain(ms)
  vim.wait(ms, function()
    return false
  end)
end

M.drain = drain

--- Boot the config the way a real session would.
--- @return string[] errors ERROR-level notifications raised during startup
function M.boot()
  vim.go.loadplugins = true

  local errors = {}
  local raw_notify = vim.notify

  -- lazy.nvim wraps every plugin init/config in Util.try, whose handler defers
  -- to vim.notify. Plugin errors never propagate; this is the only reliable
  -- interception point.
  vim.notify = function(msg, level, opts)
    if level and level >= vim.log.levels.ERROR then
      errors[#errors + 1] = tostring(msg)
    end
    return raw_notify(msg, level, opts)
  end

  vim.notify_once = vim.notify

  local ok, err = pcall(dofile, vim.fn.stdpath "config" .. "/init.lua")

  if not ok then
    errors[#errors + 1] = "init.lua raised: " .. tostring(err)
  end

  drain(1500)

  for _, name in ipairs(M.force_load) do
    pcall(function()
      require("lazy").load { plugins = { name } }
    end)
  end

  drain(2000)

  return errors
end

--- @return string[] sorted "mode\tlhs\tdesc" lines
function M.keymaps()
  local maps = {}

  for _, mode in ipairs { "n", "i", "v", "x", "t" } do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      -- <SNR>NN_ ids depend on how many scripts happened to be sourced and vary
      -- run to run; normalise or every snapshot differs from the last.
      local lhs = tostring(m.lhs):gsub("<SNR>%d+_", "<SNR>_")
      maps[#maps + 1] = ("%s\t%s\t%s"):format(mode, lhs, m.desc or "")
    end
  end

  table.sort(maps)
  return maps
end

return M
