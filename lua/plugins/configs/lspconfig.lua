-- Do NOT require "nvchad.lsp" here if it causes a loop
local M = {}
local utils = require "core.utils"

-- 1. Setup Capabilities with nvim-cmp integration
M.capabilities = vim.lsp.protocol.make_client_capabilities()

-- This is the "Magic Link" that makes suggestions appear in the menu
local present, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if present then
  M.capabilities = cmp_lsp.default_capabilities(M.capabilities)
end

-- 2. Define on_attach
M.on_attach = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  utils.load_mappings("lspconfig", { buffer = bufnr })

  if client.server_capabilities.signatureHelpProvider then
    require("nvchad.signature").setup(client)
  end

  if not utils.load_config().ui.lsp_semantic_tokens and client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

-- 3. Add your manual completion overrides to the ALREADY updated capabilities
M.capabilities.textDocument.completion.completionItem = vim.tbl_deep_extend("force", M.capabilities.textDocument.completion.completionItem or {}, {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
})

-- 4. Fix the scoping for rustaceanvim
vim.g.rustaceanvim = {
  server = {
    -- Use M. to reference the functions defined above
    on_attach = M.on_attach,
    capabilities = M.capabilities,
    default_settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
}

return M
