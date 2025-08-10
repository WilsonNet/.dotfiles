#!/usr/bin/env bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
set -euo pipefail

AUDIO_FIELD="Audio"
SCREENSHOT_FIELD="Picture"
SENTENCE_FIELD="Context Sentence"
# leave OUTPUT_MONITOR blank to autoselect a monitor.
OUTPUT_MONITOR=""
AUDIO_BITRATE="64k"
AUDIO_FORMAT="opus"
AUDIO_VOLUME="1"
MINIMUM_DURATION="0"
IMAGE_FORMAT="webp"
# -2 to calculate dimension while preserving aspect ratio.
IMAGE_WIDTH="-2"
IMAGE_HEIGHT="400"

get_config_dir() {
    # get the configuration directory
    # adapted from https://xdgbasedirectoryspecification.com/
    local config_dir="${XDG_CONFIG_HOME-}"
    if [ -z "$config_dir" ] || [ "${config_dir::1}" != '/' ]; then
        echo -n "$HOME/.config/ames"
    else
        echo -n "$config_dir/ames"
    fi
}

# the config is sourced at the bottom of this file to overwrite functions.
CONFIG_FILE_PATH="$(get_config_dir)/config"

usage() {
    # display help
    echo "-h: display this help message"
    echo "-r: record audio toggle"
    echo "-s: interactive screenshot"
    echo "-a: screenshot same region again (defaults to -s if no region)"
    echo "-w: screenshot currently active window (xdotool)"
    echo "-c: export copied text (contents of the CLIPBOARD selection)"
}

notify_message() {
    # send a notification with a message to the user.
    # $1 is the string containing the message text.
    #
    # notifies both the console and with libnotify.
    echo "$1"
    notify-send --hint=int:transient:1 -t 500 -u normal "$1"
}

check_response() {
    # check the JSON response of a request to Anki.
    # $1 is the response from ankiconnect_request().
    local -r get_error='s/.*"error"[[:space:]]*:[[:space:]]*\([^,}]*\).*/\1/p'
    local -r strip_whitespace='s/[[:space:]]*$//'
    # if the error string itself contains "," or "}" this will end early
    local -r error="$(echo "$1" \
        | sed --posix -n "$get_error" \
        | sed --posix "$strip_whitespace")"
    if [[ "$error" != null ]]; then
        notify_message "${error:1:-1}"
        exit 1
    fi
}

notify_screenshot_add() {
    # notify the user that a screenshot was added.
    if [[ "$LANG" == en* ]]; then
        notify_message "Screenshot added"
    fi
    if [[ "$LANG" == ja* ]]; then
        notify_message "スクリーンショット付けました"
    fi
}

notify_record_start() {
    # notify the user that a recording started.
    if [[ "$LANG" == en* ]]; then
        notify_message "Recording started..."
    fi
    if [[ "$LANG" == ja* ]]; then
        notify_message "録音しています..."
    fi
}

notify_record_stop() {
    # notify the user that a recording stopped.
    if [[ "$LANG" == en* ]]; then
        notify_message "Recording added"
    fi
    if [[ "$LANG" == ja* ]]; then
        notify_message "録音付けました"
    fi
}

notify_sentence_add() {
    # notify the user that a sentence was added.
    if [[ "$LANG" == en* ]]; then
        notify_message "Sentence added"
    fi
    if [[ "$LANG" == ja* ]]; then
        notify_message "例文付けました"
    fi
}

maxn() {
    # compute the max element of a list.
    tr -d ' ' | tr ',' '\n' | awk '
    BEGIN {
        max = 0
    }
    {
        if ($0 > max) {
            max = $0
        }
    }
    END {
        print max
    }
    '
}

escape() {
    # serialize an arbitrary string for use in JSON.
    # $1 is the string to serialize.
    local escaped="${1//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    local -r newline="
"
    escaped="${escaped//$newline/\\n}"
    echo -n "$escaped"
}

get_last_id() {
    # get the id of the last card added to Anki.
    # result is stored in the global variable newest_card_id.
    local -r new_card_request='{
        "action": "findNotes",
        "version": 6,
        "params": {
        "query": "added:1"
        }
    }'
    local new_card_response list

    new_card_response="$(ankiconnect_request "$new_card_request")"
    check_response "$new_card_response"
    list="$(echo "$new_card_response" | cut -d "[" -f2 | cut -d "]" -f1)"
    newest_card_id="$(echo "$list" | maxn)"
}

