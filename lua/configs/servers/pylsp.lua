-- basedpyright owns diagnostics, completion, hover and navigation. pylsp runs
-- alongside it purely for rope's auto-import index, which - unlike pyright -
-- covers every package installed in the venv, not just the ones already
-- imported somewhere in the workspace. Every other plugin is off so it can't
-- duplicate basedpyright's output.
--
-- pylsp runs from mason's own venv, so rope would otherwise index that venv
-- rather than the project's. rope builds its index from sys.path, so the
-- project's site-packages goes in via PYTHONPATH at spawn time.
local function project_site_packages()
  local root = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" })
  local venv = root and vim.fs.find(".venv", { path = root, upward = true, type = "directory" })[1]

  if not venv then
    return nil
  end

  local matches = vim.fn.glob(venv .. "/lib/python*/site-packages", false, true)
  return matches[1]
end

return {
  cmd = function(dispatchers)
    -- the only hook pylsp cannot start without, so the self-heal can't be
    -- bypassed by a mason reinstall
    pcall(function()
      require("utils.pyvenv").ensure()
    end)

    local site_packages = project_site_packages()
    local env = site_packages and { PYTHONPATH = site_packages } or {}

    return vim.lsp.rpc.start({ "pylsp" }, dispatchers, { env = env })
  end,

  settings = {
    pylsp = {
      plugins = {
        autopep8 = { enabled = false },
        flake8 = { enabled = false },
        folding = { enabled = false },
        jedi_completion = { enabled = false },
        jedi_definition = { enabled = false },
        jedi_highlight = { enabled = false },
        jedi_hover = { enabled = false },
        jedi_references = { enabled = false },
        jedi_rename = { enabled = false },
        jedi_signature_help = { enabled = false },
        jedi_symbols = { enabled = false },
        jedi_type_definition = { enabled = false },
        mccabe = { enabled = false },
        preload = { enabled = false },
        pycodestyle = { enabled = false },
        pydocstyle = { enabled = false },
        pyflakes = { enabled = false },
        pylint = { enabled = false },
        rope_completion = { enabled = false },
        yapf = { enabled = false },

        rope_autoimport = {
          enabled = true,
          -- Keep the index in memory; on disk rope drops a ~14MB sqlite file
          -- into the project root. It still creates an empty .ropeproject/
          -- there - pylsp's config merge discards null values, so the
          -- ropeFolder=null that would disable it can never reach rope.
          memory = true,
          completions = { enabled = true },
          code_actions = { enabled = true },
        },
      },
    },
  },
}
