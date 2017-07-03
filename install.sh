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
    surfraw.conf
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

# tmux-next
ln -s $HOME/.tmux.conf $HOME/.tmux-next.conf

# Newsbeuter
mkdir -p $HOME/.newsbeuter
ln -s $SRCDIR/dot-newsbeuter $HOME/.newsbeuter/config

# Weechat
mkdir -p $HOME/.weechat
ln -s $SRCDIR/weechat.irc.conf $HOME/.weechat/irc.conf

# Some emacs modules need compilation
touch $HOME/TAGS # Make sure TAGS file exists or emacs could bork out...

# Tmux themes
git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack

mkdir -p $DESTDIR/bin
ln -s "$SRCDIR/brew_up" "$DESTDIR/bin"
ln -s "$SRCDIR/apt_up"  "$DESTDIR/bin"
ln -s "$SRCDIR/urlopen" "$DESTDIR/bin"

## Initialize some scripts
source $HOME/.bashrc
echo "make sure to install pyflakes and pep8 via pip"
