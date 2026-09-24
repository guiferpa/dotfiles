return {
  {
    "williamboman/mason.nvim",
    config = function()
      require('mason').setup()

      -- Tools that are not language servers, so mason-lspconfig does not
      -- manage them. Installed in the background when missing, or reinstalled
      -- when a pinned version differs from the one on disk.
      --
      -- delve is pinned because each release only supports three Go minors:
      -- v1.26.2 covers 1.24 to 1.26, and v1.27 already refuses the 1.24 that
      -- asdf has as the global Go. Move the pin when the Go floor moves.
      local tools = {
        goimports = true,
        gofumpt = true,
        delve = "v1.26.2",
        gotestsum = true,
      }
      local registry = require('mason-registry')
      registry.refresh(function()
        for name, version in pairs(tools) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok then
            local wanted = type(version) == "string" and version or nil
            if not pkg:is_installed() then
              pkg:install({ version = wanted })
            elseif wanted then
              pkg:get_installed_version(function(found, installed)
                if found and installed ~= wanted then
                  pkg:install({ version = wanted })
                end
              end)
            end
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
