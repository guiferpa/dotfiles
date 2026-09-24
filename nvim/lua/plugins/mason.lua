return {
  {
    "williamboman/mason.nvim",
    config = function()
      require('mason').setup()

      -- Tools that are not language servers, so mason-lspconfig does not
      -- manage them. Installed once, in the background, if missing.
      local tools = { "goimports", "gofumpt" }
      local registry = require('mason-registry')
      registry.refresh(function()
        for _, name in ipairs(tools) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = { "lua_ls", "ts_ls", "gopls", "clojure_lsp", "pylsp" }
      })
    end
  }
}
