return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufNewFile", "BufReadPre" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {}

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end
      })

      vim.keymap.set("n", "ll", function()
        lint.try_lint()
      end, { desc = "Trigger linting for current file" })
    end
  }
}
