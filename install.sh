#!/usr/bin/env bash
#set -x

INSTALLDIR=`pwd`

DESTDIR="$HOME"
SRCDIR="$HOME/dot-files"
SRCITEMS=(
    bash_profile
    bashrc
    inetrc
    inputrc
    irbrc
    pythonrc
    emacs
    emacs.d
    gitconfig
    tmux.conf
    powerline
    ttytterrc
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
cd $HOME/.emacs.d/edts && make
## cd $HOME/.emacs.d/distel && git submodule update --init && make

## Powerline
cd $HOME/.powerline && python setup.py build

## Initialize some scripts
source $HOME/.bashrc
echo "make sure to install pyflakes and pep8 via pip"
