local server_configs_path = vim.fn.stdpath("config").. "/lua/plugins/configs/servers"
local files = vim.fn.readdir(server_configs_path)

for _, file in ipairs(files) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    local ok, opts = pcall(require, "plugins.configs.servers.".. server_name)
    
    if ok and type(opts) == "table" then
      -- 1. Register the static configuration [7]
      vim.lsp.config(server_name, opts)
      -- 2. Enable the server (creates FileType autocommands) [3]
      vim.lsp.enable(server_name)
    end
  end
end
