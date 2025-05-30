#!/bin/bash
# Version 1.1

# WINEARCH win32/win64 not as good as binary wine/wine64"
# WINEDEBUG="-all" not as good as dev/null

# complex command line builder to simplify command objects
# vars bin, pfx set to wine binary, prefix dirs initially
# menus will dynamically set bin pfx to specific targets
# menu shows gui based 32/64-bit pe header exe via pev
# var 'x' for unified cross-functionality
# ${@:2} skips 'wstart' and 1st arg

# manjaro 21.2.1
#sudo pacman -S bash binutils findutils gendesk grep icoutils pcre2 perl yay winetricks; yay -S pev

# wnbin needs wine dir with: bin lib lib64 share
# manjaro default path is /usr
# can symlink various wnbin="$HOME/.local/opt"
#mkdir "$HOME"/.local/opt
#ln -sf /usr "$HOME"/.local/opt/wine
#ln -sf /usr/share/steam/compatibilitytools.d/proton-ge-custom/files "$HOME"/.local/opt/proton

wnbin="/usr"
# top level wine dir, symlink into "$HOME/.local/opt" to flatten paths
wnpfx="$HOME"
# top level wine prefix dir
pntop="$HOME/.steam"
# top level linux steam dir
pnapp="$pntop/steam/steamapps"
# steamapps subdir
pnbin="$pnapp/common"
# proton subdir normally under top/app
pnpfx="$pnapp/compatdata"
# proton prefix subdir normally under top/app
pnpge="$pntop/root/compatibilitytools.d"
# proton ge
progs="drive_c/Program Files"
# Program Files standard subdir
stcmn="Steam/steamapps/common"
# windows steam client subdir under progs
desk="$HOME/Desktop"
# desktop entry folder
icon="applications-other"
# default icon
temp="$HOME/Downloads"
# temp folder
clprm=("${@:2}")
# store cmdline args minus first option
x="$(echo "$1" | grep -Pio '(?<=-)[wp]')"
# 1st letter of 1st cmd line arg determines wine/proton
if [[ -n "$x" ]]; then
  xarg="$(echo "$1" | perl -pe 's/-[wp]/-x/gi')"
else
  xarg="$(echo "$1" | perl -pe 's/-x+/-/gi')"
fi
# drop 1st letter x or change to it
xcmd=()
i_mnus=()
myprnt=()
i_syms=()
pmenu=("Command Prompt/wineconsole.exe" "Control Panel/control.exe" "Registry Editor/regedit.exe" "Task Manager/taskmgr.exe" "Windows Explorer/explorer.exe" "Wine Configuration/winecfg.exe")
# scalable built-in programs menu
unset WINEARCH WINEDLLPATH WINEPREFIX STEAM_COMPAT_CLIENT_INSTALL_PATH STEAM_COMPAT_DATA_PATH
# prevent shell inheritance of env vars we use

w_menu () {
PS3="Please enter your choice: "
select answer in "${i_mnus[@]}"; do
  for item in "${i_mnus[@]}"; do
    if [[ $item == $answer ]]; then
      break 2
    fi
  done
done
# repeating menu requires valid selection from array
if [[ "$answer" = "quit" ]]; then
# pop quit from end of array for menu option
  exit
else
  xmrtn="$answer"
fi
unset i_mnus
clear
}

# Path ordering: wine64 x64/x32 or wine32 x32 then standard
# Order critical to proper operation
xn64 () {
xstrt="wine64"
xnldl="$xnbin/lib64:$xnbin/lib"
xndll="$xnbin/lib64/wine:$xnbin/lib/wine"
}

xn32 () {
xstrt="wine"
xnldl="$xnbin/lib"
xndll="$xnbin/lib/wine"
}

xnint () {
if [[ "$x" = "p" ]]; then
  xnbin="$pnbin"
  xnpfx="$pnpfx"
  dpth=(4 3)
else
  xnbin="$wnbin"
  xnpfx="$wnpfx"
  dpth=(3 2)
fi
}

