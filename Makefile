.DEFAULT_GOAL: help

.PHONY: init
init: ## init
	make -C zsh init
	make -C tmux init
	make -C nvim init
	make -C git init
	make -C wezterm init

.PHONY: update
update: ## update
	make -C zsh deploy
	make -C tmux deploy
	make -C nvim deploy
	make -C git deploy
	make -C wezterm deploy
	
.PHONY: clean
clean: ## clean
	make -C zsh clean
	make -C tmux clean
	make -C nvim clean
	make -C git clean
	make -C wezterm clean

.PHONY: help
help: ## this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
