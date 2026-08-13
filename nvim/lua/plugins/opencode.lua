-- opencode.nvim: drives the opencode CLI agent from inside Neovim.
--
-- The agent itself is a separate process — the `opencode` formula installed by
-- install.sh. This plugin only talks to its HTTP API, which is why the server
-- has to be started with `--port` for anything here to work.
return {
  {
    "nickjvandyke/opencode.nvim",
    -- The plugin has tagged releases and its options are typed against them,
    -- so track the latest stable tag rather than main.
    version = "*",
    -- Nothing is needed until a mapping below is pressed. Every one of them
    -- goes through `require("opencode")`, and lazy.nvim intercepts that
    -- require to load and configure the plugin on demand — the same mechanism
    -- plugins/icons.lua relies on. Declaring `keys` instead would mean
    -- registering the operator mapping through lazy's expr-mapping wrapper,
    -- which is a layer this does not need.
    --
    -- The cost: the OpencodeEvent autocmds, the buffer reloading and the
    -- permission prompts are all inert until the first mapping is used. That
    -- only matters if an opencode running elsewhere edits files before this
    -- session has touched the plugin.
    lazy = true,
    init = function()
      -- Options travel through a global, not through lazy's `opts` field:
      -- opencode.config reads `vim.g.opencode_opts` the first time it is
      -- required and merges it over its defaults. Setting it in `init` means
      -- it is in place from startup, whatever ends up triggering the load.
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- Left unset on purpose: with no url the plugin discovers whatever
          -- `opencode --port` is already running, so an agent started by hand
          -- in another pane is picked up instead of a second one being spawned.
          url = nil,
          -- Replaces the default `vsplit term://opencode --port | wincmd p`
          -- only to put the terminal on the right and give it a third of the
          -- window. `wincmd p` jumps back, so the cursor stays in the code.
          start = function()
            vim.cmd("botright vsplit term://opencode --port")
            vim.cmd("vertical resize " .. math.floor(vim.o.columns / 3))
            vim.cmd("wincmd p")
          end,
        },
      }

      -- `,a` for agent. `,o` is oil's prefix and `,c` clears the search
      -- highlight, so this does not collide with anything in keymaps.lua.
      --
      -- Deliberately not the mappings the README suggests: `<C-a>` and `<C-x>`
      -- are Vim's increment and decrement, `go` is a motion, and the scroll
      -- pair it proposes (`<S-C-u>`/`<S-C-d>`) needs a terminal that
      -- distinguishes Ctrl-Shift from plain Ctrl — Rio only does that with
      -- `use-kitty-keyboard-protocol`, which rio/config.toml leaves off.
      local function map(lhs, rhs, desc, mode, opts)
        vim.keymap.set(
          mode or "n",
          "<leader>a" .. lhs,
          rhs,
          vim.tbl_extend("force", { desc = "opencode: " .. desc }, opts or {})
        )
      end

      map("a", function()
        require("opencode").ask("@this: ")
      end, "ask about cursor or selection", { "n", "x" })

      map("b", function()
        require("opencode").ask("@buffer: ")
      end, "ask about the whole buffer")

      map("d", function()
        require("opencode").ask("@diagnostics: ")
      end, "ask about diagnostics", { "n", "x" })

      -- Prompts, commands and servers in one picker. The discoverable entry
      -- point: everything the plugin can do is reachable from here, so the
      -- mappings above are shortcuts, not the whole surface.
      map("s", function()
        require("opencode").select()
      end, "select prompt, command or server", { "n", "x" })

      -- An operator, so it composes with motions and text objects: `,aoap`
      -- appends a paragraph, `,aoi{` a block. Returns the keys to feed rather
      -- than acting, hence `expr`.
      map("o", function()
        return require("opencode").operator("@this ")
      end, "append range to the prompt", { "n", "x" }, { expr = true })

      map("n", function()
        require("opencode").command("session.new")
      end, "new session")

      map("x", function()
        require("opencode").command("session.interrupt")
      end, "interrupt session")

      -- Scrolling the agent's output without leaving the code window.
      map("u", function()
        require("opencode").command("session.half.page.up")
      end, "scroll output up")

      map("e", function()
        require("opencode").command("session.half.page.down")
      end, "scroll output down")
    end,
  },
}