store_file() {
    # store a media file.
    local -r dir="${1:?}"
    local -r name="$(basename -- "$dir")"
    local request='{
        "action": "storeMediaFile",
        "version": 6,
        "params": {
            "filename": "<name>",
            "path": "<dir>"
        }
    }'
    request="${request//<name>/$name}"
    request="${request/<dir>/$dir}"

    check_response "$(ankiconnect_request "$request")"
}

gui_browse() {
    # open the gui card browser and point the modified card.
    local -r query="${1:-nid:1}"
    local request='{
        "action": "guiBrowse",
        "version": 6,
        "params": {
            "query": "<QUERY>"
        }
    }'
    request="${request/<QUERY>/$query}"

    check_response "$(ankiconnect_request "$request")"
}

ankiconnect_request() {
    # send data to Anki through a HTTP request to AnkiConnect.
    # $1 is the data to send.
    curl --silent localhost:8765 -X POST -d "${1:?}" || \
        echo '{"error": "Empty response from AnkiConnect. Is Anki running?"}'
}

safe_request() {
    # only send requests after opening the gui browser.
    gui_browse "nid:1"
    check_response "$(ankiconnect_request "${1:?}")"
    gui_browse "nid:${newest_card_id:?Newest card is not known.}"
}

update_sentence() {
    # update card with sentence.
    # $1 is the sentence.
    get_last_id
    local update_request='{
        "action": "updateNoteFields",
        "version": 6,
        "params": {
            "note": {
                "id": <id>,
                "fields": { "<SENTENCE_FIELD>": "<sentence>" }
            }
        }
    }'

    update_request="${update_request/<id>/$newest_card_id}"
    update_request="${update_request/<SENTENCE_FIELD>/$SENTENCE_FIELD}"
    local -r sentence="$(escape "$1")"
    update_request="${update_request/<sentence>/$sentence}"

    safe_request "$update_request"
}

update_img() {
    # update card with image.
    # $1 is the path to the image.
    get_last_id
    local update_request='{
        "action": "updateNoteFields",
        "version": 6,
        "params": {
            "note": {
                "id": <id>,
                "fields": { "<SCREENSHOT_FIELD>": "<img src=\"<path>\">" }
            }
        }
    }'
    update_request="${update_request/<id>/$newest_card_id}"
    update_request="${update_request/<SCREENSHOT_FIELD>/$SCREENSHOT_FIELD}"
    update_request="${update_request/<path>/$1}"

    safe_request "$update_request"
}

update_sound() {
    # update card with sound, given by an audio file.
    # $1 is the path to the audio file.
    get_last_id
    local update_request='{
        "action": "updateNoteFields",
        "version": 6,
        "params": {
            "note": {
                "id": <id>,
                "fields": {
                    "<AUDIO_FIELD>":"[sound:<path>]"
                 }
            }
        }
    }'
    update_request="${update_request/<id>/$newest_card_id}"
    update_request="${update_request/<AUDIO_FIELD>/$AUDIO_FIELD}"
    update_request="${update_request/<path>/$1}"

    safe_request "$update_request"
}

encode_img() {
    # use ffmpeg to encode an image to some desired format.
    local -r source_path="$1"
    local -r dest_path="$2"
    ffmpeg -nostdin \
        -hide_banner \
        -loglevel error \
        -i "$source_path" \
        -vf scale="$IMAGE_WIDTH:$IMAGE_HEIGHT" \
        "$dest_path"
}

get_selection() {
    # get a region of the screen for future screenshotting.
    slop
}

take_screenshot_region() {
    # function to take a screenshot of a given screen region.
    # $1 is the geometry of the region from get_selection().
    # $2 is the output file name.
    local -r geom="$1"
    local -r path="$2"
    maim --hidecursor "$path" -g "$geom"
}

take_screenshot_window() {
    # function to take a screenshot of the current window.
    # $1 is the output file name.
    local -r path="$1"
    maim --hidecursor "$path" -i "$(xdotool getactivewindow)"
}

screenshot() {
    # take a screenshot by prompting the user for a selection
    # and then add this image to the last Anki card.
    local -r geom="$(get_selection)"
    local -r path="$(mktemp /tmp/maim-screenshot.XXXXXX.png)"
    local -r base_path="$(basename -- "$path" | cut -d "." -f-2)"
    local -r converted_path="/tmp/$base_path.$IMAGE_FORMAT"

    take_screenshot_region "$geom" "$path"
    encode_img "$path" "$converted_path"

    rm "$path"
    echo "$geom" >/tmp/previous-maim-screenshot
    store_file "$converted_path"
    update_img "$(basename -- "$converted_path")"
    notify_screenshot_add
}

