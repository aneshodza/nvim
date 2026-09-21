-- basedpyright owns diagnostics, completion, hover and navigation. pylsp runs
-- alongside it purely for rope's auto-import index, which - unlike pyright -
-- covers every package installed in the venv, not just the ones already
-- imported somewhere in the workspace. Every other plugin is off so it can't
-- duplicate basedpyright's output.
--
-- pylsp runs from mason's own venv, so rope would otherwise index that venv
-- rather than the project's. rope builds its index from sys.path, so the
-- project's site-packages goes in via PYTHONPATH at spawn time.
local function site_packages()
  local root = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" })
  local venv = root and vim.fs.find(".venv", { path = root, upward = true, type = "directory" })[1]

  if not venv then
    return nil
  end

  local matches = vim.fn.glob(venv .. "/lib/python*/site-packages", false, true)
  return matches[1]
end

--- Source roots declared by editable installs.
---
--- `uv sync` writes one .pth per workspace member holding the absolute path of
--- its source root, e.g. services/reader/src. Those are the directories Python
--- itself imports from, so they are also the only correct base for a module
--- name.
---
--- This matters because .pth files are processed by the `site` module for real
--- site-packages directories at interpreter start, NOT for entries handed to
--- PYTHONPATH. Passing site-packages alone therefore leaves rope unable to see
--- these packages at all, and it falls back to scanning the project tree, where
--- it derives the module name from its own root and produces
--- `src.kiosk_reader.…` instead of `kiosk_reader.…`.
--- @return string[]
local function editable_roots()
  local packages = site_packages()

  if not packages then
    return {}
  end

  local roots = {}

  for _, pth in ipairs(vim.fn.glob(packages .. "/*.pth", false, true)) do
    local ok, lines = pcall(vim.fn.readfile, pth)

    if ok then
      for _, line in ipairs(lines) do
        -- a path line, not the `import ...` form some tools emit
        if line:sub(1, 1) == "/" and vim.fn.isdirectory(line) == 1 then
          table.insert(roots, line)
        end
      end
    end
  end

  return roots
end

return {
  --- Root at the source root rather than the project dir, so rope names modules
  --- the way Python does. Rooting at services/reader makes it walk down through
  --- src/ and call the package src.kiosk_reader.
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local best

    for _, root in ipairs(editable_roots()) do
      if vim.startswith(fname, root .. "/") and (not best or #root > #best) then
        best = root
      end
    end

    local dir = best or vim.fs.root(fname, { "pyproject.toml", "setup.py", ".git" })

    if dir then
      on_dir(dir)
    end
  end,

  cmd = function(dispatchers)
    -- the only hook pylsp cannot start without, so the self-heal can't be
    -- bypassed by a mason reinstall
    pcall(function()
      require("utils.pyvenv").ensure()
    end)

    -- site-packages for third-party imports, plus every editable source root so
    -- workspace packages are named from the right base
    local paths = editable_roots()
    local packages = site_packages()

    if packages then
      table.insert(paths, packages)
    end

    local env = #paths > 0 and { PYTHONPATH = table.concat(paths, ":") } or {}

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
