# Changelog

All notable changes to Paddock are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Paddock follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-11-14

### Changed

- The MIT license now sits in the header of `paddock.lua` instead of a separate
  `LICENSE.txt` in the zip, as the BeamNG repository doesn't allow readme files
  in mods. No change in game.

## [0.1.0] - 2026-11-14

### Added

- A **Modded** group in the vehicle selector, above Cars and Trucks, holding every
  vehicle that comes from a mod.
- Configs that a mod adds to a game vehicle are listed under Modded too; the
  player's own saved configs stay with the game's vehicles.
- The random vehicle button opens a modded car under Modded.
- Automation vehicles keep their own group.
- If the game's selector code changes, Paddock logs a warning and leaves the
  selector unchanged.

[Unreleased]: https://github.com/bennymxckz/paddock/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/bennymxckz/paddock/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/bennymxckz/paddock/releases/tag/v0.1.0
