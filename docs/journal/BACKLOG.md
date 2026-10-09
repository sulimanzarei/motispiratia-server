# Backlog

## Phase 1: lock down and tidy up (now, on CachyOS)

Work through these in order.

### Save the docs

- [x] 1. Create the GitHub repo (private for now) and push these docs (2026-10-08)

### Lock down access

- [x] 2. Tailscale policy: people the server is shared with can reach only Jellyfin (80), Minecraft (25565) and Satisfactory (7777, 8888) (2026-10-09)
- [x] 3. Dockhand: turn on a login (2026-10-09)
- [ ] 4. SSH: set up a key on toph, then turn off password login
- [ ] 5. ufw: allow SSH, DNS, the AdGuard admin page and Minecraft from the home network only. Keep DHCP (67/udp) working, since AdGuard now hands out addresses

### Fill the gaps

- [x] 6. Find what's handing out IP addresses (2026-10-08): it was the C80. DHCP moved to AdGuard ([0002](../decisions/0002-dhcp-on-adguard.md)) and toph got a static lease at .105
  - [ ] Give the C80 the fixed management address .2, and update its firmware (it's from 2022)
  - [x] Give the server a fallback DNS server (1.1.1.1) for when AdGuard is down (2026-10-08)
- [ ] 7. Confirm Jellyfin transcodes on the GPU

### Protect the data

- [ ] 8. First backup of configs, Minecraft and music to the 16 TB drive

### Tidy up (after the backup)

- [ ] 9. Remove Jellyswarrm and Speedtest Tracker: containers, Caddy routes, Homarr widgets, config folders. Also drop the dead Caddy routes, the unused 443 mapping and `Caddyfile.save`
- [ ] 10. Delete the duplicate `/mnt/storage` line in `/etc/fstab`
- [ ] 11. Delete old folders: Palworld (folder and image), `/mnt/storage/recordings`, `~/nexus/media`, and the old Minecraft worlds I don't want
- [ ] 12. toph's Windows install: rename it from `sulimanza` to `toph-windows`, and switch it to automatic addressing. The static lease gives it .105 too, since it uses the same network card

### Close the phase

- [ ] 13. Write the Phase 1 journal entry, then make the repo public with secret scanning and push protection on

### Optional, any time

- [ ] VS Code with Remote-SSH on toph, to edit server files in a real editor
- [ ] Minecraft memory: 10 GB → about 6 GB
- [ ] nixos-setup: scan its history with gitleaks, rename it (e.g. `toph-nixos`) and make it public

### Skipped on CachyOS, because the NixOS reinstall replaces them

- The 708 pending system updates. With SSH and DNS limited to the home network and tailnet, waiting a few weeks is low risk. Revisit if the migration slips.
- Uninstalling the HTPC leftovers (Hyprland autologin, Steam, gamescope, Decky Loader, moonlight-qt, jellyfin-web, the Jellyfin flatpak), AMP, the native Caddy package and Podman
- Pruning old Docker images, volumes and networks
- Moving Compose secrets into `.env` files. NixOS will use a secrets tool instead.
- The router's inbound IPv6 setting. Task 5 closes the server either way.

## Phase 2: NixOS plan (after toph's setup and midterms)

- [ ] Map each service to a NixOS module or a container
- [ ] Pick a secrets tool (sops-nix or agenix)
- [ ] Automated backups with retention, a second copy off the server, and a tested restore
- [ ] Build and test the config before touching the server
- [ ] Plan migration day: DNS fallback for the house, data copy, rollback

## Phase 3: migration

## Later and ideas

- [ ] Music: Soulseek on the server (slskd, SoulSync), quicker pickup in Navidrome, fewer steps in Amperfy
- [ ] Notes: maybe Obsidian instead of Vikunja
- [ ] Second RAM module for dual channel
- [ ] HTTPS for the web apps
