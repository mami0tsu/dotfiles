#!/bin/zsh
read USER_NAME\?'input user.name (e.g. mamiotsu) > '
if test -n "${USER_NAME}"; then git config --global user.name "\"${USER_NAME}\""; fi

read USER_EMAIL\?'input user.email (e.g. mamiotsu@example.com) > '
if test -n "${USER_EMAIL}"; then git config --global user.email "\"${USER_EMAIL}\""; fi

git config --global core.editor vim
git config --global init.defaultBranch main
git config --global alias.st "status -s"

echo "\n# Global config of Git"
git config --global --list
