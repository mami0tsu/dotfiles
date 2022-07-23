.PHONY: init
init: install

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy: init
	ln -sfnv ${PWD}/tmux.conf ${HOME}/.tmux.conf

.PHONY: clean
clean:
	unlink ${HOME}/.tmux.conf || true	
