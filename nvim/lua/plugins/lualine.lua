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
          -- lualine_c and lualine_x are named here; the other four keep their
          -- defaults (mode, branch/diff/diagnostics, progress, location).
          -- Naming a section replaces it wholesale, which is why lualine_x
          -- repeats the three defaults it would otherwise have.
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
          lualine_x = {
            -- The opencode agent's state. A plain require of a local module,
            -- not of the plugin: `require("opencode").statusline` would drag
            -- the plugin in on the first redraw and undo the lazy loading its
            -- spec is built around — and it is dead code besides, which
            -- lua/opencode_status.lua explains.
            require('opencode_status').component,
            'encoding',
            'fileformat',
            'filetype',
          },
        },
      })
    end
  }
}
