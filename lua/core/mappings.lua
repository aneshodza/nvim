-- n, v, i, t = mode names

local M = {}

M.general = {
  i = {
    -- navigate within insert mode
    ["<C-h>"] = { "<Left>", "Move left" },
    ["<C-l>"] = { "<Right>", "Move right" },
    ["<C-j>"] = { "<Down>", "Move down" },
    ["<C-k>"] = { "<Up>", "Move up" },
  },

  n = {
    -- Find and replace in buffer
    ["<leader>rp"] = {
      ":lua local search = vim.fn.input('Search for: '); local replace = vim.fn.input('Replace with: '); vim.fn.feedkeys(':%s#' .. search .. '#' .. replace .. '#gi')<CR>",
      "Replace word",
    },

    -- resize
    ["<leader>rhm"] = { "<cmd>horizontal resize +10<CR>", "Resize horizontal +10" },
    ["<leader>rhl"] = { "<cmd>horizontal resize -10<CR>", "Resize horizontal -10" },
    ["<leader>rhs"] = { "<cmd>horizontal resize 15<CR>", "Resize horizontal to be small (15)" },
    ["<leader>rhc"] = { "<cmd>horizontal resize ", "Resize horizontal custom" },

    ["<leader>rvm"] = { "<cmd>vertical resize +10<CR>", "Resize vertical +10" },
    ["<leader>rvl"] = { "<cmd>vertical resize -10<CR>", "Resize vertical -10" },
    ["<leader>rvs"] = { "<cmd>vertical resize 15<CR>", "Resize vertical to be small (15)" },
    ["<leader>rvc"] = { "<cmd>vertical resize ", "Resize vertical custom" },

    -- split
    ["<leader>sh"] = { "<cmd>split<CR>", "Split horizontal" },
    ["<leader>sv"] = { "<cmd>vsplit<CR>", "Split vertical" },
    ["<leader>h"] = { "<cmd>split<CR>", "Split horizontal" },
    ["<leader>v"] = { "<cmd>vsplit<CR>", "Split vertical" },

    -- Clear highlights
    ["<Esc>"] = { ":noh <CR>", "Clear highlights" },

    -- Swap lines
    ["<C-Up>"] = { ":m .-2<CR>==", "Move line up" },
    ["<C-Down>"] = { ":m .+1<CR>==", "Move line down" },

    -- switch between windows
    ["<C-h>"] = { "<C-w>h", "Window left" },
    ["<C-l>"] = { "<C-w>l", "Window right" },
    ["<C-j>"] = { "<C-w>j", "Window down" },
    ["<C-k>"] = { "<C-w>k", "Window up" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    -- Copy all
    ["<C-c>"] = { "<cmd> %y+ <CR>", "Copy whole file" },

    -- line numbers
    ["<leader>n"] = { "<cmd> set nu! <CR>", "Toggle line number" },
    ["<leader>rn"] = { "<cmd> set rnu! <CR>", "Toggle relative number" },

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },

    -- new buffer
    ["<leader>b"] = { "<cmd> enew <CR>", "New buffer" },
    ["<leader>ch"] = { "<cmd> NvCheatsheet <CR>", "Mapping cheatsheet" },

    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format { async = true }
      end,
      "LSP formatting",
    },

    ["<leader>de"] = {
      function()
        -- 1. Get the root directory from OmniSharp
        local root_dir = nil
        for _, client in ipairs(vim.lsp.get_clients({ name = "omnisharp" })) do
          root_dir = client.config.root_dir
          break
        end

        -- Fallback to CWD if OmniSharp isn't running or hasn't found a root
        root_dir = root_dir or vim.fn.getcwd()

        -- 2. Check if 'dotnet' exists
        if vim.fn.executable("dotnet") == 0 then
          vim.api.nvim_err_writeln("Error: 'dotnet' command not found.")
          return
        end

        -- 3. Notify and Build
        print(" Building project at " .. root_dir)
        
        -- We use -C to run the command as if we were in the root_dir
        local cmd = string.format("cd %s && dotnet build --property WarningLevel=0 | grep -oE '[^ ]+\\.cs\\([0-9]+,[0-9]+\\)' | sort -u", vim.fn.shellescape(root_dir))
        
        -- 4. Set format and run
        vim.opt.errorformat = [[%f(%l\,%c)]]
        local output = vim.fn.system(cmd)
        output = vim.trim(output)

        print(" Build completed.")

        if output ~= "" then
          vim.fn.setqflist({}, ' ', {
            title = " Dotnet Errors: " .. vim.fn.fnamemodify(root_dir, ":t"),
            lines = vim.split(output, "\n")
          })
          vim.cmd("copen")
        else
          vim.cmd("cclose")
          print("󱜙 Build successful, no errors were found!")
        end
      end,
      "Open dotnet errors in quickfix",
    },

    ["<leader>gc"] = {
      function()
        -- 1. Get only the lines starting with <<<<<<< from unmerged files
        local cmd = "git diff --name-only --diff-filter=U --relative 2>/dev/null | xargs grep -nH '^<<<<<<<' | awk -F: '{count[$1]++; print $1\":\"$2\":  Conflict #\"count[$1]}'"
        local output = vim.fn.systemlist(cmd)

        if #output > 0 then
          local old_efm = vim.opt.errorformat
          -- grep -nH output is 'filename:line:text'
          vim.opt.errorformat = "%f:%l:%m"

          vim.fn.setqflist({}, ' ', {
            title = "󰊢 Git Conflicts",
            lines = output
          })

          vim.opt.errorformat = old_efm
          vim.cmd("copen")
          print("󰊢 Found " .. #output .. " conflict blocks.")
        else
          vim.cmd("cclose")
          print("󰄬 No conflict markers found!")
        end
      end,
      "Open unique conflict markers in quickfix",
    },

    ["<leader>td"] = { "<cmd>TodoTelescope<cr>", "Search TODOs" },
  },

  t = {
    ["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
  },

  v = {
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
  },

  x = {
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },

    ["<C-Up>"] = { ":move '<-2<CR>gv=gv", "Move selection up", opts = { silent = true } },
    ["<C-Down>"] = { ":move '>+1<CR>gv=gv", "Move selection down", opts = { silent = true } },
  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- close buffer + hide terminal buffer
    ["<leader>x"] = {
      function()
        require("nvchad.tabufline").close_buffer()
      end,
      "Close buffer",
    },
    ["<Tab>"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Next buffer",
    },
    ["<S-Tab>"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Previous buffer",
    },
  },
}

