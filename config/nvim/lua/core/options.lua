local opt = vim.opt
local fn = vim.fn
local cmd = vim.cmd

opt.encoding = 'utf8'

opt.autoread = true

opt.number = true
opt.relativenumber = false

opt.title = true
opt.clipboard = 'unnamedplus'

opt.cursorline = true

opt.hidden = true
opt.cc = "80"
opt.cmdheight = 2

opt.shiftwidth = 2
opt.expandtab = true
opt.softtabstop = 2
opt.smartindent = true

opt.list = true
opt.listchars = { eol = '↲', tab = '▸ ', trail = '·', nbsp = '~' }

if fn.has("termguicolors") == 1 then
  opt.termguicolors = true
  cmd('let $NVIM_TUI_ENABLE_TRUE_COLOR=1')
end

if fn.has('nvim-0.7') == 1 then
  print('We got neovim 0.7')
end
