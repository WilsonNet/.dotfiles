#!/bin/bash
# Clear emoji from window name on focus
WINDOW=$(tmux display-message -p '#W')
CLEAN=$(echo "$WINDOW" | python3 -c 'import sys,re; print(re.sub(r"^(?:[^\x00-\x7F]+\s*)+", "", sys.stdin.read().strip()))')
if [ -n "$CLEAN" ] && [ "$WINDOW" != "$CLEAN" ]; then
  tmux rename-window "$CLEAN"
fi
