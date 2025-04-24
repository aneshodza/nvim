local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local os_check = require'custom.os_check'

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end
local cmp_nvim_lsp = require "cmp_nvim_lsp"
lspconfig.clangd.setup {
  on_attach = on_attach,
  capabilities = cmp_nvim_lsp.default_capabilities(),
  cmd = {
    "clangd",
    "--offset-encoding=utf-16",
  },
}

lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"rust"},
  root_dir = lspconfig.util.root_pattern("Cargo.toml")
})

lspconfig.pyright.setup {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- Options: "off", "basic", "strict"
        autoSearchPaths = true,
        diagnosticMode = "workspace", -- Options: "workspace", "openFilesOnly"
        useLibraryCodeForTypes = true
      }
    }
  }
}

if os_check.is_fedora() then
  lspconfig.solargraph.setup{
    cmd = {
      '/home/aneshodza/solargraph_lsp_wrapper.sh'
    }
  }
else
  lspconfig.solargraph.setup{}
end
-- lspconfig.steep.setup{}
-- require('custom.configs.jdtls')
