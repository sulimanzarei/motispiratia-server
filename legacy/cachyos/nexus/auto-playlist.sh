#!/bin/bash
# Snapshot of ~/nexus/auto-playlist.sh on 2026-10-07 (CachyOS era).
# For each folder in the music library, write <folder>.m3u listing that folder's files.
# Navidrome imports each .m3u as a playlist.

cd "/home/sulimanza/nexus/songs" || exit

for dir in */; do
    [ -d "$dir" ] || continue
    cd "$dir" || continue
    foldername=$(basename "$dir")
    ls -1p | grep -v "/$" | grep -v "\.m3u$" > "$foldername.m3u"
    cd ..
done
