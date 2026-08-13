return {
  {
    'nvim-lualine/lualine.nvim',
    -- lualine only knows nvim-web-devicons. It reaches it through the
    -- package.preload shim in plugins/icons.lua, which serves the mock backed
    -- by mini.icons.
    dependencies = { 'nvim-mini/mini.icons', 'SmiteshP/nvim-navic' },
    config = function()
      require('lualine').setup({
        options = {
          -- lualine's own bundled dracula theme, not the one from
          -- dracula.nvim. Same palette, and it stays in step with whatever
          -- statusline components lualine adds.
          theme = 'dracula'
        },
        sections = {
          -- Only lualine_c is named here; the other five sections keep their
          -- defaults (mode, branch/diff/diagnostics, encoding/fileformat/
          -- filetype, progress, location).
          lualine_c = {
            'filename',
            {
              -- navic returns a preformatted statusline string, which is what
              -- a function component is allowed to return, so it goes in as
              -- is. Requiring it lazily here rather than at the top of the
              -- file keeps this spec loadable even before navic has set up.
              function()
                return require('nvim-navic').get_location()
              end,
              -- Without this the component would render an empty string on
              -- every buffer with no LSP attached, and lualine would still
              -- draw its padding and separator around it.
              cond = function()
                local ok, navic = pcall(require, 'nvim-navic')
                return ok and navic.is_available()
              end,
            },
          },
        },
      })
    end
  }
}
