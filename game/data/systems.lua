-- Targets, layers, the vulns found in each layer, and the daemons rootkits buy.
local M = {}

local SYSTEMS = {
  "VANTEL SYSTEMS", "BRINDLE & ROE", "MERIDIAN FREIGHT", "CORVID ANALYTICS",
  "HALCYON DIAGNOSTICS", "KESTREL MUTUAL", "VEHICLE REGISTRY",
  "CALDER POWER", "CIVIL INFRASTRUCTURE", "OSTMARK BUREAU",
}

local function systemName(count)
  local n = (count or 0) + 1
  local base = SYSTEMS[((n - 1) % #SYSTEMS) + 1]
  local lap = math.floor((n - 1) / #SYSTEMS)
  return lap > 0 and (base .. " " .. lap + 1) or base
end

-- Zones map onto the security layers of the target, so the six bands a run
-- walks through are named rather than numbered.
local function layerName(z)
  if z >= 100 then return "CORE" end
  if z >= 81 then return "DATA" end
  if z >= 61 then return "ENDPOINT" end
  if z >= 41 then return "NETWORK" end
  if z >= 21 then return "IDENTITY" end
  return "EDGE"
end

local VULNS = {
  EDGE     = { "OPEN PORT", "DEFAULT CREDS", "EXPOSED API KEY", "STALE TLS" },
  IDENTITY = { "ORPHANED ACCOUNT", "WEAK MFA", "SHARED PASSWORD" },
  NETWORK  = { "TRUSTED SUBNET", "DNS CACHE POISON", "OPEN RELAY" },
  ENDPOINT = { "UNPATCHED BUILD SERVER", "SIGNED DRIVER LOAD", "CI RUNNER SHELL" },
  DATA     = { "PUBLIC BUCKET", "PLAIN BACKUP", "SQL INJECTION" },
  CORE     = { "DOMAIN TRUST", "ROOT CA MISUSE", "KERNEL MODULE" },
}

local function vulnName(z)
  local list = VULNS[layerName(z)] or VULNS.EDGE
  return list[((z - 1) % #list) + 1]
end

-- Daemons are the permanent boons bought with rootkits: code of yours that keeps
-- running whether you are watching or not.
-- Rootkit spend. Buying one is permanent and it survives every ascension.
-- Ten of them, priced in rootkits. kinds are read by sim/economy and sim/save:
-- dps_mul, credits_mul, click_mul, probes, boss_seconds, rootkit_bonus, offline_hours
local DAEMONS = {
  { name = "CRON",     cost = 5,   eff = "+1 probe per second",     effects = { { "probes", 1 } } },
  { name = "WATCHDOG", cost = 12,  eff = "+15% credits from vulns", effects = { { "credits_mul", 1.15 } } },
  { name = "BEACON",   cost = 20,  eff = "+10% throughput",         effects = { { "dps_mul", 1.10 } } },
  { name = "WRAITH",   cost = 30,  eff = "+15% probe damage",       effects = { { "click_mul", 1.15 } } },
  { name = "HONEYPOT", cost = 45,  eff = "+10s on every firewall",  effects = { { "boss_seconds", 10 } } },
  { name = "GRID",     cost = 75,  eff = "+25% credits from vulns", effects = { { "credits_mul", 1.25 } } },
  { name = "SQUID",    cost = 110, eff = "+1 rootkit on ascension", effects = { { "rootkit_bonus", 1 } } },
  { name = "TUNNEL",   cost = 160, eff = "+3 probes per second",    effects = { { "probes", 3 } } },
  { name = "LEGION",   cost = 240, eff = "+25% throughput",         effects = { { "dps_mul", 1.25 } } },
  { name = "SENTRY",   cost = 340, eff = "+2h offline progress",    effects = { { "offline_hours", 2 } } },
}

-- one reader for every daemon effect in the game
function M.daemon_mults(st)
  local m = { dps = 1, credits = 1, click = 1, probes = 0, boss_seconds = 0,
              rootkit_bonus = 0, offline_hours = 0 }
  local owned = st.daemons or {}
  for i, d in ipairs(DAEMONS) do
    if owned[i] and d.effects then
      for _, e in ipairs(d.effects) do
        local kind, v = e[1], e[2]
        -- the field a kind lands in; add for counts, multiply for multipliers
        local field = ({ dps_mul = "dps", credits_mul = "credits", click_mul = "click" })[kind]
        if field then m[field] = m[field] * v
        elseif m[kind] ~= nil then m[kind] = m[kind] + v end
      end
    end
  end
  return m
end

M.list, M.daemons, M.vulns = SYSTEMS, DAEMONS, VULNS
M.name = systemName
M.layer = layerName
M.vuln = vulnName
return M