M.nvimtree = {
  plugin = true,

  n = {},
}

M.comment = {
  plugin = true,

  n = {},
}

M.lspconfig = {
  plugin = true,

  n = {
    ["gD"] = {
      function()
        vim.lsp.buf.declaration()
      end,
      "LSP declaration",
    },

    ["gd"] = {
      function()
        vim.lsp.buf.definition()
      end,
      "LSP definition",
    },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "LSP hover",
    },


    ["<leader>ls"] = {
      function()
        vim.lsp.buf.signature_help()
      end,
      "LSP signature help",
    },

    ["<leader>D"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "LSP type definition",
    },

    -- Diagnostics
    ["<leader>df"] = {
      function()
        vim.diagnostic.open_float { border = "rounded" }
      end,
      "Floating diagnostic",
    },

    ["<leader>dp"] = {
      function()
        vim.diagnostic.jump { count = -1, float = true }
      end,
      "Prev diagnostic",
    },

    ["<leader>dn"] = {
      function()
        vim.diagnostic.jump { count = 1, float = true }
      end,
      "Next diagnostic",
    },

    ["<leader>dl"] = {
      function()
        vim.diagnostic.setloclist()
      end,
      "Diagnostics → loclist",
    },

    -- Editing actions
    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format()
      end,
      "Format buffer",
    },

    ["<leader>rn"] = {
      function()
        vim.lsp.buf.rename()
      end,
      "Rename symbol",
    },

    ["<leader>fi"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "Code actions / autofix",
    },

    ["<leader>gi"] = {
      function()
        vim.lsp.buf.implementation()
      end,
      "Get implementation",
    },

    ["<leader>gd"] = {
      function()
        vim.lsp.buf.definition()
      end,
      "Get definition",
    },

    ["<leader>rf"] = {
      function()
        require('telescope.builtin').lsp_references()
      end,
      "Show references",
    },

    -- CodeLens
    ["<leader>cl"] = {
      function()
        vim.lsp.codelens.run()
      end,
      "Run CodeLens",
    },

    ["<leader>cL"] = {
      function()
        vim.lsp.codelens.refresh()
      end,
      "Refresh CodeLens",
    },
  },
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<leader>ff"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>fw"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
    ["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "Find buffers" },
    ["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "Help page" },
    ["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "Find oldfiles" },
    ["<leader>fz"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },

    -- git
    ["<leader>cm"] = { "<cmd> Telescope git_commits <CR>", "Git commits" },
    ["<leader>gt"] = { "<cmd> Telescope git_status <CR>", "Git status" },

    -- theme switcher
    ["<leader>th"] = { "<cmd> Telescope themes <CR>", "Nvchad themes" },

    ["<leader>ma"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },
  },
}

M.nvterm = {
  plugin = true,

  t = {
    -- toggle in terminal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },
  },

  n = {
    -- toggle in normal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },

    ["<leader>th"] = {
      function()
        require("nvterm.terminal").new "horizontal"
      end,
      "New horizontal term",
    },

    ["<leader>tv"] = {
      function()
        require("nvterm.terminal").new "vertical"
      end,
      "New vertical term",
    },
  },
}

