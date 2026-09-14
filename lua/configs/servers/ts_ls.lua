-- Note: this root_dir replaces nvim-lspconfig's, which also excludes deno
-- projects and does lockfile-based monorepo detection. With the vim.uv.cwd()
-- fallback ts_ls will attach almost anywhere, including a deno project where
-- denols would be the right server. Kept as-is - changing it is a separate
-- decision from the migration.
return {
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  },

  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "package.json", "tsconfig.json", ".git" }) or vim.uv.cwd()

    if root then
      on_dir(root)
    end
  end,

  init_options = {
    hostInfo = "neovim",
    preferences = {
      importModuleSpecifierPreference = "non-relative",
    },
  },
}
