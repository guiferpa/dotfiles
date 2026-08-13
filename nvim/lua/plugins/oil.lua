return {
  {
    'stevearc/oil.nvim',
    -- Icons come from mini.icons (see plugins/icons.lua). oil prefers it over
    -- nvim-web-devicons on its own, so there is no dependency to declare.
    dependencies = { "nvim-mini/mini.icons" },
    config = function()
      local oil = require("oil")
      oil.setup({
        -- "icon", not "icons". oil registers icon/type/name, plus the ones
        -- the files adapter adds (size, permissions, mtime). An unregistered
        -- name is not an error: render_col returns EMPTY, so the column just
        -- silently disappears.
        columns = {
          "icon",
          "size"
        },
        skip_confirm_for_simple_edits = true,
        watch_for_changes = false,
        view_options = {
          show_hidden = true
        }
      })

      vim.keymap.set('n', '<leader>oe', oil.open)
    end
  },
}
