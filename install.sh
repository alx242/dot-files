#!/usr/bin/env bash
#set -x

DESTDIR="$HOME"
SRCDIR="$HOME/dot-files"
SRCITEMS=(
    bash_profile
    bashrc
    inetrc
    pythonrc
    emacs
    emacs.d
    tmux.conf
)

mkdir -p $HOME/.config

## First, get all git submodules like .config/awesome/vicious and .emacs.de/edts
git submodule update --init

for SRCITEM in ${SRCITEMS[*]} ; do 
    DESTITEM=$(echo $SRCITEM | tr '!' '/')
    echo "Trying to link $DESTDIR/.$SRCITEM ..."
    [ -L "$DESTDIR/.$DESTITEM" ] && continue
    [ -e "$DESTDIR/.$DESTITEM" ] && mv "$DESTDIR/.$DESTITEM" "$DESTDIR/.$DESTITEM.bak"
    ln -s "$SRCDIR/dot-$SRCITEM" "$DESTDIR/.$DESTITEM"
done

## Some emacs modules need compilation
cd $HOME/.emacs.d/edts && git submodule update --init && make
cd $HOME

## Initialize some scripts
source $HOME/.bashrc
echo "make sure to install pyflakes and pep8 via pip"
