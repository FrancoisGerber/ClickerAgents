# Shipping this to PortMaster

PortMaster's requirements live on their site, not in this repo. This page records what they
ask for, where it is written, and how this port meets it — so a submission can be checked
without re-reading their docs.

Sources, checked 26 October 2026:

- Packaging guide — <https://portmaster.games/packaging.html>
- Porting overview — <https://portmaster.games/porting.html>
- the port repository — <https://github.com/PortsMaster/PortMaster-New>
- `port.json` generator — <https://portmaster.games/port-json.html>, README generator —
  <https://portmaster.games/port-markdown.html>

## What their packaging guide requires

A port is a directory under `ports/` named after the port, and it must contain:

| File | Required | Ours |
|---|---|---|
| `port.json` | yes | `port/port.json` |
| `README.md` | yes | `port/README.md` |
| `screenshot.png` or `.jpg` | yes | `port/screenshot.png` (720×480, captured from the game) |
| `gameinfo.xml` | yes | `port/gameinfo.xml` |
| `cover.png` or `.jpg` | optional | `port/cover.png` |
| `<Port Name>.sh` | yes, capitals, `.sh` | `port/ClickerAgents.sh` |
| `<portname>/` | yes, same name as the containing directory | `port/clickeragents/` |
| `licenses/` inside `<portname>/` | yes for open-source games | `port/clickeragents/licenses/` |

Their rules for the launcher: source `control.txt`, source `mod_${CFW_NAME}.txt` if present,
call `get_controls`, set `GAMEDIR`, tee output to `log.txt`, export `XDG_DATA_HOME` (or
`bind_directories`) so saves stay in the port folder, export
`SDL_GAMECONTROLLERCONFIG`, start gptokeyb with the port's `.gptk`, call `pm_platform_helper`
before launching and `pm_finish` at the end.

Their rules for `port.json`: `version`, `name` (the zip name), `items` (the script and the
port directory), and an `attr` block with `title`, `porter`, `desc`, `inst`, `genres`,
`image`, `rtr`, `runtime`, `reqs`, `arch`. For a game that runs on a supplied runtime, keep
`runtime: null`; the shipped LÖVE ports (Gone Fishing, 2048) still list `arch` as
`["aarch64", "x86_64"]`, and this port follows them.

Process notes from the same page: run `tools/prepare_repo.sh` after forking, put the port in
`ports/<portname>/`, keep script and directory names unique across the whole repo, and get
the port tested in the `#testing-n-dev` channel — a pull request without documented testing
is not accepted. Nintendo-adjacent or decomp ports go to `PortMaster-MV-New` instead; this
is an original game, so the normal repo applies.

## Ours, line by line

- **Runtime, not a binary.** LÖVE 11.5 comes from PortMaster (`runtimes/love_11.5`), so the
  pak carries no executable and no libs: `rtr: true`, `reqs: []`. The launcher sources
  `love.txt` and runs the `.love`.
- **No external game files.** Nothing to supply, nothing to patch — the `.love` is the game.
- **Saves.** `XDG_DATA_HOME` points at `clickeragents/saves`, so the save travels with the
  folder. `Save.sync` writes on purchase, zone change, ascension, every 60 s, on focus loss
  and on quit.
- **Input.** `clickeragents.gptk` maps the buttons, and the game reads that file at load, so
  the mapping in the pak is the mapping the game uses. The suite fails if they disagree.
- **Licence.** GPL-3.0-or-later, and the `.love` is a zip of the source, so distributing the
  port distributes the source. `licenses/` carries the licence and a note on the runtime.
- **Logs.** The launcher tees stdout to `clickeragents/log.txt`; the game logs load, save and
  binding lines into it.

## Checks to run before a submission

```sh
tools/test.sh                 # syntax + 390 headless checks
tools/build.sh                # game/ -> clickeragents.love -> ClickerAgents.zip
unzip -l ClickerAgents.zip    # the file list above must all be there
tools/push.sh [host]          # install on a handheld and verify by hash
```

Then: play it on the device for a session, note the device and firmware in the pull request,
and get a second pair of eyes in `#testing-n-dev`. Their guide is explicit that untested
pull requests are rejected.
