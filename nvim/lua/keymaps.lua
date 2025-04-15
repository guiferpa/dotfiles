function map(mode, lhs, rhs, opts)
  local options = { noremap=true, silent=true }
  if opts then
    opts = vim.tbl_extend('force', options, opts)
  end
  vim.api.vim_set_keymap(mode, lhs, rhs, options)
end

map('n', '<leader>c', ':nohl<CR>')
