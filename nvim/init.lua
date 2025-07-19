-- Load core configuration
require("options")
require("keymaps")
require("autocmds")

-- Define standard paths
local config_dir = vim.fn.stdpath("config")
local cache_dir = vim.fn.stdpath("cache")
local dein_base_dir = vim.fs.joinpath(cache_dir, "dein")
local dein_repo_dir = vim.fs.joinpath(dein_base_dir, "repos/github.com/Shougo/dein.vim")

-- Bootstrap dein.vim: install if it's not already installed.
local function bootstrap_dein()
  if vim.fn.exists("*dein#begin") == 0 then
    if vim.fn.isdirectory(dein_repo_dir) == 0 then
      print("Installing dein.vim...")
      vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/Shougo/dein.vim", dein_repo_dir })
    end
    vim.opt.runtimepath:prepend(dein_repo_dir)
  end
end

bootstrap_dein()

-- Configure dein.vim
vim.g.dein = {
  auto_recache = true,
  lazy_rplugins = true,
  install_progress_type = "floating",
  install_check_diff = true,
  enable_notification = true,
  install_check_remote_threshold = 24 * 60 * 60, -- 1 day
  auto_remote_plugins = false,
  install_copy_vim = true,
}

-- Load plugins from TOML files
if vim.fn["dein#min#load_state"](dein_base_dir) > 0 then
  vim.fn.setenv("BASE_DIR", config_dir)
  vim.fn["dein#begin"](dein_base_dir, vim.empty_dict())

  local tomls = {
    { file = "dein.toml", lazy = 0 },
    { file = "dein_lazy.toml", lazy = 1 },
    { file = "ddc.toml", lazy = 1 },
    { file = "ddu.toml", lazy = 1 },
    { file = "neovim.toml", lazy = 0 },
    { file = "neovim_lazy.toml", lazy = 1 },
  }

  for _, toml_spec in ipairs(tomls) do
    local toml_path = vim.fs.joinpath(config_dir, toml_spec.file)
    if vim.fn.filereadable(toml_path) > 0 then
      vim.fn["dein#load_toml"](toml_path, { lazy = toml_spec.lazy })
    end
  end

  -- Install any missing plugins (moved here)
  if vim.fn["dein#check_install"]() > 0 then
    vim.fn["dein#install"]()
  end

  vim.fn["dein#end"]()
  vim.fn["dein#save_state"]()
end
