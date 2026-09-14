local nvlsp = require "nvchad.configs.lspconfig"

-- base46 lsp highlights, diagnostic config, NvChad's LspAttach defaults, lua_ls
nvlsp.defaults()

-- vim.lsp.config("*", ...) merges rather than replaces, so NvChad's on_init
-- survives this.
local capabilities = vim.lsp.protocol.make_client_capabilities()
local present, cmp_lsp = pcall(require, "cmp_nvim_lsp")

if present then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

vim.lsp.config("*", { capabilities = capabilities })

-- conform owns formatting. Disabling the providers here rather than in a
-- per-server on_attach keeps the server files free of it - see
-- configs/servers/init.lua for why that matters.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserNoLspFormat", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,
})

require "configs.servers"

-- must come after nvlsp.defaults(), which calls nvchad.lsp.diagnostic_config()
require "configs.diagnostics"
