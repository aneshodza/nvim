require "nvchad.mappings"

local map = vim.keymap.set

-- IMPORTANT: everything below must stay AFTER the require above. <leader>h and
-- <leader>v deliberately shadow NvChad's defaults (which open terminals) to
-- keep them as window splits. Move that require down the file and they
-- silently become terminal-openers.
--
-- Dropped here because NvChad already maps them identically: <C-h/j/k/l> in
-- both normal and insert, <Esc> noh, <C-s>, <C-c>, <leader>n, <leader>rn,
-- <leader>b, <leader>ch, <leader>fm, <leader>ff/fw/fb/fh/fo/fz/cm/gt/ma/th,
-- <leader>wk/wK, <leader>x, <tab>/<S-tab>, t <C-x>.

-- general -------------------------------------------------------------------
map(
  "n",
  "<leader>rp",
  ":lua local search = vim.fn.input('Search for: '); local replace = vim.fn.input('Replace with: '); vim.fn.feedkeys(':%s#' .. search .. '#' .. replace .. '#gi')<CR>",
  { desc = "Replace word" }
)

map("n", "<leader>rhm", "<cmd>horizontal resize +10<CR>", { desc = "Resize horizontal +10" })
map("n", "<leader>rhl", "<cmd>horizontal resize -10<CR>", { desc = "Resize horizontal -10" })
map("n", "<leader>rhs", "<cmd>horizontal resize 15<CR>", { desc = "Resize horizontal to be small (15)" })
map("n", "<leader>rhc", "<cmd>horizontal resize ", { desc = "Resize horizontal custom" })

map("n", "<leader>rvm", "<cmd>vertical resize +10<CR>", { desc = "Resize vertical +10" })
map("n", "<leader>rvl", "<cmd>vertical resize -10<CR>", { desc = "Resize vertical -10" })
map("n", "<leader>rvs", "<cmd>vertical resize 15<CR>", { desc = "Resize vertical to be small (15)" })
map("n", "<leader>rvc", "<cmd>vertical resize ", { desc = "Resize vertical custom" })

map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split horizontal" })
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split vertical" })
map("n", "<leader>h", "<cmd>split<CR>", { desc = "Split horizontal" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Split vertical" })

map("n", "<C-Up>", ":m .-2<CR>==", { desc = "Move line up" })
map("n", "<C-Down>", ":m .+1<CR>==", { desc = "Move line down" })

-- move through wrapped lines, but not in operator-pending mode so d/y/c are unaffected
local wrapped = { expr = true }
map("n", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', vim.tbl_extend("force", wrapped, { desc = "Move down" }))
map("n", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map(
  "n",
  "<Down>",
  'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
  vim.tbl_extend("force", wrapped, { desc = "Move down" })
)
map("n", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map(
  "v",
  "<Down>",
  'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
  vim.tbl_extend("force", wrapped, { desc = "Move down" })
)
map("v", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))
map("x", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', vim.tbl_extend("force", wrapped, { desc = "Move down" }))
map("x", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', vim.tbl_extend("force", wrapped, { desc = "Move up" }))

map("x", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { silent = true, desc = "Dont copy replaced text" })
map("x", "<C-Up>", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
map("x", "<C-Down>", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "Find all" })
map("n", "<leader>td", "<cmd>TodoTelescope<CR>", { desc = "Search TODOs" })

map("n", "<leader>de", require("utils.quickfix").dotnet_build, { desc = "Dotnet errors to quickfix" })
map("n", "<leader>gc", require("utils.quickfix").git_conflicts, { desc = "Git conflicts to quickfix" })

-- terminals -----------------------------------------------------------------
-- <A-i>/<A-h>/<A-v> toggles come from NvChad. These open *new* terminals, and
-- moved off <leader>th (which is NvChad's theme picker) and <leader>h.
map("n", "<leader>ts", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "New horizontal term" })

map("n", "<leader>tv", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "New vertical term" })

-- plugins -------------------------------------------------------------------
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "Preview markdown" })
map("n", "<leader>sa", "<cmd>AerialToggle right<CR>", { desc = "Show aerial (symbols outline)" })
map("n", "<leader>sw", "ysiw", { remap = true, desc = "Surround word" })
map("n", "<leader>sl", "yss", { remap = true, desc = "Surround line" })

-- gitsigns ------------------------------------------------------------------
map("n", "]c", function()
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    require("gitsigns").next_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Jump to next hunk" })

map("n", "[c", function()
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    require("gitsigns").prev_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Jump to prev hunk" })

map("n", "<leader>rh", function()
  require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })

map("n", "<leader>ph", function()
  require("gitsigns").preview_hunk()
end, { desc = "Preview hunk" })

-- was package.loaded.gitsigns.blame_line(), which nil-indexes before gitsigns loads
map("n", "<leader>gb", function()
  require("gitsigns").blame_line()
end, { desc = "Blame line" })

-- moved off <leader>td, which collided with TodoTelescope
map("n", "<leader>gD", function()
  require("gitsigns").toggle_deleted()
end, { desc = "Toggle deleted" })

-- diagnostics ---------------------------------------------------------------
-- global rather than buffer-local: vim.diagnostic works with no client attached
map("n", "<leader>df", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "Floating diagnostic" })

map("n", "<leader>dp", function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Prev diagnostic" })

map("n", "<leader>dn", function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Next diagnostic" })

map("n", "<leader>dc", function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })

  if #diagnostics == 0 then
    vim.notify "No diagnostics under cursor"
    return
  end

  local messages = vim.tbl_map(function(d)
    return d.message
  end, diagnostics)

  vim.fn.setreg("+", table.concat(messages, "\n"))
  vim.notify("Copied " .. #diagnostics .. " diagnostic(s)")
end, { desc = "Copy diagnostic to clipboard" })

map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- lsp -----------------------------------------------------------------------
-- Buffer-local, so these replace the old M.lspconfig section. K is deliberately
-- absent: nvim 0.11 maps it to hover on attach, but only when nothing else has
-- claimed it. gd/gD are NOT nvim defaults (only grn/gra/grr/gri are), so they
-- stay here.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspMappings", { clear = true }),
  callback = function(args)
    local function opts(desc)
      return { buffer = args.buf, desc = desc }
    end

    map("n", "gd", vim.lsp.buf.definition, opts "LSP definition")
    map("n", "gD", vim.lsp.buf.declaration, opts "LSP declaration")
    map("n", "<leader>gd", vim.lsp.buf.definition, opts "Get definition")
    map("n", "<leader>gi", vim.lsp.buf.implementation, opts "Get implementation")
    map("n", "<leader>D", vim.lsp.buf.type_definition, opts "LSP type definition")
    map("n", "<leader>ls", vim.lsp.buf.signature_help, opts "LSP signature help")

    -- <leader>rn is NvChad's relative-number toggle; grn also renames
    map("n", "<leader>ra", vim.lsp.buf.rename, opts "Rename symbol")

    map("n", "<leader>rf", function()
      require("telescope.builtin").lsp_references()
    end, opts "Show references")

    map("n", "<leader>fi", require("utils.lsp").code_action, opts "Code actions / autofix")

    map("n", "<leader>cl", vim.lsp.codelens.run, opts "Run CodeLens")
    map("n", "<leader>cL", vim.lsp.codelens.refresh, opts "Refresh CodeLens")
  end,
})
