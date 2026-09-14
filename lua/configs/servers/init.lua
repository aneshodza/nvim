-- Every *.lua in this directory configures and enables one LSP server; the
-- filename IS the server name, so adding a server means adding a file.
--
-- The specs must be pure data: no on_attach, no capabilities.
--
-- vim.lsp.config merges '*' -> lsp/<name>.lua (nvim-lspconfig) -> this config,
-- highest wins. So setting either key here silently beats nvim-lspconfig's own,
-- which costs real behaviour: its on_attach is where :LspPyrightOrganizeImports
-- and friends get registered, and lsp/omnisharp.lua deliberately sets
-- capabilities.workspace.workspaceFolders = false to work around
-- OmniSharp-roslyn#909. Shared capabilities go through vim.lsp.config("*", ...)
-- in configs/lspconfig.lua instead; shared on_attach behaviour goes in an
-- LspAttach autocmd. scripts/checkload.lua enforces this.

local dir = vim.fn.stdpath "config" .. "/lua/configs/servers"

for name, kind in vim.fs.dir(dir) do
  if kind == "file" and name ~= "init.lua" and name:match "%.lua$" then
    local server = name:sub(1, -5)

    vim.lsp.config(server, require("configs.servers." .. server))
    vim.lsp.enable(server)
  end
end

-- servers that need no configuration beyond nvim-lspconfig's own
vim.lsp.enable { "html" }