again() {
    # if screenshot() has been called, then repeat take another screenshot
    # with the same dimensions as last time and add to the last Anki card.
    # otherwise, call screenshot().
    local -r path="$(mktemp /tmp/maim-screenshot.XXXXXX.png)"
    local -r base_path="$(basename -- "$path" | cut -d "." -f-2)"
    local -r converted_path="/tmp/$base_path.$IMAGE_FORMAT"

    if [[ -f /tmp/previous-maim-screenshot ]]; then
        take_screenshot_region "$(cat /tmp/previous-maim-screenshot)" "$path"
        encode_img "$path" "$converted_path"
        rm "$path"
        store_file "$converted_path"
        get_last_id
        update_img "$(basename -- "$converted_path")"
        notify_screenshot_add
    else
        screenshot
    fi
}

screenshot_window() {
    # take a screenshot of the active window and add to the last Anki card.
    local -r path="$(mktemp /tmp/maim-screenshot.XXXXXX.png)"
    local -r base_path="$(basename -- "$path" | cut -d "." -f-2)"
    local -r converted_path="/tmp/$base_path.$IMAGE_FORMAT"
    take_screenshot_window "$path"
    encode_img "$path" "$converted_path"
    rm "$path"
    store_file "$converted_path"
    update_img "$(basename -- "$converted_path")"
    notify_screenshot_add
}

current_time() {
    # current time as an integer number of milliseconds since the epoch.
    echo "$(date '+%s')$(date '+%N' | awk '{ print substr($1, 0, 3) }')"
}

record_function() {
    local -r audio_file="$1"
    notify_message $audio_file
    # We need the & at the end otherwise it hangs in the pw-record
    pw-record -P '{ stream.capture.sink=true }' "$audio_file" &
}

record_start() {
    # begin recording audio.
    local -r audio_file="$(mktemp \
                               "/tmp/ffmpeg-recording.XXXXXX.$AUDIO_FORMAT")"
    echo "$audio_file" >"$recording_toggle"

    record_function "$audio_file"
    echo "$!" >> "$recording_toggle"

    current_time >> "$recording_toggle"

    notify_record_start
}

record_end() {
    local -r audio_file="$(sed -n "1p" "$recording_toggle")"
    local -r pid="$(sed -n "2p" "$recording_toggle")"
    local -r start_time="$(sed -n "3p" "$recording_toggle")"
    local -r duration="$(($(current_time) - start_time))"

    echo "The pid is: ${pid}"
    if [ "$duration" -le "$MINIMUM_DURATION" ]; then
        sleep "$((MINIMUM_DURATION - duration))e-3"
    fi

    rm "$recording_toggle"
    kill -15 "$pid"

    wait "$pid" || true

    while [ "$(du "$audio_file" | awk '{ print $1 }')" -eq 0 ]; do
        true
    done

    store_file "${audio_file}"
    update_sound "$(basename -- "$audio_file")"

    notify_record_stop
}

record() {
    # this section is a heavily modified version of the linux audio
    # script written by salamander on qm's animecards.
    recording_toggle="/tmp/ffmpeg-recording-audio"

    if [[ ! -f /tmp/ffmpeg-recording-audio ]]; then
        record_start
    else
        record_end
    fi
}

copied_text() {
    # get the contents of the clipboard.
    if command -v xclip &> /dev/null
    then
        xclip -o -selection clipboard
    elif command -v xsel &> /dev/null
    then
        xsel -b
    else
        echo "Couldn't find xclip or xsel." >&2
        exit 1
    fi
}

clipboard() {
    # get the current clipboard, and add this text to the last Anki card.
    local -r sentence="$(copied_text)"
    update_sentence "${sentence}"

    notify_sentence_add
}

if [[ -f "$CONFIG_FILE_PATH" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE_PATH"
fi

if [[ -z "${1-}" ]]; then
    usage
    exit 1
fi

while getopts 'hrsawc' flag; do
    case "${flag}" in
        h) usage ;;
        r) record ;;
        s) screenshot ;;
        a) again ;;
        w) screenshot_window ;;
        c) clipboard ;;
        *) ;;
    esac
done
