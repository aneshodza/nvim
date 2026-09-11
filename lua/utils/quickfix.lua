-- Extracted from lua/core/mappings.lua, where these were 70 lines of shell
-- pipelines living inside a keymap table.
--
-- Both shell out to POSIX tools (grep, sort, awk, xargs) and are macOS/Linux
-- only by construction.

local M = {}

--- Build the nearest C# project and put the compiler errors in the quickfix list.
function M.dotnet_build()
  if vim.fn.executable "dotnet" == 0 then
    vim.notify("'dotnet' not found on PATH", vim.log.levels.ERROR)
    return
  end

  local root_dir
  for _, client in ipairs(vim.lsp.get_clients { name = "omnisharp" }) do
    root_dir = client.config.root_dir
    break
  end

  root_dir = root_dir or vim.fn.getcwd()

  vim.notify(" Building project at " .. root_dir)

  local cmd = string.format(
    "cd %s && dotnet build --property WarningLevel=0 "
      .. "| grep -oE '[^ ]+\\.cs\\([0-9]+,[0-9]+\\)' | sort -u",
    vim.fn.shellescape(root_dir)
  )

  vim.opt.errorformat = [[%f(%l\,%c)]]
  local output = vim.trim(vim.fn.system(cmd))

  if output == "" then
    vim.cmd "cclose"
    vim.notify "󱜙 Build successful, no errors were found!"
    return
  end

  vim.fn.setqflist({}, " ", {
    title = " Dotnet Errors: " .. vim.fn.fnamemodify(root_dir, ":t"),
    lines = vim.split(output, "\n"),
  })

  vim.cmd "copen"
end

--- Put every conflict marker in the unmerged files into the quickfix list.
function M.git_conflicts()
  local cmd = "git diff --name-only --diff-filter=U --relative 2>/dev/null "
    .. "| xargs grep -nH '^<<<<<<<' "
    .. "| awk -F: '{count[$1]++; print $1\":\"$2\":  Conflict #\"count[$1]}'"

  local output = vim.fn.systemlist(cmd)

  if #output == 0 then
    vim.cmd "cclose"
    vim.notify "󰄬 No conflict markers found!"
    return
  end

  local old_efm = vim.opt.errorformat

  -- grep -nH output is 'filename:line:text'
  vim.opt.errorformat = "%f:%l:%m"

  vim.fn.setqflist({}, " ", {
    title = "󰊢 Git Conflicts",
    lines = output,
  })

  vim.opt.errorformat = old_efm

  vim.cmd "copen"
  vim.notify("󰊢 Found " .. #output .. " conflict blocks.")
end

return M
