# Roadmap

Five milestones, all shipped. Each one was playable when it landed, and each one carries an
acceptance number that the headless suite asserts, so tuning cannot quietly break the pacing.

## M0 — The shell ✅

Nine screens, input driven entirely by the gptk, layout at 720×480, 640×480 and 720×720,
procedurally drawn sprites, logo, pak.

**Acceptance:** the suite draws every screen at three sizes with no rect outside the canvas,
and the gptk agrees with the game on every binding.

## M1 — One agent, one vuln ✅

- Vuln HP, credits per kill, ten kills to a zone
- DPS tick, probe damage, kill → next vuln
- The agent ladder: `cost × 1.07^(level-1)`, ×4 damage at level 25 and every 25 levels after
- Battle screen with the target, HP bar, credits and throughput
- Save on quit, load on launch

**Acceptance:** a fresh run reaches zone 10 inside four minutes, and a quit/relaunch continues
at the same credits, level and zone.

## M2 — The full ladder ✅

- Twelve agents, unlocked by zone, four buy amounts (×1 / ×10 / ×100 / MAX on SELECT)
- Ten global tools, bought with A, applied to throughput, probe damage and credits
- Twelve skills bought with A on SKILLS, cast with X, one buff each
- Clearing a zone stops the run there: X walks you on. Nothing advances on its own while you
  play — the agents' throughput is the only automation.
- Lists longer than their panel scroll with a `n/N` counter

**Acceptance:** met — a greedy player that buys the cheapest agent level, then the next tool,
and walks through every gate reaches **zone 100 at 1,004 s (16.7 min)**, with the final zone at
zone 105 inside 25 minutes. The assertion lives in `tests/headless.lua` and fails if it drifts
outside 15–25 minutes, so the content numbers have to move, not the code.

## M3 — Bosses and the clock ✅

- A firewall every fifth zone: one target, 30 s, triple payout, `10 × vuln HP`
- A failed attempt pushes you back one zone with the gate open, so you can farm what you are
  missing; credits are never lost
- The clock is drawn from `st.timer`, pulsing under 10 s, and it lives on the arena bar
- Killing the firewall leaves its stats on the vuln that replaces it (`bossFarm`), so a cleared
  boss zone never pays less than the boss did

**Acceptance:** met. A player who refuses to enter a firewall they cannot break in 30 s plays
eight simulated hours without regressing their best zone; the suite covers the clock, the
push-back, the re-armed timer and the farmed-boss state.

## M4 — Ascension ✅

- The gate is zone 100, and it **doubles with every system you take**: 100, 200, 400, 800
- Rootkits: `floor(totalAgentLevels / 2000) + firewalls broken this run`
- Unspent rootkits are +10% throughput each, permanently
- Ten daemons bought with rootkits: probes, throughput, credits, probe damage, firewall
  seconds, an extra rootkit per ascension, offline hours
- Ascension wipes credits, agent levels, tools and zone, and hands nothing back — the first
  Spider of a new run costs its printed price like a new save

**Acceptance:** met — a first run reaches zone 140 at 7,739 s with 31 rootkits, and the second
run reaches zone 100 in 580 s against the first run's 1,004 s. Rootkits and best zone survive
a quit and relaunch.

## M5 — Port shape ✅

- PortMaster pak: launcher, `port.json`, `gameinfo.xml`, cover, `pm_finish`
- 720×480 verified on the desktop at the device's exact resolution and on the card
- Offline progress with the 8-hour cap and a Welcome Back screen; the window is banked on
  load so the same hours cannot be paid twice
- Autosave on purchase, on zone change, on ascension, every 60 s, on focus loss and on quit
- `log.txt` in the port folder
- STATS and ACHIEVEMENTS live: lifetime kills, firewalls, playtime, per-agent throughput, and
  ten achievements evaluated from run state

**Acceptance:** installed on the RG34XXSP and the RG34XX, played, powered off mid-run and
relaunched — the run continues and the save is intact. Pushes verify every file by hash.

## After v1

What a player would miss first, in order:

1. **A deeper skill layer** — more than one buff per agent, and crit rolls
2. **Gilds** — random agent buffs, one decision every ten zones
3. **A second prestige layer** — only if the first runs out of road before zone 1,500
4. **Zone-300 economy work** — past zone ~140 the HP tail outruns the agent ladder; the levers
   are cost growth 1.07 → 1.05, a bigger milestone step, or a gentler tail

Not planned: clans, mercenaries, relics, rubies, shop, ads, accounts, cloud saves.
