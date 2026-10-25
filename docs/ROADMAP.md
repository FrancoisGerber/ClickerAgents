# Roadmap

Five milestones. Each one is playable when it is done — that is the acceptance test. No milestone leaves the game in a state you cannot run for five minutes and learn something from.

## M0 — The shell (done)

Seven screens, input driven entirely by the gptk, layout at 720×480, 640×480 and
720×720, procedurally drawn sprites, logo, pak. Everything on them was fake
until M1 landed.

**Acceptance:** the headless suite draws every screen at three sizes with no rect
outside the canvas, and the gptk agrees with the game on every binding.

## M1 — One agent, one vuln (done)

- `sim/world.lua`: vuln HP, credits per kill, zone progression, 10 kills per zone
- `sim/combat.lua`: DPS tick, click damage, kill → next vuln
- The agent ladder with 1.07 cost scaling and the ×4 milestones
- Battle screen with a vuln, HP bar, credits, DPS
- Save/load on quit

**Acceptance:** start fresh, reach zone 10 in under four minutes, quit, relaunch, and continue at zone 10 with the same credits and level. A headless test asserts vuln HP and agent cost against the formulas at zones 1, 5, 50 and 140.

## M2 — The full agent ladder

- All 12 agents in `game/data/agents.lua`, unlocked by zone
- Buy amounts ×1 / ×10 / ×100 / MAX from the START button
- Ten global tools
- Agent list with scrolling, six visible rows, affordability colours

**Acceptance:** a scripted player that only buys MAX on the newest affordable agent reaches **zone 100 in 15–25 minutes** of simulated time. That simulation is the balance test — if it lands outside the window, the content numbers change, not the code.

## M3 — Bosses and the clock

- Boss zone every 5: one vuln, 30-second timer, failure resets the zone
- Red pulsing timer under 10 s
- Real-time accuracy: the timer uses `dt`, so a lagging frame does not steal a second

**Acceptance:** a boss you cannot beat fails exactly once and puts you back on the same zone with credits intact. Simulated over 300 zones, no boss is ever unwinnable *and* unavoidable — every one can be passed by buying something.

## M4 — Ascension

- Rootkits from boss firewalls (zone ≥ 100) plus `totalAgentLevels / 2000`
- Unspent rootkits at +10% DPS each
- Prestige tab with a live "rootkits if you ascend now" figure and the daemon shop
- Wipes and keeps exactly as `DESIGN.md` says

**Acceptance:** ascend at zone 140, and the next run reaches zone 140 faster than the first — measured in simulated seconds, not vibes. Best zone and rootkits survive a quit/relaunch.

## M5 — Port shape

- PortMaster pak: launcher, `port.json`, `gameinfo.xml`, `pm_finish`
- 720×480 verified on the device with no letterboxing and no OS cursor
- Offline progress with the 8-hour cap and a Welcome Back screen
- Autosave on purchase, zone change and every 60 s
- `log.txt` in the port folder for bug reports

**Acceptance:** installed on the RG34XXSP, played for 30 minutes, powered off mid-run, relaunched — the run continues, the offline report is accurate, and the save is intact after three of those cycles.

## After v1

Ordered by what a player would miss first, not by what is easy:

1. **Rootkit spend** — buying back consumed systems as permanent perks, and the
   idle/active split that creates
2. **Crits and the skill layer** — six actives on the strip, cooldowns, crit rolls
3. **Auto-clickers** — the reward loop that makes leaving it running feel earned
4. **Gilds** — random agent buffs, one decision per 10 zones
5. **Second prestige layer** — only if the first one runs out of road before zone 1,500

Not planned: clans, mercenaries, relics, rubies, shop, ads, accounts, cloud saves.
