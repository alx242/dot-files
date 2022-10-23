# -*- mode: sh -*-
#
# zsh version
export PATH=~/bin:~/.local/bin:/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
export EDITOR=emacs

bindkey "\e[1;5C" vi-forward-word    # CTRL+RIGHT
bindkey "\e[1;5D" vi-backward-word   # CTRL+LEFT
bindkey "\e\e[C" vi-forward-word     # META+RIGHT
bindkey "\e\e[D" vi-backward-word    # META+LEFT
bindkey "\e^?" vi-backward-kill-word # META+BACKSPACE

# Fix for zsh compinit: insecure directories, run compaudit for list.
#
# sudo chmod -R 755 =$(brew --prefix)/share

# Load all the zsh completion (homebrew style)
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
    autoload -Uz compinit
    compinit
fi

# Load git version control info
setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats       \
    '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f '
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git cvs svn

# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}

# REVERSE PROMPT 
RPROMPT=$'$(vcs_info_wrapper)'

# ORDINARY PROMPT
PS1='%F{blue}%T%f-%F{green}%n@%m%f:%F{yellow}%~%f $ '

# Git environment
function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function git-branch-in {
    echo branch \($1\) has these commits and \($(parse_git_branch)\) does not
    git log ..$1 --no-merges --format='%h | Author:%an | Date:%ad | %s' --date=local
}

function git-branch-out {
    echo branch \($(parse_git_branch)\) has these commits and \($1\) does not
    git log $1.. --no-merges --format='%h | Author:%an | Date:%ad | %s' --date=local
}

function git-branches {
    for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k|head -n 1`\\t$k;done|sort -r
}

function git-latest {
    for k in `git branch -r | perl -pe 's/^..(.*?)( ->.*)?$/\1/'`; do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k -- | head -n 1`\\t$k; done | sort -r
}

function git-svn-pull {
    DID_STASH="`git stash`"
    git pull
    git svn rebase
    if [ "${DID_STASH}" != "No local changes to save" ]; then
        git stash pop -q
    fi
}

# Repeat a command (including all params) until a error happens
# (return code =/= 0)
function repeat_until_error {
    while $@; do :; done
}

# Do a diff in emacs with file A and B
function diff_emacs {
    emacs --eval "(ediff-files \"$1\" \"$2\")"
}

# Function to see how a specific proc is behaving, limit line length
# to 80 chars
#
# Columns: CPU, PID, USER, ARGS
function top_proc {
    # Default to looking for the erlang beam
    PROC=${1:-beam.smp}
    watch -n 2 "ps -eo pcpu,pmem,pid,user,args | sort -t. -nk1,2 -k4,4 -r | grep ${PROC} | grep -v grep | grep -v \"pcpu,pmem\" |cut -c 1-80"
}

function weather {
    LOCATION=${1:-stockholm}
    curl http://wttr.in/${LOCATION}
}

function convert_m4a_to_mp3 {
    find . -name '*.m4a' -print0 | while read -d '' -r file; do
        ffmpeg -i "$file" -n -codec:a libmp3lame -qscale:a 2 "${file%.m4a}.mp3" < /dev/null
    done
}
# git checkout `git rev-list -n 1 --before="2009-07-27 13:37" master`

function unzipmulti {
    for i in *.zip; do
        echo "Unzipping ${i}"
        $(echo unzip -q "$i" -d "${i%%.zip}")
        echo done;
    done
}

# Aliases

# Set appropriate ls alias
case $(uname -s) in
    Darwin|FreeBSD)
        alias ls="ls -hFG"
        ;;
    Linux)
        alias ls="ls --color=always -hF"
        ;;
    NetBSD|OpenBSD)
        alias ls="ls -hF"
        ;;
esac
alias l="ls"
alias ll="ls -l"
alias la="ls -a"
alias big_dirs="du -hd1 . 2>/dev/null | grep '[0-9]G\>'"
alias above_80="grep -n '^.\{81\}'"
alias scpresume="rsync --append-verify --progress --rsh=ssh"
alias process_port="lsof -n -P -i +c 13"
alias tail_f="journalctl -f"
alias battery_info="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
alias tmuxemacs="tmux new-window emacs $@"

# Devel environment
#
# Supplies auto completion for ordinary python
export PYTHONSTARTUP=${HOME}/.pythonrc

# Erlang inet config:
# http://www.erlang.org/doc/apps/erts/inet_cfg.html
export ERL_INETRC=${HOME}/.inetrc
# Turn on debug info by default in all erlang applications.
export ERL_COMPILER_OPTIONS=[debug_info]

# Some dirs to scrape for source files for my etags file. Override
# these in the $EXTRA bashrc file.
export JAVA_DIRS=""
export PYTHON_DIRS=""
export ERLANG_DIRS=""
EXTRA=${HOME}/.bashrc.d/extra.bashrc
if [ -e $EXTRA ]
then
  source $EXTRA
fi
