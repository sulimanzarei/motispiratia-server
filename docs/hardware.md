# Hardware

Collected on 2026-10-07 with `inxi -Fxxxmz`, `lsblk`, `smartctl` and `lsusb` (see [scripts/](../scripts/)). Serial numbers and MAC addresses are left out on purpose.

## Machine

| | |
|---|---|
| Model | Lenovo ThinkCentre M90q Gen 6 (machine type 13AC), "Tiny" mini PC |
| Firmware | UEFI, version M5PKT2EA (2025-11-11). Secure Boot off. TPM 2.0 present |
| CPU | Intel Core Ultra 9 285 (Arrow Lake), 24 cores, up to 5.6 GHz |
| RAM | 32 GiB DDR5-5600, one SK Hynix module. The second slot is empty |
| GPU | Integrated Intel graphics (Arrow Lake-S, `i915` driver). No monitor attached |
| Wired network | Intel I219-LM, 1 Gb/s full duplex (`enp128s31f6`) |
| Wireless | Intel AX211 Wi-Fi (down, unused) and Bluetooth 5.4 (on, unused) |
| Audio | Intel 800-series HD audio (unused) |

> [!TIP]
> With one module, the memory runs in single-channel mode at half the bandwidth. A second matching module (32 GiB DDR5-5600 SO-DIMM) would enable dual channel. `inxi` estimates the board takes up to 128 GiB.

## Storage

| Device | Model | Size | Connection | Holds |
|---|---|---|---|---|
| `nvme0n1` | KIOXIA KBG6 (KBG6AZNV1T02) NVMe SSD | 1 TB | PCIe x4 | `/boot` and `/`: system, Docker, app configs, music, game servers |
| `sda` | Seagate IronWolf Pro 16 TB (ST16000NT001), 7200 rpm | 16 TB | USB, inside the TerraMaster D4-320 | `/mnt/storage`: media |

`lsblk` reports the HDD as 14.6T. That's the same 16 TB: drive makers count in powers of 10, Linux counts in powers of 2.

### The enclosure

- TerraMaster D4-320, a 4-bay USB enclosure. One bay is used, three are free.
- USB bridge chip: ASMedia (USB ID `174c:235c`), handled by the `uas` driver.
- Link speed: 10 Gb/s.

## Health on 2026-10-07

| Drive | SMART overall health | Temperature |
|---|---|---|
| NVMe | PASSED | 38 °C |
| 16 TB HDD | PASSED | |

The CPU was at 54 °C under light load.
