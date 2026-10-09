# motispiratia

My home server: a Lenovo ThinkCentre mini PC that runs my media stack, a few web apps, DNS and DHCP for the house, and game servers for friends. This repo records how it's set up, every change I make, and why. Eventually it will hold the server's entire configuration.

> [!NOTE]
> **Current state:** CachyOS with Docker Compose. Inventoried on 2026-10-07. Changes since then are tracked in the [backlog](docs/journal/BACKLOG.md).
> **Decided:** moving to NixOS ([decision record](docs/decisions/0001-nixos-for-motispiratia.md)).

## At a glance

| | |
|---|---|
| Machine | Lenovo ThinkCentre M90q Gen 6 (mini PC) |
| CPU | Intel Core Ultra 9 285, 24 cores, integrated Intel graphics (used by Jellyfin) |
| RAM | 32 GB DDR5-5600 (one of two slots used) |
| Storage | 1 TB NVMe for the system, configs, music and game servers. 16 TB HDD for media, in a TerraMaster D4-320 over USB |
| OS | CachyOS, installed May 2026, run headless |
| Apps | 19 Docker containers in three Compose stacks |
| Network | Wired 1 Gb/s, static LAN address. AdGuard Home is the house's DNS and DHCP server |
| Remote access | Tailscale. The server is shared with friends (Minecraft) and family (Jellyfin) |

## What runs on it

| Service | For | Address on the LAN |
|---|---|---|
| Jellyfin | Movies, shows, anime | `jellyfin.motis` |
| Jellyseerr | Requests | `requests.motis` |
| Sonarr, Sonarr (anime), Radarr | TV, anime and movie automation | `sonarr.motis`, `anime.motis`, `radarr.motis` |
| Prowlarr + FlareSolverr | Indexers | `prowlarr.motis` |
| qBittorrent | Downloads | `qbittorrent.motis` |
| Navidrome | Music | `music.motis` |
| Homarr | Dashboard | `home.motis` |
| Vikunja | Notes and tasks | `notes.motis` |
| AdGuard Home | DNS, DHCP and ad blocking for the house | port 8082 |
| Caddy | Reverse proxy behind the `.motis` names | |
| Dockhand | Docker management UI | `docker.motis` |
| Minecraft (Fabric) | Game server for friends | port 25565 |

Speedtest Tracker and Jellyswarrm also run but are being removed. Full details are in [docs/services.md](docs/services.md).

## Docs

| File | Covers |
|---|---|
| [hardware.md](docs/hardware.md) | The machine, disks, enclosure, health |
| [system.md](docs/system.md) | OS, boot, mounts, users, SSH, firewall, timers, updates, leftovers |
| [network.md](docs/network.md) | LAN, DNS, DHCP, Tailscale, Caddy routes, open ports |
| [services.md](docs/services.md) | Every container: image, role, config and data paths |
| [storage.md](docs/storage.md) | Folder layout, sizes, Samba shares, backups |
| [music.md](docs/music.md) | How songs get from Soulseek to my phone |
| [game-servers.md](docs/game-servers.md) | Minecraft, Satisfactory, old worlds |
| [decisions/](docs/decisions/) | Why things are the way they are |
| [journal/](docs/journal/) | What I did, what broke, how I fixed it. [BACKLOG.md](docs/journal/BACKLOG.md) is the to-do list |

## Repo layout

```
motispiratia-server/
├── README.md
├── tailscale/          policy rules for tailscale
├── docs/
│   ├── hardware.md, system.md, network.md, services.md,
│   │   storage.md, music.md, game-servers.md
│   ├── decisions/      one file per decision
│   └── journal/        dated entries + BACKLOG.md
├── legacy/cachyos/     sanitized copies of the current config files
└── scripts/            read-only inventory scripts
```

## Roadmap

| Phase | Goal | Status |
|---|---|---|
| 0. Inventory | Document the server as it is | Done 2026-10-07 |
| 1. Lock down and tidy | Access rules, first backup, light cleanup | In progress |
| 2. NixOS plan | Map every service to a module or container, secrets, automated backups, test the config | After toph's NixOS setup and midterms |
| 3. Migration | Reinstall as NixOS and restore data | |
| 4. Improvements | Music workflow, notes app, HTTPS | |

## Conventions

- No secrets in git. Config copies use `${VARIABLES}` instead of real values, and `.env` files are ignored.
- Commits made on toph are scanned with gitleaks before they're created. GitHub's secret scanning and push protection cover the rest.
- No public IP addresses, Tailscale addresses or tailnet name in this repo.
- Commit messages follow Conventional Commits (`docs:`, `feat:`, `fix:`).
- Journal filenames start with an ISO date, e.g. `2026-10-07-phase0-inventory.md`.
