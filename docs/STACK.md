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
├── conf.lua            identity, window 720×480, modules
├── main.lua            boot, scene switch
├── sim/                pure Lua: no love.* calls, fully testable
│   ├── numbers.lua     formatting, fixed-point helpers
│   ├── formulas.lua    vuln HP, costs, milestones, rootkits
│   ├── combat.lua      probes, kills, zones, boss clock
│   ├── save.lua        snapshot, serialise, offline replay
│   ├── combat.lua      DPS ticks, clicks, boss timer
│   └── save.lua        serialize / deserialize / versioned
├── ui/                 screens: battle, stats, prestige, menu
└── data/               heroes.lua, biomes.lua, upgrades.lua — the CONTENT tables
```

The one rule that matters: **`sim/` never calls `love.*`**. That is what makes it testable on the desktop without a window, and what lets an agent run a thousand simulated zones in a second.

## PortMaster pak layout

```
ports/
├── ClickerAgents.sh          launcher
└── Clicker Agents/
    ├── clickeragents.love    the game
    └── saves/            XDG_DATA_HOME, created on first run
```

`port.json` declares `arch: [aarch64, x86_64]` (LÖVE is architecture-agnostic once the runtime exists) and `rtr: true` with empty `reqs` — there are no external files to supply, which is the whole point of an original game.

Knulli reads ports from `/userdata/roms/ports`, muOS from `/roms/ports`. The launcher should behave like every other PortMaster script: source `control.txt`, call `get_controls`, export `XDG_DATA_HOME` into the port's own folder, pipe output to `log.txt`, and call `pm_finish` on exit.

## Save files

- `love.filesystem` writes into `$XDG_DATA_HOME/clickeragents/`, which the launcher points inside the port folder — so saves travel with the port when the SD card moves.
- Format: JSON, one file, with `version` at the top. On load, unknown versions migrate or are refused with a message; never silently reset.
- Autosave: on purchase, on zone change, and every 60 seconds. The RG34XXSP's power button kills the process without warning.

## Testing on this machine

```sh
sudo pacman -S love
love game                 # run
luajit tests/run.lua      # headless sim tests, no window
```

The simulation tests are the important ones: vuln HP at zones 1/50/140/500 against the formula, agent cost at levels 1/25/200, rootkits at zones 100/150/250/500, and a full offline simulation of 8 hours landing on a sane zone.

## Performance

The H700 is four Cortex-A53s with a Mali-G31 — no problem for a 2D game drawing a few hundred rectangles. The budget to respect:

- Recompute DPS on purchase only, never per frame.
- One `love.graphics.print` per text run, batched by screen, with a cached font.
- Draw the agent list as 6 rows, not 12 — scroll, do not render what is off-screen.
- Target 60 fps, and accept 30 while a boss timer runs; the timer must still tick at real seconds, so use `dt` accumulation, not frame counts.

## Licence compliance

GPL-3.0-or-later for this project. LÖVE is zlib (GPL-compatible). PortMaster is redistributed by its own project, not bundled here. The `.love` is a zip of source, so distributing the game *is* distributing the source — which satisfies the GPL naturally and is worth stating in the README.
