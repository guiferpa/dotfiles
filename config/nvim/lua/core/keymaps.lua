-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Disable arrow keys
-- map('', '<up>', '<nop>')
-- map('', '<down>', '<nop>')
-- map('', '<left>', '<nop>')
-- map('', '<right>', '<nop>')

-- Clear search highlighting with <leader> and c
map('n', '<leader>c', ':nohl<CR>')

vim.g.coc_snippet_next = '<TAB>'
vim.g.coc_snippet_prev = '<S-TAB>'

-- https://github.com/fatih/vim-go
vim.g.go_highlight_functions = 1
vim.g.go_highlight_methods = 1
vimg.go_highlight_fields = 1
vim.g.go_highlight_types = 1
vim.g.go_highlight_operators = 1
vim.g.go_highlight_build_constraints = 1

vim.api.nvim_exec([[
let s:comment_map = {
    \   "c": '\/\/',
    \   "cpp": '\/\/',
    \   "go": '\/\/',
    \   "java": '\/\/',
    \   "javascript": '\/\/',
    \   "lua": '--',
    \   "scala": '\/\/',
    \   "php": '\/\/',
    \   "python": '#',
    \   "ruby": '#',
    \   "rust": '\/\/',
    \   "sh": '#',
    \   "desktop": '#',
    \   "fstab": '#',
    \   "conf": '#',
    \   "profile": '#',
    \   "bashrc": '#',
    \   "bash_profile": '#',
    \   "mail": '>',
    \   "eml": '>',
    \   "bat": 'REM',
    \   "ahk": ';',
    \   "vim": '"',
    \   "tex": '%',
    \ }

function! ToggleComment()
  if has_key(s:comment_map, &filetype)
    let comment_leader = s:comment_map[&filetype]
    if getline('.') =~ "^\\s*" . comment_leader . " "
      " Uncomment the line
      execute "silent s/^\\(\\s*\\)" . comment_leader . " /\\1/"
    else
      if getline('.') =~ "^\\s*" . comment_leader
        " Uncomment the line
        execute "silent s/^\\(\\s*\\)" . comment_leader . "/\\1/"
      else
        " Comment the line
        execute "silent s/^\\(\\s*\\)/\\1" . comment_leader . " /"
      end
    end
  else
    echo "No comment leader found for filetype"
  end
endfunction

nnoremap <leader><Space> :call ToggleComment()<cr>
vnoremap <leader><Space> :call ToggleComment()<cr>
]], false)

-- Toggle auto-indenting for code paste
-- map('n', '<F2>', ':set invpaste paste?<CR>')
-- vim.opt.pastetoggle = '<F2>'
