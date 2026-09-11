return {
  formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    cs = { "csharpier" },
    css = { "prettier" },
    html = { "prettier" },
    htmlangular = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    -- added so CI's stylua --check and format-on-save agree
    lua = { "stylua" },
    markdown = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },

  format_on_save = {
    timeout_ms = 3000,
    -- `lsp_fallback` was deprecated in conform 8. Note the fallback is inert
    -- anyway: configs/lspconfig.lua disables documentFormattingProvider on
    -- every client, so a missing formatter is a silent no-op.
    lsp_format = "fallback",
  },
}
