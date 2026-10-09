# Network

## LAN

| | |
|---|---|
| Router | Huawei HG8245W5 from the ISP (fiber modem and router in one), at 192.168.100.1 |
| Subnet | 192.168.100.0/24 |
| Server | 192.168.100.100, static (set in NetworkManager), wired 1 Gb/s. It also runs DHCP and DNS for the house |
| Access point | TP-Link Archer C80, meant to run as an access point only |
| toph | 192.168.100.105. NixOS gets it from a static DHCP lease. Windows has it set by hand, with DNS: the server first, then 1.1.1.1 |
| IPv6 | The ISP provides a public /64, and the server has a public IPv6 address |
| Port forwarding | None. Removed when Tailscale was set up |

## DHCP

AdGuard Home on the server hands out addresses for the whole house ([decision 0002](decisions/0002-dhcp-on-adguard.md)). The Huawei's DHCP server is off, and the C80's should be too.

| Setting | Value |
|---|---|
| Interface | `enp128s31f6` |
| Gateway | 192.168.100.1 |
| DNS handed out | 192.168.100.100 (AdGuard itself) |
| Lease | 24 hours |
| Pool | 192.168.100.10 – .250 |
| Static leases | toph → .105 |

Address plan:

| Addresses | Use |
|---|---|
| .1 | Huawei router |
| .2 – .149 | Fixed addresses: C80 at .2 (planned), server at .100, toph at .105 |
| .150 – .250 | DHCP pool for everything else, including guests |

> [!NOTE]
> **What happened (2026-10-08).** Devices kept getting addresses even though the Huawei's DHCP and AdGuard's DHCP were both off.
>
> A DHCP discover found exactly one DHCP server: the C80, which was supposed to be just an access point. It was handing out addresses on its own 192.168.0.x network. So any device that asked for an address landed there instead of on the main network, and toph got a 192.168.0.x address after switching to automatic addressing.
>
> AdGuard's DHCP had most likely been off since the move from Proxmox to CachyOS, with the C80 covering for it unnoticed.
>
> Fix:
> - Turned the C80's DHCP off.
> - Turned AdGuard's DHCP on.
> - Added a static lease for toph.
>
> A second discover from toph then showed one DHCP server, the server at .100, handing out itself as DNS.

## DNS: AdGuard Home

- Runs in Docker with host networking, so it listens directly on port 53 (TCP and UDP) and serves its admin page on port 8082.
- Upstream: Quad9 over DNS-over-HTTPS (`dns10.quad9.net`), bootstrapped through 9.9.9.10 and 149.112.112.10.
- Blocklist: the AdGuard DNS filter. An AdAway list is configured but disabled.
- DNS rewrite: `*.motis` → 192.168.100.100. This is what makes the `.motis` names reach Caddy.
- The query log is kept for 90 days and statistics for 24 hours.
- It's also the DHCP server for the house (see above).
- Load: about 178,000 queries a day, about 1.8% blocked (Homarr widget, 2026-10-07).
- The server itself resolves through AdGuard at 127.0.0.1. systemd-resolved's stub listener is turned off so AdGuard can own port 53.

> [!WARNING]
> The house depends on the server for addresses and names. When the server is down:
> - devices keep their address until their 24-hour lease runs out, but new devices can't join;
> - any device whose only DNS server is the server can't resolve names, which looks like "the internet is down".
>
> toph's Windows install has 1.1.1.1 as a second DNS server. Other devices have no fallback, and the server itself only uses its own AdGuard.
>
> A second, public DNS server has side effects. Windows switches to it whenever the first one is slow to answer, and while it's using 1.1.1.1, the `.motis` names don't resolve and ads aren't blocked.

## Tailscale

| | |
|---|---|
| Version | 1.96.4, running on the host (not in a container) |
| MagicDNS | On |
| Split DNS | `motis` → the server's Tailscale address, so the `.motis` names also work over Tailscale |
| Subnet routes, exit node | None |
| Tailscale SSH | Off |
| Serve, Funnel | Not used |
| My devices | the server, toph (Windows), MacBook Pro, iPhone, Apple TV |
| Shared in | One device from a friend's tailnet, offline for months |
| Shared out | The server, through machine sharing, with friends (Minecraft) and three family members (Jellyfin) |
| Access policy | Shared members can only access ports for game servers and Jellyfin |

> [!IMPORTANT]
> Machine sharing decides *which device* people can reach. The access policy decides *which ports*. Under allow-all, everyone the server is shared with can reach every port on it, including SSH and Dockhand. The fix, a rule that limits `autogroup:shared` to Jellyfin and Minecraft, is on the [backlog](journal/BACKLOG.md).

## Reverse proxy: Caddy

- HTTP only (`auto_https off`). No domain and no certificates.
- The container publishes ports 80, 443, 2000, 5055 and 7878. Nothing uses 443.
- Requests are routed by hostname. On the LAN and over split DNS that's the `.motis` names; over the tailnet name, Caddy also routes by port.

| Address | Goes to | Works? |
|---|---|---|
| `jellyfin.motis`, tailnet name on port 80 | Jellyfin (8096) | Yes |
| `jellyswarrm.motis` | Jellyswarrm (3000) | Yes, being removed |
| `sonarr.motis` | Sonarr (8989) | Yes |
| tailnet name on port 8989 | Sonarr | **No**, port not published |
| `anime.motis` | Sonarr anime (8989) | Yes |
| `radarr.motis` | Radarr (7878) | Yes |
| tailnet name on port 7879 | Radarr | **No**, port not published |
| `qbittorrent.motis`, tailnet name on port 2000 | qBittorrent (8081) | Yes |
| `prowlarr.motis` | Prowlarr (9696) | Yes |
| `requests.motis`, tailnet name on port 5055 | Jellyseerr (5055) | Yes |
| `music.motis`, tailnet name on port 7878 | Navidrome (4533) | Yes. Note that 7878 is normally Radarr's port |
| `home.motis` | Homarr (7575) | Yes |
| `docker.motis` | Dockhand (3000) | Yes |
| tailnet name on port 3333 | Dockhand | **No**, port not published |
| `notes.motis` | Vikunja (3456) | Yes |
| `speedtest.motis` | Speedtest Tracker (80) | Yes, being removed |

## What's listening

Reachability:

- **LAN:** every Docker-published port. Native services only where ufw allows them.
- **Tailnet:** every port.
- **Internet over IPv4:** nothing. The router uses NAT and has no port forwards.
- **Internet over IPv6:** depends on whether the router filters inbound IPv6. Not confirmed yet.

| Port | Service | Notes |
|---|---|---|
| 22/tcp | SSH | Password login enabled |
| 53/tcp, 53/udp | AdGuard Home DNS | |
| 80/tcp | Caddy | All `.motis` names, plus Jellyfin on the tailnet name |
| 139, 445/tcp | Samba | Blocked on the LAN by ufw, works over Tailscale |
| 443/tcp | Caddy | Unused |
| 2000/tcp | Caddy → qBittorrent | Tailnet shortcut |
| 5055/tcp | Caddy → Jellyseerr | Tailnet shortcut |
| 7575/tcp | Homarr | Direct access |
| 7878/tcp | Caddy → Navidrome | Tailnet shortcut |
| 8082/tcp | AdGuard Home admin | |
| 9000/tcp | Dockhand | No login, and it controls Docker |
| 9595/tcp | homarr-iframes | |
| 25565/tcp | Minecraft | |
| 41641/udp | Tailscale | |
| 5353/udp, 5355 | mDNS (Avahi), LLMNR (systemd-resolved) | |
| 127.0.0.1:1337 | Decky Loader | Local only |
