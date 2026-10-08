# Services

Every app runs in Docker, in three Compose stacks under my home directory, and I manage them through Dockhand.

| Stack (Compose project) | File | Containers |
|---|---|---|
| `nexus` | `~/nexus/docker-compose.yml` | 17 |
| `servers` | `~/servers/docker-compose.yml` | 1 (Minecraft) |
| `docker` | `~/docker/docker-compose.yml` | 1 (Dockhand) |

- Docker 29.4.2 and Compose 5.1.3, from the CachyOS repos. Data root `/var/lib/docker` (overlayfs), json-file logging, no `daemon.json`.
- Every container restarts `unless-stopped`, except homarr-iframes (`on-failure`). None have memory limits.
- Sanitized copies of the Compose files and Caddyfile are in [legacy/cachyos/](../legacy/cachyos/).

In the tables below, `config/` means `~/nexus/config/`.

## Media

| Container | Image | Role | Config | Data |
|---|---|---|---|---|
| jellyfin | `jellyfin/jellyfin` (10.11.8) | Media server | `config/jellyfin/server` | `/mnt/storage/media` → `/data`. Cache in an unnamed volume |
| jellyseerr | `fallenbagel/jellyseerr` | Requests | `config/jellyfin/jellyseerr` | |
| sonarr | `linuxserver/sonarr` | TV shows | `config/jellyfin/sonarr` | media → `/data` |
| sonarr-anime | `lscr.io/linuxserver/sonarr` | Anime (a second Sonarr instance) | `config/jellyfin/sonarr-anime` | media → `/data` |
| radarr | `linuxserver/radarr` | Movies | `config/jellyfin/radarr` | media → `/data` |
| prowlarr | `linuxserver/prowlarr` | Indexer manager | `config/jellyfin/prowlarr` | |
| flaresolverr | `ghcr.io/flaresolverr/flaresolverr` | Solves Cloudflare challenges for Prowlarr | unnamed volume | |
| qbittorrent | `linuxserver/qbittorrent` | Torrent client, web UI on 8081 | `config/jellyfin/downloads` | media → `/data` |
| jellyswarrm | `ghcr.io/llukas22/jellyswarrm` | Merges several Jellyfin servers. Unused, being removed | `config/jellyfin/jellyswarrm` | |

- The linuxserver images run as uid/gid 1000 (`PUID`/`PGID`) with `TZ=Asia/Riyadh`.
- Every app that moves media files sees the same `/mnt/storage/media` as `/data`. That lets Sonarr and Radarr import with hardlinks instead of copies: instant, and no extra space while a torrent keeps seeding. The folder sizes in [storage.md](storage.md) suggest hardlinks are working.
- Jellyfin uses Intel Quick Sync (QSV) on `/dev/dri/renderD128`:
  - hardware decoding for H.264, HEVC, VC-1, MPEG-2, VP8, VP9 and AV1
  - hardware encoding for H.264 only (HEVC and AV1 encoding off)
  - tone mapping on (VPP)
  - Not yet confirmed that a real transcode uses the GPU.
- qBittorrent has no VPN. Its incoming peer port (6881) isn't published, so peers can't connect in.
- qBittorrent's config lives in `config/jellyfin/downloads`. That name is confusing and should change during the migration.

## Music

| Container | Image | Role | Config | Data |
|---|---|---|---|---|
| navidrome | `deluan/navidrome` | Music server (`music.motis`), runs as uid 1000, rescans hourly | `config/navidrome` | `~/nexus/songs` → `/music`, read-only |

How songs get there: [music.md](music.md).

## Dashboard and productivity

| Container | Image | Role | Config |
|---|---|---|---|
| homarr | `ghcr.io/homarr-labs/homarr` | Dashboard (`home.motis`, port 7575) | `config/homarr`, plus the Docker socket |
| homarr-iframes | `ghcr.io/diogovalentte/homarr-iframes` | Shows Vikunja tasks inside Homarr (port 9595) | |
| vikunja | `vikunja/vikunja:2.3.0` | Notes and tasks (`notes.motis`) | `config/vikunja/files` |
| vikunja_db | `mariadb:10` | Vikunja's database | `config/vikunja/db` |
| speedtest-tracker | `lscr.io/linuxserver/speedtest-tracker` | Speed test every 6 hours. Being removed | `config/speedtest-tracker` |

The Homarr dashboard has widgets for:
- Docker containers, AdGuard status and stats, Jellyfin "now playing", Jellyseerr requests, qBittorrent downloads, Speedtest results
- shortcuts to Jellyfin, Jellyseerr, Dockhand and the *arr apps
- bookmarks, the Vikunja task list
- weather, clock, a stock ticker, an embedded YouTube stream, and a notes box

## Network and infrastructure

| Container | Image | Role | Config |
|---|---|---|---|
| caddy | `caddy:latest` | Reverse proxy (see [network.md](network.md)) | `config/caddy/Caddyfile`, `config/caddy/data` |
| adguard | `adguard/adguardhome` | DNS and DHCP for the house, with host networking | `config/adguard/conf`, `config/adguard/work` |
| docker | `fnsys/dockhand` | Dockhand, a Docker management UI (`docker.motis`, port 9000) | `~/docker/data`. Mounts the Docker socket, `~/nexus` and `~/servers` |

> [!WARNING]
> Dockhand and Homarr both mount the Docker socket, and whoever controls the socket controls the server. Dockhand has no login yet.

## Game servers

| Container | Image | Details |
|---|---|---|
| minecraft-duke | `itzg/minecraft-server` | [game-servers.md](game-servers.md) |

## Image freshness

- All images were pulled around install time and none have been updated since. Their build dates range from late 2025 to May 2026.
- Most use `latest`, so the next pull jumps several months at once. Only `vikunja/vikunja:2.3.0` and `mariadb:10` are pinned.
- Jellyseerr's `latest` image is 13 months old, older than the install itself. Worth checking whether the project now publishes under a different image.

Unused images on disk:
- `homepage`, `palworld-server-docker`, `itzg/minecraft-server:java17`
- `satisfactory-server`, kept until Satisfactory comes back

Docker could reclaim about 3.8 GB of images and 2.2 GB in 38 dangling volumes. Two networks are left over from old projects: `moonlight_default` and `serverbackup_default`.
