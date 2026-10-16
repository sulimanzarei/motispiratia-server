# 2026-10-16: AdGuard's rate limit was making pages load slowly

**Goal:** Find out why some web pages took seconds to start loading on toph, while downloads ran at full speed.

## What I did

1. Measured from toph. Ruled out the usual suspects first: IPv4 and IPv6 both work, no packet loss to the server or the router, path MTU discovery works (the real MTU is 1492 and the kernel learns it), Firefox has NVIDIA acceleration, and the disk and memory are idle. With a warm DNS cache, pages fetch in 0.17–0.6 s.
2. Timed name lookups instead. One at a time they were fine, about 110 ms. In parallel, which is what a browser does, a third of them took exactly 5 seconds, glibc's resolver timeout.
3. Narrowed it to AdGuard. The same parallel load against the router and against 1.1.1.1 was clean, so it wasn't the network or toph.
4. Found the cause by querying a name **already in AdGuard's cache**, so no upstream work was involved. A burst of 40 of those got 19 answers in 19–39 ms and 21 no answer at all. The cliff was sharp: 18 queries at once were fine at 26 ms, 20 at once took 3 seconds.
5. That is AdGuard Home's `ratelimit`, which defaults to 20 queries a second per client. Set it to 0 in Settings → DNS settings, and re-measured.

## What the numbers showed

| Test | Before | After |
|---|---|---|
| Burst of 40 cached queries | 19 answered, 21 unanswered | 40 of 40, 43 ms worst |
| Burst of 100 cached queries | — | 100 of 100, 53 ms worst |
| 120 cold lookups, 8 at a time | 45 stalled, 12.2 s at the 95th percentile | none stalled, 86 ms |
| 38 real page hostnames, 12 at a time | about 19 served, the rest at 5 s | none stalled, 114 ms cold, 6 ms warm |

## What broke or surprised me

- The limit is per client address, so one browser opening a page with 25 or more hostnames went over it by itself. Nothing else in the house had to be busy.
- AdGuard **drops** the queries over the limit instead of refusing them. A refusal would let the client fail over at once; silence makes it wait out its own timeout, 5 seconds on glibc. This is why it looked like a slow network rather than a broken one.
- It only ever showed up on heavy pages pulling from many third-party hostnames. A page on one or two domains felt instant, and a reload was fast because the names were cached by then. That's what made it look random for so long.
- The limit had been on since the server was installed. The symptom was easy to blame on the ISP.
- Measuring with made-up hostnames is misleading. Resolving hundreds of names that don't exist throttles the Quad9 upstream and gets worse the more you do it. Only real hostnames give an honest picture.

## Decisions

- Rate limit off (0) rather than raised. It exists to stop a resolver open to the internet being used for amplification attacks. There's no port forwarding, so AdGuard is reachable only from the home network and the tailnet, and has no such exposure. This depends on DNS staying closed to the internet, which is [backlog task 5](BACKLOG.md).
- Keep AdGuard as the DNS server for the house. The fault was one setting, not the design.

## Next

Carry the setting over to the NixOS configuration, so the migration doesn't quietly bring the default back.
