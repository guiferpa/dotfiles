return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufNewFile", "BufReadPre" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "flake8" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        go = { "golangcilint" }
      }

      local eslint = require("config.eslint")

      -- JS/TS projects without an ESLint config are left unlinted instead
      -- of showing eslint_d's "no config found" error.
      local function try_lint()
        if eslint.filetypes[vim.bo.filetype] and not eslint.has_config(0) then
          return
        end
        lint.try_lint()
      end

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = lint_augroup,
        callback = try_lint
      })

      vim.keymap.set("n", "<leader>ll", try_lint, { desc = "Trigger linting for current file" })
    end
  }
}
