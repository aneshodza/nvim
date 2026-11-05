local M = {}

--- In a uv workspace every member shares one .venv, and sibling libraries are
--- installed into it as editable .pth entries. nvim-lspconfig's root_markers
--- stop at the first pyproject.toml, which is the *member* directory - so those
--- sibling libraries land outside the workspace and pyright treats them as
--- third-party: indexed once at startup and never watched. Editing or adding a
--- file in one then does nothing until :lsp restart.
---
--- Rooting at the workspace instead keeps them inside it, so they are watched
--- like any other source file. ty finds the workspace .venv from here too.
--- @param fname string
--- @return string?
function M.root_for(fname)
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

--- vim.lsp.Config.root_dir built on root_for.
function M.root_dir(bufnr, on_dir)
  local root = M.root_for(vim.api.nvim_buf_get_name(bufnr))

  if root then
    on_dir(root)
  end
end

return M
