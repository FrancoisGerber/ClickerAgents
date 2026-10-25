# Content — v1

Small on purpose. Twelve agents, six security layers, ten tools. Every number here is data,
not code: the game loads these from tables so content can be tuned without touching the loop.

## Agents

You are the framework; agents are what it deploys. Cost is the level-1 price; the next
level is `floor(cost × 1.07^level)`. Damage is throughput at level 1, and the level-200
milestone rule (`×4` every 25 levels) applies to every agent.

| # | Agent | Base cost | Base DPS | Deploys at | Specialism |
|---|---|---|---|---|---|
| 1 | Spider | 5 | 0 | zone 1 | crawler: finds the surface, +1 probe damage per level |
| 2 | Pick | 50 | 5 | zone 1 | credential spray, first real throughput |
| 3 | Bait | 250 | 22 | zone 4 | social engineering, converts people into access |
| 4 | Splice | 1,000 | 74 | zone 8 | injection: RCE, SQLi, deserialisation |
| 5 | Relay | 4,000 | 245 | zone 13 | pivots; stronger the deeper you already are |
| 6 | Grind | 20,000 | 1,000 | zone 19 | hash cracking, works while you are away |
| 7 | Cicada | 100,000 | 4,300 | zone 26 | droppers and persistence on endpoints |
| 8 | Mule | 400,000 | 17,000 | zone 34 | exfiltration and staging |
| 9 | Taint | 2,000,000 | 75,000 | zone 43 | supply chain: one dependency, everything downstream |
| 10 | Hush | 10,000,000 | 320,000 | zone 53 | wireless and implants, walks past a perimeter |
| 11 | Badge | 50,000,000 | 1,400,000 | zone 64 | insider: buys a human instead of a hole |
| 12 | Onyx | 250,000,000 | 6,000,000 | zone 76 | endgame framework, multiplies every other agent |

Each agent costs roughly 4–6× the previous one and deals about 4× its throughput, so a new
agent is always worth more than levelling the last one — that is the whole point of the
7%-cost / 5.7%-damage gap.

## Systems and layers

Each run is one **system**. Ascending consumes it and opens the next, harder target.

| # | System | What it is |
|---|---|---|
| 1 | Vantel Systems | mid-market SaaS, sloppy, the tutorial target |
| 2 | Brindle & Roe | boutique law firm: secrets, small attack surface |
| 3 | Meridian Freight | logistics: OT networks and tracking telemetry |
| 4 | Corvid Analytics | data broker; the DATA layer is the whole point |
| 5 | Halcyon Diagnostics | hospital group: legacy endpoints, patient records |
| 6 | Kestrel Mutual | insurer: identity fortress, weak suppliers |
| 7 | Vehicle Registry | government, ancient CORE, huge volume |
| 8 | Calder Power | grid operator: air gap and physical security |
| 9 | Civil Infrastructure | ministry; nation-scale and defended |
| 10 | Ostmark Bureau | signals; the endgame, and it hunts back |

Beyond ten, the ladder repeats with a lap number (`VANTEL SYSTEMS 2`).

Within a system every run walks the same six layers:

| Zones | Layer | Vulns |
|---|---|---|
| 1–20 | **EDGE** | open port, default creds, exposed API key, stale TLS |
| 21–40 | **IDENTITY** | orphaned account, weak MFA, shared password |
| 41–60 | **NETWORK** | trusted subnet, DNS cache poison, open relay |
| 61–80 | **ENDPOINT** | unpatched build server, signed driver load, CI runner shell |
| 81–99 | **DATA** | public bucket, plain backup, SQL injection |
| 100+ | **CORE** | domain trust, ROOT CA misuse, kernel module |

Each system skews its composition: identity-heavy for banks and insurers, endpoint-heavy
for hospitals, air-gapped CORE for utilities and ministries.

## Boss firewalls

Every fifth zone. One target, **30 seconds**, `10 × H(L)` HP. Failing closes the perimeter:
you lose the attempt, not your credits.

Names cycle per layer: `WAF RULESET`, `MFA GATE`, `SOC TRIAGE`, `EDR FLEET`, `AIR GAP`,
`FORENSICS SWEEP`.

## Tooling

Ten global tools, each bought once at a fixed credit price. They are where credits go when
levelling the best agent is no longer efficient.

| Tool | Cost | Effect |
|---|---|---|
| Scanner | 1,000 | +25% probe damage |
| Wordlist | 5,000 | +10% all throughput |
| Skimmer | 20,000 | +25% credits from vulns |
| Exploit Kit | 100,000 | ×2 probe damage |
| Botnet | 500,000 | +15% all throughput |
| Launderer | 2,000,000 | +50% credits from vulns |
| 0-Day | 10,000,000 | ×3 probe damage |
| Backdoor | 50,000,000 | +20% all throughput |
| Mixer | 250,000,000 | +100% credits from vulns |
| Persistence | 2,000,000,000 | +25% throughput, and +1 rootkit per ascension |

## Rootkits

Boss firewalls on zones divisible by 5 and ≥ 100 pay
`floor(((n + 4) / 5) ^ 1.3)` with `n = (zone − 100) / 5` — zone 100 pays 1, zone 150 pays
20, zone 250 pays 137, zone 500 pays 1,306. Plus `floor(totalAgentLevels / 2000)`.

Unspent rootkits are +10% throughput each, permanently, across every system.

First ascension should land at zone 130–150 with roughly 8–15 rootkits: enough that the
bonus is felt immediately, small enough that the second system is clearly better rather
than trivial.

## Skills

Six actives, one per agent, each free once its agent is deployed, on a fixed cooldown.
Bought and cast on the SKILLS tab: **A** buys, **X** fires. A cast starts the cooldown;
while it runs the row shows the seconds left and X is refused.

| Skill | Agent | Cost | Cooldown | Effect |
|---|---|---|---|---|
| Crawl | Spider | 2,000 | 30s | +10 probes/s for 30s |
| Spray | Pick | 25,000 | 45s | ×2 throughput for 30s |
| Phish | Bait | 250,000 | 60s | every hit crits, 30s |
| Siphon | Mule | 2,000,000 | 90s | ×3 credits for 30s |
| Flood | Relay | 25,000,000 | 120s | +100% probe damage, 30s |
| Blackout | Onyx | 500,000,000 | 180s | −15% vuln HP, 30s |

## Achievements

Eight, checked against run state. They exist to give the Stats and Achievements screens
something real to show, and to mark the milestones the design already tunes around.

| Achievement | Requirement |
|---|---|
| First Breach | clear layer 1 |
| Firewall Down | beat 10 boss firewalls |
| Ten Rootkits | hold 10 rootkits at once |
| New Target | ascend for the first time |
| Core Access | reach layer 100 |
| Full Roster | deploy all 12 agents |
| Silent Run | clear 100 vulns |
| Root | reach layer 250 |

## Out of scope for v1

The toolkit tree, gilds, relics, mercenaries, clans, auto-probes as purchases, daily quests,
and a second framework. Each is a screen or a timer; none is needed for the loop to be good.
