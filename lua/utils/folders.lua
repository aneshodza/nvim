-- <leader>fd: pick a folder, focus it in nvim-tree.
--
-- Searching the tree with `/` does not find nested folders reliably: nvim-tree
-- renders a chain like db/migrations on one line, so the text you are looking
-- for may not exist as its own entry to match against.

local M = {}

--- Directories under `root`, including every intermediate one.
---
--- Derived from `rg --files` rather than `find`, so .gitignore is respected for
--- free and .git, node_modules and build output stay out. rg is already a hard
--- dependency of telescope's live_grep here.
---
--- @param root string
--- @return string[] relative paths, sorted, shallowest first
function M.directories(root)
  -- run rg *in* root, so results are relative to it. vim.fn.systemlist has no
  -- cwd option and would silently search wherever nvim happens to be.
  local result = vim.system({ "rg", "--files", "--hidden", "--glob", "!.git/*" }, { cwd = root, text = true }):wait()

  if result.code ~= 0 then
    return {}
  end

  local files = vim.split(result.stdout or "", "\n", { trimempty = true })

  local seen, dirs = {}, {}

  for _, file in ipairs(files) do
    local dir = vim.fs.dirname(file)

    -- walk up so parents are pickable too, not just leaves
    while dir and dir ~= "." and dir ~= "/" and not seen[dir] do
      seen[dir] = true
      dirs[#dirs + 1] = dir
      dir = vim.fs.dirname(dir)
    end
  end

  table.sort(dirs, function(a, b)
    local da, db = select(2, a:gsub("/", "")), select(2, b:gsub("/", ""))
    if da ~= db then
      return da < db
    end
    return a < b
  end)

  return dirs
end

--- The directory the tree is rooted at, so a pick is always revealable.
local function tree_root()
  local ok, api = pcall(require, "nvim-tree.api")

  if ok then
    local nodes = api.tree.get_nodes()

    if nodes and nodes.absolute_path then
      return nodes.absolute_path
    end
  end

  return vim.uv.cwd()
end

function M.pick()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local root = tree_root()
  local dirs = M.directories(root)

  if #dirs == 0 then
    vim.notify("No folders found under " .. root, vim.log.levels.WARN)
    return
  end

  pickers
    .new({}, {
      prompt_title = "Folders",
      finder = finders.new_table { results = dirs },
      sorter = conf.generic_sorter {},

      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          actions.close(bufnr)

          local entry = action_state.get_selected_entry()

          if not entry then
            return
          end

          -- find_file focuses a folder as happily as a file, and leaves the
          -- tree root alone
          require("nvim-tree.api").tree.find_file {
            buf = vim.fs.joinpath(root, entry[1]),
            open = true,
            focus = true,
          }
        end)

        return true
      end,
    })
    :find()
end

return M
