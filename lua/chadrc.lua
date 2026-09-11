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
    -- not derivable: eslint_d is used through null-ls, stylua only by conform
    pkgs = { "eslint_d", "stylua" },
    -- a ruby gem, not a mason package: gem install solargraph
    skip = { "solargraph" },
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
