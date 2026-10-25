# Clicker Agents

An open-source idle (incremental) RPG for PortMaster handhelds — built to be played on the Anbernic RG34XXSP's 3.4" 720×480 screen with a D-pad and four face buttons.

You are a rogue intrusion framework with no owner and no account. Deploy **agents**, tear
through **vulns**, break the **boss firewall** every fifth zone, and when a system's CORE
falls, consume it and move to a bigger target. Credits buy better agents; **rootkits**
survive the reset.

- **Licence:** GPL-3.0-or-later (`LICENSE`)
- **Runtime:** LÖVE 11.5, supplied by PortMaster — the port ships as a `.love` file, no compiled binary
- **Target:** Anbernic RG34XXSP (Allwinner H700, 720×480), Knulli or muOS with PortMaster
- **Status:** all seven screens and the full input/selection layer are in; no combat simulation yet.

## Design

| Document | What is in it |
|---|---|
| [`docs/DESIGN.md`](docs/DESIGN.md) | The fiction, and every mechanic with its formula: throughput, probes, layers, boss firewalls, rootkits |
| [`docs/CONTENT.md`](docs/CONTENT.md) | The v1 content tables — 12 agents, 10 systems, 6 layers, tooling, skills, achievements |
| [`docs/UI.md`](docs/UI.md) | Layout profiles and derived anchors, the button map, screens, number formatting |
| [`docs/STACK.md`](docs/STACK.md) | Why LÖVE, how the PortMaster pak is laid out |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | M1–M5, each with an acceptance check |

## Layout

```
Clicker Agents/
├── game/       the LÖVE project: main.lua, layout.lua, font.lua, conf.lua
├── port/       PortMaster pak: ClickerAgents.sh, port.json, gameinfo.xml, clickeragents/
├── tests/      headless suite: three screen sizes, input, gptk agreement
├── tools/      build, test, capture and push scripts
├── docs/       design, content, UI, stack, roadmap
├── .device     handheld address and Samba password (chmod 600, never committed)
└── LICENSE     GPL-3.0-or-later
```

## Run it on a computer

```sh
love game                    # LÖVE 11.5; x buys, z clicks, q/e tabs
```

## The four commands

```sh
tools/test.sh                # syntax check + headless suite, all three screen sizes
tools/build.sh               # game/ -> clickeragents.love -> port/ -> ClickerAgents.zip
tools/push.sh                # build, SMB to the handheld, verify each file by hash
tools/screens.sh             # capture every screen to design/ (Xvfb, no desktop needed)
tools/shots.sh               # capture 720x480, 640x480 and 720x720 layout checks
```

`push.sh` needs `.device` — copy `.device.example` and fill it in. Enable Samba on the
handheld first (System Settings → Network); the port then appears under Ports and
launches from there.

`design/` is gitignored: it holds nothing but captures that `screens.sh` regenerates.

## Licence notes

- Code: GPL-3.0-or-later.
- LÖVE is zlib-licensed and GPL-compatible; PortMaster supplies the runtime, this repo does not redistribute it.
- Art and audio are drawn or synthesised in code in v1, so no third-party asset licensing applies. Any future third-party asset must be CC0 or CC-BY-4.0 to stay GPL-compatible.
