return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- v2 needs nvim-treesitter's `main` branch, which needs Neovim 0.12.
      -- Held on v1 for as long as plugins/treesitter.lua is held on `master`.
      { "fredrikaverpil/neotest-golang", version = "^1" },
    },
    -- Everything lives under `,t`, for *test*.
    keys = {
      { "<leader>tt", function() require("neotest").run.run() end, desc = "Run the nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run the tests in this file" },
      {
        "<leader>tp",
        function() require("neotest").run.run(vim.fn.expand("%:p:h")) end,
        desc = "Run the tests in this file's package",
      },
      { "<leader>ta", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run every test in the project" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Rerun the last run" },
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug the nearest test",
      },
      { "<leader>tx", function() require("neotest").run.stop() end, desc = "Stop the run" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle the test tree" },
      {
        "<leader>to",
        function() require("neotest").output.open({ enter = true, auto_close = true }) end,
        desc = "Show the output of the nearest test",
      },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle the output panel" },
      {
        "]e",
        function() require("neotest").jump.next({ status = "failed" }) end,
        desc = "Next failed test",
      },
      {
        "[e",
        function() require("neotest").jump.prev({ status = "failed" }) end,
        desc = "Previous failed test",
      },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-golang")({
            -- gotestsum writes its JSON to a file instead of stdout, which
            -- avoids the adapter's known decoding problems with `go test
            -- -json`. Installed by mason (see plugins/mason.lua).
            runner = "gotestsum",
          }),
        },
      })
    end,
  },
}
