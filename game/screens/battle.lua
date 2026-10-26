local Draw = require("ui.draw")
local W = require("ui.widgets")
local Config = require("config")
local Numbers = require("core/numbers")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local text, textR, textC, textW = Draw.text, Draw.textR, Draw.textC, Draw.textW
local fit, wire, wireWrap = Draw.fit, Draw.wire, Draw.wireWrap
local drawText, drawTextR, drawTextC = Draw.text, Draw.textR, Draw.textC
local panel, rowSel, rowsPanel = W.panel, W.rowSel, W.rowsPanel
local C, ART = Config.C, Config.ART
local fmt = Numbers.fmt

local M = {}
local st, L, opts

local Sprites = require("ui.sprites")
local Systems = require("data.systems")
local drawVuln, drawBossVuln = Sprites.drawVuln, Sprites.drawBossVuln
local lg = { push = Draw.push, pop = Draw.pop, translate = Draw.translate }
local systemName, layerName, vulnName = Systems.name, Systems.layer, Systems.vuln
local Economy = require("sim.economy")
local Formulas = require("sim.formulas")
local Combat = require("sim.combat")

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
  -- the arena reads the boss from the run unless a preview explicitly overrides it
  local isBoss = o.boss
  if isBoss == nil then isBoss = st.boss end
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
  local cleared = st.cleared and not o.preview
  local nm = isBoss and "BOSS FIREWALL" or vulnName(zSel)
  local nw = textW(nm, 2)
  local plateW = math.max(nw + 16, 200)
  local plateX = math.floor((bw - plateW) / 2)

  -- the header names the target and the layer you are inside; the zone itself
  -- lives in the top bar. Gold means you are looking at an earlier zone.
  local looking = (zSel ~= st.zone)
  drawText(systemName() .. " · " .. layerName(zSel), 16, 40,
           looking and C.gold or C.dim, 2)
  if isBoss then
    px(16, 62, bw - 48, 2, C.warn)
  else
    for i = 0, 9 do px(16 + i * 16, 60, 8, 8, i < st.kills and C.gold or C.rule) end
  end

  local mx = math.floor(bw / 2) - 76
  local frac = st.hpMax > 0 and (st.hp / st.hpMax) or 1
  if isBoss then
    drawBossVuln(math.floor(bw / 2) - 86, monY - 12, frac, 1.1)
  else
    drawVuln(math.floor(bw / 2) - 88, monY - 4, frac, flash, 1.4)
  end

  px(plateX, nameY - 4, plateW, 20, ART.floor)  -- nameplate hides the floor studs
  drawTextC(nm, math.floor(bw / 2), nameY, C.text, 2)

  local frac = st.hpMax > 0 and (st.hp / st.hpMax) or 0
  hpBar(L.hpX, hpY, L.hpW, 32, frac, isBoss)
  local pct = math.floor(frac * 100 + 0.5) .. "%"
  -- the percentage is white and owns the right edge: in warn red it vanished into
  -- a full boss bar, and the numbers can grow into it if they are not clipped
  local room = (L.labelR - textW(pct, 2) - 8) - (L.hpX + 8)
  drawText(fit(fmt(st.hp) .. " / " .. fmt(st.hpMax), room), L.hpX + 8, hpY + 8, C.text, 2)
  drawTextR(pct, L.labelR, hpY + 8, C.text, 2)

  drawText("vulns " .. st.kills .. " / " .. (st.killsRequired or 10), 32, killsY, cleared and C.gold or C.dim, 2)
  drawTextR("+" .. fmt(st.creditsKill) .. " credits", L.labelR, killsY, C.gold, 2)

  drawText("PROBE", 32, clickY, C.dim, 2)
  drawText(fmt(st.click), 108, clickY, C.gold, 2)
  local dpsTxt = fmt(st.dps)
  drawTextR("DPS", L.labelR - textW(dpsTxt, 2) - 14, clickY, C.dim, 2)
  drawTextR(dpsTxt, L.labelR, clickY, C.gain, 2)
  if o.held then drawText("10/s", 168, clickY, C.dim, 2) end

  if o.held then
    px(mx + 132, monY + 42, 8, 8, C.gold); px(mx + 140, monY + 70, 8, 8, C.text)
    px(mx + 134, monY + 98, 8, 8, C.gold)
    drawText("-" .. fmt(st.click), mx + 148, monY, C.gold, 3)
    drawText("-" .. fmt(st.dps), mx + 148, monY + 28, C.gain, 2)
  end

  if cleared then
    drawText("NEXT ZONE READY", 32, nextY, C.gold, 2)
    drawTextR("X TO ADVANCE", L.labelR, nextY, C.gold, 2)
    px(32, barY, L.hpW, 8, C.gold)
  elseif isBoss then
    local t = math.max(0, st.timer)
    local late = t <= 10
    local pulse = late and (math.floor(os.clock() * 4) % 2 == 1)
    drawText("BOSS TIMER", 32, nextY, late and C.warn or C.dim, 2)
    drawTextR(string.format("%d:%02d", math.floor(t / 60), math.floor(t % 60)), L.labelR, nextY,
              pulse and C.text or (late and C.warn or C.text), 2)
    px(32, barY, L.hpW, 8, C.hpEmpty)
    local full = Combat.boss_seconds(st)
    px(32, barY, math.floor(L.hpW * math.min(1, t / full) / 4) * 4, 8, pulse and C.text or C.warn)
  else
    drawText("NEXT SYSTEM", 32, nextY, C.dim, 2)
    drawTextR("ZONE 100", L.labelR, nextY, C.dim, 2)
    px(32, barY, L.hpW, 8, C.rule)
    px(32, barY, math.floor(L.hpW * math.min(st.zone, 100) / 100 / 4) * 4, 8, C.gold)
  end

  lg.pop()
  px(L.battleX - 2, L.topH, 2, L.H - L.topH - L.hintH, C.rule)

