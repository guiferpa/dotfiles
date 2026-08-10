return {
  {
    'mawkler/modicator.nvim',
    -- modicator reads the mode colours out of the active colorscheme at setup
    -- time, so the colorscheme has to be loaded first. This was
    -- 'mawkler/onedark.nvim', copied from the plugin's README, which pulled in
    -- a second colorscheme that was never applied and left the ordering
    -- against the one that is.
    dependencies = 'Mofiqul/dracula.nvim',
    config = function ()
      require('modicator').setup()
    end
  }
}
