<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/banner-dark.svg">
  <img alt="Paddock: modded vehicles, grouped." src=".github/assets/banner-light.svg">
</picture>

Paddock is a BeamNG.drive mod that gives every modded
vehicle its own **Modded** group in the vehicle selector, so mods stop getting lost
among the game's own cars.

[![CI](https://github.com/bennymxckz/paddock/actions/workflows/ci.yml/badge.svg)](https://github.com/bennymxckz/paddock/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/bennymxckz/paddock?include_prereleases&sort=semver)](https://github.com/bennymxckz/paddock/releases)
[![BeamNG.drive](https://img.shields.io/badge/BeamNG.drive-0.40-orange)](https://www.beamng.com/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

> [!NOTE]
> Paddock is in beta (0.x). It works, but expect changes before 1.0.

## Features

- **A Modded group** in the vehicle selector, above Cars and Trucks. Favourites
  and recent vehicles stay on top.
- **Config packs count too.** Configs that a mod adds to a game vehicle are listed
  under Modded, while your own saved configs stay with the game's vehicles.
- **Random picks land in Modded.** When the random vehicle button picks a modded
  car, it opens under Modded too.
- **Nothing else changes.** Automation cars keep their own group, and every other
  "Group by" option works as before.
- **No game files replaced.** Paddock hooks the selector's grouping at runtime. If
  a game update changes that code, Paddock logs a warning and steps aside, leaving
  the selector exactly as the game made it.
- **Follows your mods live.** Turning mods on or off while the game runs updates
  the group.

## Install

**BeamNG repository:** coming with the first public release.

**Manually:** download `paddock.zip` from the
[latest release](https://github.com/bennymxckz/paddock/releases), put it in your
mods folder (`%LOCALAPPDATA%\BeamNG\BeamNG.drive\current\mods`), and restart the
game (or reload Lua with <kbd>Ctrl</kbd>+<kbd>L</kbd>).

To uninstall, remove the zip or disable Paddock in the in-game mod manager.

## Compatibility

| Paddock | BeamNG.drive |
|---|---|
| 0.1.x | 0.40 |

Paddock supports the current game version. After each game update it's checked
again, and this table is updated.

It works alongside vehicle, map and config mods. Mods that replace the vehicle
selector itself may not combine with it.

## How it decides what's modded

A vehicle is **modded** when its `info.json` comes from a mod rather than the
game's own folder (the same test the game uses for its "BeamNG - Official" label).
A config is modded when its vehicle is, or when the config itself comes from a
mod. Automation vehicles are left in their own group.

## Troubleshooting

If the Modded group doesn't appear, open the console (<kbd>~</kbd>) and look for
lines tagged `paddock`:

- `Paddock 0.1.0: modded vehicles are grouped as "Modded"` means it's running.
- `The vehicle selector's grouping isn't where Paddock expects it` means a game
  update changed the selector. Please [open an issue](https://github.com/bennymxckz/paddock/issues/new/choose).

## Contributing

Bug reports, ideas and pull requests are welcome. Start with
[CONTRIBUTING.md](CONTRIBUTING.md), and ask questions in
[Discussions](https://github.com/bennymxckz/paddock/discussions).

## License

[MIT](LICENSE) © 2026 bennymxckz and Paddock contributors.

Paddock is a community mod and isn't affiliated with or endorsed by BeamNG GmbH.
