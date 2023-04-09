.PHONY: init
init: deploy
	chmod +x init.sh
	./init.sh

.PHONY: deploy
deploy: 
	cat $(CURDIR)/gitconfig >> ${HOME}/.gitconfig

.PHONY: clean
clean:
	rm ${HOME}/.gitconfig || true