xnexe () {
# menu installed wine/proton or exit
readarray -t i_mnus < <(find -L "$xnbin" -maxdepth "${dpth[0]}" -type f -iname 'wine' ! \( -ipath '*/sbin*' \) 2>/dev/null | perl -pe "s|\Q$xnbin\E/(.*)[/]*bin/wine|\1| ; s|/$||" | sort ; echo "quit")
if [[ ${#i_mnus[@]} -gt 2 ]]; then
  clear
  w_menu
  xnbin="$(realpath "$xnbin/$xmrtn")"
  unset xmrtn
elif [[ ${#i_mnus[@]} -eq 2 ]]; then
  xnbin="$(realpath "$xnbin/${i_mnus[0]}")"
else
  echo "No installed Wine/Proton found."
  exit 1
fi
}

xndef () {
# create default prefix cross-function
if [[ "$x" = "p" ]]; then
  if [[ ! -d "$xnpfx/0" ]]; then
  # always create default 0 prefix
    xnpfx="$xnpfx/0"
    echo "Creating default prefix: $xnpfx"
    mkdir -p "$xnpfx"
    STEAM_COMPAT_DATA_PATH="$xnpfx" "${xnbin%/*}/proton" run > /dev/null 2>&1 &
    xnpfx="$xnpfx/pfx"
  fi
else
  if [[ ! -d "$xnpfx/.wine" ]]; then
  # always create default wine prefix
    xnpfx="$xnpfx/.wine"
    echo "Creating default prefix: $xnpfx"
    WINEPREFIX="$xnpfx" "$xnbin"/bin/winecfg > /dev/null 2>&1 &
    if [[ -d "$HOME/.wine" && "$HOME/.wine" != "$xnpfx" ]]; then
      rm -rf "$HOME"/.wine
      ln -sf "$xnpfx" "$HOME"/.wine
    fi
  fi
fi
}

xnpre () {
# menu wine/proton prefix
readarray -t i_mnus < <(find "$xnpfx" -maxdepth "${dpth[1]}" -type f -iname 'system.reg' 2>/dev/null | perl -pe "s|\Q$xnpfx\E/(.*)/system.reg|\1|" | sort ; echo "quit")
# use perl escaped Q/E to preserve special characters in path variable
if [[ ${#i_mnus[@]} -gt 2 ]]; then
# display menu with min two options plus quit
# guard proton cross-function
  if [[ "$x" = "p" ]]; then
    for value in $(find "$xnpfx" -maxdepth 1 -type d -ipath '*/[0-9]*' -printf "${xnpfx///compatdata}/appmanifest_%P.acf\n" 2>/dev/null); do
      test -f "$value" && myprnt+=("$(grep -Pio '^\s+\"(appid|name)\"\s+\"(.*)\"' "$value" | perl -pe 's/.*appid.+?\"(.*)\"\v|.*name.+?\"(.*)\"/\1 \2/')")
    done
    if [[ ${#myprnt[@]} -gt 0 ]]; then
      printf '%s\n' "${myprnt[@]}" | sort
    fi
    # correlate appmanifest to proton prefix and list before menu
    unset myprnt
  fi
  w_menu
  xnpfx="$xnpfx/$xmrtn"
  unset xmrtn
elif [[ ${#i_mnus[@]} -eq 2 ]]; then
# don't menu if only one option plus quit
  xnpfx="$xnpfx/${i_mnus[0]}"
fi
if [[ -d "$xnpfx/$progs (x86)" ]]; then
  xn64
else
  xn32
fi
}

xnenv () {
# core env vars allow proper targetting of wine/proton
xpath="$xnbin/bin:$PATH"
xcmd=(env PATH="$xpath" WINEDLLPATH="$xndll" LD_LIBRARY_PATH="$xnldl" WINEPREFIX="$xnpfx")
# guard proton cross-function which adds on to core env vars
if [[ "$x" = "p" ]]; then
  xcmd+=(STEAM_COMPAT_DATA_PATH="${xnpfx///pfx}" STEAM_COMPAT_CLIENT_INSTALL_PATH="$pntop")
fi
}

xnldr () {
# loader default to proton as applicable, otherwise wine
if [[ "$x" = "p" ]]; then
  read -r -p 'wine loader? [y/N] ' chse
  if [[ "$chse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    xcmd+=("$xstrt")
  else
    xcmd+=("${xnbin%/*}/proton" "run")
  fi
else
  xcmd+=("$xstrt")
fi
}

xnset () {
# set cross-fuction
xnint
# wine/proton menu
xnexe
# create default prefix as required
xndef
# wine/proton prefix
xnpre
# wine/proton env vars
xnenv
}

xlnch () {
# cross-function command line launcher
if [[ -z "$dbg" ]]; then
  ("${xcmd[@]}" > /dev/null 2>&1 &)
else
  echo "${xcmd[@]}"
  if [[ "$dbg" = "1" ]]; then
    ("${xcmd[@]}" &)
  elif [[ "$dbg" = "2" ]]; then
    (WINEDEBUG="warn+all" "${xcmd[@]}" &)
  fi
fi
# prepend cmd with dbg=1 to see command and default debug output
# dbg=2 to see command and all debug output, dbg=? for command only
}

allexe () {
# unfiltered list of exe in specified path
if [[ -n "$(stat --file-system --format=%T $(stat --format=%m "$pedir" 2>/dev/null) 2>/dev/null | grep -Pio 'fuse')" ]]; then
  readarray -t i_mnus < <(find "$pedir" -maxdepth 7 -type f -regextype posix-extended -iname '*.exe' 2>/dev/null | perl -pe "s|\Q$pedir\E/(.*)|\1|" | sort ; echo "quit")
  # skip exe validity tests if file is on network drive
else
  readarray -t i_mnus < <(env pedir="$pedir" find "$pedir" -maxdepth 7 -type f -regextype posix-extended -iname '*.exe' -exec sh -c '(readpe -h optional "$1" 2>/dev/null | grep -Piq '0x2.*gui') && (wrestool "$1" 2>/dev/null | grep -Piq 'type=icon') && echo "$1" 2>/dev/null | perl -pe "s|\Q$pedir\E/(.*)|\1|"' -- {} \; 2>/dev/null | sort ; echo "quit")
  # perform exe validity tests if file is on local drive
fi
}

fewexe () {
# filtered list of exe in standard paths
readarray -t i_mnus < <(env pedir="$pedir" find "$pedir" -maxdepth 7 -type f -regextype posix-extended ! \( -ipath '*cache*' -o -ipath '*/microsoft*' -o -ipath '*/windows*' -o -ipath '*/temp*' \) ! \( -iregex '.*(capture|clokspl|helper|iexplore|install|internal|kernel|[^ ]launcher|legacypm|overlay|proxy|redist|renderer|(crash|error)reporter|serv(er|ice)|setup|streaming|tutorial|unins|update).*' \) -iname '*.exe' -exec sh -c '(readpe -h optional "$1" 2>/dev/null | grep -Piq '0x2.*gui') && (wrestool "$1" 2>/dev/null | grep -Piq 'type=icon') && echo "$1" 2>/dev/null | perl -pe "s|\Q$pedir\E/(.*)|\1|"' -- {} \; 2>/dev/null | sort ; echo "quit")
# valid exe will have gui and icon
}

alloth () {
# unfiltered list of variable type in specified path
  readarray -t i_mnus < <(find "$pedir" -maxdepth 7 -type f -regextype posix-extended -iname "$xflt" 2>/dev/null | perl -pe "s|\Q$pedir\E/(.*)|\1|" | sort ; echo "quit")
}

fewoth () {
# filtered list of variable type in standard paths
readarray -t i_mnus < <(env pedir="$pedir" find "$pedir" -maxdepth 7 -type f -regextype posix-extended ! \( -ipath '*cache*' -o -ipath '*/microsoft*' -o -ipath '*/windows*' -o -ipath '*/temp*' \) ! \( -iregex '.*(capture|clokspl|helper|iexplore|install|internal|kernel|[^ ]launcher|legacypm|overlay|proxy|redist|renderer|(crash|error)reporter|serv(er|ice)|setup|streaming|tutorial|unins|update).*' \) -iname "$xflt" 2>/dev/null | perl -pe "s|\Q$pedir\E/(.*)|\1|" | sort ; echo "quit")
}

xbld () {
# cross-function custom prefix builder
pnpfx="$pnpfx/${clprm[0]}"
wnpfx="$wnpfx/${clprm[0]}"
xnint
if [[ -z "${clprm[0]}" ]]; then
  echo "Wine/Proton prefix name required: (e.g. .wine, 0 )"
elif [[ -d "$xnpfx" ]]; then
  echo "Wine/Proton Prefix exists: $xnpfx"
else
  xnexe
  echo "Creating Wine/Proton Prefix: ${clprm[0]}"
  if [[ "$x" = "p" ]]; then
    xnenv
    mkdir -p "$xnpfx"
    xcmd+=(STEAM_COMPAT_DATA_PATH="$xnpfx" "${xnbin%/*}/proton" "run")
  else
    read -r -p '32-bit only? [y/N] ' chse
    if [[ "$chse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
      xn32
      xnenv
      xcmd+=(WINEARCH="win32" "$xstrt" "winecfg.exe")
    else
      xn64
      xnenv
      xcmd+=(WINEARCH="win64" "$xstrt" "winecfg.exe")
    fi
  fi
  xlnch
fi
}

xpmn () {
# use specified exe, menu specified folder, or menu system
if [[ -f "${clprm[0]}" ]]; then
# parse 1st cmdline arg, queue if valid file
  pedir="$(realpath "${clprm[0]}")"
  xmrtn="$(basename "$pedir")"
  pedir="$(dirname "$pedir")"
else
  if [[ -d "${clprm[0]}" ]]; then
  # parse 1st cmdline arg, use as path if valid
    pedir="$(realpath "${clprm[0]}")"
    test -z "$xflt" && allexe || alloth
  else
  # if no cmdline path, use prefix drive_c
    pedir="$xnpfx/drive_c"
    test -z "$xflt" && fewexe || fewoth
  fi
  # create menu, from path, of file
  test ${#i_mnus[@]} -gt 1 && w_menu
fi
}

xlyt() {
# pe layout for launch
# 64-bit prefix, 32-bit pe header, reset env to 32
if [[ -n "$(readpe -h optional "$pedir/$xmrtn" 2>/dev/null | grep -Pi 'magic number.*0x10b')" && -d "$xnpfx/$progs (x86)" ]]; then
  xn32
  xnenv
fi
xnldr
# if 1st arg is file/folder, skip it and run selection + remaining args
if [[ -e "${clprm[0]}" ]];then
  xcmd+=("$pedir/$xmrtn" "${clprm[@]:1}")
else
  xcmd+=("$pedir/$xmrtn" "${clprm[@]}")
fi
}

xstm() {
if [[ "$x" = "p" ]]; then
  sstrt="$(realpath "$(which steam)" 2>/dev/null)"
else
  xnset
  sstrt="$(find "$xnpfx/drive_c" -maxdepth 3 -iname 'steam.exe' 2>/dev/null)"
  if [[ -f "$sstrt" ]]; then
    pnapp="$(dirname "$sstrt")/steamapps"
    xcmd+=("$xstrt")
  fi
fi
# find wine/proton steam binary path, normally subdir of program files
if [[ -f "$sstrt" ]]; then
  test -d "$pnapp" && readarray -t i_mnus < <(find "$pnapp" -maxdepth 1 -type f -iname 'appmanifest_*.acf' -exec grep -Pio '^\s+\"(appid|name)\"\s+\"(.*)\"' "{}" \; 2>/dev/null | perl -pe 's/.*appid.+?\"(.*)\"\v|.*name.+?\"(.*)\"/\1 \2/' | sort ; echo -e "steam\nquit")
  # read appmanifests to create menu entries
  test ${#i_mnus[@]} -gt 2 && w_menu && xmrtn="$(expr "$xmrtn" : '\([0-9]*\)')"
  if [[ -n "$xmrtn" ]]; then
  # lauch selection with steam
    xcmd+=("$sstrt" "-no-browser" "-applaunch" "$xmrtn")
    xlnch
  else
  # launch steam was selected
  # minigamelist (short game list) for no-browser (disabled chrome) to save memory
    xcmd+=("$sstrt" "-no-browser" "steam://open/minigameslist")
    xlnch
  fi
else
  echo -e "Steam not found."
fi
}

xpge () {
if [[ ! -d "$(dirname "$pnpge")" ]];then
  echo -e "Could not create folder 'compatibilitytools.d/protonge' in:\n  $(dirname "$pnpge")\n because that path does not exist.\nVerify script variable 'pnpge'"
elif [[ ! -d "$pnbin" ]];then
  echo -e "Could not create sym-link 'protonge' in:\n  $pnbin\n because that path does not exist.\nVerify script variable 'pnbin'"
else
  test -d "$pnpge" || mkdir -p "$pnpge"
  gedl="$(git ls-remote https://github.com/GloriousEggroll/proton-ge-custom | grep -Pio '[^/]+$' | grep -Pio '^ge-.*\d$' | sort -V | tail -1)"
#  gedl="$(gh release list -R GloriousEggroll/proton-ge-custom -L 1 | grep -Pio '^ge[^ ]+')"
  gever="$(echo "$gedl" | grep -Pio '(?<=ge-proton).*')"
  if [[ -f "$pnpge/protonge/version" ]]; then
    if [[ -z "$(grep -Pio "$gever" "$pnpge/protonge/version")" ]]; then
      echo -e "Available Proton GE $gever differs from installed, updating...\n"
      chse=y
    else
      echo -e "Available Proton GE $gever matches installed, nothing to do.\n"
    fi
  else
    echo -e "Proton GE not found, installing...\n"
    chse=y
  fi
fi
if [[ -n "$chse" ]]; then
  wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/"$gedl/$gedl".tar.gz -P "$temp"/
#  gh release download -D "$temp" -R GloriousEggroll/proton-ge-custom --pattern *.tar.gz
  rm -rf "$pnpge/protonge"
  tar -xf "$temp/$gedl".tar.gz -C "$pnpge/"
  mv "$pnpge"/*roton* "$pnpge/protonge"
  rm -f "$temp/$gedl".tar.gz
  grep -Piq "$gever" "$pnpge/protonge/version" || perl -pi -e "s|(?<=ge-proton).*|$gever|gi" "$pnpge/protonge/version"
  test -h "$pnbin/protonge" || ln -sf "$pnpge/protonge" "$pnbin"
fi
}

usage() {
  echo -e "\n$(basename $0): ERROR - $*" 1>&2
  echo -e "\nusage: $(basename $0)\n [-?a,--?add] [-?b,--?bld] [-?c,--?cmd] [-?d,--?dsk]\n [-?i,--?inf] [-?k,--?kil] [-?o,--?ovr] [-?p,--?prg]\n [-?s,--?stm] [-?t,--?trk] [-?u,--?cut] [-?v,--?ver]\n\n[?] = (p)roton, (w)ine\n (add) exe path to reg, (bld) build prefix,\n (cmd) prog menu, (dsk) desktop, (inf) exe info,\n (kil) kill wine, (ovr) overrides, (prg) exe list,\n (stm) steam, (trk) winetricks, (cut) shortcut,\n (ver) wine version\n" 1>&2
}

if [[ $# -lt 1 ]]; then
  usage "one option required!"
else
  case $xarg in
    -xa|--xadd)
    # cross-fuction path add to registry based on exe
      xnint
      xnpre
      xpmn
      if [[ -n "$xmrtn" ]]; then
        ptadd="$(dirname "$pedir/$xmrtn")"
        ptadd="z:${ptadd////\\\\}"
        read -r -p 'prepend to system path? [y/N] ' chse
        clear
        if [[ "$chse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
          xnreg='System\\CurrentControlSet\\Control\\Session Manager\\Environment'
          xmrtn='system.reg'
        else
          xnreg='Environment'
          xmrtn='user.reg'
        fi
        if [[ -z "$(pcre2grep -Mio "\[\Q${xnreg,,}\E\](?s).+?\"PATH\"=str\(2\):\".+?(?=\[.+?\])(?-s)" "$xnpfx/$xmrtn")" ]]; then
          perl -0777 -pi -e "s|(\[\Q${xnreg,,}\E\](?s).+?#time=(?-s).*)(?s)(.+?)(?=\[.+?\])(?-s)|\\1\n\"PATH\"=str\(2\):\"${ptadd//\\/\\\\}\"\\2|gi" "$xnpfx/$xmrtn"
          echo -e "$((echo "$xnreg" | grep -Pioq '\\Environment') && echo 'HKLM\\' || echo 'HKCU\\')$xnreg:\n\n  $ptadd\n\nPATH created successfully\n"
        elif [[ -z "$(pcre2grep -Mio "\[\Q${xnreg,,}\E\](?s).+?\"PATH\"=str\(2\):\"(?-s).*\Q${ptadd,,}\E[\;\"](?s).+?(?=\[.+?\])(?-s)" "$xnpfx/$xmrtn")" ]]; then
          perl -0777 -pi -e "s|(\[\Q${xnreg,,}\E\](?s).+?\"PATH\"=str\(2\):\")(?-s)(.*)(?s)(.+?)(?=\[.+?\])(?-s)|\\1${ptadd//\\/\\\\}\;\\2\\3|gi" "$xnpfx/$xmrtn"
          echo -e "$((echo "$xnreg" | grep -Pioq '\\Environment') && echo 'HKLM\\' || echo 'HKCU\\')$xnreg:\n\n  $ptadd\n\nPATH added successfully\n"
        else
          echo -e "$((echo "$xnreg" | grep -Pioq '\\Environment') && echo 'HKLM\\' || echo 'HKCU\\')$xnreg:\n\n  $ptadd\n\nalready in PATH\n"
        fi
        # \Q \E adds \ to non alphanums but variable with \E ends \Q
        # lowercase ${var,,} to avoid since path/reg not case sensitive
        # linux path is case sensitive so user must not create duplicates
      fi
    ;;
    -xb|--xbld)
    # cross-function prefix builder
      xbld
    ;;
    -xc|--xcmd)
    # cross-function standard tools menu
      xnset
      readarray -t i_mnus < <(printf '%s\n' "${pmenu[@]}" | perl -pe 's|/.*||gi' ; echo "quit")
      w_menu
      xmrtn="$(printf '%s\n' "${pmenu[@]}" | grep -Pio "(?<=$xmrtn/).*")"
      xnldr
      if [[ -f "${clprm[0]}" ]];then
        pedir="$(realpath "${clprm[0]}")"
        cd "$(dirname "$pedir")"
        xcmd+=("$xmrtn" "$pedir" "${clprm[@]:1}")
      else
        xcmd+=("$xmrtn" "${clprm[@]}")
      fi
      xlnch
    ;;
    -xd|--xdsk)
    # cross-function wine desktop
      xnset
      xnldr
      xcmd+=("explorer.exe" "/desktop=shell,1024x768" "explorer.exe")
      xlnch
    ;;
    -ge|--gepn)
    # proton ge
      xpge
    ;;
    -xi|--xinf)
    # cross-fuction program info
      if [[ ! -f "${clprm[0]}" && ! -d "${clprm[0]}" ]]; then
      # don't menu prefix on supplied file or folder
        xnint
        xnpre
      fi
      if [[ ! -f "${clprm[0]}" ]]; then
      # offer to menu dll if no file given
        read -r -p 'query dll? [y/N] ' chse
        if [[ "$chse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
          xflt="*.dll"
        fi
      fi
      xpmn
      IFS=$'\n'
      if [[ -n "$xmrtn" ]]; then
        if [[ $(readpe "$pedir/$xmrtn" 2>/dev/null) ]]; then
        # if file is PE print 32/64-bit and dll references
          myprnt+=($(readpe -h optional "$pedir/$xmrtn" 2>/dev/null | grep -Piq 'PE32\+' && echo -e "FILE:\n$xmrtn\n \nPE HEADER:\n64-bit" || echo -e "FILE:\n$xmrtn\n \nPE HEADER:\n32-bit"))
          myprnt+=($(echo -e ' \nVersion:' ; peres -v "$pedir/$xmrtn" 2>/dev/null | grep -Pio '(?<=Product Version:).*' | tr -d ' '))
          # find dll references, filenames without spaces
          myprnt+=($(echo -e ' \nREFERENCES:' ; strings "$pedir/$xmrtn" | grep -Pio '[^<>:"/\\|?*\s]+\.dll' | perl -pe 's|([^/]*\Z)|lc($1)|e' | sort -u ; echo ' '))
        else
          myprnt+=($(echo -e ' \nNot a 32/64-bit program, no information to provide\n '))
        fi
      else
        myprnt+=($(echo -e ' \nNo file found\n '))
      fi
      printf '%s\n' "${myprnt[@]}"
      unset IFS myprnt
    ;;
    -xk|--xkil)
    # cross-function wine kill, must select same as running
      xnset
      xcmd+=("wineserver" "-k")
      xlnch
    ;;
    -xo|--xovr)
    # cross-function prefix override list
      xnint
      xnpre
      read -r -p 'per application? [y/N] ' chse
      clear
      IFS=$'\n'
      myprnt+=($(echo -e "Prefix:\n$xnpfx\n "))
      if [[ "$chse" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        # show existing per-application overrides
        myprnt+=($(echo -e 'Per-application overrides:' ; pcre2grep -Mio '\[\Qsoftware\\wine\\appdefaults\\\E[^\\]+\Q\\dlloverrides\E\](?s).+?(?=\[.+?\])(?-s)' "$xnpfx/user.reg" | grep -Pio '(?<=appdefaults..).*(?=..dlloverrides)|\".*\"' && echo ' ' || echo -e 'None found\n '))
      else
        # show existing prefix overrides
        myprnt+=($(echo -e 'Global overrides:' ; pcre2grep -Mio '\[\Qsoftware\\wine\\dlloverrides\E\](?s).+?(?=\[.+?\])(?-s)' "$xnpfx/user.reg" | grep -Pio '\".*\"' && echo ' ' || echo -e 'None found\n '))
      fi
      printf '%s\n' "${myprnt[@]}"
      unset IFS myprnt
      # A command like:
      # perl -pi -e 's/(\".*msvc.*\"=\")(.*),(.*)(")/\1\3,\2\4/g' user.reg
      # Swaps msvc entries (native,builtin) to (builtin,native)
    ;;
    -xp|--xprg)
    # cross-fuction run program - 1st arg valid file to run, folder to menu,
    # neither (sys menu), 2nd arg... passed to exe
      xnset
      xpmn
      if [[ -n "$xmrtn" ]]; then
        xlyt
        # change to exe dir before run
        cd "$(dirname "$pedir/$xmrtn")"
        xlnch
      fi
    ;;
    -xs|--xstm)
    # cross-function steam launcher
      xstm
    ;;
    -xt|--xtrk)
    # cross-function winetricks
      xnset
      # winetricks for selected wine/proton prefix
      if [[ ${#clprm[@]} -gt 0 ]]; then
        xcmd+=("winetricks" "${clprm[@]}")
        dbg="1"
        # use args if supplied, otherwise gui
      else
        xcmd+=("winetricks" "--gui")
        # protontricks may work better
      fi
      xlnch
    ;;
    -xu|--xcut)
    # cross-function desktop shortcut
      if [[ -d "$desk" ]]; then
        xnset
        xpmn
        if [[ -n "$xmrtn" ]]; then
          xlyt
          # change to desktop dir before create icon
          cd "$desk"
          read -r -e -p $'Shortcut Name?\x0a' -i "$(basename "${xmrtn/.*}")" chse
          # create desktop entry
          gendesk -f -n --name="$chse" --comment='created by wstart' --custom='Keywords=wine;proton;launcher;' --exec="bash -c 'cd \"$(dirname "$pedir/$xmrtn")\" ; $(printf '"%s" ' "${xcmd[@]}")'" --icon="$icon" --terminal=false --categories='Emulator;Game' --startupnotify=false --pkgname="$chse"
          chmod 755 "$chse".desktop
        fi
      else
        echo -e "Invalid desktop location:  $desk\nPlease edit the script"
      fi
    ;;
    -xv|--xver)
    # cross-function wine version
      xnint
      xnexe
      xnenv
      xcmd+=("wine" "--version")
      ("${xcmd[@]}" &)
    ;;
    -h|--help)
      echo -e "\n  General usage:  wstart -w? args\n  -w? options for wine and -p? for proton.\n  Type wstart by itself for command list.\n\n  Edit script path variables as needed.\n  bash, find, gendesk, grep, readpe,\n  strings, winetricks, wrestool,\n  pcre2grep, peres, perl needed by\n  certain items.\n"
    ;;
    -*|\*|*)
     # do_usage
      usage "invalid option $1"
      exit 1
    ;;
  esac
fi

