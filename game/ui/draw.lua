-- Pixel primitives and text. This is the only file that talks to
-- love.graphics for shapes; everything else composes these.
local GL = require("font")
local C = require("config").C
local M = {}

local lg = love.graphics

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
    -- the font deliberately has no zero: a slashed-only zero read as garbage on the
    -- device. Digits fall back to the letter O, which is what a 5x7 zero looks like.
    local rows = GL[ch] or GL[ch:upper()] or (ch == "0" and GL["O"]) or GL["?"]
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

M.push = function() lg.push() end
M.pop = function() lg.pop() end
M.translate = function(dx, dy) lg.translate(dx, dy) end

M.px, M.rrect, M.frame = px, rrect, frame
M.text, M.textR, M.textC = drawText, drawTextR, drawTextC
M.textW, M.fit, M.chars = textW, fit, chars
M.wrapLines, M.wire, M.wireWrap = wrapLines, wire, wireWrap
return M
