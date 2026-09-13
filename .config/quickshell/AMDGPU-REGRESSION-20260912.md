# AMDGPU Rembrandt regression — 2026-09-12 update

**STATUS: RESOLVED (mitigated). System is running fine on pinned firmware.**
**Do NOT unpin `linux-firmware-amdgpu` until a version newer than `20260910-1` exists AND is verified working (see "When is it safe to run pacman -Syu").**
Last updated: 2026-09-12 23:45 (America/Sao_Paulo)

## TL;DR — root cause and fix

- **Trigger:** `linux-firmware-amdgpu 20260910-1` (installed by `pacman -Syu` on 2026-09-12 21:17).
- It wedges the GPU/PSP on the first boot: `amdgpu ... probe with driver amdgpu failed with error -22`, black screen.
- **Warm reboots and `modprobe -r/-i` do NOT clear it.** Even after downgrading the firmware, every subsequent boot kept failing until a **full power cycle (EC reset)** was done.
- **Recovery that worked:** downgrade firmware to `20260810-2` → shutdown → unplug charger → hold power button 20–30 s → power on → boot normally. GPU came back immediately.
- **Confirmed NOT the cause:** kernel `7.2.4` (and the `6.18.51` LTS generation) and `amd-ucode 20260910-1`. The current working system runs all of these *with* the old firmware.
- **Current working stack:** `linux 7.2.4-arch1-2` + `linux-lts 6.18.51-1` + `amd-ucode 20260910-1` + `linux-firmware-amdgpu 20260810-2` (pinned). Evidence: `[drm] Initialized amdgpu 3.64.0 for 0000:03:00.0 on minor 1` at boot 2026-09-12 23:40.

## System

- Laptop: Xiaomi, AMD Ryzen 7 6800H (Rembrandt), Radeon 680M iGPU `[1002:1681]` at PCI `0000:03:00.0`
- Arch Linux, GRUB bootloader (`/etc/default/grub`), LUKS root
- Hostname: menuvivofibra.br / archlinux

## Symptom (what a regression looks like)

- Black screen on boot; only usable with `nomodeset` appended in GRUB (simpledrm fallback, no acceleration).
- Kernel log signature (fails in early device init, after CPU topology and before IP-block detection = VBIOS/PSP stage):
  ```
  amdgpu: Virtual CRAT table created for CPU
  amdgpu: Topology: Add CPU node
  amdgpu 0000:03:00.0: probe with driver amdgpu failed with error -22
  ```
- Healthy boot looks like:
  ```
  amdgpu 0000:03:00.0: Fetched VBIOS from VFCT
  amdgpu 0000:03:00.0: [drm] ATOM BIOS: 113-REMBRANDT-X35 ...
  amdgpu 0000:03:00.0: SMU is initialized successfully!
  amdgpu 0000:03:00.0: [drm] Display Core v3.2.384 initialized on DCN 3.1.2
  [drm] Initialized amdgpu 3.64.0 for 0000:03:00.0 on minor 1
  ```

## Timeline

- 2026-09-12 21:14 — `pacman -Syu`: `amd-ucode 20260810-2 → 20260910-1`, `linux 7.2.3 → 7.2.4`, `linux-lts 6.18.49 → 6.18.51`, `linux-firmware-* 20260810-2 → 20260910-1`.
- 21:24+ — black screen on every boot; `nomodeset` rescue boot at 23:14.
- 23:24 — `linux-firmware-amdgpu` downgraded to `20260810-2` + pinned in `/etc/pacman.conf`.
- 23:25 — live module reload on kernel 7.2.4 with old firmware **still failed `-22`** (live reload cannot reset the PSP — this was the red herring).
- 23:40 — **cold power cycle** (shutdown → unplug → hold power 30 s) → booted normally, GPU initialized, driver in use.
- 23:45 — root cause confirmed: bad firmware + wedged PSP requiring full power cycle. This doc updated.

## When is it safe to run `sudo pacman -Syu` again?

**Right now — it is safe.** The pin makes pacman skip only the bad firmware; everything else (kernel, ucode, mesa, systemd, apps) updates normally. Expected message during upgrade:

```
warning: linux-firmware-amdgpu: ignoring package upgrade (20260810-2 => 20260910-1)
```

That is the pin working as intended. Also normal: `pacman -Qu` lists it as `[ignored]`.

### Rules for unpinning

1. Check what the repo offers:
   ```sh
   pacman -Sy && pacman -Qu linux-firmware-amdgpu
   # linux-firmware-amdgpu 20260810-2 -> <repo-version> [ignored]
   ```
2. If `<repo-version>` is **`20260910-1` or older → do nothing.** Keep the pin.
3. Unpin only when `<repo-version>` is **newer than `20260910-1`** (e.g. `20260910-2` pkgrel fix, or a newer tag such as `20260917-1` / `202610xx-1`). A pkgrel bump has fixed this kind of breakage before (June 2025: `20250613.12fe085f-5 → -6` broke, `-7/-8/-9` fixed it), so watch for it.
4. Even with a newer version, treat the upgrade as a test (see "How to verify a fix"). Have the recovery steps ready; if it regresses, downgrade + **cold power cycle**, then re-pin.

