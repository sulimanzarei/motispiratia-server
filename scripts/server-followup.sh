#!/usr/bin/env bash
# server-followup.sh — second read-only pass for the handoff.
#
# Run:     bash server-followup.sh      (call bash explicitly; your login shell is fish)
# Output:  ~/server-followup.txt
#
# Changes nothing. `checkupdates` downloads package lists into a temporary database to count
# pending updates, but does not touch the installed system. Password/key/token values are masked.

set -u
OUT="${1:-$HOME/server-followup.txt}"
s()    { printf '\n--- %s\n' "$*"; }
mask() { sed -E 's/((pass|token|secret|key|psk|private)[^[:space:]:=]*[[:space:]]*[:=][[:space:]]*)[^[:space:]].*/\1<REDACTED>/I'; }

sudo -v || echo "Continuing without sudo; some sections will be incomplete." >&2
echo "Collecting… (the size check on the 16 TB drive can take a minute)" >&2

{
printf 'server-followup generated %s\n' "$(date -Is)"

# ---- music automation
s "playlist.service / playlist.timer"; systemctl cat playlist.service playlist.timer 2>&1
s "~/nexus/auto-playlist.sh"; mask < "$HOME/nexus/auto-playlist.sh" 2>&1
s "playlist runs (last 10)"; journalctl -u playlist.service -n 10 --no-pager -o short-iso 2>&1

# ---- what's where, and how big
s "folder sizes"
sudo du -sh "$HOME/nexus/songs" "$HOME/nexus/media" "$HOME/nexus/config" "$HOME/servers/games" \
            "$HOME/docker/data" /mnt/storage/recordings /mnt/storage/media/* 2>&1
s "~/nexus/songs"; printf 'files: %s\n' "$(find "$HOME/nexus/songs" -type f 2>/dev/null | wc -l)"; ls "$HOME/nexus/songs" 2>&1 | head -n 30
s "~/nexus/media"; ls -la "$HOME/nexus/media" 2>&1 | head -n 30
s "/mnt/storage/recordings"; ls -la /mnt/storage/recordings 2>&1 | head -n 30
s "~/servers/games"; ls -la "$HOME/servers/games" 2>&1
s "~/nexus/config"; ls -la "$HOME/nexus/config" "$HOME/nexus/config/jellyfin" 2>&1
s "compose files anywhere in home"; find "$HOME" -maxdepth 4 -name '*compose*.y*ml' 2>/dev/null
s "minecraft mods and world"; ls "$HOME/servers/games/minecraft-duke/mods" 2>&1; sudo du -sh "$HOME"/servers/games/minecraft-duke/world* 2>&1

# ---- AdGuard Home (DNS + DHCP + rewrites)
s "AdGuardHome.yaml (secrets masked)"
sudo cat "$HOME/nexus/config/adguard/conf/AdGuardHome.yaml" 2>&1 | mask

# ---- Jellyfin
s "Jellyfin version"; docker exec jellyfin /jellyfin/jellyfin --version 2>&1
s "Jellyfin encoding.xml (hardware acceleration settings)"
sudo find "$HOME/nexus/config/jellyfin/server" -maxdepth 2 -name encoding.xml -exec cat {} \; 2>&1

# ---- leftovers
s "AMP units"; systemctl cat ampfirewall.service amptasks.service 2>&1 | head -n 40
getent passwd amp; ls -d /home/amp /opt/cubecoders 2>&1
s "Decky Loader unit"; systemctl cat plugin_loader.service 2>&1 | head -n 15
s "login sessions"; loginctl list-sessions --no-legend 2>&1
s "display manager"; systemctl status sddm --no-pager 2>&1 | head -n 3
s "top memory users"; ps -eo user,comm,rss --sort=-rss | head -n 15
s "memory"; free -h

# ---- Samba
s "smb.conf (non-comment lines)"; grep -vE '^\s*(#|;|$)' /etc/samba/smb.conf 2>&1 | mask
s "Samba users"; sudo pdbedit -L 2>&1

# ---- SSH: who logs in, and is anyone outside trying?
s "accepted SSH logins, last 60 days (method user source)"
sudo journalctl -u sshd --since -60d --no-pager -o cat 2>/dev/null | grep 'Accepted' | awk '{print $2, $4, $6}' | sort | uniq -c
s "failed SSH attempts, last 60 days (count by source)"
sudo journalctl -u sshd --since -60d --no-pager -o cat 2>/dev/null | grep -E 'Failed|Invalid user' \
  | grep -oE 'from [0-9a-fA-F.:]+' | sort | uniq -c | sort -rn | head -n 20
s "IPv6 addresses on the LAN interface"; ip -6 addr show dev enp128s31f6 2>&1

# ---- Docker housekeeping
s "images"; docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}' 2>&1
s "dangling volumes"; docker volume ls -qf dangling=true 2>/dev/null | wc -l
s "disk use"; docker system df 2>&1

# ---- updates
s "pending updates (count)"; checkupdates 2>/dev/null | wc -l
s "pending updates for core pieces"
checkupdates 2>/dev/null | grep -E '^(linux-cachyos|linux-cachyos-lts|systemd|glibc|openssh|docker|tailscale|limine|mesa|intel-media-driver) '

} > "$OUT" 2>&1

echo "Done: $OUT ($(wc -l < "$OUT") lines). Skim it, then attach it in the chat." >&2
