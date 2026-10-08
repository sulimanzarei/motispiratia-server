# Game servers

Friends connect over Tailscale, because the server is shared with them.

## Minecraft (running): `minecraft-duke`

| | |
|---|---|
| Image | `itzg/minecraft-server:latest` |
| Server type | Fabric, Minecraft 26.2 |
| Memory | 10 GB (`INIT_MEMORY` and `MEMORY` both 10G), with Aikar's JVM flags |
| Port | 25565/tcp |
| Data | `~/servers/games/minecraft-duke` (the world is 5.1 GB) |
| Players | Up to 6, usually 2 or 3 |
| Compose file | `~/servers/docker-compose.yml` |

Server mods: Fabric API, Cloth Config, YetAnotherConfigLib, Placeholder API, Lithium, Lithostitched, Item Drops, Player Animation Lib.

> [!NOTE]
> Because the start and maximum memory are equal and Aikar's flags pre-touch the heap, Java claims all 10 GB at startup. While nobody plays, Linux moves most of that into compressed swap (zram), then pulls it back when players join. That costs a little CPU and can mean a short hitch on the first join.

## Older worlds

None of these are in a Compose file. Some will be kept and some deleted; I'm sorting through them by hand.

| Folder | Last changed |
|---|---|
| `minecraft` | 2026-05-31 |
| `minecraft-map` | 2026-05-24 |
| `minecraft-sololevel` | 2026-08-29 |
| `minecraft-valhelsia` | 2026-08-29 |

## Satisfactory (kept, not running)

| | |
|---|---|
| Image | `wolveix/satisfactory-server:latest` (still on disk) |
| Players | Up to 4 (`MAXPLAYERS=4`) |
| Memory | Limit 8 GB, reservation 4 GB |
| Ports | 7777 TCP and UDP (game), 8888 TCP |
| Data | `~/servers/games/satisfactory` → `/config` |
| Compose | Not on the server. Kept in sticky notes on toph, copied to [legacy/cachyos/servers/satisfactory.compose.yml](../legacy/cachyos/servers/satisfactory.compose.yml) |

The Tailscale rule for shared users (backlog task 2) includes ports 7777 and 8888, so friends can join once it's running again.

## Palworld (being removed)

`~/servers/games/palworld` is empty (owned by root). The image `thijsvanloef/palworld-server-docker` is still on disk.
