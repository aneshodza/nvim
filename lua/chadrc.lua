-- Only the deltas against NvChad's defaults, which live in the ui plugin's
-- lua/nvconfig.lua. Anything that matched the default (theme, theme_toggle,
-- transparency, cmp style, telescope style, statusline, tabufline, cheatsheet,
-- lsp.signature) is deliberately omitted rather than restated.

---@type ChadrcConfig
return {
  -- NvChad derives most packages from the enabled LSP configs and conform
  -- formatters, so angular-language-server, omnisharp, csharpier, basedpyright,
  -- python-lsp-server, clangd, prettier and friends come for free.
  mason = {
    -- Not derivable: eslint_d comes in through null-ls, stylua only through
    -- conform, and rust-analyzer is driven by rustaceanvim rather than by a
    -- server spec in configs/servers.
    -- ruff is listed explicitly because NvChad's name map has no entry for
    -- conform's ruff_format / ruff_organize_imports, so it cannot derive it.
    pkgs = { "eslint_d", "ruff", "rust-analyzer", "stylua" },
    -- a ruby gem, not a mason package: gem install solargraph
    skip = { "solargraph" },
  },

  cheatsheet = {
    -- The heading is the first word of each mapping's desc, so these hide
    -- entries that are plumbing rather than shortcuts. The first four are
    -- NvChad's own defaults - this list replaces rather than extends them.
    excluded_groups = {
      "terminal (t)",
      "autopairs",
      "Nvim",
      "Opens",

      -- These must match the RAW first word of the desc: NvChad checks the
      -- exclusion list before capitalising the heading.
      "which-key-trigger",
      "vim.snippet.jump",
      "LuaSnip:",
      "Dont",
    },
  },

  nvdash = {
    -- upstream defaults this to false
    load_on_startup = true,

    header = {
      "                                        ",
      "                        ██              ",
      " ███ ███   ███     ███     ████ ███ ███ ",
      "  ███  ███  ███   ███  ███  ███  ██  ███",
      "  ███  ███   ███ ███   ███  ███  ██  ███",
      "  ███  ███    █████    ███  ███  ██  ███",
      " ████  ███     ███     ███ ████  ██  ███",
      "                                        ",
    },

    -- v3.0 replaced the { "label", "Spc f f", "cmd" } triple with this shape
    buttons = {
      { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
      { txt = "󰈚  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
      { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
      { txt = "  Bookmarks", keys = "ma", cmd = "Telescope marks" },
      { txt = "  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
      { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
    },
  },
}
