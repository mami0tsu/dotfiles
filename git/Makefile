.PHONY: init
init: deploy
	chmod +x init.sh
	./init.sh

.PHONY: deploy
deploy: 
	ln -sfnv $(CURDIR)/.gitconfig ${HOME}

.PHONY: clean
clean:
	rm ${HOME}/.gitconfig || true
