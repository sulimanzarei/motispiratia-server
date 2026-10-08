# 0001: NixOS for motispiratia

**Status:** Accepted, 2026-10-08. The migration comes after toph's NixOS setup and midterms.

## Context

- I installed CachyOS when this box was an HTPC. The Apple TV has since taken over playback, so it's now a headless server.
- Its setup is a desktop distro with rolling updates, configured by hand across Compose files, `/etc` and web UIs. Nothing is backed up, and the setup is hard to document or rebuild.
- I already run NixOS on my desktop (toph) and keep its config in git.

## What I need

- The whole server described in files in this repo, so it can be rebuilt from scratch.
- A light, headless system.
- Backups that are easy to set up and test.
- No virtual machines needed.
- Editing in a real editor instead of nano over SSH.
- Keep: Jellyfin and the *arr apps, Navidrome, AdGuard Home, Homarr, Minecraft (Fabric with mods), Satisfactory.

## Options

### Stay on CachyOS

- **For:** works today, no migration.
- **Against:** desktop-oriented. Rolling updates, already five months behind. Changes made by hand aren't recorded anywhere.

### Proxmox VE

- **For:** snapshots and backups of whole VMs and containers. Great for running many operating systems side by side.
- **Against:** I don't need VMs. Adds a layer between the apps and the hardware. USB-attached storage is awkward to hand to VMs. Configuration lives in a web UI, not in files.

### NixOS

- **For:**
  - The whole system is declared in this repo, so every change is a commit.
  - A bad change can be rolled back from the boot menu.
  - Native modules cover most of the stack: Jellyfin, Sonarr, Radarr, Prowlarr, Jellyseerr, Navidrome, AdGuard Home, Caddy and Vikunja. They update with the system.
  - Anything without a good module (Homarr, Satisfactory, maybe Minecraft) still runs as a container, declared in the same config.
  - Backups and their schedule are part of the config too.
  - I can edit the config on toph and deploy it to the server remotely.
  - Same skills as toph.
- **Against:**
  - Learning curve, and some services have no module.
  - Secrets need a dedicated tool (sops-nix or agenix).
  - The reinstall means downtime for the house's DNS.

## Decision

NixOS, keeping containers where no good module exists.

## About Docker

Docker isn't being dropped for being "bad". Its real downsides here are fixable:
- its daemon runs as root, and the Docker socket is root-equivalent;
- it bypasses ufw;
- `latest` images that never get updated.

NixOS reduces how much depends on Docker and makes the rest declarative.

## Consequences

- Before migrating, every service gets mapped to a module or a container (Phase 2).
- Secrets are handled by a secrets tool in the NixOS config, not in `.env` files on CachyOS.
- Work on CachyOS until then is limited to security fixes, a first backup and light cleanup. Updates and uninstalls wait for the reinstall.
- The reinstall day needs a DNS fallback for the house.
