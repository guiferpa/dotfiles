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
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
      vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, opts)
    end
  }
}
