-- <leader>uv* toolset for uv projects.
--
-- Deliberately not a TOML parser: uvd only needs string arrays under three
-- known keys, so it reads those directly rather than carrying a dependency.

local M = {}

---------------------------------------------------------------- roots

--- Nearest pyproject.toml going up - in a workspace this is the member.
--- @return string? dir
function M.member_root(path)
  local found = vim.fs.find("pyproject.toml", {
    path = vim.fs.dirname(path or vim.api.nvim_buf_get_name(0)),
    upward = true,
  })[1]

  return found and vim.fs.dirname(found)
end

--- The pyproject.toml carrying [tool.uv.workspace], if there is one.
--- @return string? dir
function M.workspace_root(path)
  local candidates = vim.fs.find(function(name)
    return name == "pyproject.toml"
  end, {
    path = vim.fs.dirname(path or vim.api.nvim_buf_get_name(0)),
    upward = true,
    limit = math.huge,
  })

  for _, file in ipairs(candidates) do
    local ok, lines = pcall(vim.fn.readfile, file)

    if ok and table.concat(lines, "\n"):find "%[tool%.uv%.workspace%]" then
      return vim.fs.dirname(file)
    end
  end
end

---------------------------------------------------------------- toml

--- Collect `key = [ "a", "b" ]` arrays, keyed by section. Handles the
--- multi-line form. Inline tables (authors = [{ name = ... }]) are collected
--- too, but nothing here asks for those keys.
local function arrays(file)
  local ok, lines = pcall(vim.fn.readfile, file)

  if not ok then
    return {}
  end

  local out, section, open_key, buf = {}, "", nil, nil

  local function store(sec, key, values)
    out[sec] = out[sec] or {}
    out[sec][key] = values
  end

  for _, line in ipairs(lines) do
    local header = line:match "^%s*%[([^%]]+)%]%s*$"

    if header then
      section, open_key = header, nil
    elseif open_key then
      for value in line:gmatch '"([^"]+)"' do
        table.insert(buf, value)
      end

      -- strip strings first: "psycopg[binary]>=3.3.5" contains a ] that would
      -- otherwise look like the end of the array
      if line:gsub('"[^"]*"', ""):find "%]" then
        store(section, open_key, buf)
        open_key, buf = nil, nil
      end
    else
      local key, rest = line:match "^%s*([%w_%-]+)%s*=%s*(%[.*)$"

      if key then
        buf = {}

        for value in rest:gmatch '"([^"]+)"' do
          table.insert(buf, value)
        end

        if rest:gsub('"[^"]*"', ""):find "%]" then
          store(section, key, buf)
          buf = nil
        else
          open_key = key
        end
      end
    end
  end

  return out
end

local function project_name(file)
  local ok, lines = pcall(vim.fn.readfile, file)

  if not ok then
    return nil
  end

  for _, line in ipairs(lines) do
    local name = line:match '^%s*name%s*=%s*"([^"]+)"'

    if name then
      return name
    end
  end
end

---------------------------------------------------------------- float

local function open_float(title, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "uvtools"

  local width = 0

  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  width = math.min(math.max(width + 4, 46), vim.o.columns - 8)
  local height = math.min(math.max(#lines, 3), vim.o.lines - 8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  vim.wo[win].wrap = false

  for _, key in ipairs { "q", "<Esc>" } do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true })
  end
end

---------------------------------------------------------------- running uv

--- @param args string[]
--- @param on_done fun(output: string[], failed: boolean)
local function run(args, on_done)
  local root = M.workspace_root() or M.member_root()

  if not root then
    vim.notify("uv: no pyproject.toml above this buffer", vim.log.levels.WARN)
    return
  end

  vim.notify("uv " .. table.concat(args, " ") .. " ...")

  vim.system(vim.list_extend({ "uv" }, args), { cwd = root, text = true }, function(res)
    local output = vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true })

    vim.schedule(function()
      on_done(output, res.code ~= 0)
    end)
  end)
