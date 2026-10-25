#!/usr/bin/env python3
"""Draw Clicker Agents' logo, mark and pak cover from code.

Everything is generated: the wordmark reuses the same 5x7 bitmap font the game
draws with, so the logo can never drift from the game. No external assets, no
fonts to license, nothing to trace by hand.

    python3 tools/gen_logo.py

Writes art/*.svg plus art/*.png (via rsvg-convert) and the pak cover at
port/clickeragents/images/cover.png.
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ART = ROOT / "art"

BG = "#0B0D12"
PANEL = "#161A24"
RULE = "#2A3040"
TEXT = "#E6E9F0"
DIM = "#8A93A6"
GOLD = "#E8B45A"
HOT = "#FFF0C8"

CELL_ADVANCE = 6          # the font's advance, in 5x7 cells


# ---------------------------------------------------------------- font
def load_glyphs():
    """Read the 5x7 glyph table straight out of game/font.lua."""
    src = (ROOT / "game" / "font.lua").read_text(encoding="utf-8")
    glyphs = {}
    for ch, bits in re.findall(r'\["(.?)"\]\s*=\s*"([0-9/]+)"', src):
        rows = bits.split("/")
        if len(rows) == 7 and all(len(r) == 5 for r in rows):
            glyphs[ch] = rows
    if not glyphs:
        sys.exit("no glyphs found in game/font.lua")
    return glyphs


GLYPHS = load_glyphs()


def text_rects(text, x, y, cell, colour):
    """One <rect> per horizontal run of pixels — pixel text, cheap in SVG."""
    out, cursor = [], x
    for ch in text.upper():
        rows = GLYPHS.get(ch)
        if rows is None:
            cursor += CELL_ADVANCE * cell
            continue
        for ry, row in enumerate(rows):
            run = 0
            for rx, bit in enumerate(row + "0"):
                if bit == "1":
                    run += 1
                elif run:
                    out.append(
                        f'<rect x="{cursor + (rx - run) * cell}" y="{y + ry * cell}" '
                        f'width="{run * cell}" height="{cell}" fill="{colour}"/>'
                    )
                    run = 0
        cursor += CELL_ADVANCE * cell
    return out, cursor - x


def text_width(text, cell):
    return len(text) * CELL_ADVANCE * cell - cell


# ---------------------------------------------------------------- mark
def grid_rects(grid, x, y, cell, colours):
    """Turn a list of equal-length strings into merged rects.

    '.' is empty, everything else is looked up in `colours`.
    """
    out = []
    for gy, row in enumerate(grid):
        run_ch, run = None, 0
        for gx, ch in enumerate(row + "."):
            if ch == run_ch and ch != ".":
                run += 1
                continue
            if run_ch and run_ch != ".":
                out.append(
                    f'<rect x="{x + (gx - run) * cell}" y="{y + gy * cell}" '
                    f'width="{run * cell}" height="{cell}" fill="{colours[run_ch]}"/>'
                )
            run_ch, run = (ch if ch != "." else None), (1 if ch != "." else 0)
    return out


# Inner art for the badge. 16x16 cells, drawn inside the gold frame.
# A: the clicker itself — a pointer cutting a broken bar.
MARK_POINTER = [
    "................",
    ".gg.............",
    ".gggg...........",
    ".gggggg.........",
    ".gggggggg.......",
    ".gggggggggg.....",
    ".gggggggggggg...",
    ".ggggggggggg....",
    ".gggggggggg.....",
    ".gggg..gggg.....",
    ".ggg....ggg.....",
    ".gg......gg.....",
    ".g........g.....",
    "................",
    "....mmmmmmmm....",
    "................",
]

# B: a node being breached — hexagon, solid core, one edge knocked out.
MARK_BREACH = [
    "................",
    ".....gggggg.....",
    "...gg......gg...",
    "..g..........g..",
    ".g............g.",
    ".g.....gg.....g.",
    "g.....gggg.....g",
    "g.....gggg......",
    "g.....gggg.....g",
    ".g.....gg....g..",
    ".g..........gg..",
    "..g........g....",
    "...gg....gg.....",
    ".....gggggg.....",
    "................",
    "................",
]

PALETTE = {"s": PANEL, "d": RULE, "g": GOLD, "h": HOT, "m": RULE}


def svg(width, height, body, bg=None):
    back = f'<rect width="{width}" height="{height}" fill="{bg}"/>' if bg else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n{back}\n' + "\n".join(body) + "\n</svg>\n"
    )


def badge(x, y, size, inner, inset=2):
    """Gold frame, dark interior, then the inner grid inside it."""
    cell = size // 20
    body = [f'<rect x="{x}" y="{y}" width="{size}" height="{size}" fill="{GOLD}"/>']
    body.append(f'<rect x="{x + inset * cell}" y="{y + inset * cell}" '
                f'width="{size - 2 * inset * cell}" height="{size - 2 * inset * cell}" '
                f'fill="{BG}"/>')
    body += grid_rects(inner, x + inset * cell, y + inset * cell, cell, PALETTE)
    return body


def lockup_raw(draw_mark, inner, width, height, tagline=None):
    """Mark on the left, two-line wordmark on the right, tagline underneath.

    The wordmark sets the height; the badge is sized to match it, so the two
    always line up rather than drifting apart as the canvas changes.
    """
    line1, line2 = "CLICKER", "AGENTS"
    pad = int(height * 0.07)
    gap = int(height * 0.09)

    tag_cell = 0
    tag_h = 0
    if tagline:
        tag_cell = max(2, int(min(height * 0.042,
                                  (width * 0.70) / (CELL_ADVANCE * len(tagline)))))
        tag_h = 7 * tag_cell + int(height * 0.05)

    band = height - 2 * pad - tag_h          # vertical space for mark + wordmark
    max_len = max(len(line1), len(line2))
    cell = max(2, int(min((width * 0.62) / (CELL_ADVANCE * max_len),
                          band / (7 * 2 + 3))))
    block_h = 7 * cell * 2 + int(cell * 3)

    mark_px = block_h - block_h % 20
    total_w = mark_px + gap + (CELL_ADVANCE * max_len - 1) * cell
    x0 = (width - total_w) // 2
    ty = pad + (band - block_h) // 2
    my = ty
    tx = x0 + mark_px + gap

    body = draw_mark(x0, my, mark_px, inner)
    body += text_rects(line1, tx, ty, cell, DIM)[0]
    body += text_rects(line2, tx, ty + 7 * cell + int(cell * 3), cell, GOLD)[0]

    if tagline:
        tag_w = text_width(tagline, tag_cell)
        body += text_rects(tagline, (width - tag_w) // 2,
                           height - pad - 7 * tag_cell, tag_cell, DIM)[0]
    return body


def lockup(inner, width, height, tagline=None):
    return lockup_raw(badge, inner, width, height, tagline)


# a 10x10 agent: a small node with a bead of light inside
AGENT = [
    "..dddddd..",
    ".dssssssd.",
    "dssssssssd",
    "dss.dd.ssd",
    "dssdggdssd",
    "dssdggdssd",
    "dss.dd.ssd",
    "dssssssssd",
    ".dssssssd.",
    "..dddddd..",
]


def cover_svg(inner):
    W, H = 480, 360
    body = [f'<rect width="{W}" height="{H}" fill="{BG}"/>']
    for y in range(0, H, 8):
        body.append(f'<rect x="0" y="{y}" width="{W}" height="1" fill="{PANEL}" opacity="0.35"/>')

    body += lockup(inner, W, int(H * 0.56), tagline="AN UNLICENSED FRAMEWORK")

    # a squad of agents walking in under the lockup
    cell = 5
    for i in range(3):
        x = W // 2 - (10 * cell * 3 + 2 * cell * 4) // 2 + i * (10 * cell + 2 * cell * 2)
        body += grid_rects(AGENT, x, int(H * 0.70), cell, PALETTE)

    body.append(f'<rect x="0" y="{H - 30}" width="{W}" height="2" fill="{RULE}"/>')
    body += text_rects("GPL-3.0-OR-LATER", 12, H - 24, 2, RULE)[0]
    label = "V1"
    body += text_rects(label, W - 12 - text_width(label, 2), H - 24, 2, RULE)[0]
    return svg(W, H, body)


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print("  ", path.relative_to(ROOT))


def png(svg_path, out, width=None, height=None):
    cmd = ["rsvg-convert", "-o", str(out)]
    if width:
        cmd += ["-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    cmd.append(str(svg_path))
    subprocess.run(cmd, check=True)
    print("  ", out.relative_to(ROOT), f"({out.stat().st_size} B)")


def main():
    ART.mkdir(exist_ok=True)
    inner = MARK_POINTER

    # the lockup: used on the cover, in the README and on GitHub
    body = lockup(inner, 1200, 320, tagline="AN UNLICENSED FRAMEWORK")
    write(ART / "logo.svg", svg(1200, 320, body))
    png(ART / "logo.svg", ART / "logo.png", width=1200)
    png(ART / "logo.svg", ART / "logo@2x.png", width=2400)

    # the mark on its own, at the sizes a launcher or store listing needs
    write(ART / "mark.svg", svg(400, 400, badge(0, 0, 400, inner)))
    for size in (400, 128, 64):
        png(ART / "mark.svg", ART / f"mark-{size}.png", width=size)
    png(ART / "mark.svg", ART / "mark.png", width=400)

    # GitHub social preview is 1280x640 with the mark on the left
    gh = [f'<rect width="1280" height="640" fill="{BG}"/>']
    for y in range(0, 640, 8):
        gh.append(f'<rect x="0" y="{y}" width="1280" height="1" fill="{PANEL}" opacity="0.35"/>')
    gh += lockup(inner, 1280, 340, tagline="AN UNLICENSED FRAMEWORK")
    write(ART / "social.svg", svg(1280, 640, gh))
    png(ART / "social.svg", ART / "social.png", width=1280)

    # the pak cover, and the copy the pak actually ships
    write(ART / "cover.svg", cover_svg(inner))
    png(ART / "cover.svg", ART / "cover.png", width=480)
    pak = ROOT / "port" / "clickeragents" / "images"
    pak.mkdir(parents=True, exist_ok=True)
    png(ART / "cover.svg", pak / "cover.png", width=480)


if __name__ == "__main__":
    main()
