-- nvim --headless -l scripts/lsp_smoke.lua <language>
--
-- Proves the editor is actually wired up for a language, end to end: the right
-- client attaches to a real project, a seeded error produces a diagnostic, and
-- <leader>fi offers a code action for it.
--
-- This deliberately does NOT force-load nvim-lspconfig. It opens a file and
-- lets the real trigger chain run, because that chain is where the subtle
-- breakage lives: NvChad fires `User FilePost` only when vim.g.ui_entered is
-- set, and that flag comes from UIEnter, which never fires headless. Miss it
-- and nothing attaches while every other check still passes.

local config_dir = vim.fn.stdpath "config"
local lib = dofile(config_dir .. "/scripts/lib.lua")

local SPECS = {
  python = {
    file = "main.py",
    -- basedpyright types and pylsp supplies rope's auto-import index
    clients = { "basedpyright", "pylsp" },
    cursor = { 1, 10 },
    diagnostic = "defaultdict",
    -- stdlib on purpose: no venv or third-party package needed in CI
    action = "^from collections import defaultdict",
  },

  typescript = {
    file = "main.ts",
    clients = { "ts_ls" },
    cursor = { 1, 30 },
    diagnostic = "not assignable",
  },

  rust = {
    file = "src/main.rs",
    -- rustaceanvim starts and names the client itself: "rust-analyzer" with a
    -- hyphen, not the "rust_analyzer" key nvim-lspconfig would have used.
    clients = { "rust-analyzer" },
    cursor = { 2, 21 },
    -- rust-analyzer's own type check says "expected i32, found &str"; cargo
    -- check/clippy says "mismatched types". Which one arrives depends on
    -- whether flycheck has run, and flycheck is on-save only - so accept
    -- either rather than depending on a save.
    diagnostic = { "mismatched types", "expected i32", "expected `i32`" },
  },

  lua = {
    file = "main.lua",
    -- configured by nvchad.configs.lspconfig.defaults(), not by us
    clients = { "lua_ls" },
    cursor = { 1, 14 },
    diagnostic = "undefined_global_symbol",
  },
}

local lang = (_G.arg or {})[1]
local spec = SPECS[lang]

if not spec then
  error(("usage: lsp_smoke.lua <%s>"):format(table.concat(vim.tbl_keys(SPECS), "|")), 0)
end

local failures = {}

local function check(cond, msg)
  if not cond then
    failures[#failures + 1] = msg
  end
end

local function report()
  if #failures > 0 then
    io.stderr:write("\n" .. table.concat(failures, "\n\n") .. "\n")
    error(("lsp_smoke[%s]: %d check(s) failed"):format(lang, #failures), 0)
  end

  io.stdout:write(("lsp_smoke[%s]: ok\n"):format(lang))
end

-- leave everything lazy so the real trigger chain is what starts the server
local errors = lib.boot { force_load = false }
lib.enter_ui()

local fixture = ("%s/tests/fixtures/%s/%s"):format(config_dir, lang, spec.file)
check(vim.fn.filereadable(fixture) == 1, "fixture missing: " .. fixture)

vim.cmd.edit(vim.fn.fnameescape(fixture))
vim.cmd.lcd(vim.fn.fnameescape(vim.fs.dirname(fixture)))

local bufnr = vim.api.nvim_get_current_buf()
local filetype = vim.bo[bufnr].filetype

-- lazy's `ft` trigger does not fire reliably under `nvim -l`, so an ft-gated
-- plugin that starts its own client (rustaceanvim, which owns rust_analyzer
-- rather than a spec in configs/servers) would never load and the client would
-- never appear. Load anything matching this buffer's filetype explicitly - a
-- real session gets there via the FileType event.
for name, plugin in pairs(require("lazy.core.config").spec.plugins) do
  local fts = plugin.ft

  if type(fts) == "string" then
    fts = { fts }
  end

  if type(fts) == "table" and vim.tbl_contains(fts, filetype) then
    pcall(function()
      require("lazy").load { plugins = { name } }
    end)
  end
end

lib.drain(500)

-- 1. the expected clients attach ---------------------------------------------
local function attached()
  local names = {}

  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    names[client.name] = true
  end

  return names
end

vim.wait(90000, function()
  local names = attached()

  for _, want in ipairs(spec.clients) do
    if not names[want] then
      return false
    end
  end

  return true
end, 250)

local names = attached()

for _, want in ipairs(spec.clients) do
  check(names[want], ("client %q never attached (attached: %s)"):format(want, vim.inspect(vim.tbl_keys(names))))
end

if #failures > 0 then
  report()
end

-- 2. the seeded error produces a diagnostic -----------------------------------
vim.wait(90000, function()
  return #vim.diagnostic.get(bufnr) > 0
end, 250)

local diagnostics = vim.diagnostic.get(bufnr)
check(#diagnostics > 0, "no diagnostics produced for the seeded error")

local wanted = type(spec.diagnostic) == "table" and spec.diagnostic or { spec.diagnostic }
local matched = false

for _, d in ipairs(diagnostics) do
  for _, want in ipairs(wanted) do
    if d.message:lower():find(want:lower(), 1, true) then
      matched = true
    end
  end
end

check(
  matched,
  ("no diagnostic matching any of %s; got: %s"):format(
    vim.inspect(wanted),
    vim.inspect(vim.tbl_map(function(d)
      return d.message
    end, diagnostics))
  )
)

-- 3. a code action is offered for it ------------------------------------------
vim.api.nvim_win_set_cursor(0, spec.cursor)

local titles, pending = {}, 0

for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
  pending = pending + 1

  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)

  -- Mirrors utils.lsp.code_action: rope only matches flake8/mypy-shaped
  -- diagnostics, so basedpyright's code is relabelled for the request.
  local lsp_diagnostics = {}

  for _, d in ipairs(vim.diagnostic.get(bufnr, { lnum = spec.cursor[1] - 1 })) do
    local ld = d.user_data and d.user_data.lsp

    if ld then
      if ld.code == "reportUndefinedVariable" then
        ld = vim.tbl_extend("force", ld, { code = "name-defined" })
      end

      table.insert(lsp_diagnostics, ld)
    end
  end

  params.context = { diagnostics = lsp_diagnostics }

  client:request("textDocument/codeAction", params, function(_, result)
    for _, action in ipairs(result or {}) do
      titles[#titles + 1] = tostring(action.title)
    end

    pending = pending - 1
  end, bufnr)
end

vim.wait(30000, function()
  return pending == 0
end, 100)

check(#titles > 0, "no code actions offered at the diagnostic")

if spec.action then
  local found = false

  for _, title in ipairs(titles) do
    if title:find(spec.action) then
      found = true
    end
  end

  check(found, ("no action matching %q; got: %s"):format(spec.action, vim.inspect(titles)))
end

io.stdout:write(
  ("[%s] clients=%s diagnostics=%d actions=%d\n"):format(lang, table.concat(spec.clients, ","), #diagnostics, #titles)
)

check(#errors == 0, "ERROR notifications during startup:\n" .. table.concat(errors, "\n---\n"))
report()
