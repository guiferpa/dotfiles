-- opencode.nvim: drives the opencode CLI agent from inside Neovim.
--
-- The agent itself is a separate process — the `opencode` formula installed by
-- install.sh. This plugin only talks to its HTTP API, which is why the server
-- has to be started with `--port` for anything here to work.
--
-- Three things live in this file beyond the plugin spec: the terminal the
-- agent runs in (`term`), a check for the configuration it needs before it can
-- do anything useful (`preflight`), and the mappings. The statusline half is
-- in lua/opencode_status.lua.

-- Where `opencode auth login` stores credentials. Documented, and the reason
-- this config never handles an API key itself.
local AUTH_FILE = vim.fn.expand("~/.local/share/opencode/auth.json")

-- Untracked file sourced at the end of zsh/zshenv. The only place a real key
-- may be written on this machine.
local ENV_LOCAL = vim.fn.expand("~/.zshenv.local")

-- Providers that authenticate from the environment instead of auth.json, so an
-- empty auth.json is not proof that nothing is configured. Bedrock works this
-- way, and custom providers reference `{env:VAR}` from opencode.json.
local ENV_VARS = {
  "ANTHROPIC_API_KEY",
  "OPENAI_API_KEY",
  "OPENROUTER_API_KEY",
  "AWS_BEARER_TOKEN_BEDROCK",
  "AWS_PROFILE",
}

-- Shortcuts past the first menu of `opencode auth login`. Choosing "other"
-- runs it with no --provider, which lists everything opencode supports.
local PROVIDERS = {
  { id = "anthropic", label = "Anthropic (Claude)" },
  { id = "openai", label = "OpenAI" },
  { id = "openrouter", label = "OpenRouter" },
  { id = nil, label = "Other — full provider list" },
}

--------------------------------------------------------------------------- --
-- Terminal
--------------------------------------------------------------------------- --

local term = {
  ---@type integer? Buffer running the agent, kept across hide and show.
  buf = nil,
}

---The window in the current tab showing `term.buf`, if any.
---@return integer?
function term.win()
  if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == term.buf then
      return win
    end
  end
  return nil
end

---Opens a vertical split on the right, a third of the window wide.
---@return integer win
local function split()
  vim.cmd("botright vsplit")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 3))
  return vim.api.nvim_get_current_win()
end

---Strips the editor chrome that makes no sense over a TUI. Window-local, so
---this has to run every time the buffer is put in a window, not just once.
---@param win integer
local function dress(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = false
  vim.wo[win].list = false
end

---Shows the agent terminal, starting it if it is not running yet.
---@param focus boolean Enter the terminal in insert mode.
---@return integer? win Nil when preflight refused to start anything.
function term.open(focus)
  local existing = term.win()
  if existing then
    if focus then
      vim.api.nvim_set_current_win(existing)
      vim.cmd("startinsert")
    end
    return existing
  end

  local previous = vim.api.nvim_get_current_win()

  -- Reuse the buffer whenever the job is still alive: hiding the window leaves
  -- the terminal buffer loaded, so the agent — and the port the plugin talks
  -- to — survive being closed and reopened.
  if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    local win = split()
    vim.api.nvim_win_set_buf(win, term.buf)
    dress(win)
    if focus then
      vim.api.nvim_set_current_win(win)
      vim.cmd("startinsert")
    else
      vim.api.nvim_set_current_win(previous)
    end
    return win
  end

  -- Nothing running: this is the only path that spawns an agent, which is why
  -- the configuration check hangs off it. Both entry points — the ,at mapping
  -- and the plugin's own server.start — funnel through here.
  if not term.preflight() then
    return nil
  end

  local win = split()
  vim.cmd("terminal opencode --port")
  term.buf = vim.api.nvim_get_current_buf()
  dress(win)

  -- bufhidden stays at its default on purpose. Anything that wipes this buffer
  -- kills the opencode process with it.
  vim.bo[term.buf].buflisted = false

  -- Getting out of a nested TUI is otherwise <C-\><C-n> and then a window
  -- motion. Buffer-local so it costs nothing anywhere else.
  vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], {
    buffer = term.buf,
    desc = "opencode: leave terminal mode and move window",
  })

  if focus then
    vim.api.nvim_set_current_win(win)
    vim.cmd("startinsert")
  else
    vim.api.nvim_set_current_win(previous)
  end
  return win
end

---Closes the window without touching the buffer, so the agent keeps running.
function term.hide()
  local win = term.win()
  if win then
    vim.api.nvim_win_close(win, false)
  end
end

function term.toggle()
  if term.win() then
    term.hide()
  else
    term.open(true)
  end
end

---Runs a one-off command in its own split, leaving the agent terminal alone.
---@param cmd string[]
local function run_in_split(cmd)
  local win = split()
  vim.cmd("terminal " .. table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " "))
  dress(win)
  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert")
end

--------------------------------------------------------------------------- --
-- Preflight
--------------------------------------------------------------------------- --

-- `:checkhealth opencode` covers the binary, curl, pgrep and lsof, but checks
-- no authentication at all — an agent with no provider starts fine and then
-- fails on the first question. That gap is what this fills.

local preflight = {
  -- Set once a provider is found. Authentication does not lapse mid-session,
  -- and this runs on every terminal start.
  ok = false,
}

