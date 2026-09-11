local present, null_ls = pcall(require, "null-ls")

if not present then
  return
end

local function use_extra(path)
  local ok, extra = pcall(require, "none-ls." .. path)
  return ok and extra or nil
end

local eslint_config_files = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  ".eslintrc.js",
  ".eslintrc.json",
  ".eslintrc",
}

--- Look for an eslint config from the buffer upwards rather than from cwd.
--- Keying off cwd misbehaves in monorepos and after any :cd.
local function eslint_root(params)
  return vim.fs.root(params and params.bufnr or 0, eslint_config_files)
end

local diagnostics = use_extra "diagnostics.eslint_d"
local code_actions = use_extra "code_actions.eslint_d"

local sources = {}

if diagnostics then
  table.insert(
    sources,
    diagnostics.with {
      filetypes = { "javascript", "typescript", "html", "htmlangular" },
      timeout = 5000,
      condition = function()
        return eslint_root() ~= nil
      end,
      method = {
        null_ls.methods.DIAGNOSTICS_ON_OPEN,
        null_ls.methods.DIAGNOSTICS_ON_SAVE,
      },
      cwd = eslint_root,
    }
  )
end

if code_actions then
  table.insert(sources, code_actions)
end

null_ls.setup {
  -- was left on, which writes verbose output to the null-ls log on every run
  debug = false,
  sources = sources,
}
