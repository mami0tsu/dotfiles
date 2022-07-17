.PHONY: init
init:
	chmod +x init.sh
	./init.sh

.PHONY: deploy
deploy: init
	cat ${PWD}/gitconfig >> ${HOME}/.gitconfig

.PHONY: clean
clean:
	rm ${HOME}/.gitconfig || true
