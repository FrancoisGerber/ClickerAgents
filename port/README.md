## Notes

Clicker Agents is an idle (incremental) RPG about a rogue intrusion framework. Deploy
agents, tear through vulns, and break the boss firewall every fifth zone before its
30-second clock runs out. When a system's CORE falls, ascend: the run resets, the rootkits
stay, and every rootkit is +10% throughput forever. No accounts, no network, no shop, no
ads.

Twelve agents, twelve skills, ten tools, ten daemons, ten achievements, ten systems, six
security layers. Saves live in `clickeragents/saves/` and travel with the folder.

Written in Lua on LÖVE 11.5, drawn entirely in code — the only image assets are the logo
and the cover.

## Screens

The layout follows the window's aspect ratio rather than the device, so it fills whatever
panel it finds: 3:2, 16:9, 4:3 and 1:1 all work, with the font fixed at 12 px and the list
showing as many rows as fit. Played on a 720×480 RG34XXSP and RG34XX, a 720×720 XF40H and a
640×480 D007 Plus; the 960×544, 1280×720 and 800×600 sizes are covered by the test suite.

Source: https://github.com/FrancoisGerber/ClickerAgents

License: GPL-3.0-or-later. The `.love` is a zip of the source, so the port distributes the
source with the game.

## Controls

| Button | Action |
|--|--|
| D-pad up / down | move the agent selection (or the row cursor on list screens) |
| D-pad left / right | buy amount −1 / +1 (1 to 100; 0 is MAX) |
| A | buy the selected agent, tool or skill; activate elsewhere |
| B | one manual probe into the vuln; on list screens, back to battle |
| X | go to the zone you are looking at, or advance a cleared zone; cast a skill on SKILLS |
| Y | unused, reserved |
| L1 / R1 | previous / next tab |
| L2 / R2 | step the zone cursor back / forward |
| START | pause menu (stops the clock and saves) |
| SELECT | cycle the buy amount |

## Compile

The port ships Lua source in a `.love`; there is nothing to compile.

```sh
git clone https://github.com/FrancoisGerber/ClickerAgents.git
cd ClickerAgents
tools/build.sh      # game/ -> clickeragents.love -> ClickerAgents.zip
tools/test.sh       # luac -p plus the headless suite
```
