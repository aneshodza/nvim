-- Expand paths immediately to avoid execution failures in WSL
local dotnet_bin = vim.fn.expand("/home/aneshodza/.dotnet/dotnet")
-- Ensure this points to the actual OmniSharp.dll if using 'dotnet' to run it
local omnisharp_dll = vim.fn.expand("/home/aneshodza/.local/share/nvim/omnisharp/OmniSharp.dll")

-- Environment setup
vim.env.DOTNET_ROOT = "/home/aneshodza/.dotnet"
vim.env.MSBUILDDISABLENODEREUSE = "1" 

return {
  filetypes = { "cs", "vb", "csproj", "sln" },
  
  -- Use a function for cmd to dynamically include the PID and absolute paths
  cmd = {
    dotnet_bin,
    omnisharp_dll,
    "--languageserver",
    "--hostPID",
    tostring(vim.fn.getpid()),
    "--loglevel", "information",
  },
  
  -- Neovim 0.11 requires the on_dir callback to trigger buffer attachment [4]
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    -- prioritize.sln for OmniSharp stability in WSL [3, 5]
    local root = vim.fs.root(fname, { "*.sln", "*.csproj", ".git" })
    
    if root then
      on_dir(root) -- This is the missing link that attaches the buffer
    end
  end,
  
  settings = {
    omnisharp = {
      useModernNet = true,
      enableEditorConfigSupport = true,
      enablePackageRestore = true,
      analyzeOpenDocumentsOnly = true, 
      enableMsBuildLoadProjectsOnDemand = true,
    },
    roslyn = {
      extensionsOptions = {
        enableImportCompletion = true,
        enableAnalyzersSupport = true,
      },
    },
  },
  
  -- Capabilities for completion (e.g., cmp-nvim-lsp) [6]
  capabilities = (function()
    local ok, lsp_configs = pcall(require, "plugins.configs.lspconfig")
    return ok and lsp_configs.capabilities or nil
  end)(),

  -- Mapping formatting and other logic to the native attach event
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    
    -- Optional: Import your custom keymaps
    local ok, lsp_configs = pcall(require, "plugins.configs.lspconfig")
    if ok then lsp_configs.on_attach(client, bufnr) end
  end,
}
