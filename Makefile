deploy: ## deploy setting files (neovim, starship, zsh)
	@make deploy-nvim
	@make deploy-starship
	@make deploy-zshrc
deploy-neovim:
	ln -s nvim/ ~/.config/nvim/
deploy-starship:
	ln -s starship.toml ~/.config/starship.toml
deploy-zshrc:
	ln -s .zshrc ~/.zshrc
# ------------------------------------------------------------
install: ## install tools (neovim, starship)
	@make install-nvim
	@make install-starship
install-neovim:
	if test $(uname) = Darwin; then
		brew install neovim
	elif test $(uname) = Linux; then
		if grep 'NAME="Ubuntu"' /etc/os-release > /dev/null; then
			sudo update
			sudo apt install -y neovim
		else
			echo 'Your platform is not supported.'
			exit 1
	else
		echo 'Your platform is not supported.'
		exit 1
	fi
install-starship:
	curl -sS https://starship.rs/install.sh | sh
	if test $(uname) = Darwin; then
		brew install starship
	elif test $(uname) = Linux; then
		if grep 'NAME="Ubuntu"' /etc/os-release > /dev/null; then
			sudo update
			sudo apt install -y starship
		else
			echo 'Your platform is not supported.'
			exit 1
	else
		echo 'Your platform is not supported.'
		exit 1
	fi
# ------------------------------------------------------------
set-gitconfig: ## set gitconfig
	read USER_NAME\?'input user.name (e.g. username) > '
	if test -n "${USER_NAME}"; then git config --global user.name "\"${USER_NAME}\""; fi
	read USER_EMAIL\?'input user.email (e.g. username@example.com) > '
	if test -n "${USER_EMAIL}"; then git config --global user.email "\"${USER_EMAIL}\""; fi
# ------------------------------------------------------------
help: ## this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
