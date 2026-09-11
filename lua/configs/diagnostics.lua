-- Runs after nvchad.configs.lspconfig.defaults(), which calls
-- nvchad.lsp.diagnostic_config() and would otherwise win.
--
-- Signs are configured through vim.diagnostic.config rather than sign_define:
-- the latter was deprecated for diagnostics in 0.10 and REMOVED in 0.12, where
-- the old call silently stops producing gutter icons.

local severity = vim.diagnostic.severity

vim.diagnostic.config {
  virtual_text = {
    prefix = "●",
    spacing = 4,
    severity = { min = severity.HINT },
  },

  signs = {
    text = {
      [severity.ERROR] = "󰅚 ",
      [severity.WARN] = "󱄊 ",
      [severity.HINT] = "󰌶 ",
      [severity.INFO] = "󰋽 ",
    },
  },

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
