# CachyOS-era config snapshot

Copies of the server's hand-written config files as they were on 2026-10-07, before any Phase 1 changes. They're here for reference during the NixOS migration. Nothing reads them from this folder.

| File here | Live path on the server |
|---|---|
| `nexus/docker-compose.yml` | `~/nexus/docker-compose.yml` |
| `nexus/.env.example` | (not on the server yet) names of the secrets used above |
| `nexus/config/caddy/Caddyfile` | `~/nexus/config/caddy/Caddyfile` |
| `nexus/auto-playlist.sh` | `~/nexus/auto-playlist.sh` |
| `servers/docker-compose.yml` | `~/servers/docker-compose.yml` |
| `servers/satisfactory.compose.yml` | Not on the server. Copied from sticky notes on toph |
| `docker/docker-compose.yml` | `~/docker/docker-compose.yml` |
| `systemd/playlist.service`, `systemd/playlist.timer` | `/etc/systemd/system/` |
| `samba/smb.conf` | `/etc/samba/smb.conf` (comments removed) |

## What changed from the live files

- **Secrets:** the live `nexus/docker-compose.yml` has passwords, keys and tokens written inline. Here they're `${VARIABLES}`, listed in `.env.example`.
- **Tailnet name:** the Caddyfile uses `TAILNET` in place of the real tailnet name.
- **Header comments:** each file starts with a comment saying where it came from.

Everything else is unchanged, including mistakes, so this stays an honest record.
