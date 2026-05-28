#!/usr/bin/env bash
#set -x

INSTALLDIR=`pwd`

DESTDIR="$HOME"
SRCDIR="$HOME/dot-files"
SRCITEMS=(
    inputrc
    tigrc
    pythonrc
    emacs
    emacs.d
    gitconfig
    zshrc
    mg
    ripgreprc
)

mkdir -p $HOME/.config


# ssl.conf Only works with openssl (on linux)

## First, get all git submodules like .config/awesome/vicious and .emacs.de/edts
git submodule update --init

for SRCITEM in ${SRCITEMS[*]} ; do
    DESTITEM=$(echo $SRCITEM | tr '!' '/')
    echo "Trying to link $DESTDIR/.$SRCITEM ..."
    [ -L "$DESTDIR/.$DESTITEM" ] && continue
    [ -e "$DESTDIR/.$DESTITEM" ] && mv "$DESTDIR/.$DESTITEM" "$DESTDIR/.$DESTITEM.bak"
    ln -s "$SRCDIR/dot-$SRCITEM" "$DESTDIR/.$DESTITEM"
done

# Newsboat
mkdir -p $HOME/.newsboat
ln -s $SRCDIR/dot-newsboat $HOME/.newsboat/config

# Starship
ln -s $SRCDIR/starship.toml $HOME/.config/starship.toml

mkdir -p $DESTDIR/.local/bin
ln -s "$SRCDIR/urlopen" "$DESTDIR/.local/bin"
mkdir -p $HOME/.zsh
