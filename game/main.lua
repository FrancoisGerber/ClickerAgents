-- Clicker Agents — the mockup, running, on any screen.
-- Layout comes from game/layout.lua, so the same code draws at 640x480, 720x480
-- and 720x720 with no scaling. Buttons change the numbers (buying agents) but
-- there is still no simulation, no save and no combat tick.

local GL = require("font")
local Layout = require("layout")

---------------------------------------------------------------- colours
local function hex(s)
  return {
    tonumber(s:sub(2, 3), 16) / 255,
    tonumber(s:sub(4, 5), 16) / 255,
    tonumber(s:sub(6, 7), 16) / 255,
  }
end

local C = {
  ground  = hex("#0B0D12"), panel   = hex("#161A24"), rule     = hex("#2A3040"),
  text    = hex("#E6E9F0"), dim     = hex("#8A93A6"), gold     = hex("#E8B45A"),
  hp      = hex("#B4402E"), hpEmpty = hex("#3A1A16"), gain     = hex("#5FBF6A"),
  poor    = hex("#8A3B34"), warn    = hex("#E8453C"), aura     = hex("#6B2230"),
  rowsplit = hex("#1A1E27"), iconOff = hex("#1B2028"), iconFg = hex("#20252F"),
  flashLt = hex("#B0765F"), bossDk  = hex("#2C1915"),
}

local ART = {
  sky       = hex("#171210"), floor     = hex("#0E0C0F"), horizon   = hex("#241A17"),
  pillar    = hex("#211A18"), pillarLt  = hex("#2A211F"), monster   = hex("#59332A"),
  monsterDk = hex("#3E241D"), monsterLt = hex("#6E4236"), shadow    = hex("#100C0A"),
}

---------------------------------------------------------------- primitives
local lg = love.graphics
local L                                  -- layout table, rebuilt on load/resize

local function dbg(s) if not _G.DS_TEST then print(s) end end

local function px(x, y, w, h, c)
  if w <= 0 or h <= 0 then return end
  lg.setColor(c)
  lg.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))
end

local function rrect(x, y, w, h, r, c)
  lg.setColor(c)
  lg.rectangle("fill", x, y, w, h, r, r)
end

local function frame(x, y, w, h, t, c)
  px(x, y, w, t, c); px(x, y + h - t, w, t, c)
  px(x, y, t, h, c); px(x + w - t, y, t, h, c)
end

