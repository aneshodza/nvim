local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- Resolve the interpreter pyright should use to find site-packages.
-- Prefer asdf's active python (the single source of truth for dev deps);
-- fall back to whatever python3 is on PATH.
local function resolve_python()
  local asdf = vim.fn.trim(vim.fn.system("asdf which python 2>/dev/null"))
  if vim.v.shell_error == 0 and asdf ~= "" and vim.fn.executable(asdf) == 1 then
    return asdf
  end
  local py = vim.fn.exepath("python3")
  return py ~= "" and py or "python3"
end

return {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    python = {
      pythonPath = resolve_python(),
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  }
}

