local options = {
  formatters_by_ft = {
    html = { "prettier" },
    htmlangular = { "prettier" },
    markdown = { "prettier" },
    css = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    cs = { "csharpier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },

  formatters = {
    prettier = {
      prepend_args = {},
    },
  },

  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
}

return options
