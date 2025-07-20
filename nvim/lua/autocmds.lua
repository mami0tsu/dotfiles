
-- FileType
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.go", command = "set filetype=go" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.lua", command = "set filetype=lua" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.md", command = "set filetype=markdown" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.tf", command = "set filetype=terraform" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.ts", command = "set filetype=typescript" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.tsx", command = "set filetype=typescript" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.yml", command = "set filetype=yaml" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.yaml", command = "set filetype=yaml" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.toml", command = "set filetype=toml" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "*.vim", command = "set filetype=vim" })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, { pattern = "Dockerfile*", command = "set filetype=dockerfile" })

-- Indentation settings
vim.api.nvim_create_autocmd("FileType", { pattern = "go", command = "setlocal ts=4 sts=4 sw=4" })
vim.api.nvim_create_autocmd("FileType", { pattern = "lua", command = "setlocal ts=2 sts=2 sw=2" })
vim.api.nvim_create_autocmd("FileType", { pattern = "terraform", command = "setlocal ts=2 sts=2 sw=2" })
vim.api.nvim_create_autocmd("FileType", { pattern = "typescript", command = "setlocal ts=2 sts=2 sw=2" })
vim.api.nvim_create_autocmd("FileType", { pattern = "toml", command = "setlocal ts=2 sts=2 sw=2" })
vim.api.nvim_create_autocmd("FileType", { pattern = "yaml", command = "setlocal ts=2 sts=2 sw=2 et" })
vim.api.nvim_create_autocmd("FileType", { pattern = "vim", command = "setlocal ts=4 sts=4 sw=4" })

vim.api.nvim_create_autocmd("TermOpen", { pattern = "*", command = "startinsert" })
