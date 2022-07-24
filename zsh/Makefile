CONFIG := ${HOME}/.config/zsh

.PHONY: init
init:
	ln -sfnv ${PWD}/00_zshrc ${HOME}/.zshrc

.PHONY: deploy
deploy: init
	mkdir -p ${CONFIG} && \
	ln -sfnv ${PWD}/01_config.zsh ${CONFIG} && \
	ln -sfnv ${PWD}/02_aliases.zsh ${CONFIG} && \
	ln -sfnv ${PWD}/03_plugins.zsh ${CONFIG} && \
	ln -sfnv ${PWD}/04_starship.toml ${HOME}/.config/starship.toml

.PHONY: clean
clean:
	unlink ${HOME}/.zshrc || true && \
	unlink ${HOME}/.config/starship.toml || true && \
	rm -rf $(CONFIG) || true
