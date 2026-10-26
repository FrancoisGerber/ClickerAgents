-- Every number that changes how the game plays, in one place.
--
-- This file is for balance, not content: multipliers, growth rates, thresholds and
-- timers live here and nowhere else. Individual prices and effects (what an agent
-- costs, what a tool does) stay with their rows in data/, because they are content
-- you edit item by item.
--
-- Nothing here should be a copy of a data row: if a number is needed in two modules,
-- it lives here and both read it. tests/headless.lua proves the modules consume these
-- values by changing one at runtime and watching the result move.

local T = {}

-- ---------------------------------------------------------------- zones and vulns
T.zone = {
  kills_per_zone = 10,        -- vulns to clear before the gate opens
  boss_every = 5,             -- every fifth zone is a firewall
}

T.vuln = {
  base = 10,                  -- HP of the zone-1 vuln
  growth = 1.55,              -- per-zone HP growth while the curves still fit doubles
  linear = 10,                -- flat HP added per zone, keeps the first ten zones honest
  soft_cap = 140,             -- zone where the growth curve switches to the tail
  tail_growth = 1.145,        -- per-zone growth past the soft cap
}

T.payout = {
  share = 0.05,               -- credits per vuln, as a share of its HP
  boss_multiplier = 3,        -- a firewall pays three vulns' worth
}

-- ---------------------------------------------------------------- agents
T.agent = {
  cost_growth = 1.07,         -- each level costs this much more than the last
  milestone_first = 25,       -- first damage milestone
  milestone_every = 25,       -- subsequent milestones
  milestone_step = 4,         -- damage multiplier per milestone
}

-- ---------------------------------------------------------------- probes
T.probe = {
  -- One press is worth this many seconds of the agents' output at zone 1, so a steady
  -- tap is always the faster way to kill something. The bonus over 1.0 halves every
  -- half_life zones, settling on share_floor: clicking still always beats waiting, but
  -- by less and less as the run grows, until the agents carry the zone on their own.
  -- Never set share_floor at or below 1.0.
  share = 1.5,
  share_floor = 1.06,
  half_life = 70,             -- zones for the bonus to halve
  min = 1,                    -- damage floor, so a run with no agents can still open
}

-- ---------------------------------------------------------------- firewalls
T.boss = {
  hp_multiplier = 10,         -- firewall HP as a multiple of the zone's vuln
  seconds = 30,               -- clock for one attempt
  honeypot_seconds = 10,      -- HONEYPOT daemon adds this to every attempt
}

-- ---------------------------------------------------------------- skills
T.buff = {
  duration = 30,              -- every skill lasts this long
  crit_multiplier = 10,       -- PHISH makes every probe crit for this
  crawl_probes = 10,          -- CRAWL's extra probes per second
  blackout_cut = 0.15,        -- BLACKOUT's share of vuln HP removed
}

-- ---------------------------------------------------------------- prestige
T.prestige = {
  unlock_zone = 100,          -- first ascension becomes available here
  gate_doubles = true,        -- and every ascension after that doubles it: 200, 400, 800
  levels_per_rootkit = 2000,  -- agent levels needed per rootkit on offer
  hold_bonus = 0.10,          -- throughput multiplier per unspent rootkit
}

-- ---------------------------------------------------------------- persistence
T.save = {
  interval = 60,              -- seconds between autosaves when nothing changes
  offline_cap = 8 * 3600,     -- longest stretch of offline progress replayed
  offline_min = 30,           -- shorter gaps earn no Welcome Back report
}

return T
