vim.opt.encoding = "utf8"
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.title = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.cursorline = true
vim.opt.cc = "80"
vim.opt.cmdheight = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.list = true
-- Every glyph here has to exist in the terminal font (JetBrainsMono Nerd Font
-- Mono, set in rio/config.toml), since `list` draws them on every line.
-- That font has no ↲, so eol uses ⏎, the closest return mark it does carry.
vim.opt.listchars = { eol = '⏎', tab = '▸ ', trail = '·', nbsp = '~' }
vim.g.mapleader = ","
vim.g.maplocalleader = ","

