#!/bin/bash

# asdf
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# set default editor to Vim
export EDITOR=nvim


#fly.io
export FLYCTL_INSTALL="/home/wilson/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

#My Bins
export PATH=$PATH:~/bin

# Turso
export PATH="/home/wilson/.turso:$PATH"

PATH=~/.console-ninja/.bin:$PATH

#WINEVN
alias winevn='LC_ALL="ja_JP.UTF-8" TZ="Asia/Tokyo" WINEPREFIX=~/.winevn wine'
alias wineffd='LC_ALL="ja_JP.UTF-8" TZ="Asia/Tokyo" WINEPREFIX=~/.wineffd wine'

#Grisaia 
alias grisaiaload='cdemu load 0 /run/media/wilson/wil/ajatt/vn/r49197/grisaia-no-kajitsu/GRISAIA.MDS'
alias grisaiamount='sudo mount -o loop /run/media/wilson/wil/ajatt/vn/r49197/grisaia-no-kajitsu/GRISAIA.ISO /media/cdrom0'
alias grisaiastart='cd /media/cdrom0/ && winevn bootmenu.exe'

#CDEmu
alias cdunload='cdemu unload 0'
alias cdunmount='sudo umount /media/cdrom0' 
alias texthooker='winevn /run/media/wilson/wil/ajatt/tools/Textractor/x86/Textractor.exe'

#fzf
alias fzfd='cd $(find ~ -type d -print | fzf)'

#zoxide
eval "$(zoxide init bash)"


alias clip='xclip -sel clip'

alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'


function timebox {
  local time=$1
  local sound_file=~/sounds/ringing.ogg

  timer $time && mpv $sound_file
}

function ttask {
  local flag=$1;
  local all_args=("$@")
  local rest_args=("${all_args[@]:1}")

  case $flag in
    "add")
      task add $rest_args project:"today" due:"eod";
      ;;
    "list")
      task list project:"today";
      ;;
    *)
      echo "Invalid flag";
      ;;
  esac
}

function shutdownp {
  echo -n "Are you sure you want to shut down? (y/n): "
  read choice
  if [[ $choice == "y" || $choice == "Y" ]]; then
    shutdown
  else
    echo "Shutdown canceled."
  fi
}

function nodeIpv4 {
  export NODE_OPTIONS="--dns-result-order=ipv4first"
}

export PATH="$(yarn global bin):$PATH"



#Fcitx5
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
