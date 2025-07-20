
-- Basic settings
vim.opt.undodir = vim.fn.expand("~/.vim/undo")
vim.opt.undofile = true
vim.opt.undolevels = 1000

-- Encode
vim.opt.encoding = "UTF-8"
vim.opt.shortmess:append("c")

vim.opt.cmdheight = 0

-- Set statusline
vim.opt.laststatus = 2

-- Display line number
vim.opt.number = true

-- Highlight a matching opening or closing parenthesis, square bracket or a curly brace
vim.opt.showmatch = true

-- Display ruler
vim.opt.ruler = true

-- Enable incsearch
vim.opt.incsearch = true

-- Switch on highlighting the last used search pattern
vim.opt.hlsearch = true

-- Display another buffer when current buffer isn't saved.
vim.opt.hidden = true

-- Do not create swap files
vim.opt.swapfile = false

-- Share clipboard
vim.opt.clipboard:append("unnamedplus")

vim.opt.signcolumn = "yes"

vim.opt.termguicolors = true

vim.opt.showmode = false

-- Set default indent width
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wildmenu = true
vim.opt.wildmode = "full"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 0
vim.opt.virtualedit = "block"

vim.api.nvim_create_user_command("T", "split | wincmd j | resize 20 | terminal <args>", { nargs = "*" })
