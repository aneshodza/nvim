-- nvim --headless -l scripts/checkload.lua
--
-- Runs with loadplugins = false and init.lua unsourced, so it needs no plugins
-- and finishes in a couple of seconds. That makes it the first CI gate: it
-- catches the common breakage before the job pays for a plugin install.
--
-- `nvim -l` is used rather than `-u init.lua +qa` because headless nvim exits 0
-- even when the config raises - only `-l` propagates a failure as exit 1.

local root = vim.fn.stdpath "config"
local failures = {}

local function check(cond, msg)
  if not cond then
    failures[#failures + 1] = msg
  end
end

local function lua_files(glob)
  return vim.fn.glob(root .. glob, false, true)
end

-- 1. everything parses ------------------------------------------------------
for _, file in ipairs(lua_files "/lua/**/*.lua") do
  local _, err = loadfile(file)
  check(not err, "parse: " .. tostring(err))
end

-- 2. portability and migration-completeness invariants ----------------------
local banned = {
  { pat = 'os%.getenv%("HOME"%)', why = "hardcoded $HOME, use vim.fn.stdpath" },
  { pat = "/Users/", why = "hardcoded macOS user path" },
  { pat = "%.local/share/nvim", why = "hardcoded data dir, use vim.fn.stdpath 'data'" },
  { pat = "core%.utils", why = "leftover NvChad v2.0 module" },
  { pat = "core%.os_check", why = "leftover NvChad v2.0 module" },
  { pat = "plugins%.configs", why = "leftover NvChad v2.0 module path" },
  { pat = "load_mappings", why = "leftover NvChad v2.0 API" },
}

for _, file in ipairs(lua_files "/lua/**/*.lua") do
  local code = {}

  -- Strip line comments before scanning. Several of these patterns appear in
  -- prose explaining why the code avoids them, and flagging those is noise.
  for _, line in ipairs(vim.fn.readfile(file)) do
    if not line:match "^%s*%-%-" then
      code[#code + 1] = line:gsub("%s+%-%-[^\"']*$", "")
    end
  end

  local src = table.concat(code, "\n")

  for _, rule in ipairs(banned) do
    check(not src:find(rule.pat), ("%s: %s"):format(vim.fs.basename(file), rule.why))
  end
end

-- 3. pure modules load with zero plugins ------------------------------------
for _, mod in ipairs {
  "chadrc",
  "configs.conform",
  "configs.lazy",
  "utils.quickfix",
  "utils.lsp",
  "utils.pyvenv",
  "nvimrc.health",
} do
  local loaded, err = pcall(require, mod)
  check(loaded, ("require %q: %s"):format(mod, err))
end

-- 4. server specs are pure data ---------------------------------------------
-- vim.lsp.config merges '*' -> lsp/<name>.lua -> name-level, highest wins, so a
-- per-server on_attach or capabilities silently overrides nvim-lspconfig's own.
-- That is how omnisharp lost its workspaceFolders = false workaround.
local env_before = vim.fn.environ()

for _, file in ipairs(lua_files "/lua/configs/servers/*.lua") do
  local name = vim.fn.fnamemodify(file, ":t:r")

  if name ~= "init" then
    local loaded, spec = pcall(require, "configs.servers." .. name)
    check(loaded and type(spec) == "table", ("server %s must return a table: %s"):format(name, spec))

    if loaded and type(spec) == "table" then
      check(spec.on_attach == nil, ("server %s sets on_attach; that shadows nvim-lspconfig's own"):format(name))
      check(
        spec.capabilities == nil,
        ("server %s sets capabilities; that clobbers lsp/%s.lua's workarounds"):format(name, name)
      )
    end
  end
end

for key, value in pairs(vim.fn.environ()) do
  check(env_before[key] == value, "a server spec mutated the environment at load time: " .. key)
end

-- 5. the pyvenv self-heal is correct and idempotent -------------------------
local tmp = vim.fn.tempname()
vim.fn.writefile({ "home = /x", "include-system-site-packages = true" }, tmp)

local pyvenv = require "utils.pyvenv"
check(pyvenv.ensure(tmp) == "fixed", "pyvenv.ensure should report 'fixed' on a true value")
check(pyvenv.ensure(tmp) == "ok", "pyvenv.ensure should be idempotent")
check(vim.fn.readfile(tmp)[2] == "include-system-site-packages = false", "pyvenv rewrote the wrong thing")
vim.fn.delete(tmp)

-- report --------------------------------------------------------------------
if #failures > 0 then
  io.stderr:write("\n" .. table.concat(failures, "\n") .. "\n")
  error(("checkload: %d check(s) failed"):format(#failures), 0)
end

io.stdout:write "checkload: ok\n"
