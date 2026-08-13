-- Breadcrumbs: which class/function the cursor is inside, derived from LSP
-- document symbols.
--
-- This used to be barbecue.nvim, which wrapped navic and drew a winbar itself.
-- Without that wrapper navic is only a data source — it exposes get_location()
-- and paints nothing. The LSP attachment is set up here; the drawing is a
-- lualine component in plugins/lualine.lua.
return {
  {
    "SmiteshP/nvim-navic",
    -- Not lazy on purpose. `lsp.auto_attach` below works by registering an
    -- LspAttach autocmd at setup time, so navic has to be loaded before the
    -- first server attaches. A lazy spec with no trigger would never load at
    -- all, and `event = "VeryLazy"` can fire after the attach for the file
    -- Neovim was opened with.
    lazy = false,
    opts = {
      lsp = {
        -- Attaches navic to every server that reports documentSymbolProvider,
        -- which is why nothing had to be added to the five server blocks in
        -- plugins/lsp-config.lua.
        auto_attach = true,
      },
      -- get_location() returns a statusline string, so the NavicIcons* groups
      -- that dracula.nvim defines are applied per symbol kind. lualine copes
      -- with a component that sets its own highlights: it notices the `%#` and
      -- re-appends the section highlight afterwards, so the colours do not
      -- bleed into the components that follow.
      highlight = true,
      separator = " > ",
      -- The statusline shares one line with mode, branch, diagnostics and the
      -- rest, so an unbounded chain in deeply nested code would push them off.
      -- 0 means unlimited, which is the default.
      depth_limit = 5,
      depth_limit_indicator = "..",
    },
  },
}
