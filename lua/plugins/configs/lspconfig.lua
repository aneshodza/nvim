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

-- NvChad v2.0's nvchad.signature calls vim.lsp.util.make_position_params() without
-- a position encoding, which nvim 0.11 warns about. Same popup, but the request is
-- made per client with that client's own encoding.
local function attach_signature(client, bufnr)
  local sig_config = utils.load_config().ui.lsp.signature

  if sig_config.disabled then
    return
  end

  local triggers = vim.tbl_get(client.server_capabilities, "signatureHelpProvider", "triggerCharacters") or {}

  local handler = vim.lsp.with(require("nvchad.signature").signature_window, {
    border = "single",
    focusable = false,
    silent = sig_config.silent,
  })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = vim.api.nvim_create_augroup("LspSignature", { clear = false }),
    buffer = bufnr,
    callback = function()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local line_to_cursor = vim.api.nvim_get_current_line():sub(1, col)
      local cur, prev = line_to_cursor:sub(-1), line_to_cursor:sub(-2, -2)

      for _, trigger in ipairs(triggers) do
        if cur == trigger or (cur == " " and prev == trigger) then
          local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
          client:request("textDocument/signatureHelp", params, handler, bufnr)
          return
        end
      end
    end,
  })
end

-- pylsp's rope auto-import only offers "add import" actions for diagnostics that
-- look like flake8's ("undefined name") or mypy's ("name-defined"). basedpyright
-- reports reportUndefinedVariable, so relabel a copy for the request - it ignores
-- context.diagnostics itself, and this avoids running a second linter just to
-- produce a matching message. Titles are deduplicated because both servers
-- suggest the same import when they both know the symbol.
M.code_action = function()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = {}

  for _, d in ipairs(vim.diagnostic.get(0, { lnum = lnum })) do
    local lsp_diagnostic = d.user_data and d.user_data.lsp

    if lsp_diagnostic then
      if lsp_diagnostic.code == "reportUndefinedVariable" then
        lsp_diagnostic = vim.tbl_extend("force", lsp_diagnostic, { code = "name-defined" })
      end

      table.insert(diagnostics, lsp_diagnostic)
    end
  end

  local seen = {}

  vim.lsp.buf.code_action {
    context = { diagnostics = diagnostics },
    filter = function(action)
      if seen[action.title] then
        return false
      end

      seen[action.title] = true
      return true
    end,
  }
end

-- 2. Define on_attach
M.on_attach = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  utils.load_mappings("lspconfig", { buffer = bufnr })

  if client.server_capabilities.signatureHelpProvider then
    attach_signature(client, bufnr)
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