M.whichkey = {
  plugin = true,

  n = {
    ["<leader>wK"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "Which-key all keymaps",
    },
    ["<leader>wk"] = {
      function()
        local input = vim.fn.input "WhichKey: "
        vim.cmd("WhichKey " .. input)
      end,
      "Which-key query lookup",
    },
  },
}

M.blankline = {
  plugin = true,

  n = {
    ["<leader>cc"] = {
      function()
        local ok, start = require("indent_blankline.utils").get_current_context(
          vim.g.indent_blankline_context_patterns,
          vim.g.indent_blankline_use_treesitter_scope
        )

        if ok then
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start, 0 })
          vim.cmd [[normal! _]]
        end
      end,

      "Jump to current context",
    },
  },
}

M.markdown_preview = {
  plugin = true,

  n = {
    ["<leader>mp"] = { ":MarkdownPreview<CR>", "Preview markdown" },
  },
}

M.surround = {
  plugin = true,

  n = {
    ["<leader>sw"] = { "ysiw", "Surround word", opts = { remap = true } },
    ["<leader>sl"] = { "yss", "Surround line", opts = { remap = true } },
  },
}

M.gitsigns = {
  plugin = true,

  n = {
    -- Navigation through hunks
    ["]c"] = {
      function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          require("gitsigns").next_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to next hunk",
      opts = { expr = true },
    },

    ["[c"] = {
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          require("gitsigns").prev_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to prev hunk",
      opts = { expr = true },
    },

    -- Actions
    ["<leader>rh"] = {
      function()
        require("gitsigns").reset_hunk()
      end,
      "Reset hunk",
    },

    ["<leader>ph"] = {
      function()
        require("gitsigns").preview_hunk()
      end,
      "Preview hunk",
    },

    ["<leader>gb"] = {
      function()
        package.loaded.gitsigns.blame_line()
      end,
      "Blame line",
    },

    ["<leader>td"] = {
      function()
        require("gitsigns").toggle_deleted()
      end,
      "Toggle deleted",
    },
  },
}

return M