end

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
    local sel = M.row_is_selected(st, i)
    local locked = not Economy.unlocked(st, i + 1)
    local cost = Economy.next_cost(st, i + 1)
    local rowDps = Formulas.agent_dps(h)
    local afford = st.credits >= cost

    if sel then px(0, y, hw, L.rowH, C.panel) end
    if sel then px(0, y, 4, L.rowH, C.gold) end

    drawIcon(8, y + 8, not locked)

    drawText(fit(h.name, L.nameW), L.nameX, y + 8,
             locked and C.dim or (h.lv > 0 and C.text or C.dim), 2)
    drawTextR(locked and "-" or tostring(h.lv), L.lvX, y + 8,
              (h.lv > 0 and not locked) and C.text or C.dim, 2)

    local label, cc
    if locked then label, cc = "ZONE " .. h.lock, C.dim
    else label, cc = fmt(cost), (afford and C.text or C.poor) end
    drawTextR(label, L.costX, y + 8, cc, 2)

    if L.showDps then
      drawTextR(locked and "-" or fmt(rowDps), L.dpsX, y + 8,
                (locked or rowDps == 0) and C.dim or C.gain, 2)
    end

    if i < L.rows - 1 then px(4, y + L.rowH - 2, hw - 4, 2, C.rowsplit) end
  end

  px(0, L.footY, hw, L.footH, C.panel)
  px(0, L.footY, hw, 2, C.rule)
  drawText("BUY", 8, L.footY + 1, C.dim, 2)
  drawText(st.amount == 0 and "MAX" or ("×" .. tostring(st.amount)), 52, L.footY + 1, C.gold, 2)
  if L.showDps then
    local own = Formulas.agent_dps(st.agents[st.sel])
    drawTextR("+" .. fmt(own) .. " DPS", L.dpsX, L.footY + 1, C.gain, 2)
  else
    drawTextR("+" .. fmt(Formulas.agent_dps(st.agents[st.sel])), L.costX, L.footY + 1, C.gain, 2)
  end
end

-- Rows are drawn 0-based and the selection is 1-based. Keeping the mapping in
-- one place is what stops "the highlight is on the second agent but A buys the
-- first" from happening again.
function M.row_is_selected(st, row)
  return (row + 1) == st.sel
end

function M.draw(ctx)
  st, L, opts = ctx.state, ctx.layout, ctx.opts or {}
  battleCol(opts)
  heroCol()
end

return M
