# Tactical-Retreat
[As seen on phoronix.com](https://phoronix.com/scan.php?page=news_item&px=FreeCS-Open-Counter-Strike)

Allows you to play the original modification CS 1.5 with Rad-Therapy.

![Preview 1](img/preview1.jpg)
![Preview 2](img/preview2.jpg)
![Preview 3](img/preview3.jpg)
![Preview 4](img/preview4.jpg)

## Installing 
To run it, all you need is [FTEQW](https://www.fteqw.org), [Rad-Therapy](https://www.frag-net.com/pkgs/package_valve.pk3), and [the latest release .pk3 file](https://www.frag-net.com/pkgs/package_cstrike.pk3), which you save into `Half-Life/valve/` and `Half-Life/cstrike/` respectively. That's about it. You can install updates through the **Configuration > Updates** menu from here on out.

### Disclaimer
Please **do not** file bugs if you see missing/broken content **while not** using the original data. The version on Steam is not the same game as the mod (which was free)

## Building
Here's the quick and dirty instructions:

```
$ git clone https://code.idtech.space/vera/nuclide Nuclide-SDK && cd Nuclide-SDK

# (only required if you don't have an up-to-date FTEQW & FTEQCC in your PATH)
$ make update && make fteqw

# build the menu (from valve/) then our own game-logic:
$ git clone https://code.idtech.space/fn/valve valve && make game GAME=valve
$ git clone https://code.idtech.space/fn/cstrike cstrike && make game GAME=cstrike
```

You can also issue `make` inside `valve/src/` and `cstrike/src`, but it won't generate some additional helper files.

** !! You need to also provide data-files !! **

This should be self explanatory.
Half-Life and Counter-Strike are owned by Valve and protected under copyright.

## Community

### Matrix
If you're a fellow Matrix user, join the Nuclide Space to see live-updates and more!
https://matrix.to/#/#nuclide:matrix.org

### IRC
Join us on #freecs via irc.libera.chat and talk/lurk or discuss bugs, issues
and other such things. It's bridged with the Matrix room of the same name!

### Others
We've had people ask in the oddest of places for help, please don't do that.

## Special Thanks

- Spike for FTEQW and for being the most helpful person all around!
- Xylemon for the hundreds of test maps, verifying entity and game-logic behaviour
- CYBERDEViL for his work on making Bots fascinated with Bomb Defusal
- mikota for his work on refining the bullet spread code
- To my supporters on Patreon, who are always eager to follow what I do.
- Any and all people trying it, tinkering with it etc. :)

## License
ISC License

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
 
