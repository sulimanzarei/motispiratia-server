# Storage and backups

## Where things live

| Path | Disk | Size | What |
|---|---|---|---|
| `~/nexus/config` | NVMe | 8.4 GB | All app configs and databases, mostly Jellyfin metadata and images |
| `~/nexus/songs` | NVMe | 21 GB, 670 files | Music library, mostly FLAC |
| `~/servers/games` | NVMe | 20 GB | Game server data: Minecraft worlds and Satisfactory |
| `~/docker/data` | NVMe | 9 MB | Dockhand's settings |
| `/var/lib/docker` | NVMe | about 19 GB | Docker images, containers and unnamed volumes |
| `/mnt/storage/media` | HDD | 7.4 TB | Movies, shows, anime and downloads |
| `/mnt/storage/recordings` | HDD | empty | Being removed |
| `~/nexus/media` | NVMe | 1.2 MB | Leftover from before the HDD. Being removed |

## Media layout

```
/mnt/storage/media
├── anime/       700 GB
├── downloads/   6.7 TB   qBittorrent's download folder
├── movies/      5.4 GB *
└── tv/           36 GB *
```

\* `du` counts a hardlinked file only once, in the first folder where it finds it. Radarr and Sonarr import finished downloads as hardlinks while the torrents keep seeding, so most movies and shows are counted under `downloads/` instead. The drive holds 7.4 TB in total, out of 15 TB.

## Samba shares

| Share | Path | Access |
|---|---|---|
| `Songs` | `~/nexus/songs` | `sulimanza`, read and write |
| `Media` | `/mnt/storage` | `sulimanza`, read and write |

I use them from toph (Windows) over Tailscale. ufw blocks Samba on the LAN.

## Backups

> [!CAUTION]
> Nothing is backed up. Each disk is a single point of failure.

What would hurt most to lose, in order:

| # | What | Where | Size | Notes |
|---|---|---|---|---|
| 1 | App configs, including Vikunja's database | `~/nexus/config`, `~/docker/data`, the Compose files | about 8.4 GB | Also the recipe for rebuilding the media library, since Sonarr and Radarr know every title |
| 2 | Minecraft | `~/servers/games/minecraft-duke` | 5.1 GB world (20 GB for all game data) | |
| 3 | Music | `~/nexus/songs` | 21 GB | |
| 4 | Vikunja tasks | inside #1 | small | |
| 5 | Media | `/mnt/storage/media` | 7.4 TB | Can be re-downloaded as long as #1 survives |

Everything except the media comes to about 50 GB.

Possible backup targets:
- The 16 TB HDD. A quick first copy that protects against the NVMe dying or a bad command, but not against losing the whole server.
- The 3 TB HDD from toph, once it's freed up.
- A spare bay in the D4-320.
- Cloud storage. At about 50 GB, this should be cheap.

A first manual backup is backlog task 8. Automated backups are part of Phase 2, built into the NixOS config. The usual rule of thumb is 3-2-1: three copies, on two different devices, one of them off-site.
