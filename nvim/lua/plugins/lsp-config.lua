return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require('lspconfig')

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.gopls.setup({
        capabilities = capabilities,
        settings = {
          gopls = {
            -- Matches conform, which runs gofumpt on save.
            gofumpt = true,
            staticcheck = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            -- Only drawn while inlay hints are on, see <leader>lh.
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })
      lspconfig.pylsp.setup({
        capabilities = capabilities,
      })
      lspconfig.clojure_lsp.setup({
        capabilities = capabilities,
      })

      vim.filetype.add({ extension = { ar = 'aurora' } })
      vim.lsp.config('aurorals', {
        cmd = { 'aurorals' },
        -- cmd = { '/Users/guiferpa/src/github.com/guiferpa/aurora/target/bin/aurorals' },
        filetypes = { 'aurora' },
        root_markers = { 'aurora.toml', '.git' },
      })
      vim.lsp.enable('aurorals')

      local opts = {}
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
      vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', '<leader>lh', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = "Toggle inlay hints" })
    end
  }
}
