BREWFILE="$HOME/.brewfile"

function brew-bundle-dump() {
    command brew bundle dump --file "$BREWFILE" --force
}

brew() {
    command brew $@
    brew-bundle-dump
}
