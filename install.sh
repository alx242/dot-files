#!/usr/bin/env bash
#
# Install dot-files via GNU stow.
# Works on both macOS and GNU/Linux (requires stow >= 2.4 for --dotfiles).
#
set -eu

SRCDIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v stow >/dev/null 2>&1; then
    echo "Error: GNU stow is not installed. Install it with 'brew install stow' or 'apt install stow'." >&2
    exit 1
fi

# Ensure target directories exist.
mkdir -p "$HOME/.config" "$HOME/.local/bin"

# Backup helper: remove pre-existing symlinks (so stow can replace them) and
# move regular files/directories aside to a .bak name.
backup_if_regular() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -e "$target" ]; then
        echo "Backing up existing $target -> $target.bak"
        mv "$target" "$target.bak"
    fi
}

# Package linked into $HOME (with --dotfiles: dot-foo -> .foo).
for f in "$SRCDIR"/home/dot-*; do
    base="${f##*/dot-}"
    backup_if_regular "$HOME/.$base"
done
stow -d "$SRCDIR" -t "$HOME" --dotfiles -R home

# starship.toml -> ~/.config/starship.toml
backup_if_regular "$HOME/.config/starship.toml"
stow -d "$SRCDIR" -t "$HOME/.config" -R config

# urlopen -> ~/.local/bin/urlopen
backup_if_regular "$HOME/.local/bin/urlopen"
stow -d "$SRCDIR" -t "$HOME/.local" -R local

# The newsboat config must end up at ~/.newsboat/config. With --dotfiles, stow
# links newsboat/dot-newsboat/ -> ~/.newsboat/ (as a directory symlink via
# tree-folding), which in turn contains the "config" file.
# Clean up any pre-existing ~/.newsboat (it may be a real directory created by
# the old install.sh, containing a "config" symlink).
if [ -L "$HOME/.newsboat" ]; then
    rm "$HOME/.newsboat"
elif [ -d "$HOME/.newsboat" ]; then
    if [ -L "$HOME/.newsboat/config" ]; then
        rm "$HOME/.newsboat/config"
    elif [ -e "$HOME/.newsboat/config" ]; then
        mv "$HOME/.newsboat/config" "$HOME/.newsboat/config.bak"
    fi
    rmdir "$HOME/.newsboat" 2>/dev/null || {
        echo "Backing up existing $HOME/.newsboat -> $HOME/.newsboat.bak"
        mv "$HOME/.newsboat" "$HOME/.newsboat.bak"
    }
fi
stow -d "$SRCDIR" -t "$HOME" --dotfiles -R newsboat

echo "Done."
