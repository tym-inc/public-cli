# Based on https://raw.githubusercontent.com/cdr/tym/main/install.sh

# Constants
NC='\033[0m' # No Color
TEXT_BOLD='\033[1m'
TEXT_BASE='\033[0m'
LIGHT_GREEN='\033[1;32m'

# humanpath replaces all occurrences of " $HOME" with " ~"
# and all occurrences of '"$HOME' with the literal '"$HOME'.
humanpath() {
    sed "s# $HOME# ~#g; s#\"$HOME#\"\$HOME#g"
}

cath() {
  humanpath
}

echoh() {
    echo "$@" | humanpath
}

sh_c() {
    echoh "+ $*"
    if [ ! "${DRY_RUN-}" ]; then
        sh -c "$*"
    fi
}

fetch() {
    URL="$1"
    FILE="$2"

    if [ -e "$FILE" ]; then
        echoh "+ Reusing $FILE"
        return
    fi

    sh_c mkdir -p "$CACHE_DIR"
    sh_c curl \
        -#fL \
        -o "$FILE.incomplete" \
        -C - \
        "$URL"
    sh_c mv "$FILE.incomplete" "$FILE"
}

echo_cache_dir() {
    if [ "${XDG_CACHE_HOME-}" ]; then
        echo "$XDG_CACHE_HOME/tym"
    elif [ "${HOME-}" ]; then
        echo "$HOME/.cache/tym"
    else
        echo "/tmp/tym-cache"
    fi
}


echo_standalone_postinstall() {
  echoh
  cath << EOF
✅ Standalone release has been installed into $STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION

Failed to add tym to your path, extend your path to use tym:
  PATH="$STANDALONE_INSTALL_PREFIX/bin:\$PATH"

Then run with:
  tym

EOF
}

install_standalone() {
	echo
    echo "${TEXT_BOLD}${LIGHT_GREEN}Installing Tym${TEXT_BASE}${NC}"
    echo

    STANDALONE_INSTALL_PREFIX=${STANDALONE_INSTALL_PREFIX:-$HOME/.local}
    CACHE_DIR=$(echo_cache_dir)
    VERSION="1.0.0"
    OS="linux"
    ARCH="amd64"
    DOWNLOAD_URL="https://github.com/tym-inc/public-cli/releases/download/CLI3/tym-build-darwin-cli.zip"

    echo "Downloading from" ${NC}${DOWNLOAD_URL}${NC}
    echo

    fetch $DOWNLOAD_URL \
        "$CACHE_DIR/tym-$VERSION-$OS-$ARCH.tar.gz"

    # -w only works if the directory exists so try creating it first. If this
    # fails we can ignore the error as the -w check will then swap us to sudo.
    sh_c mkdir -p "$STANDALONE_INSTALL_PREFIX" 2> /dev/null || true

    sh_c="sh_c"
    if [ ! -w "$STANDALONE_INSTALL_PREFIX" ]; then
        sh_c="sudo_sh_c"
    fi


    if [ -e "$STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION" ]; then
        echo
        echo "tym-$VERSION is already installed at $STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION"
        echo "Remove it to reinstall."
        exit 0
    fi

    "$sh_c" mkdir -p "$STANDALONE_INSTALL_PREFIX/lib" "$STANDALONE_INSTALL_PREFIX/bin"
    "$sh_c" tar -C "$STANDALONE_INSTALL_PREFIX/lib" -xzf "$CACHE_DIR/tym-$VERSION-$OS-$ARCH.tar.gz"
    "$sh_c" mv -f "$STANDALONE_INSTALL_PREFIX/lib/tym-build-darwin-cli" "$STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION"
    "$sh_c" ln -fs "$STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION/cli.sh" "$STANDALONE_INSTALL_PREFIX/bin/tym"

    if ln -s "$STANDALONE_INSTALL_PREFIX/lib/tym-$VERSION/cli.sh" "/usr/local/bin/tym"; then
        echo "Installation Complete"
        echo
        echo "🚀 Welcome to Tym! 🚀 "
        echo
        echo "Run:"
        echo "  tym"
        echo
    else

        echo_standalone_postinstall
    fi
}


main(){
    install_standalone
}

# what is the "$@"
main "$@"
