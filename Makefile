.DEFAULT_GOAL: help

.PHONY: init
init: ## init zsh, tmux, nvim, git
	cd zsh && make init && make deploy
	cd tmux && make init && make deploy
	cd nvim && make init && make deploy
	cd git && make init && make deploy
	cd wezterm && make init && make deploy

.PHONY: update
update: ## update
	cd zsh && make deploy
	cd tmux && make deploy
	cd nvim && make deploy
	cd git && make deploy
	cd wezterm && make deploy
	
.PHONY: clean
clean: ## clean
	cd zsh && make clean
	cd tmux && make clean
	cd nvim && make clean
	cd git && make clean
	cd wezterm && make clean

.PHONY: help
help: ## this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
