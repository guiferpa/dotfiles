return {
  {
    "nvimtools/none-ls.nvim",
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.gofumpt,
          null_ls.builtins.formatting.goimports,
          null_ls.builtins.diagnostics.clj_kondo,
          null_ls.builtins.formatting.prettierd,
        },
      })

      vim.keymap.set("n", "ff", function()
        vim.lsp.buf.format({ async = true })
      end, {})
    end,
  },
}
