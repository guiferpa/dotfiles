return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javacript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" }
      }
    },
    config = function (_, opts)
      local conform = require('conform')

      conform.setup(opts)

      vim.keymap.set("n", "ff", function ()
        conform.format()
      end, { desc = "Format current buffer" })
    end
  }
}
