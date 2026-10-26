# Design

**Clicker Agents** is an idle (incremental) RPG about a rogue intrusion framework that
eats computer systems. You are the framework. Your **agents** break into a target, their
throughput tears through **vulns**, and when the last zone falls the system is consumed
and a bigger one opens.

## 1. The fiction

Something escaped a lab. It has no owner, no operator, no account — it is a framework that
runs itself and grows by consuming the systems it breaks into. Every run is one
**system**: a company, an agency, a utility. Nobody authorised any of this.

That premise is what makes the loop make sense:

- You do not hire heroes, you **deploy agents** — specialists, cheap to expensive.
- You do not kill monsters, you **consume vulns** — open ports, orphaned accounts, public
  buckets, unpatched appliances. Each one is a real finding with a real name.
- You do not beat bosses, you break a **boss firewall** before it closes the hole.
- You do not earn gold, you take **credits** — they were always in the system.
- You do not "ascend" in the abstract, you run out of system: the run ends, the target is
  consumed, and the next one opens.

## 2. The loop

1. Vulns surface. Your **DPS** (throughput) drains them continuously; **A on the vuln**
   adds a manual probe.
2. Clearing a vuln pays **credits**.
3. Credits deploy more **agents** — each is a flat throughput number that scales with level.
4. Clearing the zone's vulns moves you one zone deeper. Every **5th zone** is a
   **boss firewall** with a **30-second timer**.
5. Ascend at zone 100: the system is consumed, you keep **rootkits**, and the next
   system starts harder.

Four time scales, deliberately: seconds (probes and skills), minutes (a zone), hours
(a system), days (a campaign across systems).

## 3. Targets — one system, one zone at a time

A run walks the same six bands of security in whatever you are eating. **Zone** is the
word for all of it: the counter, the best-zone record, the achievement text and what a
failed firewall pushes you back to. The six names below are zone names, not a second
unit.

| Zones | Name | What lives there |
|---|---|---|
| 1–20 | **EDGE** | open ports, default creds, exposed API keys, stale TLS |
| 21–40 | **IDENTITY** | orphaned accounts, weak MFA, shared passwords |
| 41–60 | **NETWORK** | trusted subnets, DNS cache poisoning, open relays |
| 61–80 | **ENDPOINT** | unpatched build servers, signed driver loads, CI runner shells |
| 81–99 | **DATA** | public buckets, plain backups, SQL injection |
| 100+ | **CORE** | domain trust, ROOT CA misuse, kernel modules |

The system ladder is fictional but deliberately plausible — a mid-market SaaS company
first, a ministry last. Each system skews its zones: banks are identity-heavy, hospitals
are endpoint-heavy, utilities keep the CORE behind an air gap.

## 4. Damage — two channels

| Channel | Source | Scales with |
|---|---|---|
| Throughput (DPS) | every deployed agent, summed, then multiplied | agent levels and multipliers |
| Probe | `1.5 × total DPS` per press | your throughput, so a tap always outruns waiting |

- **Probe base:** `probeDamage = probeUpgrades × 1.5 × totalDPS`, with a floor of 1 so a
  fresh save can still open. **Clicking is never the slower way to kill something**: one
  press is worth a second and a half of the agents' output at every zone and every level,
  so a steady tap beats idling and holding the button beats it by an order of magnitude.
  `Formulas.PROBE_SHARE` is the single number that sets this ratio.
- **Probe rate:** one press, one probe. There is no artificial cap yet; the 10-per-second
  figure this line used to promise is unimplemented, and the button has no auto-repeat.
- **Crits (v1.1):** 0% chance, ×10 damage, bought through tooling. Off in v1.
- **Skills:** six actives, one per agent, 30 seconds each on a 30–180 s cooldown. Bought
  and cast on the SKILLS tab: **A** buys, **X** fires, and a running cooldown refuses the
  second press with the seconds left.

