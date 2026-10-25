#!/usr/bin/env python3
"""One-off: split the original single-file main.lua into modules.

Slices are taken verbatim from /tmp/main_orig.lua so the drawing code survives
the move; the wrapper gives each module its requires and, where a screen needs
the run state, a module-level `st`/`L` that the exported entry point fills from
the context table before any body code runs.
"""
import pathlib

ROOT = pathlib.Path("/home/francois/Documents/Dev/Personal/ClickerAgents/game")
ORIG = pathlib.Path("/tmp/main_orig.lua").read_text().split("\n")


def slice_lines(a, b):
    """1-indexed inclusive."""
    return "\n".join(ORIG[a - 1:b])


def write(rel, text):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text if text.endswith("\n") else text + "\n")
    print("  wrote", rel, len(text.split("\n")), "lines")


# ---------------------------------------------------------------- config
write("config.lua", '''-- Palette, art colours and the few global preferences. Everything visual reads
-- from here, so retheming the game is a single file.
local M = {}

''' + slice_lines(10, 31) + '''

M.C = C
M.ART = ART
M.prefs = { list = "auto" }     -- "auto" | "narrow" | "wide"
return M
''')

# ---------------------------------------------------------------- log
write("core/log.lua", '''-- Debug logging. Silenced while the headless suite runs so test output stays
-- readable; on the device it lands in log.txt via the launcher's tee.
local M = {}
local enabled = not _G.DS_TEST

function M.dbg(s)
  if enabled then print(s) end
end

function M.set_enabled(v) enabled = v end
return M
''')

# ---------------------------------------------------------------- numbers
write("core/numbers.lua", '''-- Number formatting for a screen that has to show 1.24K and 2.4aa.
local M = {}

''' + slice_lines(110, 118) + '''

M.fmt = fmt
return M
''')

# ---------------------------------------------------------------- draw
write("ui/draw.lua", '''-- Pixel primitives and text. This is the only file that talks to
-- love.graphics for shapes; everything else composes these.
local GL = require("font")
local M = {}

local lg = love.graphics

''' + slice_lines(39, 107) + '''

''' + slice_lines(784, 810) + '''

M.px, M.rrect, M.frame = px, rrect, frame
M.text, M.textR, M.textC = drawText, drawTextR, drawTextC
M.textW, M.fit, M.chars = textW, fit, chars
M.wrapLines, M.wire, M.wireWrap = wrapLines, wire, wireWrap
return M
''')

# ---------------------------------------------------------------- widgets
write("ui/widgets.lua", '''-- Reusable panels and lists. Every screen is built out of these.
local Draw = require("ui.draw")
local Config = require("config")

local px, rrect, frame = Draw.px, Draw.rrect, Draw.frame
local text, textR = Draw.text, Draw.textR
local C = Config.C

local M = {}

''' + slice_lines(748, 782) + '''

M.panel, M.rowSel, M.rowsPanel = panel, rowSel, rowsPanel
return M
''')
