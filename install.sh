#!/usr/bin/env bash
#set -x

INSTALLDIR=`pwd`

DESTDIR="$HOME"
SRCDIR="$HOME/dot-files"
SRCITEMS=(
    bash_profile
    own.bashrc
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

# Conky
mkdir -p $HOME/.config/conky
ln -s $SRCDIR/conky.conf $HOME/.config/conky/conky.conf

mkdir -p $DESTDIR/bin
ln -s "$SRCDIR/backup"  "$DESTDIR/bin"
ln -s "$SRCDIR/up"  "$DESTDIR/bin"
ln -s "$SRCDIR/vol_up" "$DESTDIR/bin"
ln -s "$SRCDIR/vol_down" "$DESTDIR/bin"
ln -s "$SRCDIR/nvidiarun" "$DESTDIR/bin"
ln -s "$SRCDIR/randomwallpaper" "$DESTDIR/bin"

echo ""
echo "Use standard rc files from /etc/skel instead and extend with these installers..."
echo ""

## Initialize some scripts
source $HOME/.bashrc
echo "Add this to the ~/.bashrc file: "
echo "# Support own bashrc stuff"
echo "if [ -f ~/.own.bashrc ]; then"
echo "    . ~/.own.bashrc"
echo "fi"
echo ""