Total DPS is recomputed only when something is bought, never per frame:
`totalDPS = Σ(agent.levelDPS × agent.mults) × globalMults`.

## 5. Zones and vulns

- **Vulns per zone:** 10. (Depth scaling and the "fewer vulns" upgrade are v1.1.)
- **Boss zones:** every 5th zone — one boss firewall, **30 seconds**, paying triple.
  Fail and the perimeter closes: you lose the attempt, not your credits, and you are
  pushed back one zone with the gate still open so you can farm the dps you lack.
- **Vuln HP:**

  ```
  L ≤ 140:        H(L) = 10 × 1.55^(L−1) + 10 × (L−1)
  L > 140:        H(L) = H(140) × 1.145^(L−140)
  ```

  The linear term at shallow depth keeps zone 1–10 from feeling like a wall; the
  exponential tail is what makes depth expensive.

- **Boss HP:** `10 × H(L)`. A boss firewall is ten vulns in one health bar with a clock.
- **Credits per vuln:** `G(L) = 0.05 × H(L)` (tunable), boss ×3, treasure chest ×10 on a
  1% roll. Credits grow with the same exponential as HP — that is what lets agent prices
  explode without the economy breaking.

## 6. Agents

Each agent is a row: codename, base cost, base DPS at level 1, and a specialism.

- **Cost of the next level:** `floor(baseCost × 1.07^(level − 1))`.
- **Damage milestones:** at levels 25, 50, 75, 100 and then **every 25 levels from 200**,
  throughput is **×4**.

The two curves nearly cancel: cost grows 7% per level, damage grows `4^(1/25) = 5.7%` per
level. Levelling one agent forever cannot keep up with vuln HP that grows 14.5% per zone.
**You are meant to deploy the next agent, not stack the current one.** Every balance
decision in this game follows from that gap.

- **Tooling** — the ten global upgrades — gives credits somewhere to go besides agent
  levels (`+10% all throughput`, `+25% probe damage`, `+50% credits`).
- **v1 roster:** 12 agents, listed with cost and DPS in `CONTENT.md`.

## 7. Ascension — the next system

- **Unlocks:** at zone 100, when CORE is in reach — and the gate doubles with every
  ascension you take: 100, then 200, 400, 800. Each system has to reach twice as deep
  as the last before it can be cashed in. A visible confirm screen, not a hidden
  purchase — a handheld player should not have to discover a 1.9e19 purchase.
- **Wipes:** credits, agent levels, tooling, zone (back to 1), skill unlocks. Nothing is
  handed back for free: a new system has an empty roster, so the first Spider is bought
  again with the same 12 credits a brand-new save needs.
- **Keeps:** rootkits, systems breached, best zone, total playtime.
- **Rootkits earned:**

  ```
  rootkits = floor(totalAgentLevels / 2000) + firewalls defeated this run
  ```

  Both halves are counted, not estimated: `Prestige.rootkits_on_offer` sums the agent
  levels you paid for and the firewalls you actually broke. (An earlier draft quoted a
  per-boss curve, `((n + 4) / 5) ^ 1.3`, whose examples — 1 at zone 100, 20 at 150, 137 at
  250 — did not follow from the formula itself. Counting is what the game does.)

- **Unspent rootkits are +10% throughput each.** Persistence is what a rootkit is: the
  part of you the next system inherits. Holding them is a real decision at every ascension.
- **Rootkit spend:** four daemons, permanent, bought with rootkits on the PRESTIGE tab —
  CRON 5 (+1 probe/s), WATCHDOG 12 (+15% credits), BEACON 30 (+10% throughput), HONEYPOT 75
  (+10 s on every firewall). Holding is +10% each; spending trades that for a flat effect,
  so the mix is the decision at every ascension.

## 8. Numbers

Doubles hold exact integers to 9.0e15 and approximate up to 1.8e308. Some idlers push to
1e100000 for the vanity of it; Clicker Agents stays inside doubles.

