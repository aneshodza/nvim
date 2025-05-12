local lspconfig = require("lspconfig")

local server_configs_path = vim.fn.stdpath("config") .. "/lua/plugins/configs/servers"

for _, file in ipairs(vim.fn.readdir(server_configs_path)) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    local ok, opts = pcall(require, "plugins.configs.servers." .. server_name)

    if ok and type(opts) == "table" then
      lspconfig[server_name].setup(opts)
    elseif not ok then
      vim.notify("Error loading LSP config for " .. server_name .. ": " .. opts, vim.log.levels.ERROR)
    else
      vim.notify("Failed to load LSP config for " .. server_name, vim.log.levels.WARN)
    end
  end
end
