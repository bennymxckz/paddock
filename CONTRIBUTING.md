# Contributing to Paddock

Thanks for helping. This guide covers how to report problems, set up the project,
and get a change merged.

Contributions are accepted under the project's [MIT License](LICENSE).

## Reporting bugs and asking for features

- **Bugs:** [open a bug report](https://github.com/bennymxckz/paddock/issues/new?template=bug_report.yml).
  Include your game version, Paddock version, the other mods you run, and the
  console lines tagged `paddock`.
- **Ideas:** [open a feature request](https://github.com/bennymxckz/paddock/issues/new?template=feature_request.yml).
  For anything large, start a [discussion](https://github.com/bennymxckz/paddock/discussions)
  first so the approach can be agreed before code is written.
- **Questions:** use [Discussions](https://github.com/bennymxckz/paddock/discussions),
  not issues.

## Project layout

```
src/                       The mod, exactly as it goes into the zip
  lua/ge/extensions/       paddock.lua: the extension (all of Paddock's logic)
  scripts/paddock/         modScript.lua: loads the extension when the mod mounts
tools/build.py             Builds dist/paddock.zip; also checks versions and release notes
tools/install_tools.py     Installs the pinned StyLua and selene into tools/bin/
tools/requirements-dev.txt Python development tools (Ruff)
beamng.yml                 BeamNG globals for the selene linter
.github/                   CI, release workflow, issue and PR templates
```

## Development setup

You need [BeamNG.drive](https://www.beamng.com/) and Python 3.10 or newer.

```bash
git clone https://github.com/bennymxckz/paddock.git
cd paddock
python tools/install_tools.py              # StyLua and selene, at the pinned versions, into tools/bin/
pip install -r tools/requirements-dev.txt  # Ruff, for the Python tools
```

The script downloads the official release builds from GitHub. If you'd rather
install the tools another way (`cargo install`, an editor extension), use the
versions pinned at the top of `tools/install_tools.py`, so your results match CI.

Run the same checks as CI before pushing (with `tools/bin` on your `PATH`):

```bash
stylua src             # format the Lua
selene src             # lint the Lua
ruff format tools      # format the Python tools
ruff check tools       # lint the Python tools
python tools/build.py  # build dist/paddock.zip
```

### Testing in game

1. Build, then copy `dist/paddock.zip` into your mods folder, replacing any
   installed copy (`%LOCALAPPDATA%\BeamNG\BeamNG.drive\current\mods`).
2. Start the game, or press <kbd>Ctrl</kbd>+<kbd>L</kbd> to reload Lua.
3. Open the console (<kbd>~</kbd>) and check for the `paddock` startup line and no
   errors.
4. Open the vehicle selector and check:
   - the Modded group is listed above Cars and Trucks and holds your mod vehicles;
   - opening a modded vehicle there lists its configs;
   - a config pack for a game vehicle (for example extra Pickup configs) appears
     under Modded, and the game vehicle still opens with all its configs from
     Cars and Trucks;
   - favourites, recent vehicles and the other "Group by" options are unchanged.

There's no automated in-game test yet, so describe what you checked in the pull
request.

## Code style

- Formatting is StyLua's (`stylua.toml`) for Lua and Ruff's (`ruff.toml`) for
  Python; don't hand-format.
- selene must report no warnings. If you use a new BeamNG global, add it to
  `beamng.yml`.
- Keep Paddock defensive: every hook into game code must check what it hooks and
  fall back to the game's behaviour if anything is missing. A game update must
  never break the vehicle selector.
- Comments explain *why*, not what the next line does.

## Commits and pull requests

All changes, including the maintainers', go through pull requests. `main` is
protected and needs passing CI. Pull requests are **squash-merged**, so the
**pull request title becomes the commit message on `main`**.

### Titles follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

```
<type>(<optional scope>): <summary in lowercase, imperative, no period>
```

| Type | Use for | Version bump |
|---|---|---|
| `feat` | A new feature players notice | minor |
| `fix` | A bug fix | patch |
| `perf` | A performance improvement | patch |
| `refactor` | Code changes with no behaviour change | none |
| `docs` | Documentation only | none |
| `test`, `build`, `ci`, `chore` | Tests, build, CI, maintenance | none |
| `revert` | Reverting an earlier commit | depends |

A breaking change adds `!` after the type (`feat!: ...`) and explains it in the
pull request body.

Examples:

```
feat: list config packs for game vehicles under Modded
fix: keep favourites above the Modded group
docs: add troubleshooting for the console warning
```

Commits inside your branch can be anything; only the title lands on `main`.

### Pull request checklist

- One topic per pull request.
- CI passes (formatting, lint, build, title).
- Player-facing changes add a line under `## [Unreleased]` in
  [CHANGELOG.md](CHANGELOG.md).
- The description says what you tested in game, on which game version.

### AI-assisted contributions

AI tools are welcome, but you're responsible for every line you submit: read it,
test it in game, and be able to explain it in review. Credit the tool as a
co-author in the commit message, as the maintainers do with Claude:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Releases (maintainers)

Paddock follows [Semantic Versioning](https://semver.org/). Until 1.0.0, minor
versions may change behaviour.

1. Open a pull request titled `chore(release): X.Y.Z` that:
   - sets `M.version` in `src/lua/ge/extensions/paddock.lua`;
   - moves the `[Unreleased]` entries in `CHANGELOG.md` under `## [X.Y.Z] - YYYY-MM-DD`
     and updates the links at the bottom;
   - updates the compatibility table in `README.md` if needed.
2. After it's merged, tag the merge commit and push the tag:

   ```bash
   git tag -a vX.Y.Z -m "Paddock X.Y.Z"
   git push origin vX.Y.Z
   ```

3. The release workflow checks the tag matches `M.version`, builds `paddock.zip`
   and publishes a GitHub Release with the changelog section. 0.x releases are
   marked as pre-releases.
4. Upload that same `paddock.zip` to the BeamNG repository.

## Game updates

Paddock supports the current BeamNG.drive version. After a game update, a
maintainer checks Paddock in game. If the selector changed, the fix is released as
a patch and the compatibility table in the README is updated.
