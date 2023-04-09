.PHONY: init
init: install deploy

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy:
	mkdir -p ${HOME}/.config
	ln -sfnv $(CURDIR) ${HOME}/.config
	
.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true
