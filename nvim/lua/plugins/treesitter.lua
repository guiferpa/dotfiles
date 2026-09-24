return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The repo's default branch is now `main`, a rewrite that needs Neovim
    -- 0.12 and drops the `nvim-treesitter.configs` module used below. Stay on
    -- `master` until Neovim is upgraded and this file is ported.
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "rust", "go", "clojure", "typescript", "tsx", "javascript", "html", "python" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
}
