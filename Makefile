.DEFAULT_GOAL: help

.PHONY: init
init: ## init zsh, nvim, git
	make zsh
	make nvim
	make git
	
.PHONY: zsh
zsh:
	cd zsh && make deploy

.PHONY: nvim
nvim:
	cd nvim && make deploy

.PHONY: git
git:
	cd git && make deploy
	
.PHONY: clean
clean:
	cd zsh && make clean
	cd nvim && make clean
	cd git && make clean

.PHONY: help
help: ## this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
