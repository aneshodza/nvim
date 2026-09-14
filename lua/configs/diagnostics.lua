-- Runs after nvchad.configs.lspconfig.defaults(), which calls
-- nvchad.lsp.diagnostic_config() and would otherwise win.
--
-- Signs are configured through vim.diagnostic.config rather than sign_define:
-- the latter was deprecated for diagnostics in 0.10 and REMOVED in 0.12, where
-- the old call silently stops producing gutter icons.

local severity = vim.diagnostic.severity

local M = {}

-- virtual_text and virtual_lines are mutually exclusive here on purpose.
-- Neovim's `current_line` option only *filters* to the current line; there is
-- no "everywhere except the current line", and plain virtual_text is rendered
-- once with no CursorMoved hook (diagnostic.lua only installs that when
-- current_line == true). Enabling both therefore draws the same diagnostic
-- twice on the cursor line. <leader>dv swaps between them.
M.virtual_text = {
  prefix = "●",
  spacing = 4,
  severity = { min = severity.HINT },
}

M.virtual_lines = { current_line = true }

vim.diagnostic.config {
  virtual_text = M.virtual_text,

  signs = {
    text = {
      [severity.ERROR] = "󰅚 ",
      [severity.WARN] = "󱄊 ",
      [severity.HINT] = "󰌶 ",
      [severity.INFO] = "󰋽 ",
    },
  },

  virtual_lines = false,

  update_in_insert = false,
  severity_sort = true,

  float = {
    focused = false,
    style = "minimal",
    border = "rounded",
    -- source = "always" was deprecated in 0.11 in favour of a boolean
    source = true,
    header = "",
    prefix = "",
  },
}

--- Swap between compact inline text on every line and the full multi-line
--- message on the cursor line.
function M.toggle_virtual_lines()
  local on = vim.diagnostic.config().virtual_lines ~= false

  vim.diagnostic.config {
    virtual_lines = not on and M.virtual_lines or false,
    virtual_text = on and M.virtual_text or false,
  }

  vim.notify("Diagnostics: " .. (on and "inline text" or "full message on cursor line"))
end

return M