---@return string[] Names of the provider variables currently exported.
function preflight.env_vars_set()
  local found = {}
  for _, var in ipairs(ENV_VARS) do
    if vim.env[var] and vim.env[var] ~= "" then
      table.insert(found, var)
    end
  end
  return found
end

---@return boolean
function preflight.has_auth()
  if preflight.ok then
    return true
  end

  -- Read the credential store rather than parsing `opencode auth list`: the
  -- path is documented, the format is JSON, and it costs no subprocess.
  local file = io.open(AUTH_FILE, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local decoded_ok, decoded = pcall(vim.json.decode, content)
    if decoded_ok and type(decoded) == "table" and next(decoded) ~= nil then
      preflight.ok = true
      return true
    end
  end

  if #preflight.env_vars_set() > 0 then
    preflight.ok = true
    return true
  end

  return false
end

---Offers to authenticate. Hands the whole exchange to `opencode auth login`
---rather than asking for a key here: that command also handles the providers
---whose login is not an API key at all, and the secret lands in opencode's own
---store instead of passing through this config.
function preflight.login()
  vim.ui.select(PROVIDERS, {
    prompt = "opencode has no provider configured. Log in with:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    local cmd = { "opencode", "auth", "login" }
    if choice.id then
      vim.list_extend(cmd, { "--provider", choice.id })
    end

    -- Clear the cache so the next start re-reads auth.json instead of
    -- trusting a "no" from before the login.
    preflight.ok = false
    run_in_split(cmd)
  end)
end

---@return boolean ok Whether an agent can usefully be started.
function term.preflight()
  if vim.fn.executable("opencode") ~= 1 then
    vim.notify(
      "opencode is not on $PATH.\nInstall it with: brew install opencode",
      vim.log.levels.ERROR,
      { title = "opencode" }
    )
    return false
  end

  if not preflight.has_auth() then
    vim.notify("opencode has no authenticated provider yet.", vim.log.levels.WARN, { title = "opencode" })
    preflight.login()
    return false
  end

  return true
end

---Appends a provider variable to ~/.zshenv.local.
---
---The secondary path, for the providers that genuinely need it: Bedrock
---authenticates from AWS_* and custom providers read `{env:VAR}`. Prefer
---`opencode auth login` for everything else.
function preflight.set_env_var()
  vim.ui.select(ENV_VARS, { prompt = "Variable to set in ~/.zshenv.local:" }, function(var)
    if not var then
      return
    end

    -- inputsecret, not vim.ui.input: the value must not be echoed on screen,
    -- kept in the ':messages' history, or recoverable from the shada file.
    local value = vim.fn.inputsecret(var .. " = ")
    if value == "" then
      return
    end

    -- Written from Lua rather than shelled out to `echo`, which would put the
    -- secret in the process table for anything running `ps` to read.
    local file, err = io.open(ENV_LOCAL, "a")
    if not file then
      vim.notify("Could not write " .. ENV_LOCAL .. ": " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    file:write(string.format('export %s="%s"\n', var, value))
    file:close()
    vim.uv.fs_chmod(ENV_LOCAL, tonumber("600", 8))

    vim.notify(
      var
        .. " written to ~/.zshenv.local.\n"
        .. "Only new shells read it, so restart the agent terminal for opencode to see it.",
      vim.log.levels.INFO,
      { title = "opencode" }
    )
  end)
end

---What is configured and what is missing, without touching any value.
function preflight.report()
  local lines = {}

  if vim.fn.executable("opencode") == 1 then
    table.insert(lines, "✓ opencode on $PATH")
  else
    table.insert(lines, "✗ opencode missing — brew install opencode")
  end

  if vim.uv.fs_stat(AUTH_FILE) then
    table.insert(lines, "✓ credentials at " .. AUTH_FILE)
  else
    table.insert(lines, "✗ no " .. AUTH_FILE .. " — run opencode auth login")
  end

  local env = preflight.env_vars_set()
  table.insert(lines, #env > 0 and ("✓ env: " .. table.concat(env, ", ")) or "· no provider env vars exported")

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "opencode setup" })
end

--------------------------------------------------------------------------- --

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
    -- ,at is the exception: it drives the terminal in this file and never
    -- touches the plugin, so it works whether or not the plugin has loaded.
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
          -- Routed through the same terminal ,at drives, so there is only ever
          -- one agent however it got started. Safe because discovery scans OS
          -- processes filtered by CWD — it never looks at windows or buffers,
          -- so a hidden terminal is still found.
          start = function()
            term.open(false)
          end,
        },
      }

      -- Registers the OpencodeEvent listener that feeds the statusline. Cheap,
      -- and it has to be in place before the agent connects.
      require("opencode_status")

      vim.api.nvim_create_user_command("OpencodeSetup", preflight.report, {
        desc = "Report what opencode still needs",
      })
      vim.api.nvim_create_user_command("OpencodeLogin", preflight.login, {
        desc = "Authenticate a provider with opencode auth login",
      })
      vim.api.nvim_create_user_command("OpencodeEnv", preflight.set_env_var, {
        desc = "Write a provider variable to ~/.zshenv.local",
      })

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

      map("t", term.toggle, "toggle the agent terminal")

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
