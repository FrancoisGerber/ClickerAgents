# Stack

## LÖVE 11.5, as a PortMaster port

The game is Lua on LÖVE, shipped as a `.love` file (a zip of the project). PortMaster supplies the LÖVE runtime for aarch64, so the port itself contains **no compiled binary** — the launcher sources PortMaster's runtime and runs the `.love`.

This reverses an earlier recommendation of C++17 + SDL2, and the reason is the target changing. That argument was about avoiding a runtime dependency when targeting the device directly. Now the target *is* PortMaster, the runtime is already installed on the handheld, and every objection turns into an advantage:

| | LÖVE | C++17 + SDL2 |
|---|---|---|
| Build step | none — zip the folder | cross-compile with zig or aarch64-gcc |
| Iteration | `love game`, instantly | compile, deploy, run |
| Runtime dependency | PortMaster's `love_11.5` | none, but you own the ELF and libc floor |
| Compile-time checks | none | catches a whole class of agent bugs |
| Right for a UI-and-numbers game | yes | yes, with more code |

For an agent-built game whose entire content is text and rectangles, the fast loop wins. The missing type checking is real and is answered by tests instead of the compiler — see `ROADMAP.md`, every milestone carries a headless test.

**Escape hatch:** if the LÖVE runtime ever proves unreliable on the H700, the same design ports to SDL2 unchanged — the simulation is pure Lua tables in `sim/` and never touches `love.*`, so only the input/ draw layer would be rewritten.

## Project layout

```
game/
├── conf.lua            identity, window 720x480, LÖVE modules
├── main.lua            boot, routing, the frame
├── config.lua          palette, type, version
├── tuning.lua          every balance value in the game, and nothing else
├── layout.lua          screen size -> anchors (panelH, panelRows, battle column)
├── font.lua            5x7 bitmap font, drawn from a glyph table
├── core/               binds.lua (reads the gptk), numbers.lua (K/M/B/T), log.lua
├── data/               agents, skills, upgrades, systems (daemons), achievements
├── sim/                state, formulas, economy, combat, buffs, prestige, save, achievements
├── ui/                 draw primitives, widgets, sprites, chrome (top bar + hints), toast
├── screens/            one file per screen: splash, welcome, battle, skills, upgrades,
│                       prestige, achievements, stats, menu
└── app/actions.lua     everything a button press can do
```

The one rule that matters: **`sim/` never calls `love.*`**. That is what makes it testable on
the desktop without a window, and what lets a test run thousands of simulated seconds in a
second. `ui/` and `screens/` are the only layers that know a graphics API exists.

## PortMaster pak layout

```
port/
├── ClickerAgents.sh                launcher
├── port.json                       catalogue metadata
├── gameinfo.xml                    entry for frontends that read it
├── README.md                       notes, controls, build steps (required by PortMaster)
├── screenshot.png                  720x480 capture, required
├── cover.png                       optional catalogue art
└── clickeragents/
    ├── clickeragents.love          the game: a zip of game/
    ├── clickeragents.gptk          the button map the game reads at load
    ├── images/{cover,logo}.png     art the pak itself uses
    └── licenses/                   GPL-3.0 text and what the runtime brings
```

On the card that lands as `roms/ports/ClickerAgents.sh` next to `roms/ports/clickeragents/`,
and the launcher points `XDG_DATA_HOME` at `clickeragents/saves` so a save travels with the
folder. `port.json` declares `rtr: true` with empty `reqs`: there are no external game files
to supply, which is the whole point of an original game.

Knulli reads ports from `/userdata/roms/ports`, muOS from `/roms/ports`. The launcher behaves
like every other PortMaster script: source `control.txt`, `get_controls`, export
`XDG_DATA_HOME`, tee output to `log.txt`, source the `love_11.5` runtime, `pm_finish` on exit.

## Save files

- `love.filesystem` writes into `$XDG_DATA_HOME/clickeragents/save.lua` — a Lua table
  literal, not JSON, so it loads without a parser and reads as plain data in a diff.
- `version = 2` sits at the top of the snapshot. `Save.apply` copies what it knows onto a
  fresh run and leaves anything it does not understand at its default, so an older save
  loads into a newer build without a migration step.
- Autosave: on purchase, on zone change, on ascension, every 60 s, on focus loss and on
  quit — all through `Save.sync`, which is the only beat that writes.
- Offline replay: the time away is replayed through the same combat rules, capped at eight
  hours (plus anything SENTRY buys), and never paid twice.

## Testing on this machine

```sh
tools/test.sh             # luac -p over every file, then the headless suite
tools/build.sh            # game/ -> clickeragents.love -> port/ -> ClickerAgents.zip
tools/push.sh [host]      # build, SMB to a handheld, verify every file by hash
love game                 # play it; x buys, z probes, q/e tabs
```

`tests/headless.lua` runs 390 checks with a stubbed `love`: three screen sizes with no rect
outside the canvas, the formulas, the tick, buying, the save round trip and offline replay,
the gptk contract, the menu, the ascension reset and the pacing acceptance numbers.

## Performance

The H700 is four Cortex-A53s with a Mali-G31 — no problem for a 2D game drawing a few hundred rectangles. The budget to respect:

- Recompute DPS on purchase only, never per frame.
- One `love.graphics.print` per text run, batched by screen, with a cached font.
- Draw only the rows that fit (`L.panelRows`, 9 at 720x480) and scroll the rest — 12 agents
  and 10 daemons do not fit, and drawing them anyway is free work for pixels nobody sees.
- Target 60 fps, and accept 30 while a boss timer runs; the timer must still tick at real seconds, so use `dt` accumulation, not frame counts.

## Licence compliance

GPL-3.0-or-later for this project. LÖVE is zlib (GPL-compatible). PortMaster is redistributed by its own project, not bundled here. The `.love` is a zip of source, so distributing the game *is* distributing the source — which satisfies the GPL naturally and is worth stating in the README.
