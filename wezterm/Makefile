.PHONY: init
init: install deploy

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy:
	mkdir -p ${HOME}/.config/wezterm
	ln -sfnv $(CURDIR)/wezterm.lua ${HOME}/.config/wezterm/wezterm.lua

.PHONY: clean
clean:
	unlink ${HOME}/.config/wezterm/wezterm.lua || true
