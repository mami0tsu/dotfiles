.PHONY: init
init: install
	mkdir -p ${HOME}/.config/wezterm

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy:
	ln -sfnv ${PWD}/wezterm.lua ${HOME}/.config/wezterm/wezterm.lua

.PHONY: clean
clean:
	unlink ${HOME}/.config/wezterm/wezterm.lua || true
