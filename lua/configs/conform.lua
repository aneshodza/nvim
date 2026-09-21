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
    -- ruff rather than black: it is what uv projects reach for, it is fast, and
    -- it picks up [tool.ruff] from the project's pyproject.toml. Imports first,
    -- then formatting.
    python = { "ruff_organize_imports", "ruff_format" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },

  -- A function rather than a table so <leader>tf can switch it off per session
  -- or per buffer - useful when editing someone else's file.
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end

    return {
      timeout_ms = 3000,
      -- `lsp_fallback` was deprecated in conform 8. Note the fallback is inert
      -- anyway: configs/lspconfig.lua disables documentFormattingProvider on
      -- every client, so a missing formatter is a silent no-op.
      lsp_format = "fallback",
    }
  end,
}
