.PHONY: init
init:
	mkdir -p ${HOME}/.config

.PHONY: install
install:
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

.PHONY: deploy
deploy: init
	ln -sfnv ${PWD} ${HOME}/.config/nvim
	
.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true
