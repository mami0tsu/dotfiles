#!/bin/bash

if test $(uname) = Darwin; then
    brew tap wez/wezterm
    brew install --cask wez/wezterm/wezterm
elif test $(uname) = Linux; then
    if grep 'NAME="Ubuntu"' /etc/os-release > /dev/null; then
        if grep 'VERSION_ID="22.04"' /etc/os-release > /dev/null; then
            curl -LO https://github.com/wez/wezterm/releases/download/20220624-141144-bd1b7c5d/wezterm-20220624-141144-bd1b7c5d.Ubuntu22.04.deb
            sudo apt install -y ./wezterm-20220624-141144-bd1b7c5d.Ubuntu22.04.deb
        elif grep 'VERSION_ID="20.04"' /etc/os-release > /dev/null; then
            curl -LO https://github.com/wez/wezterm/releases/download/20220624-141144-bd1b7c5d/wezterm-20220624-141144-bd1b7c5d.Ubuntu20.04.deb
            sudo apt install -y ./wezterm-20220624-141144-bd1b7c5d.Ubuntu20.04.deb
        fi
    fi
else
    echo 'Your platform is not supported.'
    exit 1
fi
