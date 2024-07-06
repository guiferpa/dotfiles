return {
  {
    'mawkler/modicator.nvim',
    dependencies = 'mawkler/onedark.nvim', -- Add your colorscheme plugin here
    config = function ()
      require('modicator').setup()
    end
  }
}
