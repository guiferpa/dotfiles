return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        -- goimports first so the import block is settled before gofumpt
        -- lays out the rest.
        go = { "goimports", "gofumpt" }
      },
      -- Go only: gofmt is the language's convention, so formatting on save
      -- never fights anyone. Other filetypes keep formatting on demand.
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "go" then
          return { timeout_ms = 1000 }
        end
      end
    },
    config = function (_, opts)
      local conform = require('conform')

      conform.setup(opts)

      vim.keymap.set("n", "<leader>lf", function ()
        conform.format()
      end, { desc = "Format current buffer" })
    end
  }
}