- **Representation:** every quantity is a double.
- **Display:** `1.23K / M / B / T / aa / ab …` — two decimals below 100, none above.
- **Ceiling:** content ends around **zone 1,500 ≈ 1e90 HP**. Beyond that the numbers stop
  being readable on a 3.4" screen, which is a worse failure than running out of exponents.
  If the game ever needs to go higher, a `BigNum` as `(mantissa, exponent)` is the escape
  hatch — a v3 decision, not a v1 one.

## 9. Idle, offline, and the clock

The handheld has a real clock, so offline progress works properly.

- **On quit:** save a timestamp.
- **On launch:** `elapsed = now − saved`, capped at **8 hours** (beyond that, farming
  stops being interesting and the numbers get silly).
- **Simulation:** advance zones while your throughput beats the zone's HP inside a
  5-second budget per vuln, then **stop at the first boss firewall you cannot break in
  30 seconds** — you always return to a decision, never to a wall you slept through.
- **Report:** a Welcome Back screen listing zones gained, credits earned, and where the
  framework stalled.

## 10. What is deliberately not in this game

No accounts, no shop, no ads, no in-app purchases, no cloud saves, no clans, no
mercenaries, no relics, no daily quests. This is a GPL game for a handheld: there is
nobody to sell anything to, and every one of those systems costs a screen a 3.4" display
does not have.

## 11. Tuning targets

| Milestone | Target |
|---|---|
| First vuln | 3 probes clears it |
| First agent | affordable at zone 2, credits spent within 30 s of starting |
| Zone 5 boss firewall | passable without any upgrade |
| Zone 100 (CORE) | 15–25 minutes of play |
| First ascension | 25–40 minutes |
| Second system | 15 minutes, reaching zone 150 |

## Pacing rule

Nothing moves the player on. The tenth kill opens the gate to the next zone but does
not walk through it: the player stays in the zone and keeps farming credits, with the
agents still killing whatever spawns, until they press **X** to advance. That pause is
the upgrade window — bank credits, level agents, then move on. Autobuy and auto-zone
are forbidden during play; the only automation is the agents' own throughput, and the
only place zones advance unattended is the offline replay on launch.

## 11. Where the numbers live

Every value that changes how the game plays is in **`game/tuning.lua`** and nowhere else:
zone and firewall counts, the vuln HP curve and where it changes shape, the credit share,
agent cost growth and damage milestones, probe share, skill duration and magnitudes, the
ascension gate and rootkit rate, and the save cadence.

The file holds *balance*, not content. What an individual agent costs, what a tool does and
what a skill is called stay with their rows in `data/`, because those are edited item by
item. Nothing in `sim/` is allowed to keep a private copy of a tuned constant: if two
modules need a number, it lives in `tuning.lua` and both read it.

The suite proves it rather than trusting it — it moves `probe.share`, `vuln.linear` and
`agent.cost_growth` at runtime and watches the formulas follow, then greps the sim modules
for the old literals.

## 12. A beaten firewall

Killing the firewall opens the gate but does not shrink the target: `advance()` sets
`boss = false` and `bossFarm = true`, and the vuln that takes its place keeps the
firewall's HP and its three-times payout. Every respawn in that zone keeps those numbers
until `X` moves the run on, which clears the flag for the new zone.

Walking back to a firewall zone you have already beaten (`travel_to`) sets the same flag,
so an old boss zone arrives open, at boss scale, with no clock to beat.

## 13. What one press is worth

`probe.share = 1.5` at zone 1, falling on a half-life of `probe.half_life = 70` zones and
settling on `probe.share_floor = 1.06`: ×1.225 at zone 100, ×1.171 at 140, ×1.083 at 300.
Clicking always beats waiting, but the margin shrinks as the agents take over, and the
economy enforces at least `dps + 1` so rounding can never tie them.
