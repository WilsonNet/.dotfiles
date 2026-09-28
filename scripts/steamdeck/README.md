# Steam Deck scripts

These scripts run **on the Steam Deck** (SteamOS), not on the machine where this
repo is checked out. They talk to the same files your SFTP session sees under
`sftp://deck@steamdeck/home/deck/`.

They are plain bash and use only tools that SteamOS already ships (ffmpeg,
python3, find, ...), so nothing has to be installed.

## Running a script

### Option 1: pipe it over SSH (nothing to copy, recommended)

```sh
ssh deck@steamdeck 'bash -s' < extract-steam-recordings.sh
```

How it works:

- `ssh deck@steamdeck` opens a shell on the Deck as user `deck`.
- `'bash -s'` is the command executed there: bash reads the script from standard
  input instead of a file.
- `< extract-steam-recordings.sh` feeds the local script file into that stdin.
- The script itself executes on the Deck, so it reads and writes local paths
  (`/home/deck/...`) at full speed, and you see its output in your local terminal.

Add `bash -n` before `bash -s` to only syntax-check it remotely:

```sh
ssh deck@steamdeck 'bash -n' < extract-steam-recordings.sh
```

### Option 2: copy the file to the Deck and run it there

```sh
scp extract-steam-recordings.sh deck@steamdeck:
ssh deck@steamdeck ./extract-steam-recordings.sh
```

Or copy it via your SFTP client and run it from Konsole in Desktop mode.

### Environment overrides

Both scripts accept settings via environment variables. With the SSH form you
pass them inside the quoted remote command:

```sh
ssh deck@steamdeck 'OUTPUT_DIR=/home/deck/Videos SINCE=2026-01-01 bash -s' < copy-screenshots.sh
```

Run any script with `--help` to see its options:

```sh
ssh deck@steamdeck 'bash -s' < extract-steam-recordings.sh --help
```

## extract-steam-recordings.sh

Steam stores recordings as fragmented MP4 (DASH): `session.mpd` plus
`init-streamN.m4s` and `chunk-streamN-*.m4s` files, which no normal player can
open. This script finds every session under
`userdata/<steamid>/gamerecordings/` (background recordings and saved clips),
concatenates the fragments per stream and muxes them with ffmpeg using stream
copy, so the video and audio are not re-encoded and lose no quality.

- Output: one `.mp4` per session in `/home/deck/Videos`
- Filename: `Hades II_20250601_093500.mp4`, `Hades II_clip_20250602_101000.mp4`
  (game name resolved locally from Steam metadata, appid used when unknown)
- Safe to re-run: finished files are skipped, and a background recording that is
  still active (files changed in the last 2 minutes) is left alone
- Fails soft: a broken session is reported as `FAILED`, everything else continues
- Env: `OUTPUT_DIR` (default `~/Videos`), `STEAM_ROOT` (default
  `~/.local/share/Steam`)

## copy-screenshots.sh

Collects screenshots into one folder:

- Steam game screenshots: `userdata/*/760/remote/<appid>/screenshots/`
- Desktop screenshots: `Screenshot_*` files under `~/Pictures`, plus everything
  in `~/Pictures/Screenshots` and `~/Pictures/Steam Screenshots`

Files modified since 2025-01-01 are copied flat into `/home/deck/Screenshots`,
with the game name prefixed to the filename so they stay tellable apart, e.g.
`Portal 2_20250601120000_1.jpg`. Unknown appids use their numeric id as the
prefix, desktop screenshots use `Desktop_` (e.g.
`Desktop_Screenshot_20250301_120000.png`). Existing files are skipped and
nothing is ever deleted, so it is safe to run repeatedly.

- Env: `OUTPUT_DIR` (default `~/Screenshots`), `SINCE` (default `2025-01-01`),
  `STEAM_ROOT`
- Example: only 2026 screenshots, into a different folder:
  `ssh deck@steamdeck 'SINCE=2026-01-01 OUTPUT_DIR=/home/deck/Screenshots2026 bash -s' < copy-screenshots.sh`

## Notes

- Steam has to have written the files already; the scripts read Steam's folders,
  they do not drive the Steam client.
- The Deck may suspend when idle, which pauses long conversions; keep it awake
  or plugged in for very large jobs.
- See `AGENTS.md` for device details and conventions if you want to add scripts.
