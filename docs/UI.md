# UI

One code path draws every screen size. Nothing is scaled: the font stays 12 px
(5×7 glyphs at 2× in 12-px cells) and the rows stay 32 px, so text is pixel-exact
on a 640×480 RG35XX and a 720×480 RG34XX alike. `game/layout.lua` turns the
window size into every anchor the screens use; `game/main.lua` only reads from it.

## Profiles

Chosen automatically from `W/H`:

| Profile | Ratio | Devices | agent column | rows |
|---|---|---|---|---|
| `wide` | ≥ 1.45 | RG34XX / RG34XXSP 720×480, RK3566 1280×720 | 40% of W (288 @ 720) | 12 @ 480 |
| `classic` | 1.15–1.45 | RG35XX family, RG40XX, RG28XX 640×480 | 42% of W (272 @ 640) | 12 @ 480 |
| `square` | < 1.15 | CubeXX 720×720 | 42% of W (304 @ 720) | 19 @ 720 |

The column width is snapped to an 8-px multiple and clamped to 240–384 px.
A player setting (`prefs.list = "auto" | "narrow" | "wide"`) overrides the
fraction to 0.34 / 0.46 — it changes how much room the list takes, not the
profile. There is no "force 4:3" mode; pillar bars are never drawn.

## Bands

Profiles are chosen by aspect ratio alone: wide (≥1.45), classic (1.15–1.45), square
(<1.15). The suite draws every screen at 720×480, 640×480, 720×720, 1280×720, 800×600 and
960×544; 720×480 is the device the game is built for. All three profiles have since been
played on hardware: wide on the two RG34XX units, classic on a 4:3 handheld, square on a 1:1
handheld. No sprite is scaled and the font is
fixed at 12 px, so a bigger window means more rows, not bigger type.

`layout.lua` returns: `topH 32`, `hintH 32`, `hdrH 16`, `rowH 32`, `footH 16`,
then `heroW / battleX / battleW`, `rows / rowY / footY`.

| Band | y | content |
|---|---|---|
| Top bar | 0 | `CREDITS` · `DPS` · `ROOTKITS` · `ZONE`, sized by need (see below) |
| Agent header | 32 | `AGENT` · `LV` · `COST` · `DPS`, dim |
| Agent rows | 48 | `rows` × 32 px: 16-px icon, name, level, cost, DPS |
| Agent footer | `footY` | `BUY ×n` left, `+n DPS` right |
| Hint bar | `H - 32` | chips + labels, then four tab dots at the right |

Top-bar slots are sized from a minimum (label plus a six-character value) plus a weighted
share of the leftover width: credits first, then throughput, then rootkits and zone. Values
are right-aligned and clipped to their own box, so a number growing from `999` to `1.24K`
never nudges its neighbours. There is no boss clock in the bar — a firewall's time lives on
its own bar in the arena.

The battle column's vertical rhythm is measured from the body bottom
(`H - hintH`): HP bar at `-184`, kills at `-144`, click/DPS at `-112`,
prestige row at `-72`, progress bar at `-48`. At 480 that reproduces the
mockup's 264 / 304 / 336 / 376 / 400; at 720 the block spreads down instead of
leaving the lower half empty. The vuln sits at `hpY - 168` with its name at
`hpY - 32`.

## Agent row columns

Right-aligned anchors derived from the column width:

| Column | wide (288) | classic (272) |
|---|---|---|
| name | x 28, 84 px budget, `…` truncation | x 28, 56 px |
| LV | `heroW - 148` | `heroW - 124` |
| COST | `heroW - 76` | `heroW - 8` |
| DPS | `heroW - 8` | **dropped** |

A column narrower than ~264 px cannot hold name + three numbers, so the DPS
column is dropped and the space goes to the name and the cost. The DPS total is
still in the top bar; the footer's `+n DPS` becomes `+n`.

## Buttons

Device keys arrive through `clickeragents.gptk`: **on this unit the printed A arrives as SDL `a`** (verified by pressing it — it sent the key bound to `a`), so `a = x` carries the buy key and `b = z` the click key, matching the hint bar. `tests/headless.lua` reads the gptk and fails if either binding disagrees with the game.

| Input | Key | Does, today |
|---|---|---|
| D-pad up/down | arrows | move the selection one row |
| D-pad left/right | arrows | buy amount 1…100 |
| **A** | `x` | buy `amount` of the selected agent |
| **B** | `z` | one manual click into the vuln: HP drops by click damage, the sprite flashes; a killing click refills the bar and ticks the kills counter. On a wireframe tab it returns to battle |
| **X** | `c` | walk through a cleared zone, or snap the zone cursor back to the live zone |
| **Y** | `v` | **unmapped on purpose** |
| **L / R** | `q` / `e` | previous / next tab (battle → skills → upgrades → prestige → achievements → stats) |
| **Start** | `return` | open the pause menu (tick stops, autosave, RESUME / QUIT) |
| **Select** | `tab` | cycle amount 1 → 10 → 100 → MAX → 1 |
| 1 / 2 / 3 | — | desktop only: normal / boss / holding-A states |
| `m` | — | desktop only: cycle list width auto → narrow → wide |

