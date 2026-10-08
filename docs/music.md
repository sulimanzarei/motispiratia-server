# Music

## How it works today

1. I download songs with Soulseek on toph (Windows).
2. I copy them by hand into a playlist folder in the `Songs` Samba share, which is `~/nexus/songs/<playlist>/` on the server. Each top-level folder is one playlist, and there are two today.
3. Every 5 minutes, `playlist.timer` runs `~/nexus/auto-playlist.sh`. The script writes `<folder name>.m3u` inside each folder, listing that folder's files in name order.
4. Navidrome imports each `.m3u` file as a playlist and picks up the new songs. It's set to rescan every hour (`ND_SCANSCHEDULE=1h`).
5. I listen with Feishin on the desktop (at home, no Tailscale) and Amperfy on the iPhone. Amperfy downloads songs while I'm home, so I can play them offline.

The script, exactly as on the server:

```bash
#!/bin/bash

cd "/home/sulimanza/nexus/songs" || exit

for dir in */; do
    [ -d "$dir" ] || continue
    cd "$dir" || continue
    foldername=$(basename "$dir")
    ls -1p | grep -v "/$" | grep -v "\.m3u$" > "$foldername.m3u"
    cd ..
done
```

The systemd units are in [legacy/cachyos/systemd/](../legacy/cachyos/systemd/).

## Notes

- The timer runs every 5 minutes, but Navidrome rescans hourly, so a playlist can lag behind its folder by up to an hour. Newer Navidrome versions can also watch the folder for changes, which may be quicker; to check.
- The script rewrites every `.m3u` file every 5 minutes, even when nothing changed.
- Playlist order is alphabetical by filename, not by date added.
- The music lives on the NVMe, not the 16 TB drive.

## Pain points

- Getting new songs onto the iPhone takes several steps in Amperfy: open the app, go through several menus to the playlist, refresh it twice, then download.
- Every song goes through toph and a manual copy.

## Ideas (not decided)

- Run a Soulseek client on the server (slskd has a web UI), so downloads land in the library directly. Setting up SoulSync next to Navidrome is already on my to-do list.
- Find an Amperfy setting that syncs and downloads playlists automatically when the app opens.
- Make Navidrome notice new files sooner.
