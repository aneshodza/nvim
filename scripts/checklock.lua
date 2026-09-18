-- nvim --headless -l scripts/checklock.lua
--
-- Assert every installed plugin sits at the revision lazy-lock.json pins.
--
-- Deliberately not `git diff -- lazy-lock.json`: that trusts lazy to have
-- rewritten the file to reflect reality, and a restore that is still in flight
-- when nvim exits leaves a file describing neither the old nor the new state.
-- Reading each plugin's HEAD is a direct measurement instead.

local config_dir = vim.fn.stdpath "config"
local data_dir = vim.fn.stdpath "data"

local ok, lock = pcall(vim.fn.readfile, config_dir .. "/lazy-lock.json")

if not ok then
  error("cannot read lazy-lock.json", 0)
end

local pinned = vim.json.decode(table.concat(lock, "\n"))
local failures, checked = {}, 0

for name, entry in pairs(pinned) do
  -- lazy.nvim is bootstrapped by init.lua with `git clone --branch=stable`
  -- before the lockfile can be read, so its entry legitimately tracks whatever
  -- stable currently is.
  if name ~= "lazy.nvim" then
    local dir = vim.fs.joinpath(data_dir, "lazy", name)

    if vim.fn.isdirectory(dir) == 1 then
      checked = checked + 1

      local head = vim.fn.trim(vim.fn.system { "git", "-C", dir, "rev-parse", "HEAD" })

      if head ~= entry.commit then
        table.insert(
          failures,
          ("  %-28s locked %s  installed %s"):format(name, entry.commit:sub(1, 10), head:sub(1, 10))
        )
      end
    else
      table.insert(failures, ("  %-28s not installed"):format(name))
    end
  end
end

if #failures > 0 then
  table.sort(failures)
  io.stderr:write("\nplugins do not match lazy-lock.json:\n" .. table.concat(failures, "\n") .. "\n")
  error(("checklock: %d of %d plugin(s) drifted"):format(#failures, checked), 0)
end

io.stdout:write(("checklock: ok (%d plugins)\n"):format(checked))
