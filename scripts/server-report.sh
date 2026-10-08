#!/usr/bin/env bash
# server-report.sh — read-only snapshot of the HTPC/server for the Claude handoff.
#
# Run:     bash server-report.sh        (CachyOS's default shell is fish, so call bash explicitly)
# Output:  ~/server-report.txt          (or pass a different path as the first argument)
#
# Changes nothing on the system. Asks for sudo once (hardware, SMART, firewall, ports, sshd).
# Password/token/key values in compose files and Caddyfiles are masked, .env values are never
# printed, and serial numbers / MAC addresses are filtered. Skim the file before sharing anyway.

set -u
OUT="${1:-$HOME/server-report.txt}"
CFILES=(); WDIRS=(); CADDYF=(); ids=""

have() { command -v "$1" >/dev/null 2>&1; }
h()    { printf '\n\n########## %s ##########\n' "$*"; }
s()    { printf '\n--- %s\n' "$*"; }
oneline() { tr '\n' ' ' | fold -s -w 110; echo; }

# Mask likely secrets in compose / env / Caddyfile text.
redact() {
  sed -E \
    -e 's/((pass|token|secret|key|credential|salt)[^[:space:]:=]*[[:space:]]*[:=][[:space:]]*)[^[:space:]].*/\1<REDACTED>/I' \
    -e 's/^([[:space:]]*(api_token|api_key|token|password|secret|auth_token)[[:space:]]+)[^{[:space:]].*/\1<REDACTED>/I' \
    -e 's/^([[:space:]]*(acme_)?dns[[:space:]]+[a-z0-9_]+[[:space:]]+)[^{[:space:]].*/\1<REDACTED>/I' \
    -e 's/\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}/<REDACTED-HASH>/g'
}

sudo -v || echo "Continuing without sudo; some sections will be incomplete." >&2

DOCKER=""
if have docker; then
  if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi
fi

echo "Collecting… (usually under a minute)" >&2

