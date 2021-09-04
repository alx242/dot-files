# -*- mode: sh -*-
export PATH=~/bin:~/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH
export EDITOR=emacs

# Stop the silly bash vs zsh warning in macos
export BASH_SILENCE_DEPRECATION_WARNING=1

# Darwin
if [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
    source "/usr/local/etc/profile.d/bash_completion.sh"
    source "/usr/local/etc/bash_completion.d/git-prompt.sh"
fi

case $(lsb_release -is) in
   Fedora)
       source /usr/share/git-core/contrib/completion/git-prompt.sh
       ;;
   *)
       ;;
esac

# Prompt flipping...
function ok_prompt {
    local DARKBLUE="\[\033[2;34m\]"
    local LIGHTBLUE="\[\033[0;34m\]"
    local LIGHTRED="\[\033[0;34m\]"
    local WHITE="\[\033[1;37m\]"
    local CYAN="\[\033[1;36m\]"
    local BLACK="\[\033[1;30m\]"
    local GREEN="\[\033[1;32m\]"
    local PURPLE="\[\033[1;35m\]"
    local RED="\[\033[1;31m\]"
    local YELLOW="\[\033[1;33m\]"
    local NO_COLOUR="\[\033[0m\]"
    local GIT='$(__git_ps1 " (%s)")'
    case $TERM in
        xterm*|rxvt*)
            TITLEBAR='\[\033]0;\u@\h:\w\007\]'
            ;;
        *)
            TITLEBAR=""
            ;;
    esac

#     PS1="${TITLEBAR}\
# $WHITE[$NO_COLOR\u@\h:\w${GIT}$WHITE]\
# $WHITE->$NO_COLOUR "
    # PS1='[\u@\h \W]\$ '
    PS1="\[\033[35m\]\t\[\033[m\]-\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
    PS2='> '
    PS4='+ '
}
ok_prompt

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
EXTRA=${HOME}/.extra.bashrc
if [ -e $EXTRA ]
then
  source $EXTRA
fi
