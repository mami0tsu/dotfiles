local config_dir = vim.fn.stdpath("config")

vim.cmd.source(vim.fs.joinpath(config_dir, "ddc.vim"))
vim.cmd.source(vim.fs.joinpath(config_dir, "ddu.vim"))
vim.cmd.source(vim.fs.joinpath(config_dir, "ddu-ui-ff.vim"))
vim.cmd.source(vim.fs.joinpath(config_dir, "ddu-ui-filer.vim"))
