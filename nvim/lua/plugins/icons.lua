return {
  {
    "nvim-mini/mini.icons",
    -- mini.icons has no tags of its own; the release tags live on the
    -- mini.nvim monorepo. `version = false` is what upstream documents for
    -- tracking the main branch of a standalone module.
    version = false,
    -- Nothing requires this at startup. `oil` and `lualine` reach for icons
    -- only when they first draw, and both entry points below go through
    -- `require`, which lazy.nvim intercepts to load and set up the plugin on
    -- demand.
    lazy = true,
    opts = {},
    init = function()
      -- oil finds mini.icons on its own (it probes for `mini.icons` before
      -- falling back, see oil/util.lua get_icon_provider). lualine does not:
      -- it does a bare `pcall(require, "nvim-web-devicons")` at render time
      -- and has no knowledge of mini.icons.
      --
      -- Registering a `package.preload` entry is what keeps lualine working
      -- without the real plugin installed. Lua consults `package.preload`
      -- before searching `runtimepath`, so its require lands here, gets the
      -- mock installed into `package.loaded`, and receives an object with the
      -- nvim-web-devicons API backed by MiniIcons.get.
      --
      -- Doing it here rather than in `opts`/`config` matters: `init` runs
      -- during startup, so the hook is in place no matter which plugin draws
      -- first. Load order stops being something this config has to arrange.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
