# 2026-10-07: Phase 0, Inventory

**Goal:** Document the server exactly as it is before changing anything, and move server help from Gemini to Claude.

## What I did

1. Asked Gemini for a handoff document with everything it knew about the server.
2. Corrected it. Gemini thought the server still ran Proxmox with CachyOS in a VM. In fact it's the old HTPC, running CachyOS on bare metal since May.
3. Ran two read-only inventory scripts ([scripts/](../../scripts/)). They collect hardware, disks, network, Docker, Caddy and AdGuard settings, with secrets masked.
4. Filled the remaining gaps by hand: router, Tailscale sharing, backup priorities, plans.
5. Wrote this repo's docs from the results.

## What broke or surprised me

- Gemini's picture was wrong in several places. There's no Proxmox and no Pi-hole (AdGuard Home only), the dashboard is Homarr rather than Homepage, and there's no TLS or domain.
- ufw doesn't filter Docker's published ports or Tailscale traffic, so the firewall looked stricter than it is.
- Tailscale machine sharing doesn't limit ports. Under the default allow-all policy, everyone I share the server with can reach SSH and Dockhand, and Dockhand has no login.
- Three Caddy routes over Tailscale (Sonarr, Radarr, Dockhand) never worked, because those ports aren't published.
- `/etc/fstab` mounts the 16 TB drive twice.
- The router's DHCP is off and AdGuard's DHCP is off, yet devices get addresses. Still to explain.
- 708 pending updates. Nothing has been updated since install.
- Leftovers from the HTPC days and old tests are still running: Hyprland autologin, Decky Loader, Steam, AMP units.
- Nothing is backed up.

## Decisions

- Keep Homarr; the look matters.
- Remove Jellyswarrm, Speedtest Tracker, Palworld, the recordings folder, and the HTPC and AMP leftovers.
- The repo is public, so it contains no addresses beyond the LAN, no tailnet name and no secrets.
- Move to NixOS ([0001](../decisions/0001-nixos-for-motispiratia.md)), accepted 2026-10-08.

## Next

Phase 1: lock down access (Tailscale policy, SSH keys, Dockhand login, ufw), clean up leftovers, and take a first backup.
