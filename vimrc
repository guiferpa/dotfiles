set title

let mapleader = ","

" Normally we use vim-extensions. If you want true vi-compatibility
" remove change the following statements
set nocompatible  " Use Vim defaults instead of 100% vi compatibility
set backspace=2   " more powerful backspacing

set textwidth=80

set nowrap
set autoindent
set copyindent    " copy the previous indentation on autoindenting
set shiftwidth=2 tabstop=2

" Show trailing characters and undesirable spaces
set list
set listchars=tab:▸\ ,trail:·,nbsp:~

" Remove trailing spaces when save buffer
autocmd BufWritePre * :%s/\s\+$//e

set encoding=utf-8  " Define file to utf-8

set cursorline " Highlight current line
set expandtab " Expand tabs to spaces
set wrapscan " Searches wrap around end of file
set history=1000 " Increase history from 20 default to 1000

set hls  " highlight search
" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" AUTORELOAD
" Automatically reload buffers when file changes
set autoread

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

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
  Plug 'morhetz/gruvbox'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'ekalinin/Dockerfile.vim', {'for' : 'Dockerfile'}
  Plug 'arthurxavierx/vim-caser' "https://github.com/arthurxavierx/vim-caser#usage
  Plug 'scrooloose/nerdtree'
  Plug 'mattn/emmet-vim'
  Plug 'digitaltoad/vim-pug'
  Plug 'pangloss/vim-javascript'
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
  Plug 'junegunn/fzf.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
call plug#end()

syntax enable
set number
set bg=dark
colorscheme gruvbox
set ignorecase

" -- Syntax --

" JSON
au Bufread,BufNewFile *.json set ft=json syntax=javascript

" https://github.com/fatih/vim-go
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1


" ==================== FZF ====================
let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'down': '~20%' }

" history search file
nnoremap <leader>h :FzfHistory<cr>

" search across files in the current directory
nnoremap <leader>f :FzfFiles<cr>

nnoremap <leader>l :FzfAg<cr>

nnoremap <leader>ve :vsplit ~/.vim/vimrc<cr>

nnoremap <silent> <c-x> :NERDTreeToggle<cr>

