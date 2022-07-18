.PHONY: init
init: install
	mkdir -p ${HOME}/.config

.PHONY: install
install:
	chmod +x install.sh
	./install.sh

.PHONY: deploy
deploy: init
	ln -sfnv ${PWD} ${HOME}/.config/nvim
	
.PHONY: clean
clean:
	unlink ${HOME}/.config/nvim || true
