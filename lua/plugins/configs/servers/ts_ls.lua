-- plugins/configs/servers/ts_ls.lua
return {
  -- No need to require lspconfig util here if we use native vim.fs
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  },
  -- This mimics the manual test's success
  root_dir = function(fname)
    return vim.fs.root(fname, { "package.json", "tsconfig.json", ".git" }) 
           or vim.uv.cwd() -- The fallback that made your test work
  end,
  -- Use a function for init_options to ensure it's fresh
  init_options = {
    hostInfo = "neovim",
    preferences = {
      importModuleSpecifierPreference = "non-relative",
    },
  },
}
