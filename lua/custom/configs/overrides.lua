local M = {}
local cmp = require "cmp"

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
    ignore = false,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

-- copilot
M.copilot = {
  -- Possible configurable fields can be found on:
  -- https://github.com/zbirenbaum/copilot.lua#setup-and-configuration
  md = "Copilot",
  event = "InsertEnter",
}

local cmp_active = false
M.cmp = {
  sources = {
    { name = "nvim_lsp", group_index = 2 },
    { name = "copilot", group_index = 2 },
    { name = "luasnip", group_index = 2 },
    { name = "buffer", group_index = 2 },
    { name = "nvim_lua", group_index = 2 },
    { name = "path", group_index = 2 },
  },

  mapping = {
    ["<Tab>"] = cmp.mapping(function(fallback)
      if vim.fn.pumvisible() == 0 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n")
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if vim.fn.pumvisible() == 0 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true), "n")
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<Down>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
    ["<Up>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
    ["<CR>"] = cmp.mapping(function(fallback)
      if vim.fn.pumvisible() == 0 and cmp_active then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n")
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<C-Right>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    },
    ["<C-Enter>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    },
  },

  event = {
    on_confirm_done = function()
      cmp_active = false
    end,
    on_menu_open = function()
      cmp_active = true
    end,
    on_menu_close = function()
      cmp_active = false
    end,
  },
}

M.lazy_nvimtree = {
  dev = os.getenv "HOME" .. "/p",
}

return M