## Periodic checks (ask opencode to run these)

Fingerprint to search for: `amdgpu "probe with driver amdgpu failed with error -22" Rembrandt 20260910`

1. **Primary** — Arch package version (want > `20260910-1`):
   <https://archlinux.org/packages/core/any/linux-firmware-amdgpu/>
   ```sh
   pacman -Sy && pacman -Qu linux-firmware-amdgpu
   ```
2. Upstream firmware repo (files for `rembrandt_*` / `yellow_carp_*` / `psp_13_0_4_*` changed after the `20260910` tag?):
   <https://gitlab.com/kernel-firmware/linux-firmware/-/commits/main/amdgpu> and issues:
   <https://gitlab.com/kernel-firmware/linux-firmware/-/issues>
3. Arch packaging bug tracker:
   <https://gitlab.archlinux.org/archlinux/packaging/packages/linux-firmware/-/issues>
4. AMD DRM (kernel) issues: <https://gitlab.freedesktop.org/drm/amd/-/issues>
5. Kernel regression reports: <https://lore.kernel.org/regressions/>, amd-gfx: <https://lore.kernel.org/amd-gfx/>
6. Arch forums: <https://bbs.archlinux.org/viewforum.php?id=44> (Pacman & Package Upgrade), <https://bbs.archlinux.org/viewforum.php?id=22> (Kernel & Hardware)
7. Kernels are *not* suspects here, but keep an eye on <https://archlinux.org/packages/core/x86_64/linux/> if any future amdgpu/PSP fix is mentioned.

## How to verify a candidate fix

1. Comment out the pin in `/etc/pacman.conf` (line 25: `IgnorePkg = linux-firmware-amdgpu`).
2. `sudo pacman -Syu` (pacman warning about downgrade/replacement is fine).
3. **Normal reboot** (no cold boot needed for a test).
4. Check:
   ```sh
   journalctl -b -k | grep -iE "Initialized amdgpu|probe with driver amdgpu|error -22"
   lspci -k -s 03:00.0 | grep "Kernel driver in use"
   ```
   Success = `Initialized amdgpu ... for 0000:03:00.0` appears and there is no `-22`.
5. Functional check: `/sys/class/drm/card0/device/uevent | grep DRIVER=amdgpu` and `glxinfo | grep "OpenGL renderer"` shows the Radeon 680M.
6. If it fails → go to "Recovery", then re-add the pin.

## Recovery (if a future firmware breaks it again)

1. Boot with `nomodeset`: GRUB menu → `e` → append `nomodeset` to the line starting with `linux` → Ctrl+X.
   (Permanent alternative: add `nomodeset` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub` + `sudo grub-mkconfig -o /boot/grub/grub.cfg`; remove it after recovery.)
2. Downgrade the firmware (offline, from the local cache):
   ```sh
   sudo pacman -U /var/cache/pacman/pkg/linux-firmware-amdgpu-20260810-2-any.pkg.tar.zst
   ```
3. **Full power cycle — this step is mandatory:** shutdown → unplug charger → hold power button 20–30 s → power on → boot normally.
4. Re-add the pin in `/etc/pacman.conf` if it was removed.

## Known-good assets (all persistent in `/var/cache/pacman/pkg/`)

| Package | Version | Purpose |
|---|---|---|
| linux-firmware-amdgpu | 20260810-2 | the working firmware (pinned) |
| linux | 7.2.3.arch1-2 | proven-good kernel (boot 20:58) if ever needed |
| linux-lts | 6.18.49-2 | pre-update LTS fallback |
| amd-ucode | 20260810-2 | pre-update microcode (not needed, 20260910-1 is fine) |

Arch Linux Archive URLs (if the cache is ever cleaned):
- <https://archive.archlinux.org/packages/l/linux-firmware-amdgpu/linux-firmware-amdgpu-20260810-2-any.pkg.tar.zst>
- <https://archive.archlinux.org/packages/l/linux/linux-7.2.3.arch1-2-x86_64.pkg.tar.zst>

Current pin: `/etc/pacman.conf` line 25 → `IgnorePkg = linux-firmware-amdgpu`

## Progress log

- 2026-09-12 21:14 — `pacman -Syu` (kernels, firmware, ucode).
- 2026-09-12 21:24+ — black screen; `-22` on every boot; `nomodeset` rescue at 23:14.
- 2026-09-12 23:24 — firmware downgraded to 20260810-2 + pinned; initramfs rebuilt.
- 2026-09-12 23:25 — live module reload still failed (`-22`) → PSP wedge suspected.
- 2026-09-12 23:40 — cold power cycle → **working**.
- 2026-09-12 23:42 — confirmed: `Kernel driver in use: amdgpu`, `Initialized amdgpu 3.64.0`, no `-22`.
- 2026-09-12 23:45 — doc updated: root cause confirmed, unpin policy defined.

## How to use with opencode

Prompt: `Read @AMDGPU-REGRESSION-20260912.md and run the periodic checks: is linux-firmware-amdgpu newer than 20260910-1 available, and is there any report that the Rembrandt -22 issue is fixed? If yes, follow the doc's verify-a-fix steps.`
