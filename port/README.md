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