{
printf 'server-report generated %s\n' "$(date -Is)"

# ---------------------------------------------------------------- SYSTEM
h "SYSTEM"
s "hostname / OS / kernel"
hostnamectl 2>/dev/null | grep -Ev 'Machine ID|Boot ID'
grep -E '^(PRETTY_NAME|BUILD_ID|VERSION_ID)=' /etc/os-release 2>/dev/null
uname -r
s "uptime"; uptime
s "first pacman log line (~ install date)"; head -n1 /var/log/pacman.log 2>/dev/null
s "firmware"; if [ -d /sys/firmware/efi ]; then echo UEFI; else echo "BIOS/legacy"; fi
s "kernel cmdline"; cat /proc/cmdline
s "bootloader"; sudo bootctl status 2>/dev/null | head -n 25; ls -1 /boot /boot/efi /efi 2>/dev/null
s "display manager / sessions / autologin"
readlink -f /etc/systemd/system/display-manager.service 2>/dev/null
ls /usr/share/wayland-sessions /usr/share/xsessions 2>/dev/null
grep -rhs -A3 '^\[Autologin\]' /etc/sddm.conf /etc/sddm.conf.d/ 2>/dev/null
s "sleep targets (masked = disabled)"
for t in sleep suspend hibernate hybrid-sleep; do
  printf '%-14s %s\n' "$t" "$(systemctl is-enabled "$t.target" 2>&1)"
done

# ---------------------------------------------------------------- HARDWARE
h "HARDWARE"
if have inxi; then
  sudo inxi -Fxxxmz -c0 2>&1 || inxi -Fxxxz -c0 2>&1
else
  echo "(inxi not installed: sudo pacman -S inxi; using fallbacks)"
  s "cpu";    lscpu | grep -E 'Model name|^CPU\(s\)|Thread|Core|Socket|max MHz'
  s "memory"; free -h
  s "board";  sudo dmidecode -t baseboard 2>/dev/null | grep -E 'Manufacturer|Product Name|Version'
  s "dimms";  sudo dmidecode -t memory 2>/dev/null | grep -E '^\s+(Size|Type|Speed|Configured Memory Speed|Locator):' | grep -v 'No Module'
  s "pci";    lspci 2>/dev/null | grep -Ei 'vga|3d|display|ethernet|network|usb|sata|nvme|thunderbolt'
fi
s "gpu device nodes"; ls -l /dev/dri 2>/dev/null
have nvidia-smi && nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
s "usb devices"; lsusb 2>/dev/null
s "usb tree (link speeds)"; lsusb -t 2>/dev/null

# ---------------------------------------------------------------- STORAGE
h "STORAGE"
s "block devices"; lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,TRAN
s "filesystems";   df -hT -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs
s "/etc/fstab";    grep -Ev '^\s*(#|$)' /etc/fstab
s "swap / zram";   swapon --show
s "root fs";       findmnt -no SOURCE,FSTYPE,OPTIONS /
if [ "$(findmnt -no FSTYPE /)" = btrfs ]; then
  s "btrfs subvolumes (snapshots only counted)"
  sudo btrfs subvolume list / 2>/dev/null | grep -v '\.snapshots/'
  printf 'snapshot subvolumes: %s\n' "$(sudo btrfs subvolume list / 2>/dev/null | grep -c '\.snapshots/')"
fi
s "snapshot / backup tools installed"
pacman -Q snapper snap-pac btrfs-assistant timeshift restic borg borgmatic rsnapshot kopia rclone 2>/dev/null
s "systemd automounts"; systemctl list-units --type=automount --no-pager --no-legend 2>/dev/null
s "SMART (identity + health)"
if have smartctl; then
  for d in $(lsblk -dno NAME,TYPE | awk '$2=="disk" && $1 !~ /^(zram|loop)/ {print $1}'); do
    s "/dev/$d"
    out=$(sudo smartctl -i -H "/dev/$d" 2>&1)
    if echo "$out" | grep -qiE 'unknown usb bridge|specify device type'; then
      out=$(sudo smartctl -d sat -i -H "/dev/$d" 2>&1)
    fi
    echo "$out" | grep -Eiv 'serial|wwn|copyright|^smartctl [0-9]|^=== |^$'
  done
else
  echo "(smartmontools not installed: sudo pacman -S smartmontools)"
fi
s "layout of large data mounts (>= 10 TB; big folders only counted)"
while read -r tgt; do
  printf '\n%s  (owner/mode %s)\n' "$tgt" "$(stat -c '%U:%G %a' "$tgt" 2>/dev/null)"
  for d in "$tgt"/*/; do
    [ -d "$d" ] || continue
    echo "  ${d%/}"
    n=$(find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$n" -le 12 ]; then
      find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | sed 's/^/      /'
    else
      echo "      ($n subfolders, not listed)"
    fi
  done
done < <(df -B1T --output=target,size -x tmpfs -x devtmpfs -x overlay 2>/dev/null | awk 'NR>1 && $2+0>=10 {print $1}')

# ---------------------------------------------------------------- NETWORK
h "NETWORK"
s "interfaces"; ip -br addr | grep -Ev '^veth'
s "link type / speed"
for i in /sys/class/net/*; do
  n=${i##*/}
  case $n in lo|veth*|docker*|br-*) continue ;; esac
  kind=wired; [ -d "$i/wireless" ] && kind=wifi
  printf '%-16s %-6s state=%s speed=%s\n' "$n" "$kind" "$(cat "$i/operstate" 2>/dev/null)" "$(cat "$i/speed" 2>/dev/null || echo n/a)"
done
s "routes"; ip route
if have nmcli; then
  s "NetworkManager (ipv4.method: auto = DHCP, manual = static)"
  nmcli -t -f NAME,TYPE,DEVICE connection show --active
  nmcli -t -f NAME connection show --active | while IFS= read -r c; do
    printf '%s -> ipv4.method=%s\n' "$c" "$(nmcli -g ipv4.method connection show "$c" 2>/dev/null)"
  done
