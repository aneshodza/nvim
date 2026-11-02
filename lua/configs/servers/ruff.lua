-- Lint diagnostics and fix-all/organize-imports code actions. Formatting stays
-- with conform and hover with basedpyright (see configs/lspconfig.lua).
return {
  cmd = function(dispatchers, config)
    -- the project's mise ruff, else mason's (see utils/mise.lua)
    local ruff = require("utils.mise").which("ruff", config.root_dir) or "ruff"

    return vim.lsp.rpc.start({ ruff, "server" }, dispatchers)
  end,
}
