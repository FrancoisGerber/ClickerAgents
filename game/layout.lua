-- Clicker Agents — layout profiles.
-- One place that turns a screen size into every anchor the screens use.
-- Nothing is scaled: at any size the font stays 12 px and the rows stay 32,
-- so the picture is crisp on a 640x480 RG35XX and on a 720x480 RG34XX alike.
--
-- Profiles are picked by aspect ratio; the player-facing "list width"
-- preference overrides the fraction, not the profile.

local Layout = {}

local UNIT = 8          -- everything lands on an 8-px multiple
local ROW_H = 32
local TOP_H = 32
local HINT_H = 32
local HDR_H = 16
local FOOT_H = 16

local function snap(v) return math.floor(v / UNIT + 0.5) * UNIT end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- name | LV | COST | DPS, right-aligned, all derived from the column width.
-- When the column gets tight the DPS column is dropped rather than squeezing
-- three numbers and a name into 250 px.
local function anchors(heroW, showDps)
  local a
  if showDps then
    a = { lv = heroW - 148, cost = heroW - 76, dps = heroW - 8 }
  else
    a = { lv = heroW - 124, cost = heroW - 8, dps = nil }
  end
  a.name = 28
  a.nameW = math.max(36, a.lv - a.name - 28)
  return a
end

-- pref: "auto" (default), "narrow", "wide"
function Layout.compute(W, H, pref)
  local ratio = W / H
  local profile
  if ratio >= 1.45 then profile = "wide"          -- 720x480, 1280x720
  elseif ratio >= 1.15 then profile = "classic"   -- 640x480, 800x600
  else profile = "square" end                     -- 720x720

  local frac = (profile == "wide") and 0.40 or 0.42
  if pref == "narrow" then frac = 0.34
  elseif pref == "wide" then frac = 0.46 end

  local heroW = snap(clamp(W * frac, 240, 384))
  local battleW = W - heroW

  -- the DPS column survives only when a name keeps ~6 characters
  local showDps = (heroW - 148 - 28 - 28) >= 72
  local a = anchors(heroW, showDps)

  local bodyH = H - TOP_H - HINT_H
  local rows = math.max(6, math.floor((bodyH - HDR_H - FOOT_H) / ROW_H))

  return {
    W = W, H = H, ratio = ratio, profile = profile, pref = pref or "auto",
    topH = TOP_H, hintH = HINT_H, hdrH = HDR_H, footH = FOOT_H, rowH = ROW_H,
    heroW = heroW, battleX = heroW, battleW = battleW,
    rows = rows, rowY = TOP_H + HDR_H,
    footY = H - HINT_H - FOOT_H,
    showDps = showDps,
    nameX = a.name, nameW = a.nameW, lvX = a.lv, costX = a.cost, dpsX = a.dps,
    -- battle column, expressed from its own width so the bar and the numbers
    -- follow the column instead of the screen
    hpX = 32, hpW = battleW - 64,
    labelR = battleW - 32,
    midX = math.floor(battleW / 2),
  }
end

return Layout
