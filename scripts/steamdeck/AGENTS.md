# Steam Deck scripts

This folder holds scripts that run on the Steam Deck, not on the machine where this
repo is checked out. Develop and test them here, then deploy over SSH/SFTP.

## Target device

- SteamOS 3.8.x ("holo"), Arch-based, host `steamdeck`, user `deck` (`/home/deck`).
- `deck` has passwordless sudo; default login shell is bash (zsh and fish are
  installed but not the default).
- Immutable A/B root filesystem: `/usr` is read-only and reset by every OS update,
  so `pacman` installs do not survive. Persistent: `/home`, `/var`, `/etc` (overlay).
  Prefer preinstalled tools; for extra software use flatpak, AppImage, distrobox,
  or `~/.local` user installs.
- Desktop mode is KDE Plasma 6 (Wayland since 3.8); Game mode runs the gamescope
  session. Scripts can assume no display unless told otherwise.
- microSD cards mount under `/run/media/`, named after the device
  (`/run/media/mmcblk0p1` on NVMe Decks, `mmcblk1p1` on eMMC models).
- Long-running jobs should block suspend (e.g. `systemd-inhibit --what=sleep:idle`)
  or run via `systemd --user`, since the Deck sleeps when idle.

## Preinstalled tools (verified against the SteamOS 3.8.10 package list)

bash, python3 (package `python`, many `python-*` modules), ffmpeg/ffprobe, jq,
curl, rsync, git, openssh, flatpak, distrobox, podman, systemd, coreutils,
findutils, sed, gawk, bc, fd, ripgrep, bat, libnotify (`notify-send`),
zenity-gtk3, kdialog, konsole, dolphin, spectacle, xdotool, pipewire, upower,
networkmanager, usbutils, nvme-cli, smartmontools, mangohud, zsh, fish.

Not available: yt-dlp, mpv, vlc, wl-clipboard, power-profiles-daemon, yay/AUR.

## Conventions for scripts here

- One self-contained `#!/bin/bash` script per task, `set -euo pipefail`, executable.
- No installs; check `command -v` for optional tools and fail with a clear message.
- Expose paths as env overrides (`OUTPUT_DIR`, `STEAM_ROOT`, ...) so behavior can be
  tested locally with fixtures.
- Be idempotent: skip finished work, write to a `.part`/temp file and rename on success.
- Keep media processing lossless (`ffmpeg -c copy`) unless re-encoding is requested.
- Test locally with synthetic fixtures. `ffmpeg -f dash` produces exactly the
  `init-stream0.m4s` + `chunk-stream0-*.m4s` layout Steam uses; verify results with
  `ffprobe`, and run `bash -n` (shellcheck is not guaranteed to be installed).
- Deploy/run remotely: `ssh deck@steamdeck 'bash -s' < script.sh`, or scp/rsync the
  file over and execute it there.

## Steam paths and Game Recording

- Steam install: `~/.local/share/Steam` (with `~/.steam/steam` symlink); per-account
  data in `userdata/<steamid>/`. User-facing video folder is `~/Videos` (capital V).
- Raw recordings: `userdata/<id>/gamerecordings/{video,clips}/<bg_|clip_><appid>_<YYYYMMDD>_<HHMMSS>/`
  each containing `session.mpd`, `init-streamN.m4s` and `chunk-streamN-*.m4s`
  (stream0 = video, stream1 = audio). These are fragmented MP4 (DASH), not playable
  mp4: concatenate init + chunks per stream and mux with ffmpeg (`-c copy`).
- A `bg_*` session whose files changed in the last ~2 minutes is still recording,
  do not convert it.
- Resolve game names from local metadata: `steamapps/appmanifest_<appid>.acf`
  (`"name"` field) in every library folder listed in `steamapps/libraryfolders.vdf`
  (covers the SD card); non-Steam shortcuts live in binary VDF
  `userdata/<id>/config/shortcuts.vdf` (needs python3 to parse; no text version).
- Screenshots: `userdata/<id>/760/remote/<appid>/screenshots/` (Steam game
  screenshots, thumbnails in a `thumbnails/` subfolder); desktop-mode Spectacle
  saves under `~/Pictures` as `Screenshot_*.png`.
- Example implementations: `extract-steam-recordings.sh`, `copy-screenshots.sh`.
