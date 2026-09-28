#!/bin/bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Videos}"
STEAM_ROOT="${STEAM_ROOT:-$HOME/.local/share/Steam}"
USERDATA_DIR="$STEAM_ROOT/userdata"

usage() {
    cat <<'EOF'
Convert Steam Game Recording sessions (.m4s DASH fragments) into .mp4 files.

Usage: extract-steam-recordings.sh

Run this on the Steam Deck. It finds every recording session under
~/.local/share/Steam/userdata/*/gamerecordings (background recordings and
saved clips) and muxes the fragments into <session-name>.mp4 inside ~/Videos.
Sessions that are already converted are skipped, ffmpeg does a lossless
stream copy (no re-encode).

When the game is known locally, the file is named after it, e.g.
"Hades II_20250601_093500.mp4" or "Hades II_clip_20250602_101000.mp4".
Otherwise the raw session folder name is kept.

Env overrides:
  OUTPUT_DIR  output folder (default: ~/Videos)
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

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "error: ffmpeg not found (try: sudo pacman -S ffmpeg)" >&2
    exit 1
fi

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
    printf '%s' "$name"
}

output_name() {
    local session="$1" type appid stamp game
    if [[ $session =~ ^(bg|clip)_([0-9]+)_(.+)$ ]]; then
        type="${BASH_REMATCH[1]}"
        appid="${BASH_REMATCH[2]}"
        stamp="${BASH_REMATCH[3]}"
        game=$(game_name_for "$appid")
        if [[ -n $game ]]; then
            game="${game//\//-}"
            if [[ $type == clip ]]; then
                printf '%s\n' "${game}_clip_${stamp}.mp4"
                return
            fi
            printf '%s\n' "${game}_${stamp}.mp4"
            return
        fi
    fi
    printf '%s\n' "$session.mp4"
}

load_game_names

TMP_DIR=$(mktemp -d "$OUTPUT_DIR/.extract.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

convert_session() {
    local dir="$1" out="$2" stream init rc=0
    local chunks=() inputs=() maps=() idx=0

    for init in "$dir"/init-stream*.m4s; do
        [[ -e $init ]] || continue
        stream="${init##*/init-}"
        stream="${stream%.m4s}"
        chunks=("$dir"/chunk-"$stream"-*.m4s)
        [[ -e ${chunks[0]:-} ]] || continue
        cat "$init" "${chunks[@]}" > "$TMP_DIR/$stream.mp4" || return 1
        inputs+=(-i "$TMP_DIR/$stream.mp4")
        maps+=(-map "$idx")
        idx=$((idx + 1))
    done

    [[ ${#inputs[@]} -gt 0 ]] || return 1

    ffmpeg -hide_banner -loglevel error -y -analyzeduration 100M -probesize 50M \
        "${inputs[@]}" "${maps[@]}" -c copy -movflags +faststart -f mp4 "$out.part" || rc=1
    rm -f "$TMP_DIR"/*.mp4
    if [[ $rc -ne 0 ]]; then
        rm -f "$out.part"
        return 1
    fi
    mv "$out.part" "$out"
}

converted=0
skipped=0
failed=0

while IFS= read -r -d '' mpd; do
    dir="${mpd%/*}"
    session="${dir##*/}"
    fname=$(output_name "$session")
    out="$OUTPUT_DIR/$fname"

    if [[ -s $out ]]; then
        echo "skip     $fname (already exists)"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ $session == bg_* ]] && [[ -n $(find "$dir" -type f -newermt '-2 minutes' -print -quit) ]]; then
        echo "active   $session (still recording, try again later)"
        continue
    fi

    printf 'convert  %s ... ' "$fname"
    if convert_session "$dir" "$out"; then
        echo "ok"
        converted=$((converted + 1))
    else
        echo "FAILED"
        failed=$((failed + 1))
    fi
done < <(find "$USERDATA_DIR" -type f -name session.mpd -print0 | sort -z)

echo
echo "done: $converted converted, $skipped skipped, $failed failed"
echo "output: $OUTPUT_DIR"
