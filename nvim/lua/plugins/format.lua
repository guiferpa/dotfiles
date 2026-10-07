return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        -- eslint_d when the project configures ESLint, otherwise prettierd,
        -- which falls back to Prettier's defaults when there is no
        -- .prettierrc either.
        javascript = { "eslint_d", "prettierd", stop_after_first = true },
        typescript = { "eslint_d", "prettierd", stop_after_first = true },
        javascriptreact = { "eslint_d", "prettierd", stop_after_first = true },
        typescriptreact = { "eslint_d", "prettierd", stop_after_first = true },
        -- goimports first so the import block is settled before gofumpt
        -- lays out the rest.
        go = { "goimports", "gofumpt" }
      },
      formatters = {
        eslint_d = {
          condition = function(_, ctx)
            return require("config.eslint").has_config(ctx.buf)
          end
        }
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
