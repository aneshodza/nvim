local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

-- Resolve the interpreter basedpyright should use to find site-packages.
-- Prefer the project's virtualenv (uv and python -m venv both create .venv; in a
-- uv workspace it sits at the workspace root, so search upwards), then an
-- activated venv, then asdf's python, then whatever python3 is on PATH.
local function resolve_python(root)
  local candidates = {}

  if root then
    local venv = vim.fs.find(".venv", { path = root, upward = true, type = "directory" })[1]
    if venv then
      table.insert(candidates, venv .. "/bin/python")
    end
  end

  if vim.env.VIRTUAL_ENV then
    table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
  end

  local asdf = vim.fn.trim(vim.fn.system "asdf which python 2>/dev/null")
  if vim.v.shell_error == 0 and asdf ~= "" then
    table.insert(candidates, asdf)
  end

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  local py = vim.fn.exepath "python3"
  return py ~= "" and py or "python3"
end

return {
  on_attach = on_attach,
  capabilities = capabilities,

  -- Resolved per project at attach time, not once at startup, so a different
  -- project opened in the same session gets its own interpreter.
  before_init = function(_, config)
    config.settings.python.pythonPath = resolve_python(config.root_dir)
  end,

  settings = {
    python = {},
    basedpyright = {
      analysis = {
        -- basedpyright defaults to "recommended", which is far stricter than the
        -- "basic" pyright was running at. Leaving useLibraryCodeForTypes unset on
        -- purpose so pyproject.toml can still override it.
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        diagnosticMode = "workspace",
      },
    },
  },
}
