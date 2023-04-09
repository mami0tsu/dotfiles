.PHONY: init
init: install deploy

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy:
	ln -sfnv $(CURDIR)/tmux.conf ${HOME}/.tmux.conf

.PHONY: clean
clean:
	unlink ${HOME}/.tmux.conf || true	