fi
s "DNS"
grep -v '^#' /etc/resolv.conf 2>/dev/null
resolvectl status 2>/dev/null | head -n 25
grep -rhs -i 'DNSStubListener' /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/
s "listening ports (proto  address:port  process)"
sudo ss -tulpnH 2>/dev/null | awk '{print $1, $5, $7}' | sort -u
s "firewall"
for u in ufw firewalld nftables iptables; do printf '%-10s %s\n' "$u" "$(systemctl is-active "$u" 2>/dev/null)"; done
have ufw && sudo ufw status verbose 2>&1 | head -n 40
have firewall-cmd && sudo firewall-cmd --list-all 2>&1 | head -n 30
s "nftables tables"; sudo nft list tables 2>/dev/null

# ---------------------------------------------------------------- TAILSCALE
h "TAILSCALE"
if have tailscale; then
  tailscale version 2>/dev/null | head -n1
  printf 'tailscaled: %s\n' "$(systemctl is-active tailscaled 2>/dev/null)"
  s "status"; tailscale status 2>&1
  s "selected prefs"
  sudo tailscale debug prefs 2>/dev/null \
    | grep -E -A3 '"(AdvertiseRoutes|AdvertiseTags|ExitNodeID|ExitNodeIP|RunSSH|CorpDNS|RouteAll|ShieldsUp|Hostname)"' \
    | grep -Eiv 'key|priv|persist|^--$'
  s "serve / funnel"
  tailscale serve status 2>&1 | head -n 20
  tailscale funnel status 2>&1 | head -n 20
else
  echo "tailscale CLI not found on the host (maybe it runs in a container)"
fi

# ---------------------------------------------------------------- DOCKER
h "DOCKER"
if [ -n "$DOCKER" ]; then
  s "versions"
  $DOCKER version --format 'engine {{.Server.Version}}' 2>&1
  $DOCKER compose version 2>&1
  pacman -Q docker docker-compose docker-buildx 2>/dev/null
  s "engine info"
  $DOCKER info --format 'root={{.DockerRootDir}} driver={{.Driver}} logging={{.LoggingDriver}} cgroup={{.CgroupDriver}}' 2>&1
  s "/etc/docker/daemon.json"; cat /etc/docker/daemon.json 2>/dev/null || echo "(none)"
  s "containers"; $DOCKER ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  s "compose projects"; $DOCKER compose ls -a 2>&1
  ids=$($DOCKER ps -aq)
  if [ -n "$ids" ]; then
    s "restart policy / network mode / devices / memory limit"
    $DOCKER inspect --format '{{.Name}}  restart={{.HostConfig.RestartPolicy.Name}}  net={{.HostConfig.NetworkMode}}  devices={{range .HostConfig.Devices}}{{.PathOnHost}} {{end}} mem_limit={{.HostConfig.Memory}}' $ids
    s "mounts (host -> container)"
    $DOCKER inspect --format '{{.Name}}{{range .Mounts}}{{"\n    "}}{{.Source}} -> {{.Destination}}{{if not .RW}} (ro){{end}}{{end}}' $ids
    s "networks"; $DOCKER network ls
    s "named volumes"; $DOCKER volume ls
    s "live resource use"; $DOCKER stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>&1
    mapfile -t CFILES < <($DOCKER inspect --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}' $ids | tr ',' '\n' | sed '/^$/d;/no value/d' | sort -u)
    mapfile -t WDIRS  < <($DOCKER inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' $ids | sed '/^$/d;/no value/d' | sort -u)
  fi
else
  echo "docker CLI not found"
fi

h "COMPOSE FILES (secret values masked)"
for f in "${CFILES[@]}"; do
  s "$f"
  { cat "$f" 2>/dev/null || sudo cat "$f" 2>/dev/null || echo "(could not read)"; } | redact
done
s "compose folders: contents, and .env variable NAMES only (values never printed)"
for d in "${WDIRS[@]}"; do
  printf '\n%s/\n' "$d"
  ls -1A "$d" 2>/dev/null | sed 's/^/    /'
  for e in "$d"/.env "$d"/*.env; do
    [ -f "$e" ] || continue
    printf '  %s variable names:\n' "${e##*/}"
    { cat "$e" 2>/dev/null || sudo cat "$e" 2>/dev/null; } \
      | grep -E '^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' \
      | sed -E 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/      \2/'
  done
