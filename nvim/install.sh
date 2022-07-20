#!/bin/bash

if test $(uname) = Darwin; then
    brew install neovim
elif test $(uname) = Linux; then
    if grep 'NAME="Ubuntu"' /etc/os-release > /dev/null; then
        sudo update
        sudo apt install -y neovim
    else
        echo 'Your platform is not supported.'
        exit 1
    fi
else
    echo 'Your platform is not supported.'
    exit 1
fi
