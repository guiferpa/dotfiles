return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          -- lualine's own bundled dracula theme, not the one from
          -- dracula.nvim. Same palette, and it stays in step with whatever
          -- statusline components lualine adds.
          theme = 'dracula'
        }
      })
    end
  }
}
