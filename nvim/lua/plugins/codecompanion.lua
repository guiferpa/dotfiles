-- CodeCompanion: an AI assistant that lives in Neovim buffers rather than in a
-- terminal. Two ways in:
--
--   * inline — select code (or not), describe what you want, and the answer is
--     written into the buffer as a diff to accept or reject;
--   * chat — a markdown buffer on the side for a conversation, with the
--     selection or whole buffers attached as context.
--
-- Every interaction talks to the Anthropic API over HTTP. That is a hard
-- requirement, not a preference: the inline interaction only supports HTTP
-- adapters, so the Claude Code (ACP) adapter could drive the chat but never the
-- "select and generate" half.

-- Read by the plugin's anthropic adapter at request time (its `env.api_key`
-- default). Never set here: the real value belongs in ~/.zshenv.local, the
-- same untracked file zsh/zshenv already points to.
local API_KEY_VAR = "ANTHROPIC_API_KEY"

---Warns once, on first use, when the key is missing. Without it every request
---fails with a 401 that does not say which variable to set.
local function check_api_key()
  if vim.env[API_KEY_VAR] and vim.env[API_KEY_VAR] ~= "" then
    return
  end
  vim.notify(
    API_KEY_VAR
      .. " is not set, so every request will be rejected.\n"
      .. "Add `export "
      .. API_KEY_VAR
      .. '="sk-ant-..."` to ~/.zshenv.local and restart Neovim from a new shell.',
    vim.log.levels.WARN,
    { title = "codecompanion" }
  )
end

return {
  {
    "olimorris/codecompanion.nvim",
    -- The README recommends pinning a major: breaking changes land between
    -- them, and the option names below are the v19 ones (`interactions`, not
    -- the older `strategies`).
    version = "^19.0.0",
    dependencies = {
      -- Tracks master on purpose, per the plugin's installation notes: a
      -- pinned plenary release lags behind what codecompanion needs.
      { "nvim-lua/plenary.nvim", branch = "master" },
      "nvim-treesitter/nvim-treesitter",
    },
    -- Loads on the first command or mapping; nothing runs at startup.
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    -- `,a` for AI. Not `,c`: that is already `:nohl` plus `,ca` and `,ct`, and
    -- a fourth key there would only lengthen the wait before `,c` fires.
    keys = {
      {
        "<leader>ac",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = "n",
        desc = "codecompanion: toggle the chat",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionChat Add<cr>",
        mode = "x",
        desc = "codecompanion: add selection to the chat",
      },
      {
        "<leader>an",
        "<cmd>CodeCompanionChat<cr>",
        mode = { "n", "x" },
        desc = "codecompanion: new chat",
      },
      -- Leaves the command line open for the prompt instead of asking through
      -- vim.ui.input, so it keeps cmdline history and `#{buffer}` completion.
      -- In visual mode `:` prepends the '<,'> range, which is what sends the
      -- selection along. Not silent, or the prompt would be invisible.
      {
        "<leader>ai",
        ":CodeCompanion ",
        mode = { "n", "x" },
        silent = false,
        desc = "codecompanion: inline prompt",
      },
      {
        "<leader>ap",
        "<cmd>CodeCompanionActions<cr>",
        mode = { "n", "x" },
        desc = "codecompanion: action palette",
      },
    },
    opts = {
      -- Every interaction defaults to copilot, which is not set up on this
      -- machine — including `background`, which runs the tool-call judge and
      -- chat titles behind the chat. The model is left at the adapter's
      -- default (Claude Sonnet); `ga` in the chat switches it per conversation.
      interactions = {
        background = { adapter = "anthropic" },
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
        cmd = { adapter = "anthropic" },
      },
    },
    config = function(_, opts)
      check_api_key()
      require("codecompanion").setup(opts)
    end,
  },
}
