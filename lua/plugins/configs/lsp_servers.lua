local server_configs_path = vim.fn.stdpath("config") .. "/lua/plugins/configs/servers"
local files = vim.fn.readdir(server_configs_path)

for _, file in ipairs(files) do
  if file:match("%.lua$") then
    local server_name = file:gsub("%.lua$", "")
    -- 1. Load the server-specific file
    local ok, opts = pcall(require, "plugins.configs.servers." .. server_name)
    
    if ok then
      local common = require("plugins.configs.lspconfig")
      
      -- 2. Use 'opts' (the variable you actually loaded)
      local final_opts = vim.tbl_deep_extend("force", {
        on_attach = common.on_attach,
        capabilities = common.capabilities,
      }, opts or {})

      -- 3. Keep nvim-lspconfig's own on_attach instead of replacing it - that's
      -- where servers register their user commands (:LspPyrightOrganizeImports,
      -- :LspPyrightSetPythonPath, ...). Reading vim.lsp.config[name] resolves
      -- lsp/<name>.lua from the runtimepath; it must happen before we write.
      local default_on_attach = (vim.lsp.config[server_name] or {}).on_attach

      if default_on_attach then
        local own_on_attach = final_opts.on_attach

        final_opts.on_attach = function(client, bufnr)
          default_on_attach(client, bufnr)
          own_on_attach(client, bufnr)
        end
      end

      -- 4. Configure and enable the server
      vim.lsp.config(server_name, final_opts)
      vim.lsp.enable(server_name)
    end
  end
end
