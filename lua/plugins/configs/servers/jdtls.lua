local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

return {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    java = {
      configuration = {
        updateBuildConfiguration = "automatic",
      },
      import = {
        gradle = {
          wrapper = {
            enabled = true,
          },
        },
      },
    },
  },
}