-- UTF-8 aware: the font holds '…', '—' and '×', which are multi-byte.
local function chars(s)
  local out, i = {}, 1
  while i <= #s do
    local b = s:byte(i)
    local n = 1
    if b >= 0xF0 then n = 4
    elseif b >= 0xE0 then n = 3
    elseif b >= 0xC0 then n = 2 end
    out[#out + 1] = s:sub(i, i + n - 1)
    i = i + n
  end
  return out
end

local function drawText(s, x, y, colour, sc)
  sc = sc or 2
  lg.setColor(colour)
  local cx = x
  for _, ch in ipairs(chars(s)) do
    local rows = GL[ch] or GL[ch:upper()] or GL["?"]
    local r = 0
    for bits in rows:gmatch("[^/]+") do
      for c = 1, 5 do
        if bits:sub(c, c) == "1" then
          lg.rectangle("fill", cx + (c - 1) * sc, y + r * sc, sc, sc)
        end
      end
      r = r + 1
    end
    cx = cx + 6 * sc
  end
end

local function textW(s, sc) return #chars(s) * 6 * (sc or 2) end

local function drawTextR(s, xr, y, colour, sc)
  drawText(s, xr - textW(s, sc), y, colour, sc)
end

local function drawTextC(s, xc, y, colour, sc)
  drawText(s, math.floor((xc - textW(s, sc) / 2) / 2) * 2, y, colour, sc)
end

local function fit(s, maxw, sc)
  local n = math.floor(maxw / (6 * (sc or 2)))
  local list = chars(s)
  if #list <= n then return s end
  if n < 1 then return "" end
  local out = {}
  for i = 1, n - 1 do out[i] = list[i] end
  return table.concat(out) .. "…"
end

---------------------------------------------------------------- numbers
local SUF = { "", "K", "M", "B", "T", "aa", "ab", "ac", "ad" }
local function fmt(n)
  if n < 1000 then return tostring(math.floor(n)) end
  local i, v = 0, n
  while v >= 1000 and i < #SUF - 1 do v = v / 1000; i = i + 1 end
  if v < 10 then return string.format("%.2f%s", v, SUF[i + 1])
  elseif v < 100 then return string.format("%.1f%s", v, SUF[i + 1])
  else return tostring(math.floor(v + 0.5)) .. SUF[i + 1] end
end

---------------------------------------------------------------- the target
-- A vuln is a vulnerable service: a chassis with pins into the host, an aperture
-- where the flaw sits, and cracks that spread as its HP drains. No creature —
-- the thing you are breaking is a socket, not a beast.

local function seg(x1, y1, x2, y2, c, t)
  local dx, dy = x2 - x1, y2 - y1
  local n = math.max(math.abs(dx), math.abs(dy), 1)
  local step = t or 2
  local i = 0
  while i <= n do
    local k = i / n
    px(math.floor(x1 + dx * k), math.floor(y1 + dy * k), step, step, c)
    i = i + step
  end
end

-- damage -> how far the cracks have spread; each entry appears at a threshold
local CRACKS = {
  { 0.12, { { 0, 0 }, { 10, 12 }, { 5, 26 }, { 14, 36 } } },
  { 0.32, { { 96, 2 }, { 86, 16 }, { 92, 30 }, { 82, 42 } } },
  { 0.52, { { 8, 44 }, { 20, 50 }, { 26, 64 }, { 16, 74 } } },
  { 0.72, { { 88, 46 }, { 76, 56 }, { 82, 70 }, { 70, 80 } } },
  { 0.88, { { 40, 8 }, { 52, 20 }, { 46, 34 } } },
}

local function ledColour(frac)
  if frac > 0.6 then return C.gain end
  if frac > 0.3 then return C.gold end
  return C.warn
end

local function drawVuln(x, y, frac, flash, k)
  frac = frac or 1
  k = k or 1
  local damage = 1 - math.max(0, math.min(1, frac))
  local body = flash and C.text or C.panel
  local edge = flash and C.text or C.rule
  local dark = ART.monsterDk
  local hot  = flash and C.flashLt or C.gold
  local function R(ox, oy, w, h, c) px(x + ox * k, y + oy * k, w * k, h * k, c) end
  local function F(ox, oy, w, h, t, c) frame(x + ox * k, y + oy * k, w * k, h * k, t * k, c) end
  local function RR(ox, oy, w, h, r, c) rrect(x + ox * k, y + oy * k, w * k, h * k, r * k, c) end

  R(28, 106, 96, 8, ART.shadow)                     -- contact shadow
  R(16, 46, 8, 6, edge); R(16, 74, 8, 6, edge)      -- pins into the host
  R(128, 46, 8, 6, edge); R(128, 74, 8, 6, edge)

  RR(24, 34, 104, 64, 6, body)                      -- chassis
  F(24, 34, 104, 64, 2, edge)

  for i = 0, 2 do                                   -- vent slats
    R(34, 48 + i * 12, 14, 4, dark)
    R(104, 48 + i * 12, 14, 4, dark)
  end

  RR(56, 44, 40, 44, 4, ART.floor)                  -- aperture: the flaw itself
  F(56, 44, 40, 44, 2, edge)
  local glow = (damage > 0.5) and C.hp or hot
  R(64, 56, 24, 20, glow)
  R(68, 60, 16, 12, C.flashLt)

  for _, c in ipairs(CRACKS) do                     -- cracks spread with damage
    if damage >= c[1] then
      local pts = c[2]
      for i = 1, #pts - 1 do
        seg(x + (24 + pts[i][1]) * k, y + (34 + pts[i][2]) * k,
            x + (24 + pts[i + 1][1]) * k, y + (34 + pts[i + 1][2]) * k,
            C.warn, math.max(2, math.floor(2 * k)))
      end
    end
  end

  R(70, 22, 12, 6, edge)                            -- status LED
  R(72, 24, 8, 3, ledColour(frac))
  if flash then F(22, 32, 108, 68, 2, C.text) end
end

local function drawBossVuln(x, y, frac, k)
  frac = frac or 1
  k = k or 1
  local damage = 1 - math.max(0, math.min(1, frac))
  local edge = C.rule
  local function R(ox, oy, w, h, c) px(x + ox * k, y + oy * k, w * k, h * k, c) end
  local function F(ox, oy, w, h, t, c) frame(x + ox * k, y + oy * k, w * k, h * k, t * k, c) end
  local function RR(ox, oy, w, h, r, c) rrect(x + ox * k, y + oy * k, w * k, h * k, r * k, c) end

  R(24, 118, 112, 8, ART.shadow)
  RR(12, 30, 136, 82, 8, ART.floor)
  F(12, 30, 136, 82, 2, C.warn)
  F(16, 34, 128, 74, 2, edge)

  for i = 0, 2 do
    R(4, 44 + i * 24, 8, 8, edge)
    R(148, 44 + i * 24, 8, 8, edge)
  end

  for i = 0, 2 do
    local ax = 28 + i * 38
    RR(ax, 48, 30, 40, 4, ART.sky)
    F(ax, 48, 30, 40, 2, edge)
    local lit = (damage < 0.35 + i * 0.3)
    R(ax + 6, 56, 18, 24, lit and C.warn or ART.monsterDk)
  end

  R(28, 36, 104, 6, C.warn)

  for _, c in ipairs(CRACKS) do
    if damage >= c[1] then
      local pts = c[2]
      for i = 1, #pts - 1 do
        seg(x + (12 + pts[i][1] * 1.3) * k, y + (30 + pts[i][2]) * k,
            x + (12 + pts[i + 1][1] * 1.3) * k, y + (30 + pts[i + 1][2]) * k,
            C.warn, math.max(2, math.floor(2 * k)))
      end
    end
  end
end

---------------------------------------------------------------- the logo mark
-- The same 16x16 grid tools/gen_logo.py draws the badge from, so the title
-- screen shows the real mark rather than a picture of it.
local MARK = {
  "................", ".gg.............", ".gggg...........", ".gggggg.........",
  ".gggggggg.......", ".gggggggggg.....", ".gggggggggggg...", ".ggggggggggg....",
  ".gggggggggg.....", ".gggg.gggg......", ".ggg....ggg.....", ".gg......gg.....",
  ".g........g.....", "................", "....mmmmmmmm....", "................",
}

local function drawMark(x, y, cell)
  local size = 20 * cell
  px(x, y, size, size, C.gold)
  local inner = size - 4 * cell
  px(x + 2 * cell, y + 2 * cell, inner, inner, C.ground)
  for gy, row in ipairs(MARK) do
    for gx = 1, #row do
      local ch = row:sub(gx, gx)
      if ch ~= "." then
        px(x + (gx + 1) * cell, y + (gy + 1) * cell, cell, cell,
           ch == "m" and C.rule or C.gold)
      end
    end
  end
end

local prefs = { list = "auto" }     -- "auto" | "narrow" | "wide"

---------------------------------------------------------------- binds
-- The gptk is the source of truth for which key each printed button sends, so
-- read it instead of hard-coding: change the gptk, the game follows. Falls back
-- to x/z when there is no gptk next to the game (running from the repo).
local function readBinds()
  -- CWD differs between "love game" from the repo and a launch on the device,
  -- so try the repo layout, the game dir, and the pak layout next to main.lua.
  local src = (love and love.filesystem and love.filesystem.getSource
               and love.filesystem.getSource()) or nil
  local paths = {
    "port/clickeragents/clickeragents.gptk",
    "clickeragents.gptk",
    "../port/clickeragents/clickeragents.gptk",
  }
  if src then
    paths[#paths + 1] = src .. "/clickeragents.gptk"
    paths[#paths + 1] = src .. "/../port/clickeragents/clickeragents.gptk"
  end
  for _, p in ipairs(paths) do
    local f = io.open(p, "r")
    if f then
      local map = {}
      for line in f:lines() do
        local k, v = line:match("^%s*([%w_]+)%s*=%s*(%w+)")
        if k then map[k] = v end
      end
      f:close()
      if map.a and map.b then
        -- gptokeyb names buttons by POSITION. On this unit the printed A reports
        -- as SDL "b" (proved from the device log: pressing A emitted the key
        -- bound to "b"), so the pair is crossed on purpose.
        dbg("[binds] A=" .. map.b .. " B=" .. map.a .. " X=" .. (map.x or "c") .. " from " .. p)
        return {
          buy = map.b, click = map.a,
          fire = map.x or "c",
          prevSkill = map.l2 or "f", nextSkill = map.r2 or "g",
          src = p,
        }
      end
    end
  end
  dbg("[binds] no gptk found, falling back to A=x B=z X=c L2=f R2=g")
  return { buy = "x", click = "z", fire = "c",
           prevSkill = "f", nextSkill = "g", src = "fallback" }
end

local BINDS

---------------------------------------------------------------- skills
-- Two actives carried over from DESIGN.md's nine. The strip is a selector:
-- L2/R2 move the highlight, X casts the highlighted one.
local SKILLS = {
  { name = "CRAWL",    agent = "SPIDER",   cost = "2K",   cd = 30,
    eff = "+10 probes/s for 30s",   owned = true },
  { name = "SPRAY",    agent = "PICK",  cost = "25K",  cd = 45,
    eff = "x2 throughput for 30s",  owned = true },
  { name = "PHISH",    agent = "BAIT",     cost = "250K", cd = 60,
    eff = "every hit crits, 30s",   owned = false },
  { name = "SIPHON",   agent = "MULE",     cost = "2M",   cd = 90,
    eff = "x3 credits for 30s",     owned = false },
  { name = "FLOOD",    agent = "RELAY",    cost = "25M",  cd = 120,
    eff = "+100% probe dmg, 30s",   owned = false },
  { name = "BLACKOUT", agent = "ONYX", cost = "500M", cd = 180,
    eff = "-15% vuln HP, 30s",      owned = false },
}

---------------------------------------------------------------- achievements
-- Content only: a name and what earns it. Earned state arrives with the sim.
local ACHIEVEMENTS = {
  { "FIRST BREACH",  "clear layer 1" },
  { "FIREWALL DOWN", "beat 10 boss firewalls" },
  { "TEN ROOTKITS",  "hold 10 rootkits at once" },
  { "NEW TARGET",    "ascend for the first time" },
  { "CORE ACCESS",   "reach layer 100" },
  { "FULL ROSTER",   "deploy all 12 agents" },
  { "SILENT RUN",    "clear 100 vulns" },
  { "ROOT",          "reach layer 250" },
}

local st                     -- the run state, filled in below

---------------------------------------------------------------- systems and layers
-- One system per run. Ascending closes it and opens the next, harder one.
local SYSTEMS = {
  "VANTEL SYSTEMS", "BRINDLE & ROE", "MERIDIAN FREIGHT", "CORVID ANALYTICS",
  "HALCYON DIAGNOSTICS", "KESTREL MUTUAL", "VEHICLE REGISTRY",
  "CALDER POWER", "CIVIL INFRASTRUCTURE", "OSTMARK BUREAU",
}

local function systemName()
  local n = (st.systems or 0) + 1
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

-- Daemons are the permanent boons bought with rootkits: code of yours that keeps
-- running whether you are watching or not.
local DAEMONS = {
  { "CRON",     "5",  "+1 probe per second" },
  { "WATCHDOG", "12", "+15% credits from vulns" },
  { "BEACON",   "30", "+10% throughput" },
  { "HONEYPOT", "75", "boss firewalls give 10s longer" },
}

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

---------------------------------------------------------------- state
-- The agents you deploy. Cheapest first; each one is a specialist.
local AGENTS = {
  { name = "Spider",   lv = 12, cost = 12,        base = 0 },
  { name = "Pick",     lv = 11, cost = 214,       base = 5 },
  { name = "Bait",     lv = 6,  cost = 1400,      base = 16 },
  { name = "Splice",   lv = 0,  cost = 4200,      base = 74 },
  { name = "Relay",    lv = 0,  cost = 9800,      base = 245 },
  { name = "Grind",    lv = 0,  cost = 41000,     base = 1000 },
  { name = "Cicada",   lv = 0,  cost = 190000,    base = 4300,    lock = 26 },
  { name = "Mule",     lv = 0,  cost = 400000,    base = 17000,   lock = 34 },
  { name = "Taint",    lv = 0,  cost = 2000000,   base = 75000,   lock = 43 },
  { name = "Hush",     lv = 0,  cost = 10000000,  base = 320000,  lock = 53 },
  { name = "Badge",    lv = 0,  cost = 50000000,  base = 1400000, lock = 64 },
  { name = "Onyx",     lv = 0,  cost = 250000000, base = 6000000, lock = 76 },
}

st = {
  gold = 1240, dps = 0, souls = 12, zone = 12, zoneSel = 12, kills = 7, timer = 0, click = 0,
  hp = 483, hpMax = 1270, goldKill = 63, sel = 1, amount = 1, gain = 0,
  agents = AGENTS, systems = 0, idle = false, flashT = 0,
  tab = 1, screen = "splash", splashT = 0, welcome = true,
  cursor = { 1, 1, 1, 1, 1, 1, 1 },  -- one selection per tab
  skillSel = 1, skillCd = {}, skillFlash = 0, owned = {}, upOwned = {}, achDone = {},
  msg = nil, msgT = 0,               -- transient toast for "does nothing yet"
}

local opts = {}                     -- preview flags: boss / held / flash

local function gainOf(i)
  local h = st.agents[i + 1]
  if not h or h.lock then return 0 end
  return h.base or 0
end

local function setSel(i)
  st.sel = math.max(0, math.min(#st.agents - 1, i))
  st.gain = gainOf(st.sel)
end

-- mock economy: enough to make the buttons change the numbers, no simulation
local function recalc()
  local sum = 0
  for _, h in ipairs(st.agents) do
    h.dps = (h.base or 0) * h.lv
    sum = sum + h.dps
  end
  st.dps = sum
  st.click = 400 + st.agents[1].lv          -- Pell feeds click damage
  st.gain = gainOf(st.sel)
end

local function buy(n)
  local h = st.agents[st.sel + 1]
  if not h or h.lock then return false end
  local bought = 0
  for _ = 1, n do
    if st.gold >= h.cost then
      st.gold = st.gold - h.cost
      h.lv = h.lv + 1
      h.cost = math.floor(h.cost * 1.07)
      bought = bought + 1
    else
      break
    end
  end
  if bought > 0 then recalc() end
  return bought > 0
end

local function buyMax()
  local n = 0
  local h = st.agents[st.sel + 1]
  if not h then return end
  local gold, cost = st.gold, h.cost
  while gold >= cost and n < 999 do
    gold = gold - cost
    cost = math.floor(cost * 1.07)
    n = n + 1
  end
  if n > 0 then buy(n) end
end

-- amount 0 means MAX, so B can still buy everything without a Y button
local function buyAmount(n)
  if n == 0 then return buyMax() end
  return buy(n)
end

-- A: one manual click into the monster. No simulation yet: the hit lands, the
-- bar drains, and a kill only refills it and ticks the counter.
local function clickMonster()
  st.hp = st.hp - st.click
  st.flashT = 0.12
  if st.hp <= 0 then
    st.hp = st.hpMax
    st.kills = st.kills + 1
    if st.kills > 10 then st.kills = 0 end
  end
end

local function ownedList()
  local out = {}
  for i = 1, #SKILLS do if st.owned[i] then out[#out + 1] = i end end
  return out
end

---------------------------------------------------------------- chrome
local function topBar()
  px(0, 0, L.W, L.topH, C.panel)
  local W = L.W
  -- fixed-width slots: label + right-aligned value, so the fields never collide
  -- when a number grows and never jitter while one does
  local function slot(x, w, label, value, vc)
    drawText(label, x, 8, C.dim, 2)
    drawTextR(value, x + w - 16, 8, vc, 2)
    return x + w
  end
  local x = 16
  x = slot(x, 176, "CREDITS", fmt(st.gold), C.gold)
  x = slot(x, 104, "DPS", fmt(st.dps), C.gain)
  x = slot(x, 160, "ROOTKITS", tostring(st.souls), C.gold)
  x = slot(x, 96, "ZONE", tostring(st.zone), C.text)
  -- the boss timer earns its corner only while there is a boss to lose to
  local bossPreview = opts and opts.boss
  if st.timer > 0 or bossPreview then
    if W - x >= 120 then drawText("BOSS", W - 128, 8, C.dim, 2) end
    local secs = st.timer > 0 and st.timer or 14
    local t = string.format("%d:%02d", math.floor(secs / 60), secs % 60)
    drawTextR(t, W - 16, 8, secs <= 15 and C.warn or C.text, 2)
  end
  px(0, L.topH - 2, W, 2, C.rule)
end

local TABS = { "BATTLE", "SKILLS", "UPGRADES", "PRESTIGE", "ACHIEVEMENTS", "STATS", "MENU" }
local NTABS = #TABS

local K = {
  LR = { k = "L/R",    t = "TAB" },
  ST = { k = "START",  t = "AMOUNT" },
  SE = { k = "SELECT", t = "AUTO" },
  ZN = { k = "L2/R2",  t = "ZONE" },
}

local function hintBar()
  local aChip = { k = "A", t = "BUY" }
  local bChip = { k = "B", t = "CLICK" }
  local selChip = { k = "A", t = "SELECT" }
  local buyChip = { k = "A", t = "BUY" }
  local useChip = { k = "X", t = "USE" }
  local backChip = { k = "B", t = "BACK" }
  local chips
  if st.tab == 1 then
    chips = { aChip, bChip, K.ZN, K.ST, K.SE }
  elseif st.tab == 2 then
    chips = { buyChip, useChip, backChip, K.LR }
  elseif st.tab == 3 then
    chips = { buyChip, backChip, K.LR }
  elseif st.tab == 6 then
    chips = { backChip, K.LR }
  else
    chips = { selChip, backChip, K.LR }
  end
  local h = chips
  px(0, L.H - L.hintH, L.W, L.hintH, C.panel)
  px(0, L.H - L.hintH, L.W, 2, C.rule)

  local dotsW = NTABS * 16 + 16
  local limit = L.W - dotsW
  local x = 16
  for _, b in ipairs(h) do
    local cw = 6 * #b.k + 8
    local wNeed = cw + 6 + textW(b.t, 2) + 18
    if x + wNeed > limit then break end
    local lit = (b.t == "CLICK" and st.flashT > 0) or (b.t == "AUTO" and st.idle)
    rrect(x, L.H - L.hintH + 8, cw, 16, 2, lit and C.gold or C.rule)
    drawText(b.k, x + math.floor((cw - 6 * #b.k) / 2), L.H - L.hintH + 13,
             lit and C.ground or C.text, 1)
    x = x + cw + 6
    drawText(b.t, x, L.H - L.hintH + 8, lit and C.gold or C.dim, 2)
    x = x + textW(b.t, 2) + 18
  end
  for i = 0, NTABS - 1 do
    px(L.W - dotsW + 8 + i * 16, L.H - L.hintH + 12, 8, 8,
       i == st.tab - 1 and C.gold or C.rule)
  end
end

---------------------------------------------------------------- battle column
local function hpBar(x, y, w, h, frac, warn)
  px(x, y, w, h, C.hpEmpty)
  local fw = math.floor(w * frac / 4) * 4
  px(x, y, fw, h, warn and C.warn or C.hp)
  frame(x - 2, y - 2, w + 4, h + 4, 2, warn and C.warn or C.rule)
  if warn then
    for i = 1, 3 do px(x + fw - i * 12, y + 6, 4, h - 12, C.aura) end
  end
end

local function battleCol(o)
  o = o or {}
  local bw = L.battleW
  local flash = o.flash or st.flashT > 0
  -- vertical rhythm from the body height, so a 720-tall panel spreads its
  -- content instead of leaving the bottom half empty
  local bodyBottom = L.H - L.hintH - 16
  local hpY = bodyBottom - 184
  local killsY = bodyBottom - 144
  local clickY = bodyBottom - 112
  local nextY = bodyBottom - 72
  local barY = bodyBottom - 48
  local monY = math.max(64, hpY - 168)
  local nameY = hpY - 32

  lg.push()
  lg.translate(L.battleX, 0)
  px(0, L.topH, bw, L.H - L.topH - L.hintH, ART.sky)
  px(0, 224, bw, L.H - 224, ART.floor)
  px(0, 222, bw, 2, ART.horizon)

  -- pillars, as fractions of the column so they survive a narrower screen
  local function pillar(fx, y, w, h, cap)
    local x = math.floor(bw * fx)
    px(x, y, w, h, ART.pillar)
    if cap then px(x, y, 4, h, ART.pillarLt) end
  end
  pillar(0.06, 136, 32, 88, true)
  pillar(0.17, 160, 16, 64)
  pillar(0.80, 152, 16, 72)
  pillar(0.87, 128, 32, 96, true)
  local zSel = st.zoneSel or st.zone
  local nm = o.boss and "BOSS FIREWALL" or vulnName(zSel)
  local nw = textW(nm, 2)
  local plateW = math.max(nw + 16, 200)
  local plateX = math.floor((bw - plateW) / 2)

  -- the header names the target and the layer you are inside; the zone itself
  -- lives in the top bar. Gold means you are looking at an earlier zone.
  local looking = (zSel ~= st.zone)
  drawText(systemName() .. " · " .. layerName(zSel), 16, 40,
           looking and C.gold or C.dim, 2)
  if o.boss then
    px(16, 62, bw - 48, 2, C.warn)
  else
    for i = 0, 9 do px(16 + i * 16, 60, 8, 8, i < st.kills and C.gold or C.rule) end
  end

  local mx = math.floor(bw / 2) - 76
  local frac = st.hpMax > 0 and (st.hp / st.hpMax) or 1
  if o.boss then
    drawBossVuln(math.floor(bw / 2) - 86, monY - 12, frac, 1.1)
  else
    drawVuln(math.floor(bw / 2) - 88, monY - 4, frac, flash, 1.4)
  end

  px(plateX, nameY - 4, plateW, 20, ART.floor)  -- nameplate hides the floor studs
  drawTextC(nm, math.floor(bw / 2), nameY, C.text, 2)

  local frac = st.hp / st.hpMax
  hpBar(L.hpX, hpY, L.hpW, 32, frac, o.boss)
  drawText(fmt(st.hp) .. " / " .. fmt(st.hpMax), L.hpX + 8, hpY + 8, C.text, 2)
  drawTextR(math.floor(frac * 100 + 0.5) .. "%", L.labelR, hpY + 8, o.boss and C.warn or C.dim, 2)

  drawText("vulns " .. st.kills .. " / " .. (o.boss and 1 or 10), 32, killsY, C.dim, 2)
  drawTextR("+" .. fmt(st.goldKill) .. " credits", L.labelR, killsY, C.gold, 2)

  drawText("PROBE", 32, clickY, C.dim, 2)
  drawText(fmt(st.click), 108, clickY, C.gold, 2)
  drawTextR("DPS", L.labelR - 44, clickY, C.dim, 2)
  drawTextR(fmt(st.dps), L.labelR, clickY, C.gain, 2)
  if o.held then drawText("10/s", 168, clickY, C.dim, 2) end

  if o.held then
    px(mx + 132, monY + 42, 8, 8, C.gold); px(mx + 140, monY + 70, 8, 8, C.text)
    px(mx + 134, monY + 98, 8, 8, C.gold)
    drawText("-" .. fmt(st.click), mx + 148, monY, C.gold, 3)
    drawText("-" .. fmt(st.dps), mx + 148, monY + 28, C.gain, 2)
  end

  if o.boss then
    drawText("BOSS TIMER", 32, nextY, C.dim, 2)
    drawTextR("0:14", L.labelR, nextY, C.warn, 2)
    px(32, barY, L.hpW, 8, C.hpEmpty)
    px(32, barY, math.floor(L.hpW * (st.timer / 30) / 4) * 4, 8, C.warn)
  else
    drawText("NEXT SYSTEM", 32, nextY, C.dim, 2)
    drawTextR("ZONE 100", L.labelR, nextY, C.dim, 2)
    px(32, barY, L.hpW, 8, C.rule)
    px(32, barY, math.floor(L.hpW * math.min(st.zone, 100) / 100 / 4) * 4, 8, C.gold)
  end

  lg.pop()
  px(L.battleX - 2, L.topH, 2, L.H - L.topH - L.hintH, C.rule)

end

---------------------------------------------------------------- hero column
local function drawIcon(x, y, on)
  rrect(x, y, 16, 16, 2, on and C.rule or C.iconOff)
  local f = on and C.dim or C.iconFg
  px(x + 4, y + 4, 8, 6, f)
  px(x + 3, y + 11, 10, 4, f)
end

local function heroCol()
  local hw = L.heroW
  px(0, L.topH, hw, L.H - L.topH - L.hintH, C.ground)

  px(0, L.topH, hw, L.hdrH, C.panel)
  drawText("AGENT", L.nameX, L.topH, C.dim, 2)
  drawTextR("LV", L.lvX, L.topH, C.dim, 2)
  drawTextR("COST", L.costX, L.topH, C.dim, 2)
  if L.showDps then drawTextR("DPS", L.dpsX, L.topH, C.dim, 2) end
  px(0, L.topH + L.hdrH - 2, hw, 2, C.rule)

  for i = 0, L.rows - 1 do
    local h = st.agents[i + 1]
    if not h then break end
    local y = L.rowY + i * L.rowH
    local sel = (i == st.sel)
    local locked = h.lock ~= nil
    local afford = st.gold >= h.cost

    if sel then px(0, y, hw, L.rowH, C.panel) end
    if sel then px(0, y, 4, L.rowH, C.gold) end

    drawIcon(8, y + 8, not locked)

    drawText(fit(h.name, L.nameW), L.nameX, y + 8,
             locked and C.dim or (h.lv > 0 and C.text or C.dim), 2)
    drawTextR(locked and "-" or tostring(h.lv), L.lvX, y + 8,
              (h.lv > 0 and not locked) and C.text or C.dim, 2)

    local cost, cc
    if locked then cost, cc = "ZONE " .. h.lock, C.dim
    elseif h.max then cost, cc = "MAX", C.gold
    else cost, cc = fmt(h.cost), (afford and C.text or C.poor) end
    drawTextR(cost, L.costX, y + 8, cc, 2)

    if L.showDps then
      drawTextR(locked and "-" or fmt(h.dps), L.dpsX, y + 8,
                (locked or h.dps == 0) and C.dim or C.gain, 2)
    end

    if i < L.rows - 1 then px(4, y + L.rowH - 2, hw - 4, 2, C.rowsplit) end
  end

  px(0, L.footY, hw, L.footH, C.panel)
  px(0, L.footY, hw, 2, C.rule)
  drawText("BUY", 8, L.footY + 1, C.dim, 2)
  drawText(st.amount == 0 and "MAX" or ("×" .. tostring(st.amount)), 52, L.footY + 1, C.gold, 2)
  if L.showDps then
    drawTextR("+" .. fmt(st.gain) .. " DPS", L.dpsX, L.footY + 1, C.gain, 2)
  else
    drawTextR("+" .. fmt(st.gain), L.costX, L.footY + 1, C.gain, 2)
  end
end

---------------------------------------------------------------- other screens — wireframes
-- Placeholders on purpose: boxes, labels and rules with no numbers behind them.
-- The bars and rows use the same grammar as the hero list so the shapes are real.

local function panel(x, y, w, h, label)
  frame(x, y, w, h, 2, C.rule)
  if label then drawText(label, x + 12, y + 10, C.dim, 2) end
end

local function rowSel(x, y, w, h)
  px(x, y, w, h, C.panel)
end

local function rowsPanel(x, y, w, labels, title, sel, values)
  local rowH = 32
  local pad = title and 40 or 16
  local h = pad + #labels * rowH
  frame(x, y, w, h, 2, C.rule)
  if title then drawText(title, x + 12, y + 10, C.dim, 2) end
  for i, lb in ipairs(labels) do
    local ly = y + pad + (i - 1) * rowH
    if sel == i then rowSel(x + 4, ly - 6, w - 8, rowH - 2) end
    drawText(lb, x + 12, ly, sel == i and C.text or C.dim, 2)
    if values and values[i] then
      local v = values[i]
      if type(v) == "table" then
        drawTextR(v[1], x + w - 12, ly, v[2], 2)
      else
        drawTextR(v, x + w - 12, ly, sel == i and C.gold or C.text, 2)
      end
    end
    if i < #labels then px(x + 12, ly + 26, w - 24, 2, C.rowsplit) end
  end
  return h
end

-- Greedy word wrap: returns the lines that fit maxw, so long text never
-- gets chopped with an ellipsis when there is vertical room to wrap it.
local function wrapLines(str, maxw, sc)
  local lines, cur = {}, ""
  for word in tostring(str):gmatch("%S+") do
    local trial = (cur == "") and word or (cur .. " " .. word)
    if textW(trial, sc) <= maxw then
      cur = trial
    else
      if cur ~= "" then lines[#lines + 1] = cur end
      cur = word
    end
  end
  if cur ~= "" then lines[#lines + 1] = cur end
  return lines
end

-- Draw wrapped text, one wrapped line per step; returns the y after the block.
local function wireWrap(str, x, y, c, maxw, step)
  local lines = wrapLines(str, maxw)
  for i, line in ipairs(lines) do
    drawText(line, x, y + (i - 1) * (step or 24), c, 2)
  end
  return y + #lines * (step or 24)
end

local function wire(s, x, y, c, maxw)
  drawText(maxw and fit(s, maxw) or s, x, y, c or C.rule, 2)
end

local function statsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("STATS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, {
    "THROUGHPUT", "PROBE DAMAGE", "CREDITS PER VULN", "VULNS",
    "BEST LAYER", "SYSTEMS BREACHED", "ROOTKITS", "PLAYTIME",
  })
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h, "DPS BY LAYER")
end

-- SKILLS: the actives roster. Buying is not wired; owning is what puts a slot
-- into the battle strip.
local function skillsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("SKILLS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names, states = {}, {}
  for i, sk in ipairs(SKILLS) do
    names[i] = sk.name
    local cd = st.skillCd[i] or 0
    if cd > 0 then
      states[i] = { math.ceil(cd) .. "S", C.poor }
    elseif st.owned[i] then
      states[i] = { "OWNED", C.gold }
    else
      states[i] = { "LOCKED", C.rule }
    end
  end
  local sel = st.cursor[2]
  local h = rowsPanel(m, y, w, names, nil, sel, states)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local sk = SKILLS[sel]
  local wR2 = L.W - m - x2
  wire(sk.name, x2 + 12, y + 14, C.text, pw)
  wire("AGENT", x2 + 12, y + 42, C.dim, pw)
  drawTextR(sk.agent, x2 + wR2 - 12, y + 42, C.text, 2)
  local cdLeft = st.skillCd[sel] or 0
  wire("COOLDOWN", x2 + 12, y + 68, C.dim, pw)
  if cdLeft > 0 then
    drawTextR(math.ceil(cdLeft) .. "S LEFT", x2 + wR2 - 12, y + 68, C.poor, 2)
  else
    drawTextR(sk.cd .. "S", x2 + wR2 - 12, y + 68, C.text, 2)
  end
  if not st.owned[sel] then
    wire("COST", x2 + 12, y + 94, C.dim, pw)
    drawTextR(sk.cost, x2 + wR2 - 12, y + 94, C.gold, 2)
  end
  wire("EFFECT", x2 + 12, st.owned[sel] and y + 94 or y + 120, C.dim, pw)
  wireWrap(sk.eff, x2 + 12, st.owned[sel] and y + 118 or y + 144, C.text, pw, 24)
end

-- ACHIEVEMENTS: name + requirement, selectable like every other list.
local function achievementsScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("ACHIEVEMENTS", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names, states = {}, {}
  for i, a in ipairs(ACHIEVEMENTS) do
    names[i] = a[1]
    states[i] = st.achDone[i] and { "UNLOCKED", C.gold } or { "LOCKED", C.rule }
  end
  local sel = st.cursor[5]
  local h = rowsPanel(m, y, w, names, nil, sel, states)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local a = ACHIEVEMENTS[sel]
  wire(a[1], x2 + 12, y + 14, C.text, pw)
  wire("REQUIREMENT", x2 + 12, y + 42, C.dim, pw)
  wireWrap(a[2], x2 + 12, y + 68, C.text, pw, 24)
end

-- UPGRADES: the ten one-shot globals from docs/CONTENT.md, with their real
-- prices and effects as content. Selection moves; buying is not wired yet.
local UPGRADES = {
  { "SCANNER",     "1K",   "+25% probe damage" },
  { "WORDLIST",    "5K",   "+10% all throughput" },
  { "SKIMMER",     "20K",  "+25% credits from vulns" },
  { "EXPLOIT KIT", "100K", "x2 probe damage" },
  { "BOTNET",      "500K", "+15% all throughput" },
  { "LAUNDERER",   "2M",   "+50% credits from vulns" },
  { "0-DAY",       "10M",  "x3 probe damage" },
  { "BACKDOOR",    "50M",  "+20% all throughput" },
  { "MIXER",       "250M", "+100% credits from vulns" },
  { "PERSISTENCE", "2B",   "+25% throughput, +1 rootkit per ascension" },
}

local function upgradeLabels()
  local names = {}
  for i, u in ipairs(UPGRADES) do names[i] = u[1] end
  return names
end

local function upgradesScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("UPGRADES", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) * 0.56)
  local names = upgradeLabels()
  local states = {}
  for i = 1, #names do
    states[i] = st.upOwned[i] and { "OWNED", C.gold } or { "LOCKED", C.rule }
  end
  local sel = st.cursor[3]
  local h = rowsPanel(m, y, w, names, nil, sel, states)
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, h)
  local u = UPGRADES[sel]
  local wR3 = L.W - m - x2
  wire(u[1], x2 + 12, y + 14, C.text, pw)
  wire("COST", x2 + 12, y + 42, C.dim, pw)
  drawTextR(u[2], x2 + wR3 - 12, y + 42, C.gold, 2)
  wire("EFFECT", x2 + 12, y + 68, C.dim, pw)
  wireWrap(u[3], x2 + 12, y + 94, C.text, pw, 24)
end

local function prestigeScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("PRESTIGE", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, { "ROOTKITS ON OFFER", "ROOTKITS HELD", "BONUS PER ROOTKIT" })
  local ay = y + h + 16
  local c = st.cursor[4]
  if c == 5 then rowSel(m + 4, ay - 6, w - 8, 60) end
  frame(m, ay, w, 48, 2, c == 5 and C.gold or C.rule)
  drawText("ASCEND", m + 12, ay + 12, c == 5 and C.text or C.dim, 2)
  drawTextR("LOCKED · ZONE 100", m + w - 12, ay + 12, C.poor, 2)
  local x2 = m + w + gap
  local wR = L.W - m - x2
  local names, costs = {}, {}
  for i, d in ipairs(DAEMONS) do
    names[i], costs[i] = d[1], d[2]
  end
  rowsPanel(x2, y, wR, names, "DAEMONS · ROOTKIT SPEND", (c <= 4) and c or nil, costs)
end

local function menuScreen()
  local m, gap = 24, 16
  local bodyY = L.topH + 16
  drawText("MENU", m, bodyY, C.text, 2)
  local y = bodyY + 40
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local c = st.cursor[7]
  local items = { "RESUME", "SAVE", "QUIT" }
  for i, it in ipairs(items) do
    local ry = y + (i - 1) * 56
    local on = (i == c)
    if on then rowSel(m + 4, ry - 6, w - 8, 60) end
    frame(m, ry, w, 48, 2, on and C.gold or C.rule)
    drawText(it, m + 12, ry + 12, on and C.text or C.dim, 2)
  end
  local x2 = m + w + gap
  local pw = L.W - m - x2 - 24
  panel(x2, y, L.W - m - x2, 104, "ABOUT")
  wire("CLICKER AGENTS 0.1", x2 + 12, y + 40, C.text, pw)
  wire("GPL-3.0-OR-LATER", x2 + 12, y + 64, nil, pw)
  wire("LOVE 11.5 · PORTMASTER", x2 + 12, y + 88, nil, pw)
end

local function splashScreen()
  px(0, 0, L.W, L.H, C.ground)
  local cx = math.floor(L.W / 2)
  -- the badge is the real mark, drawn from the same grid as tools/gen_logo.py
  local cell = math.max(4, math.floor(math.min(L.W / 720, L.H / 480) * 8))
  local markSize = 20 * cell
  local my = math.floor(L.H * 0.12)
  drawMark(cx - math.floor(markSize / 2), my, cell)
  local scale = 4
  local ty = my + markSize + math.floor(L.H * 0.04)
  drawTextC("CLICKER AGENTS", cx, ty, C.gold, scale)
  drawTextC("AN UNLICENSED FRAMEWORK", cx, ty + 7 * scale + 12, C.text, 2)
  drawTextC("PRESS ANY BUTTON", cx, L.H - 72, C.dim, 2)
  px(0, L.H - 96, L.W, 2, C.rule)
  drawText("0.1", 16, L.H - 28, C.rule, 2)
  drawTextR("GPL-3.0-OR-LATER", L.W - 16, L.H - 28, C.rule, 2)
end

-- WELCOME BACK: the offline report from docs/DESIGN.md §7. Wireframe until the
-- save and the offline simulation exist; it appears once after the title so the
-- flow is real.
local function welcomeScreen()
  local m, gap = 24, 16
  px(0, 0, L.W, L.H, C.ground)
  drawText("WELCOME BACK", m, L.topH + 16, C.gold, 2)
  drawTextR("8 HOURS AWAY", L.W - m, L.topH + 16, C.dim, 2)
  local y = L.topH + 56
  local w = math.floor((L.W - m * 2 - gap) / 2)
  local h = rowsPanel(m, y, w, { "LAYERS GAINED", "CREDITS EARNED", "STOPPED AT" })
  local x2 = m + w + gap
  local wR = L.W - m - x2
  rowsPanel(x2, y, wR, { "DPS WHILE AWAY", "TIME SIMULATED", "BOSS REACHED" },
            "OFFLINE SUMMARY")
  px(m, y + h + 24, w, 48, C.rule)
  frame(m, y + h + 24, w, 48, 2, C.gold)
  drawText("CONTINUE", m + 12, y + h + 36, C.gold, 2)
  drawTextR("A", m + w - 12, y + h + 36, C.dim, 2)
end

---------------------------------------------------------------- interaction
-- Rows per tab, so the cursor knows where to stop. Nothing here changes state
-- beyond the cursor and a toast: this is the visual layer, wired end to end.
local ROWCOUNT = { 12, #SKILLS, #UPGRADES, 5, #ACHIEVEMENTS, 8, 3 }

local say                                       -- defined with the toast helpers below

-- X on the SKILLS tab casts the highlighted skill. A cooldown blocks it until
-- the timer runs out, and the row shows the seconds left while it does.
local function castSkill(i)
  local sk = SKILLS[i]
  if not sk then return end
  if not st.owned[i] then
    say("NEED " .. sk.cost .. " CREDITS")
    return
  end
  local cd = st.skillCd[i] or 0
  if cd > 0 then
    say(sk.name .. " · " .. math.ceil(cd) .. "S")
    return
  end
  st.skillCd[i] = sk.cd
  st.skillFlash = 0.4
  say(sk.name .. " ACTIVE")
end

-- L2/R2 walk the zone list you have already cleared; X snaps back to the live
-- zone. Nothing here changes combat yet — the arena just shows what you picked.
local function moveZone(d)
  local cur = st.zoneSel or st.zone
  local max = math.max(1, st.zone)
  local nxt = math.max(1, math.min(max, cur + d))
  if nxt == cur then return end
  st.zoneSel = nxt
  say("ZONE " .. nxt .. (nxt == st.zone and "" or " · EARLIER"))
end

-- switching screens clears any toast, so a message never follows you around
local function setTab(n)
  st.tab = n
  st.msg, st.msgT = nil, 0
end

function say(s) st.msg, st.msgT = s, 1.6 end

local function moveCursor(d)
  local n = ROWCOUNT[st.tab] or 1
  local c = (st.cursor[st.tab] or 1) + d
  if c < 1 then c = n elseif c > n then c = 1 end
  st.cursor[st.tab] = c
end

local function activate()
  local c = st.cursor[st.tab] or 1
  if st.tab == 2 then
    local sk = SKILLS[c]
    if st.owned[c] then say(sk.name .. " OWNED") else say("NEED " .. sk.cost .. " CREDITS") end
  elseif st.tab == 3 then
    say("NEED " .. UPGRADES[c][2] .. " CREDITS")
  elseif st.tab == 4 then
    if c == 5 then say("LOCKED · ZONE 100")
    else say(string.upper(DAEMONS[c][1]) .. " · " .. DAEMONS[c][2] .. " ROOTKITS") end
  elseif st.tab == 5 then
    say(ACHIEVEMENTS[c][1])
  elseif st.tab == 7 then
    if c == 1 then setTab(1); say("RESUMED")
    elseif c == 2 then say("SAVE UNAVAILABLE")
    else love.event.quit() end
  end
end

local function toast()
  if not st.msg or st.msgT <= 0 then return end
  local s = fit(st.msg, L.W - 56)
  local w = textW(s, 2) + 24
  local x = math.max(8, L.W - 8 - w)
  local y = L.H - L.hintH - 40            -- one band above the hint bar
  px(x, y, w, 24, C.panel)
  frame(x, y, w, 24, 2, C.rule)
  drawText(s, x + 12, y + 5, C.gold, 2)
end

---------------------------------------------------------------- loop
local function rebuild()
  local w, h = lg.getDimensions()
  L = Layout.compute(w, h, prefs.list)
end

function love.load()
  lg.setBackgroundColor(C.ground)
  lg.setDefaultFilter("nearest", "nearest")
  BINDS = readBinds()
  st.owned = {}
  for i, sk in ipairs(SKILLS) do st.owned[i] = sk.owned end
  st.upOwned = {}
  for i = 1, #UPGRADES do st.upOwned[i] = (i <= 2) end
  st.achDone = {}
  for i = 1, #ACHIEVEMENTS do st.achDone[i] = (i == 1 or i == 5) end
  rebuild()
  recalc()
end

function love.resize() rebuild() end

function love.draw()
  if st.screen == "splash" then splashScreen() return end
  if st.screen == "welcome" then welcomeScreen() return end
  topBar()
  if st.tab == 2 then skillsScreen()
  elseif st.tab == 3 then upgradesScreen()
  elseif st.tab == 4 then prestigeScreen()
  elseif st.tab == 5 then achievementsScreen()
  elseif st.tab == 6 then statsScreen()
  elseif st.tab == 7 then menuScreen()
  else
    battleCol(opts)
    heroCol()
  end
  hintBar()
  toast()
end

function love.update(dt)
  if st.flashT > 0 then st.flashT = math.max(0, st.flashT - dt) end
  if st.msgT > 0 then st.msgT = math.max(0, st.msgT - dt) end
  if st.skillFlash > 0 then st.skillFlash = math.max(0, st.skillFlash - dt) end
  for i = 1, #SKILLS do
    local c = st.skillCd[i] or 0
    if c > 0 then st.skillCd[i] = math.max(0, c - dt) end
  end
  if st.screen == "splash" then
    st.splashT = st.splashT + dt
    if st.splashT > 2.5 then st.screen = st.welcome and "welcome" or "game" end
  end
end

-- gptokeyb sends: x=A, z=B, c=X, v=Y, q/e=L/R, return=Start, tab=Select
function love.keypressed(key)
  dbg("[key] " .. tostring(key))          -- lands in log.txt on the device
  st.lastKey = key
  if st.screen == "splash" then
    if key == "escape" then love.event.quit()
    else st.screen = st.welcome and "welcome" or "game" end
    return
  end
  if st.screen == "welcome" then
    if key == "escape" then love.event.quit()
    elseif key == BINDS.buy then st.screen = "game" end   -- A continues, nothing else
    return
  end
  if key == "up" then
    if st.tab == 1 then setSel(st.sel - 1) else moveCursor(-1) end
  elseif key == "down" then
    if st.tab == 1 then setSel(st.sel + 1) else moveCursor(1) end
  elseif key == "left" then st.amount = math.max(1, st.amount - 1)
  elseif key == "right" then st.amount = math.min(100, st.amount + 1)
  elseif key == "q" then setTab(((st.tab - 2) % NTABS) + 1)   -- L: previous tab
  elseif key == "e" then setTab((st.tab % NTABS) + 1)         -- R: next tab
  elseif key == BINDS.buy then
    if st.tab == 1 then buyAmount(st.amount) else activate() end
  elseif key == BINDS.prevSkill then
    if st.tab == 1 then moveZone(-1) end          -- L2: down a zone
  elseif key == BINDS.nextSkill then
    if st.tab == 1 then moveZone(1) end           -- R2: up a zone
  elseif key == BINDS.fire then
    if st.tab == 1 then moveZone(st.zone - (st.zoneSel or st.zone))       -- X: back to the front
    elseif st.tab == 2 then castSkill(st.cursor[2]) end

  elseif key == BINDS.click then
    if st.tab == 1 then clickMonster() else setTab(1) end  -- printed B: back to battle
  elseif key == "tab" then st.idle = not st.idle        -- Select: auto-click
  elseif key == "return" then                           -- Start: cycle the amount
    if st.amount == 1 then st.amount = 10
    elseif st.amount == 10 then st.amount = 100
    elseif st.amount == 100 then st.amount = 0          -- 0 = MAX
    else st.amount = 1 end
  elseif key == "m" then                               -- desktop: cycle list width
    prefs.list = (prefs.list == "auto" and "narrow")
      or (prefs.list == "narrow" and "wide") or "auto"
    rebuild()
  elseif key == "1" then opts = {}
  elseif key == "2" then opts = { boss = true }
  elseif key == "3" then opts = { held = true, flash = true }
  elseif key == "escape" then love.event.quit() end
end

-- exposed for tests/headless.lua; LÖVE ignores a chunk's return value
return { state = st, prefs = prefs, layoutOf = function() return L end,
         bindsOf = function() return BINDS end }