end

---------------------------------------------------------------- commands

--- uvd - direct dependencies declared in this member's and the root's toml.
function M.deps()
  local member = M.member_root()

  if not member then
    vim.notify("uv: no pyproject.toml above this buffer", vim.log.levels.WARN)
    return
  end

  local root = M.workspace_root()
  local lines = {}

  local function section(file, label)
    local toml = arrays(file)
    local name = project_name(file) or vim.fs.basename(vim.fs.dirname(file))

    table.insert(lines, ("%s  %s"):format(name, label))

    local deps = (toml["project"] or {})["dependencies"] or {}

    if #deps == 0 then
      table.insert(lines, "    (no dependencies)")
    end

    for _, dep in ipairs(deps) do
      table.insert(lines, "    " .. dep)
    end

    for group, entries in pairs(toml["dependency-groups"] or {}) do
      table.insert(lines, ("    [%s]"):format(group))

      for _, dep in ipairs(entries) do
        table.insert(lines, "      " .. dep)
      end
    end

    local members = (toml["tool.uv.workspace"] or {})["members"]

    if members then
      table.insert(lines, "    [workspace members]")

      for _, m in ipairs(members) do
        table.insert(lines, "      " .. m)
      end
    end
  end

  section(member .. "/pyproject.toml", "(this project)")

  if root and root ~= member then
    table.insert(lines, "")
    section(root .. "/pyproject.toml", "(workspace root)")
  end

  open_float("uv deps", lines)
end

--- uvp - which interpreter everything actually resolved to.
function M.env()
  local root = M.workspace_root() or M.member_root()
  local lines = {}

  local function add(label, value)
    table.insert(lines, ("%-16s %s"):format(label, value or "-"))
  end

  add("workspace", root)
  add("member", M.member_root())

  local venv = root and vim.fs.joinpath(root, ".venv")
  local venv_python = venv and vim.fs.joinpath(venv, "bin/python")
  local has_venv = venv_python and vim.fn.executable(venv_python) == 1

  add("venv", has_venv and venv or (venv and venv .. "  (missing - run uv sync)"))

  if has_venv then
    add("python", vim.fn.trim(vim.fn.system { venv_python, "-c", "import sys; print(sys.version.split()[0])" }))
  end

  local uv_bin = vim.fn.exepath "uv"
  add("uv", uv_bin ~= "" and vim.fn.trim(vim.fn.system { "uv", "--version" }) or "not on PATH")

  table.insert(lines, "")

  local bp = vim.lsp.get_clients({ name = "basedpyright", bufnr = 0 })[1]
  local bp_path = bp and vim.tbl_get(bp.settings or {}, "python", "pythonPath")

  add("basedpyright", bp and (bp_path or "(no pythonPath)") or "not attached")

  if bp_path and has_venv then
    add("", bp_path == venv_python and "matches the venv" or "DOES NOT match the venv")
  end

  local py = vim.lsp.get_clients({ name = "pylsp", bufnr = 0 })[1]
  add("pylsp", py and "attached" or "not attached")

  if bp then
    add("lsp root", tostring(bp.root_dir))
  end

  open_float("uv env", lines)
end

--- uvy - sync, then restart the servers so new packages are actually seen.
function M.sync()
  run({ "sync" }, function(output, failed)
    open_float(failed and "uv sync (failed)" or "uv sync", output)

    if not failed then
      -- pyright indexes site-packages once at startup, so a package added by
      -- this sync stays invisible until the server restarts
      vim.cmd "LspRestart"
      vim.notify "uv sync complete, LSP restarted"
    end
  end)
end

--- uva - audit for known vulnerabilities.
function M.audit()
  run({ "audit" }, function(output)
    open_float("uv audit", output)
  end)
end

--- uvt - full dependency tree.
function M.tree()
  run({ "tree" }, function(output)
    open_float("uv tree", output)
  end)
end

return M
