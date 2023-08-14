BREWFILE := ${HOME}/.brewfile
CONFIG := ${HOME}/.config/zsh

.PHONY: init
init: deploy
	/bin/bash -c "$(shell curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
	brew bundle --file $(BREWFILE)

.PHONY: deploy
deploy:
	ln -sfnv $(CURDIR)/.zshrc ${HOME} && \
	mkdir -p $(CONFIG) && \
	ln -sfnv $(CURDIR)/config.zsh $(CONFIG) && \
	ln -sfnv $(CURDIR)/aliases.zsh $(CONFIG) && \
	ln -sfnv $(CURDIR)/plugins.zsh $(CONFIG) && \
	ln -sfnv $(CURDIR)/rtx.toml ${HOME}/.config/rtx/rtx.toml && \
	ln -sfnv $(CURDIR)/starship.toml ${HOME}/.config/starship/starship.toml && \
	ln -sfnv $(CURDIR)/.brewfile $(BREWFILE)

.PHONY: clean
clean:
	unlink ${HOME}/.zshrc || true && \
	unlink ${HOME}/.config/starship.toml || true && \
	rm -rf $(CONFIG) || true
