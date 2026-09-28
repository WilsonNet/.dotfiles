#!/bin/bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Screenshots}"
STEAM_ROOT="${STEAM_ROOT:-$HOME/.local/share/Steam}"
USERDATA_DIR="$STEAM_ROOT/userdata"
SINCE="${SINCE:-2025-01-01}"

usage() {
    cat <<'EOF'
Copy Steam and desktop screenshots from 2025 onwards into one folder.

Usage: copy-screenshots.sh

Run this on the Steam Deck. Sources:
  - Steam game screenshots in
    userdata/*/760/remote/<appid>/screenshots
  - Spectacle style images ("Screenshot_*") anywhere under ~/Pictures
  - every image in ~/Pictures/Screenshots and ~/Pictures/Steam Screenshots

Files are copied flat into ~/Screenshots, with the game name prefixed to the
filename (e.g. "Portal 2_20250601120000_1.jpg"). Unknown appids use their
numeric id, desktop screenshots use the "Desktop" prefix. Existing files are
skipped; nothing is deleted.

Env overrides:
  OUTPUT_DIR  destination folder (default: ~/Screenshots)
  SINCE       only copy files modified after this (default: 2025-01-01)
  STEAM_ROOT  Steam install dir (default: ~/.local/share/Steam)
EOF
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    "")
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

if [[ ! -d $USERDATA_DIR ]]; then
    echo "error: Steam userdata not found at $USERDATA_DIR" >&2
    echo "set STEAM_ROOT if Steam is installed elsewhere" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

declare -A GAME_NAMES=()

load_game_names() {
    local vdf file dir appid name
    local libs=("$STEAM_ROOT/steamapps")

    vdf="$STEAM_ROOT/steamapps/libraryfolders.vdf"
    if [[ -f $vdf ]]; then
        while IFS= read -r dir; do
            [[ -n $dir ]] && libs+=("${dir%/}/steamapps")
        done < <(sed -nE 's/^[[:space:]]*"path"[[:space:]]+"(.*)"[[:space:]]*$/\1/p' "$vdf")
    fi

    for dir in "${libs[@]}"; do
        for file in "$dir"/appmanifest_*.acf; do
            [[ -e $file ]] || continue
            appid="${file##*/appmanifest_}"
            appid="${appid%.acf}"
            name=$(sed -nE 's/^[[:space:]]*"name"[[:space:]]+"(.*)"[[:space:]]*$/\1/p' "$file" | head -n 1)
            [[ -n $name ]] && GAME_NAMES[$appid]="$name"
        done
    done

    if command -v python3 >/dev/null 2>&1; then
        for file in "$USERDATA_DIR"/*/config/shortcuts.vdf; do
            [[ -e $file ]] || continue
            while IFS=$'\t' read -r appid name; do
                [[ -n ${GAME_NAMES[$appid]:-} ]] || GAME_NAMES[$appid]="$name"
            done < <(python3 - "$file" <<'PY'
import re
import struct
import sys

data = open(sys.argv[1], "rb").read()
appids = [struct.unpack_from("<i", data, m.end())[0] for m in re.finditer(b"\x02appid\x00", data)]
names = [m.group(1).decode("utf-8", "replace") for m in re.finditer(b"\x01AppName\x00([^\x00]*)", data)]
for appid, name in zip(appids, names):
    print("%d\t%s" % (appid & 0xFFFFFFFF, name))
PY
)
        done
    fi
}

game_name_for() {
    local appid="$1" name="${GAME_NAMES[$1]:-}"
    if [[ -z $name && $appid =~ ^[0-9]+$ ]]; then
        local signed=$((appid >= 2147483648 ? appid - 4294967296 : appid))
        name="${GAME_NAMES[$signed]:-}"
    fi
    if [[ -n $name ]]; then
        printf '%s' "${name//\//-}"
    fi
}

copied=0
skipped=0

copy_file() {
    local src="$1" prefix="$2" base="${1##*/}"
    local dest="$OUTPUT_DIR/${prefix}_${base}"

    if [[ -e $dest ]]; then
        if [[ $(stat -c %s -- "$src") -eq $(stat -c %s -- "$dest") ]]; then
            skipped=$((skipped + 1))
            return
        fi
        dest="$OUTPUT_DIR/${prefix}_${base%.*}_$(stat -c %Y -- "$src").${base##*.}"
        if [[ -e $dest ]]; then
            skipped=$((skipped + 1))
            return
        fi
    fi

    cp -p -- "$src" "$dest"
    copied=$((copied + 1))
    printf 'copy  %s\n' "${dest#"$OUTPUT_DIR"/}"
}

scan_images() {
    local srcdir="$1" prefix="$2"
    shift 2
    [[ -d $srcdir ]] || return 0
    while IFS= read -r -d '' src; do
        copy_file "$src" "$prefix"
    done < <(find "$srcdir" -type f -newermt "$SINCE" -not -path "$OUTPUT_DIR/*" \
                ! -path '*/thumbnails/*' \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                   -o -iname '*.tga' -o -iname '*.webp' -o -iname '*.bmp' \) \
                "$@" -print0)
}

load_game_names

for userdir in "$USERDATA_DIR"/*; do
    [[ -d $userdir/760/remote ]] || continue
    for appdir in "$userdir"/760/remote/*; do
        [[ -d $appdir/screenshots ]] || continue
        appid="${appdir##*/}"
        game=$(game_name_for "$appid")
        scan_images "$appdir/screenshots" "${game:-$appid}"
    done
done

scan_images "$HOME/Pictures" "Desktop" -iname 'screenshot*'
scan_images "$HOME/Pictures/Screenshots" "Desktop"
scan_images "$HOME/Pictures/Steam Screenshots" "Desktop"

echo
echo "done: $copied copied, $skipped skipped"
echo "output: $OUTPUT_DIR"
