-- Agent status for the statusline, tracked from opencode.nvim's events.
--
-- Deliberately NOT `require("opencode").statusline`, which looks like exactly
-- this and is what the plugin's own README suggests. That function is dead
-- code: `opencode.events.status.update()`, the one thing that would translate
-- events into idle/busy/error, is never called — in v0.14.0 and on upstream
-- main alike, the only caller of that module is `reset()`. It returns the
-- disconnected icon and nothing else, forever. Check that upstream wired it up
-- before "simplifying" this file away.
--
-- The layer underneath does work, and is documented: the plugin emits every
-- server-sent event as a `User OpencodeEvent:<type>` autocmd carrying
-- `data.event` and `data.url`. That is the whole input to this module.
--
-- The name avoids the `opencode` module namespace on purpose. lazy.nvim maps
-- `opencode.*` to the plugin and intercepts those requires to load it, so a
-- file named `opencode/status.lua` here would be shadowed or would drag the
-- plugin in at startup.

local M = {}

-- The glyphs the plugin picked, kept so the two agree if it ever comes back.
-- All four are nf-md-* codepoints above U+F0001 — verified present in
-- JetBrainsMono Nerd Font Mono — which is the concrete reason README requires
-- Nerd Fonts 3.0 or newer rather than any patched build.
local ICONS = {
  idle = "󰚩",
  busy = "󱜙",
  error = "󱚡",
  offline = "󱚧",
}

---@type "idle" | "busy" | "error" | nil
local state = nil
---@type string?
local url = nil
-- False until any event has arrived. This is what separates "the agent was
-- never started" — where the statusline should stay out of the way entirely —
-- from "it was connected and is now gone", which is worth showing.
local seen = false

---@param args table Autocmd callback args, with `data.event` and `data.url`.
local function on_event(args)
  local event = args.data and args.data.event
  if not event then
    return
  end

  seen = true
  url = args.data.url

  if event.type == "server.connected" then
    state = "idle"
  elseif event.type == "session.status" then
    state = event.properties and event.properties.status and event.properties.status.type
  elseif event.type == "server.instance.disposed" then
    state, url = nil, nil
  else
    -- Every other event type (file.edited, permission.asked, ...) leaves the
    -- indicator alone, so there is nothing to redraw for.
    return
  end

  -- lualine repaints on a ~1s timer of its own. That is long enough to feel
  -- broken when this icon is the only sign the agent is working, so push it.
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh()
  end
end

---The lualine component. Empty until the agent has actually been used, so the
---statusline is unchanged for anyone who never touches opencode in a session.
---@return string
function M.component()
  if not seen then
    return ""
  end

  local icon = ICONS[state] or ICONS.offline
  -- Only the port is worth the width: it is what tells two agents apart when
  -- more than one is running against different directories.
  local port = url and url:match(":(%d+)")
  return port and (icon .. " :" .. port) or icon
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("opencode_status", { clear = true }),
  pattern = "OpencodeEvent:*",
  callback = on_event,
  desc = "Track opencode agent status for the statusline",
})

return M
