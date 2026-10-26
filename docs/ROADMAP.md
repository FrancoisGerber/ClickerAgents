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

## M2 — The full agent ladder  ✅ shipped

- All 12 agents in `game/data/agents.lua`, unlocked by zone
- Buy amounts ×1 / ×10 / ×100 / MAX from SELECT (START opens the pause menu)
- Clearing a zone stops the run there; X walks you through. Nothing advances on its own while you play.
- Ten global tools, bought with A and applied to throughput, probe damage and credits
- Skills bought with A on SKILLS, cast with X
- Agent list with scrolling, six visible rows, affordability colours

**Acceptance:** met — a greedy player that buys the cheapest agent level, then the next tool, and walks through every gate reaches **zone 100 at 1053 s (17.6 min)**, final zone 105 at 25 min. The assertion lives in `tests/headless.lua` and fails if it drifts outside 15–25 minutes, so the content numbers have to move, not the code.

## M3 — Bosses and the clock  ✅ shipped

- Boss zone every 5: one firewall, 30-second clock, triple payout
- A failed attempt pushes you back one zone with the gate still open, so you can farm the dps you are missing; credits are never lost
- Red pulsing timer under 10 s, drawn from the real `st.timer`
- Real-time accuracy: the timer uses `dt`, so a lagging frame does not steal a second

**Acceptance:** met. A player who refuses to enter a firewall they cannot break inside 30 s plays eight simulated hours: **zone 184, 36 firewalls broken, 0 failed**, best zone never regresses. The push-back rule guarantees the failure case is survivable by construction — the tests cover the clock, the push-back, the open gate and the re-armed timer.

**Known ceiling, not a boss problem:** zone 300 is roughly two simulated days at the current curve. Past zone ~140 the 1.145/zone HP tail outruns what the agent ladder can buy back (1.07^level costs against x4 damage every 25 levels), so each zone costs more time than the last. The boss rule is not the brake; the economy is. Options when it becomes a priority: cost growth 1.07 -> 1.05, milestones x6 instead of x4, or a gentler tail (1.08 gets zone 300 inside a simulated day).

## M4 — Ascension  ✅ shipped

- Rootkits from boss firewalls (zone ≥ 100) plus `totalAgentLevels / 2000`
- Unspent rootkits at +10% DPS each
- Prestige tab with a live "rootkits if you ascend now" figure and the daemon shop
- Wipes and keeps exactly as `DESIGN.md` says

**Acceptance:** ascend at zone 140, and the next run reaches zone 140 faster than the first — measured in simulated seconds, not vibes. Best zone and rootkits survive a quit/relaunch.

## M5 — Port shape  (code done, device acceptance pending)

- PortMaster pak: launcher, `port.json`, `gameinfo.xml`, `pm_finish`
- 720×480 verified on the desktop at the device's exact resolution; the card test is pending
- Offline progress with the 8-hour cap and a Welcome Back screen; the window is banked on
  load so the same hours cannot be paid twice
- Autosave on purchase, on walking into a zone, on ascension, every 60 s, on focus loss and
  on quit — `Save.sync` is the only beat
- `log.txt` in the port folder: the launcher tees stdout, and the game logs load, saves and
  binds into it
- STATS and ACHIEVEMENTS are live: lifetime kills, firewalls, playtime, per-agent DPS, and
  the eight achievements evaluate from run state

**Acceptance:** installed on the RG34XXSP, played for 30 minutes, powered off mid-run, relaunched — the run continues, the offline report is accurate, and the save is intact after three of those cycles. **Not yet verified: the device is off.**

## After v1

Ordered by what a player would miss first, not by what is easy:

1. **Rootkit spend** — buying back consumed systems as permanent perks, and the
   idle/active split that creates
2. **Crits and the skill layer** — six actives on the strip, cooldowns, crit rolls
3. **Auto-clickers** — the reward loop that makes leaving it running feel earned
4. **Gilds** — random agent buffs, one decision per 10 zones
5. **Second prestige layer** — only if the first one runs out of road before zone 1,500

Not planned: clans, mercenaries, relics, rubies, shop, ads, accounts, cloud saves.