Buying and probing are the only logic in the build: credits land, level rises, cost
×1.07, DPS recomputes as the sum of `base × level`; a click removes `click`
damage and a kill refills the bar and ticks the counter. There is no combat tick,
no credit income and no save yet.

## Screens

**Splash** — title, subtitle, one silhouette, `PRESS ANY BUTTON`. Any button or
2.5 s moves on; it never shows twice per launch.

**Welcome Back** — the offline report (DESIGN §7): layers gained, credits earned,
where it stopped, DPS while away. Appears after the title and **only A closes
it** — no other button dismisses it.

**Battle** (the home screen) — the working screen: agent list, arena, buying, clicking, and drives
**zone selection**: **L2 / R2** step back and forward through the zones you have
already cleared, and **X** snaps back to the live one. The arena header shows
`ZONE n · FARMING` while you are looking at an earlier zone. Nothing about combat
changes yet — the selection is a cursor.

**Upgrades** (tab 3) — the ten one-shot globals from CONTENT.md as rows, with a side panel for effect and owned state.

**Skills** (tab 2) — the actives roster: name, price or `OWNED`, and a side
panel with source agent, cooldown and effect. Six skills ship. **A** buys the
highlighted one, **X** casts it: the row and the panel count the cooldown down and
a second cast is refused until it expires.

**Achievements** (tab 5) — eight names with the requirement that earns them,
selectable, with the chosen one spelled out beside it.

**Stats** (tab 6) — eight stat rows left, `DPS BY ZONE` graph box right.

**Prestige** (tab 4) — rootkits on offer / held / bonus-per-rootkit, a greyed
`ASCEND · LOCKED · ZONE 100`, and a `SYSTEMS · ROOTKIT SPEND` panel listing the four
earliest systems for the v1.1 rootkit sink.

**Menu** (overlay) — opened with START from any screen. It pauses the ticker, writes a save, and shows `PAUSED`, `SAVED` or `SAVE FAILED`, and `RESUME / QUIT`. No hint line: the rows are the instruction. There is no save button: every purchase, zone change, ascension, focus loss and quit already saves, plus one beat a minute.

Tabs 2–7 show their real labels and, where the content exists (upgrade names and
prices), real values. Seven dots at the bottom-right track the tab; L/R cycles
them and B returns to battle.

**Interaction is wired end to end before any logic.** Each tab keeps its own
cursor (battle: agent row; upgrades: 10 rows; prestige: 4 systems + `ASCEND`;
menu: 3 rows). Up/down moves it and wraps. **A activates** — on a wireframe it
raises a toast (`NEED 20K CREDITS`, `LOCKED · ZONE 100`, `SAVE UNAVAILABLE`) and
changes nothing else; in the menu, `RESUME` really returns
to battle and `QUIT` really quits. Toasts last 1.6 s and are cleared when the
screen changes, so a message never follows you to another tab.

## Numbers

| Range | Format |
|---|---|
| < 1,000 | `123` |
| < 1e6 | `1.23K` |
| < 1e9 | `12.3M` |
| < 1e12 | `1.23B` |
| < 1e15 | `12.3T` |
| beyond | `1.23aa`, `1.23ab`, `1.23ac` … |

Two decimals below 10, one below 100, none above; right-aligned.

## Colour

| Use | Colour |
|---|---|
| ground | `#0B0D12` |
| panel | `#161A24` |
| rule | `#2A3040` |
| text | `#E6E9F0` |
| dim text | `#8A93A6` |
| credits / selection | `#E8B45A` |
| HP fill | `#B4402E` |
| HP empty | `#3A1A16` |
| DPS / gain | `#5FBF6A` |
| cost too dear | `#8A3B34` |
| warn (boss timer, boss HP) | `#E8453C` |

Battle art adds five browns: sky `#171210`, floor `#0E0C0F`, horizon `#241A17`,
pillar `#211A18` / `#2A211F`, vuln `#59332A` / `#3E241D` / `#6E4236`.

## Tests

`lua tests/headless.lua` draws the screen at 720×480, 640×480 and 720×720 with a
stubbed `love.graphics` that applies `push/pop/translate`, then asserts that
every rectangle is inside the window, that the columns tile the width and the
bands tile the height, and that pressing A actually spends credits and raises a
level. Current: 54,832 rects, 0 errors.

## Top bar

Four fields: `CREDITS`, `DPS`, `ROOTKITS`, `ZONE`. Credits and throughput carry the long
figures, so the bar is divided by need rather than into even columns: each field has a
minimum width (its label plus a six-character value) and the leftover width is handed out
with credits first, then throughput. `M.slotWidths(W)` is the one place that decides this,
and the suite checks the widest figures still fit at 640, 720 and square.

## Panels

Every tab paints its panels at one height, `L.panelH = 40 + (L.rows - 3) * 32` — 328 px at 720×480. A list longer than the window scrolls with a `n/N` position counter on the header line, so the panels line up tab to tab and nothing is hidden without a number.

The top bar carries credits, throughput, rootkits and zone only. A firewall's clock lives on its own bar in the arena; there is no second copy in the corner.
