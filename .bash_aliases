#!/bin/bash

# set default editor to Vim
export EDITOR=nvim

#My Bins
export PATH=$PATH:~/bin

#WINEVN
alias winevn='LC_ALL="ja_JP.UTF-8" TZ="Asia/Tokyo" WINEPREFIX=~/.winevn wine'
alias wineffd='LC_ALL="ja_JP.UTF-8" TZ="Asia/Tokyo" WINEPREFIX=~/.wineffd wine'

#ChaosHead 
alias chaosfrida='protontricks-launch --appid 1961950 ~/Downloads/frida-server-16.2.1-windows-x86_64.exe'
alias chaostask='protontricks -c "wine taskmgr" 1961950'

#CDEmu
alias cdunload='cdemu unload 0'
alias cdunmount='sudo umount /media/cdrom0' 
alias texthooker='winevn /run/media/wilson/wil/ajatt/tools/Textractor/x86/Textractor.exe'

#fzf
alias fzfd='cd $(find ~ -type d -print | fzf)'

#zoxide
eval "$(zoxide init zsh)"


alias clip='xclip -sel clip'

alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'

gmove() {
  git stash -- $(git diff --staged --name-only) &&
  gwip ;
  git branch $1 $2 &&
  git checkout $1 &&
  git stash pop
}

function timebox {
  local time=$1
  local sound_file=~/sounds/ringing.ogg

  # https://github.com/caarlos0/timer
  timer $time && mpv $sound_file --no-resume-playback
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

function nodeIpv4 {
  export NODE_OPTIONS="--dns-result-order=ipv4first"
}

# export PATH="$(yarn global bin):$PATH"
export PATH="/home/wilsonn/.cargo/bin:$PATH"

alias sine-a="mpv ~/sounds/a440hz.opus"
