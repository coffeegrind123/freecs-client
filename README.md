# FreeCS Client

Ready-to-play Counter-Strike 1.5 client builds for Windows and Linux. Based on [FreeCS](https://github.com/eukara/freecs) by Marco "eukara" Cawthorne — an open-source CS 1.5 reimplementation in QuakeC running on the [FTEQW](https://www.fteqw.org) engine.

This fork adds a CI pipeline that cross-compiles a patched FTEQW engine, bundles all game data, and publishes ready-to-play client packages as GitHub releases.

![Preview 1](img/preview1.jpg)
![Preview 2](img/preview2.jpg)

## Download

Grab the latest release from the [Releases page](https://github.com/coffeegrind123/freecs-client/releases/latest), or from the download page at [freecs.cs16.net](http://freecs.cs16.net:27500).

| Platform | File |
|----------|------|
| Windows 64-bit | `freecs-client-win64.zip` |
| Linux 64-bit | `freecs-client-linux64.zip` |

## Install

1. Download and extract the zip
2. Run `Play FreeCS.bat` (Windows) or `./play-freecs.sh` (Linux)
3. Open the server browser to find servers, or press `~` and type `connect ip:port`

Everything is included — no separate FTEQW download, no manual pk3 placement, no Steam required.

## What's Included

- **Patched FTEQW engine** — cross-compiled with bug fixes (see below)
- **FreeCS game logic** — compiled QuakeC progs (bomb defusal, hostage rescue, assassination, deathmatch, gun game, zombie mode)
- **Rad-Therapy** — open-source Half-Life base data
- **CS 1.5 data** — all 26 original maps, player models, weapon models, sounds, sprites, textures
- **HL1 valve data** — blood sprites, gib models, debris sounds, WAD textures (from GoldSrc Package)
- **Nuclide SDK configs** — default key bindings (WASD, mouse), video settings
- **Bot waypoints** — navigation data for 55+ maps
- **Master server config** — pre-configured to query `ms.cs16.net:27950`

## FTEQW Engine Patches

The build applies four patches to the stock FTEQW engine ([`scripts/patch-fteqw.sh`](scripts/patch-fteqw.sh)):

1. **Fix empty `infoResponse`** — `SVC_GetInfo` in `sv_main.c` didn't advance the response pointer after writing serverinfo, sending an empty 17-byte packet instead of full server data. Broke the dpmaster server browser for all clients.

2. **Fix `getserversResponse` parsing** — bit-position calculation in `net_master.c` had wrong operator precedence (`(c+N-1)<<3` vs `c+((N-1)<<3)`), causing the parser to read past the end of small server list packets. Servers from masters with few entries were silently dropped.

3. **Blank default QW masters** — `net_qwmasterextra4/5` are `CVAR_NOSAVE` (can't be overridden at runtime) and flooded the server browser probe queue with hundreds of unrelated QW servers, preventing dpmaster servers from being probed in time.

4. **Suppress update dialog** — `pkg_autoupdate` default changed from `-1` (prompt on every launch about frag-net.com update sources) to `0` (off). Updates can still be enabled manually via the downloads menu.

## Building from Source

The CI workflow handles everything automatically. To build locally:

```bash
# Install dependencies
sudo apt-get install gcc-mingw-w64-x86-64 build-essential libgl-dev \
  libasound2-dev libxss-dev libxrandr-dev libxcursor-dev libxi-dev \
  libpulse-dev megatools p7zip-full

# Run the build script
bash scripts/build-client.sh
```

This clones FTEQW, applies patches, cross-compiles for Windows and Linux, downloads all game data (Rad-Therapy, FreeCS, CS 1.5 maps, HL1 valve assets), and packages ready-to-play zips.

## Related

- [coffeegrind123/freecs-server](https://github.com/coffeegrind123/freecs-server) — Dedicated server deployment scripts
- [eukara/freecs](https://github.com/eukara/freecs) — Upstream FreeCS (game source)
- [fte-team/fteqw](https://github.com/fte-team/fteqw) — FTEQW engine
- [freecs.cs16.net](http://freecs.cs16.net:27500) — Download page with live server list

## Community

- Matrix: https://matrix.to/#/#nuclide:matrix.org
- IRC: #freecs on irc.libera.chat

## License

### FreeCS (ISC License)

Copyright (c) 2016-2025 Marco "eukara" Cawthorne <marco@icculus.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

### Other components

- FTEQW engine patches and CI pipeline are provided as-is by coffeegrind123
- CS 1.5 data and Half-Life base assets are copyrighted by Valve
- Rad-Therapy is ISC licensed by Marco "eukara" Cawthorne
