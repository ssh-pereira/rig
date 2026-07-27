# Networking

## The modern replacements

| Use | Instead of |
|---|---|
| `doggo example.com` | `dig` — readable, JSON mode, DoH/DoT support |
| `gping 1.1.1.1 8.8.8.8` | `ping` — live graph, multiple hosts at once |
| `mtr example.com` | `traceroute` — continuous, per-hop loss |
| `xh GET api.com/x` | `curl` — sane syntax, pretty JSON by default |
| `oha -n 1000 url` | `ab` / `wrk` — live TUI of latency percentiles |
| `ports` | `lsof -iTCP -sTCP:LISTEN -n -P` |

## mtr — the one to actually learn

`traceroute` shows the path once. `mtr` runs continuously and shows **loss percentage per hop**. When something is "slow sometimes", this finds the hop dropping packets.

```bash
mtr example.com          # interactive
mtr -rwc 100 example.com # 100 cycles, report mode, for pasting into a ticket
```

**Reading it correctly** — the part almost everyone gets wrong:

> Loss shown at a middle hop that does **not** persist to later hops is not real loss. That router is just deprioritising ICMP replies to itself. **Only loss that continues to the final hop is real.**

Misreading this sends people chasing an ISP that's fine.

## Things you probably don't know

- **`doggo example.com @1.1.1.1`** — query a specific resolver. Compare against your ISP's to spot stale caching or DNS-level blocking.
- **`doggo example.com MX NS TXT`** — several record types in one call.
- **`doggo --json | jq`** — scriptable DNS.
- **`xh` sends JSON by default:**
  ```bash
  xh POST api.com/users name=hugo age:=30        # := is a raw JSON value
  xh -a user:pass GET api.com/me                 # basic auth
  xh --download GET url                          # save to file
  xh -v GET url                                  # show the full request too
  ```
- **`oha -z 30s -c 50 url`** — 50 concurrent connections for 30 seconds, with a live histogram. Far more informative than a total.
- **`ports`** — what's listening. The answer to "address already in use".
- **`lsof -i :4000`** — who has port 4000 specifically.
- **`nc -zv host 1-1000`** — port scan a range without installing nmap.
- **`caddy reverse-proxy --from example.test --to :3000`** — one command, local HTTPS with a real cert, no config file. You have Caddy installed.
- **`networkQuality`** — built into macOS. Measures bandwidth *and* responsiveness under load (bufferbloat), which a plain speed test hides.
- **`ipconfig getifaddr en0`** — LAN IP without parsing `ifconfig`.
- **`scutil --dns`** — macOS's actual resolver configuration, including per-domain resolvers from VPNs. Explains "why does this one domain not resolve".
- **`sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`** — flush the macOS DNS cache.
- **`arp -a`** — everything on your local network.

## dnsmasq (installed here)

Local DNS server. The usual reason to have it: resolve `*.test` to `127.0.0.1` so every local project gets a real hostname instead of a port number.

```
# /opt/homebrew/etc/dnsmasq.conf
address=/.test/127.0.0.1
```

Combined with Caddy, `myapp.test` becomes a local HTTPS URL.

## Debugging order

1. **Is it DNS?** `doggo <host>` — resolves at all? Same answer from `@1.1.1.1`?
2. **Is it reachable?** `gping <host>` — packets returning?
3. **Where does it degrade?** `mtr <host>` — loss at the final hop?
4. **Is the port open?** `nc -zv <host> <port>`
5. **Is it the app?** `xh -v GET <url>` — full request and response.

It's DNS more often than it isn't.