done

# ---------------------------------------------------------------- CADDY
h "CADDY (tokens masked)"
printf 'native caddy service: %s\n' "$(systemctl is-active caddy 2>/dev/null)"
mapfile -t CADDYF < <(
  {
    sudo find /etc/caddy "${WDIRS[@]}" -maxdepth 4 -type f -name 'Caddyfile*' 2>/dev/null
    if [ -n "$DOCKER" ] && [ -n "$ids" ]; then
      $DOCKER inspect --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}' $ids 2>/dev/null | grep -i 'caddyfile'
    fi
  } | sort -u
)
for f in "${CADDYF[@]}"; do
  s "$f"
  { cat "$f" 2>/dev/null || sudo cat "$f" 2>/dev/null || echo "(could not read)"; } | redact
done
[ ${#CADDYF[@]} -eq 0 ] && echo "(no Caddyfile found in /etc/caddy or compose folders; paste yours by hand with tokens removed)"

# ---------------------------------------------------------------- PACKAGES & SERVICES
h "PACKAGES"
s "explicitly installed ($(pacman -Qqe | wc -l))"; pacman -Qqe | oneline
s "foreign / AUR ($(pacman -Qqm | wc -l))";       pacman -Qqm | oneline
s "AUR helpers"; for x in paru yay; do have "$x" && echo "$x"; done
if have flatpak; then s "flatpaks"; flatpak list --app --columns=application 2>/dev/null; fi

h "SERVICES"
s "key units"
for u in docker tailscaled sshd caddy pihole-FTL AdGuardHome jellyfin navidrome qbittorrent-nox \
         fail2ban crowdsec cronie smb nmb nfs-server avahi-daemon cockpit.socket \
         snapper-timeline.timer snapper-cleanup.timer; do
  printf '%-24s enabled=%-9s active=%s\n' "$u" "$(systemctl is-enabled "$u" 2>/dev/null || true)" "$(systemctl is-active "$u" 2>/dev/null)"
done
s "running services"; systemctl list-units --type=service --state=running --no-pager --no-legend --plain | awk '{print $1}' | oneline
s "enabled unit files"; systemctl list-unit-files --state=enabled --no-pager --no-legend | awk '{print $1}' | oneline
s "user services running"; systemctl --user list-units --type=service --state=running --no-pager --no-legend --plain 2>/dev/null | awk '{print $1}'

# ---------------------------------------------------------------- SCHEDULED JOBS
h "SCHEDULED JOBS"
s "system timers"; systemctl list-timers --all --no-pager
s "user timers";   systemctl --user list-timers --all --no-pager 2>/dev/null
s "user crontab";  crontab -l 2>&1
s "root crontab";  sudo crontab -l 2>&1
s "/etc/cron.*";   ls /etc/cron.d /etc/cron.daily /etc/cron.weekly 2>/dev/null

# ---------------------------------------------------------------- USERS & ACCESS
h "USERS & ACCESS"
s "human accounts (name shell)"; awk -F: '$3>=1000 && $3<60000 {print $1, $7}' /etc/passwd
s "current user"; id
s "sudoers (non-comment lines)"
sudo sh -c 'grep -hvE "^[[:space:]]*(#|$)" /etc/sudoers /etc/sudoers.d/* 2>/dev/null'
s "sshd"
printf 'enabled=%s active=%s\n' "$(systemctl is-enabled sshd 2>/dev/null)" "$(systemctl is-active sshd 2>/dev/null)"
sudo sshd -T 2>/dev/null | grep -Ei '^(port|listenaddress|permitrootlogin|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|allowusers|allowgroups) '
s "authorized_keys entries"
if [ -f "$HOME/.ssh/authorized_keys" ]; then grep -c . "$HOME/.ssh/authorized_keys"; else echo 0; fi

} > "$OUT" 2>&1

echo "Done: $OUT ($(wc -l < "$OUT") lines). Skim it, then attach it in the chat." >&2
