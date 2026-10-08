# System (CachyOS era)

This describes the server as of 2026-10-07, before the planned NixOS migration.

## Operating system

| | |
|---|---|
| Distro | CachyOS (Arch-based, rolling release) |
| Installed | 2026-05-07, with the Calamares installer |
| Kernels | `linux-cachyos` 7.0.3 (running) and `linux-cachyos-lts` 6.18.26 as a fallback |
| Bootloader | Limine 11.4.1, UEFI |
| Init | systemd 260 |
| Login shell | fish |
| Uptime at inventory | 44 days |

## Disks and mounts

| Mount | Device | Filesystem | Size | Used | Options |
|---|---|---|---|---|---|
| `/boot` | NVMe partition 1 | vfat | 4 GiB | 191 MiB | `umask=0077` |
| `/` | NVMe partition 2 | ext4 | 934 GiB | 104 GiB | `noatime` |
| `/mnt/storage` | 16 TB HDD partition 1 | ext4 | 15 TiB | 7.4 TiB | `nofail` |
| `/tmp` | RAM | tmpfs | | | |
| swap | RAM | zram | 30.7 GiB | 14 GiB | compressed swap in RAM, the CachyOS default |

The root filesystem is ext4, so there are no btrfs snapshots.

> [!WARNING]
> `/etc/fstab` has two lines for `/mnt/storage`, both pointing at the same drive. One is plain `nofail`; the other adds `x-systemd.automount` and a 10-second device timeout. systemd only uses one of them (no automount is active), so one line should go.

## Users and access

- One human account, `sulimanza` (uid 1000). It's in `wheel` (sudo, with password), `docker`, `video`, `storage` and a few desktop groups.
- Membership in `docker` is effectively root: this user can start a container that mounts the whole filesystem.
- SSH (OpenSSH 10.3p1) listens on port 22 on all interfaces:
  - `PasswordAuthentication yes`, `PubkeyAuthentication yes`, but no authorized keys exist yet.
  - `PermitRootLogin prohibit-password`, so root can't log in with a password.
  - In the 60 days before the inventory: 5 password logins, all from toph (Windows), and no failed attempts.

## Firewall

ufw is on, with deny incoming, allow outgoing, allow routed. These ports are allowed from anywhere, over IPv4 and IPv6:

| Port | For |
|---|---|
| 22/tcp | SSH |
| 53/tcp, 53/udp | AdGuard Home DNS |
| 67/udp | DHCP (AdGuard Home) |
| 8082/tcp | AdGuard Home admin page |
| 25565 | Minecraft |

> [!IMPORTANT]
> ufw sees less traffic than its rules suggest:
> - **Docker:** published container ports are forwarded by Docker's own firewall rules, which run before ufw's. They're reachable from the LAN whatever ufw says.
> - **Tailscale:** tailscaled accepts traffic arriving on `tailscale0` before ufw gets a say. That's why Samba works over Tailscale even though ufw has no rule for it. Over Tailscale, the tailnet's access policy is the only filter.

## Power

`sleep`, `suspend`, `hibernate` and `hybrid-sleep` are masked, so the server never sleeps.

## Leftovers from the HTPC days and old experiments

- A Hyprland session that auto-logs in on tty1 (no display manager)
- Steam, gamescope, moonlight-qt, PipeWire, Bluetooth
- Decky Loader (`plugin_loader.service`, runs as `sulimanza`, listens on `127.0.0.1:1337`)
- The `jellyfin-web` package and the Jellyfin Desktop flatpak
- CubeCoders AMP: `ampfirewall.service` and `amptasks.service` are enabled and `/opt/cubecoders` exists, but the `amp` user is gone
- The native Caddy package (disabled) with its default `/etc/caddy/Caddyfile`
- Podman, installed next to Docker

All of these are on the [backlog](journal/BACKLOG.md) for removal.

## Scheduled jobs

Only systemd timers run here; cron isn't installed.

| Timer | What it does |
|---|---|
| `playlist.timer` | Every 5 minutes, runs `~/nexus/auto-playlist.sh` (see [music.md](music.md)) |
| `cachyos-rate-mirrors.timer` | Ranks package mirrors |
| `fstrim.timer` | Weekly SSD trim |
| `logrotate`, `man-db`, `plocate-updatedb`, `shadow`, `systemd-tmpfiles-clean`, `archlinux-keyring-wkd-sync` | Stock maintenance |

## System services that are running

`avahi-daemon`, `bluetooth`, `containerd`, `docker`, `NetworkManager`, `smb`, `sshd`, `systemd-resolved`, `tailscaled`, `ananicy-cpp`, `wpa_supplicant`, and `plugin_loader` (Decky Loader).

## Updates

Nothing has been updated since install. On 2026-10-07, `checkupdates` listed 708 pending updates, including:

| Package | Installed | Available |
|---|---|---|
| linux-cachyos | 7.0.3 | 7.2.9 |
| linux-cachyos-lts | 6.18.26 | 6.18.55 |
| systemd | 260.1 | 262 |
| glibc | 2.43 | 2.44 |
| openssh | 10.3p1 | 10.6p1 |
| limine | 11.4.1 | 12.9.0 |
| mesa | 26.0.6 | 26.2.4 |
| intel-media-driver | 26.1.5 | 26.3.5 |
| docker | 29.4.2 | 29.8.2 |
| tailscale | 1.96.4 | 1.102.5 |

> [!NOTE]
> Rolling-release distros expect frequent, small updates. Catching up five months at once works, but it's riskier: the bootloader, kernel, systemd and glibc all change together. Whether to update now or wait for the NixOS migration is on the backlog.
