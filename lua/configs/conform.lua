-- oxfmt where the project has an oxfmt config, prettier everywhere else
local web = { "oxfmt", "prettier", stop_after_first = true }

-- for formatters only some projects provide: an empty list rather than an
-- unavailable formatter, which would warn on every save
local function only_if_available(name)
  return function(bufnr)
    return require("conform").get_formatter_info(name, bufnr).available and { name } or {}
  end
end

return {
  formatters_by_ft = {
    -- the project's mise buildifier (mason's is skipped in chadrc so it can't
    -- shadow the pinned version pre-commit runs)
    bzl = only_if_available "buildifier",
    c = { "clang-format" },
    cpp = { "clang-format" },
    cs = { "csharpier" },
    css = web,
    html = web,
    htmlangular = { "prettier" },
    javascript = web,
    javascriptreact = web,
    json = web,
    -- oxfmt-only, so projects without an oxfmt config keep not formatting these
    jsonc = only_if_available "oxfmt",
    yaml = only_if_available "oxfmt",
    -- added so CI's stylua --check and format-on-save agree
    lua = { "stylua" },
    markdown = web,
    -- ruff rather than black: it is what uv projects reach for, it is fast, and
    -- it picks up [tool.ruff] from the project's pyproject.toml. Imports first,
    -- then formatting.
    python = { "ruff_organize_imports", "ruff_format" },
    typescript = web,
    typescriptreact = web,
  },

  -- project-pinned tools come from mise, so saves match pre-commit (see utils/mise.lua)
  formatters = {
    -- only where the project pins it; unavailable (and silent) everywhere else
    buildifier = {
      command = function(_, ctx)
        return require("utils.mise").which("buildifier", ctx.dirname) or "buildifier"
      end,
      condition = function(_, ctx)
        return require("utils.mise").which("buildifier", ctx.dirname) ~= nil
      end,
    },
    -- unavailable unless an .oxfmtrc.json(c) is found upward
    oxfmt = { require_cwd = true },
    -- the project's ruff, else mason's
    ruff_format = {
      command = function(_, ctx)
        return require("utils.mise").which("ruff", ctx.dirname) or "ruff"
      end,
    },
    ruff_organize_imports = {
      command = function(_, ctx)
        return require("utils.mise").which("ruff", ctx.dirname) or "ruff"
      end,
    },
  },

  -- A function rather than a table so <leader>tf can switch it off per session
  -- or per buffer - useful when editing someone else's file.
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end

    return {
      timeout_ms = 3000,
      -- `lsp_fallback` was deprecated in conform 8. Note the fallback is inert
      -- anyway: configs/lspconfig.lua disables documentFormattingProvider on
      -- every client, so a missing formatter is a silent no-op.
      lsp_format = "fallback",
    }
  end,
}
