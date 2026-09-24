return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    -- Everything lives under `,d`, for *debug*. Loaded on the first of these
    -- keys, so nothing is paid for until a session is actually wanted.
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Start or continue" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Rerun the last session" },
      { "<leader>dx", function() require("dap").terminate() end, desc = "Stop the session" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle the debug UI" },
      {
        "<leader>de",
        function() require("dapui").eval() end,
        mode = { "n", "v" },
        desc = "Evaluate the expression under the cursor or the selection",
      },
      { "<leader>dt", function() require("dap-go").debug_test() end, desc = "Debug the Go test under the cursor" },
      { "<leader>dT", function() require("dap-go").debug_last_test() end, desc = "Debug the last Go test again" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Uses `dlv` from PATH, which mason puts first (see plugins/mason.lua).
      require("dap-go").setup()
      dapui.setup()

      -- The UI follows the session: it opens when one starts and closes when
      -- it ends, so `,du` is only needed to peek at it in between.
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
    end,
  },
}
