# Inventory scripts

Read-only scripts I used for the Phase 0 inventory. Neither changes anything on the system.

| Script | Collects | Output |
|---|---|---|
| `server-report.sh` | Hardware, disks, network, firewall, Tailscale, Docker, Compose files, Caddyfile, packages, services, timers, users, SSH | `~/server-report.txt` |
| `server-followup.sh` | Music automation, folder sizes, AdGuard Home config, Jellyfin settings, leftovers, Samba, SSH login history, Docker cleanup, pending updates | `~/server-followup.txt` |

Run them with `bash` (the login shell is fish):

```
bash server-report.sh
bash server-followup.sh
```

They mask passwords, keys and tokens, but the output still contains IP addresses and device names. That's why `.gitignore` keeps both output files out of the repo. Read the output before sharing it.
