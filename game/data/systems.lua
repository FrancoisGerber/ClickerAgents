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
local DAEMONS = {
  { "CRON",     5,  "+1 probe per second",      "cron" },
  { "WATCHDOG", 12, "+15% credits from vulns",  "watchdog" },
  { "BEACON",   30, "+10% throughput",          "beacon" },
  { "HONEYPOT", 75, "+10s on every firewall",   "honeypot" },
}

M.list, M.daemons, M.vulns = SYSTEMS, DAEMONS, VULNS
M.name = systemName
M.layer = layerName
M.vuln = vulnName
return M
