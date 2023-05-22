#!/bin/bash


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

alias clip='xclip -sel clip'

alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'

alias code="flatpak run com.visualstudio.code"

function timebox {
  local time=$1
  local sound_file=~/sounds/ringing.ogg

  timer $time && mpv $sound_file
}

