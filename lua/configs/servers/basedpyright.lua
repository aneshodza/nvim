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

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  -- only now pay for a subprocess; the previous version spawned this
  -- unconditionally, even when a .venv had already been found
  local asdf = vim.fn.trim(vim.fn.system "asdf which python 2>/dev/null")

  if vim.v.shell_error == 0 and asdf ~= "" and vim.fn.executable(asdf) == 1 then
    return asdf
  end

  local py = vim.fn.exepath "python3"
  return py ~= "" and py or "python3"
end

--- In a uv workspace every member shares one .venv, and sibling libraries are
--- installed into it as editable .pth entries. nvim-lspconfig's root_markers
--- stop at the first pyproject.toml, which is the *member* directory - so those
--- sibling libraries land outside the workspace and pyright treats them as
--- third-party: indexed once at startup and never watched. Editing or adding a
--- file in one then does nothing until :LspRestart.
---
--- Rooting at the workspace instead keeps them inside it, so they are watched
--- like any other source file.
local function root_for(fname)
  local pyprojects = vim.fs.find(function(name)
    return name == "pyproject.toml"
  end, { path = vim.fs.dirname(fname), upward = true, limit = math.huge })

  for _, file in ipairs(pyprojects) do
    local ok, lines = pcall(vim.fn.readfile, file)

    if ok and table.concat(lines, "\n"):find "%[tool%.uv%.workspace%]" then
      return vim.fs.dirname(file)
    end
  end

  return vim.fs.root(fname, {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  })
end

return {
  root_dir = function(bufnr, on_dir)
    local root = root_for(vim.api.nvim_buf_get_name(bufnr))

    if root then
      on_dir(root)
    end
  end,

  -- Resolved per project at attach time, not once at startup, so a different
  -- project opened in the same session gets its own interpreter. vim.lsp
  -- deepcopies the config before start_config, so this mutates a per-client
  -- copy rather than the cached resolved config.
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
