
-- Define keymap
vim.g.mapleader = " "

vim.api.nvim_set_keymap("n", "<Leader>w", ":w<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "U", "<C-r>", { noremap = true })

-- Window
vim.api.nvim_set_keymap("n", "ws", ":split<CR><C-w>w", { noremap = true })
vim.api.nvim_set_keymap("n", "wv", ":vsplit<CR><C-w>w", { noremap = true })

vim.api.nvim_set_keymap("n", "ww", "<C-w>w", { noremap = true })
vim.api.nvim_set_keymap("n", "wh", "<C-w>h", { noremap = true })
vim.api.nvim_set_keymap("n", "wk", "<C-w>k", { noremap = true })
vim.api.nvim_set_keymap("n", "wj", "<C-w>j", { noremap = true })
vim.api.nvim_set_keymap("n", "wl", "<C-w>l", { noremap = true })

vim.api.nvim_set_keymap("n", "<C-w><Left>", "<C-w><", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-w><Right>", "<C-w>>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-w><Up>", "<C-w>+", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-w><Down>", "<C-w>-", { noremap = true })

vim.api.nvim_set_keymap("n", "<Left>", ":bp<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Right>", ":bn<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "gk", ":tabedit<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "gj", ":tabclose<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "gh", "gT", { noremap = true })
vim.api.nvim_set_keymap("n", "gl", "gt", { noremap = true })

vim.api.nvim_set_keymap("i", "<C-[>", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-[>", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-[>", "<C-\\><C-n>", { noremap = true, silent = true })
