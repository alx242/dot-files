#!/usr/bin/env bash
#set -x

INSTALLDIR=`pwd`

DESTDIR="$HOME"
SRCDIR="$HOME/dot-files"
SRCITEMS=(
    bash_profile
    inetrc
    inputrc
    irbrc
    tigrc
    pythonrc
    emacs
    emacs.d
    gitconfig
    tmux.conf
    alacritty.yml
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

# tmux-next
ln -s $HOME/.tmux.conf $HOME/.tmux-next.conf

# Newsboat
mkdir -p $HOME/.newsboat
ln -s $SRCDIR/dot-newsboat $HOME/.newsboat/config

# Conky
mkdir -p $HOME/.config/conky
ln -s $SRCDIR/conky.conf $HOME/.config/conky/conky.conf

mkdir -p $DESTDIR/.local/bin
ln -s "$SRCDIR/backup"  "$DESTDIR/.local/bin"
ln -s "$SRCDIR/up"  "$DESTDIR/.local/bin"
ln -s "$SRCDIR/vol_up" "$DESTDIR/.local/bin"
ln -s "$SRCDIR/vol_down" "$DESTDIR/.local/bin"
ln -s "$SRCDIR/nvidiarun" "$DESTDIR/.local/bin"
ln -s "$SRCDIR/randomwallpaper" "$DESTDIR/.local/bin"
ln -s "$SRCDIR/urlopen" "$DESTDIR/.local/bin"
ln -s "$SRCDIR/conky-restart" "$DESTDIR/.local/bin"
mkdir -p $HOME/.zsh
ln -s "$SRCDIR/dot-zshrc" "$DESTDIR/.zshrc"
