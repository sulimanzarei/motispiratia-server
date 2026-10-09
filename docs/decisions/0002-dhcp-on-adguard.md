# 0002: DHCP on the server (AdGuard Home)

**Status:** Accepted, 2026-10-08.

## Context

- Devices were getting addresses even though both the Huawei's DHCP server and AdGuard's DHCP server were off.
- A DHCP discover showed the only DHCP server was the TP-Link Archer C80. It's meant to be just an access point, but it was handing out addresses on its own 192.168.0.x network.
- AdGuard's DHCP had most likely been off since the move from Proxmox to CachyOS.

## What I need

- Every device, including guests' phones, gets an address automatically.
- Every device uses AdGuard for DNS, so ad blocking and the `.motis` names work everywhere.
- Fixed addresses for the server and toph.

## Options

### The Huawei router

- **For:** addresses keep working when the server is down.
- **Against:** the ISP firmware doesn't let me choose the DNS server it hands out, so devices would bypass AdGuard.

### The C80

- **Against:** it's meant to be only an access point, and it was handing out a separate network.

### AdGuard Home on the server

- **For:**
  - Hands out itself as the DNS server, so filtering covers every device.
  - Static leases and the address plan live in one place.
  - Already running, with host networking.
- **Against:** the house depends on the server for addresses as well as names.

## Decision

AdGuard Home. Pool .10–.250, 24-hour leases. The Huawei's and the C80's DHCP servers stay off.

## Consequences

- If the server goes down, devices keep their address until their lease runs out (up to 24 hours), but new devices can't join.
- Migration day needs a plan for DHCP and DNS: keep the downtime short, or hand DHCP back to the Huawei temporarily.
- The pool includes the server's own address (.100) and toph's (.105). toph's is reserved by its static lease. AdGuard pings each address before offering it, so it never hands out .100 while it's running.
- The firewall must keep allowing DHCP (67/udp).
- Only one DHCP server may run on the network. If the C80 is ever reset, its DHCP server needs turning off again.
