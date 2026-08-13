-- Dracula, matching the Rio palette in rio/themes/dracula.toml.
--
-- Mofiqul/dracula.nvim rather than the upstream dracula/vim: this config is
-- built on treesitter, LSP semantic tokens, telescope, trouble and navic,
-- and only the Lua port ships highlight groups for them. dracula/vim is
-- vimscript and predates all of it, so those plugins would fall back to
-- default groups.
return {
  {
    "Mofiqul/dracula.nvim",
    name = "dracula",
    priority = 1000,
    config = function()
      require("dracula").setup({
        -- Rio draws the background, and window.opacity in rio/config.toml
        -- makes it translucent. Painting an opaque #282a36 over it inside
        -- Neovim would cancel that out for every buffer.
        transparent_bg = false,
        italic_comment = true,
        lualine_bg_color = nil,
        show_end_of_buffer = false,
        overrides = {},
      })

      vim.o.background = "dark"
      vim.cmd.colorscheme "dracula"
    end
  }
}
