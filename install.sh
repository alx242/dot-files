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
    tigrc
    pythonrc
    emacs
    emacs.d
    gitconfig
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

# tmux-next
ln -s $HOME/.tmux.conf $HOME/.tmux-next.conf

# Newsboat
mkdir -p $HOME/.newsboat
ln -s $SRCDIR/dot-newsboat $HOME/.newsboat/config

# Weechat
mkdir -p $HOME/.weechat
ln -s $SRCDIR/weechat.irc.conf $HOME/.weechat/irc.conf

# Some emacs modules need compilation
touch $HOME/TAGS # Make sure TAGS file exists or emacs could bork out...

mkdir -p $DESTDIR/bin
ln -s "$SRCDIR/up"  "$DESTDIR/bin"
ln -s "$SRCDIR/urlopen" "$DESTDIR/bin"
ln -s "$SRCDIR/hidpi-scale" "$DESTDIR/bin"

## Initialize some scripts
source $HOME/.bashrc
echo "make sure to install pyflakes and pep8 via pip"
