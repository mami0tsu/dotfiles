#!/bin/zsh

read USER_NAME\?'input user.name (e.g. username) > '
if test -n "${USER_NAME}"; then git config --global user.name "\"${USER_NAME}\""; fi
read USER_EMAIL\?'input user.email (e.g. username@example.com) > '
if test -n "${USER_EMAIL}"; then git config --global user.email "\"${USER_EMAIL}\""; fi
