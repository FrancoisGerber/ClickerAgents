#!/bin/bash
# Capture every screen with its selection and any toast at 720x480.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/design"
GAME=$ROOT/game
OUT=$ROOT/design
Xvfb :90 -screen 0 720x480x24 >/tmp/xvfb90.log 2>&1 &
XPID=$!
sleep 2
DISPLAY=:90 love "$GAME" >/tmp/ds90.log 2>&1 &
LPID=$!
sleep 1.1
export DISPLAY=:90
import -window root "$OUT/screen-0-splash.png"
WIN=$(xdotool search --name "Clicker Agents" | head -1)
xdotool windowactivate "$WIN" 2>/dev/null; xdotool windowfocus "$WIN"
sleep 0.3
shot() { import -window root "$OUT/$1"; echo "  $1"; }
key() { xdotool key --window "$WIN" "$1"; sleep 0.35; }

key x; shot "screen-1-welcome.png"   # A continues off the title
key x; shot "screen-2-battle.png"    # A continues off the report
key g; key c; sleep 0.3; shot "screen-2c-cast.png"     # R2 selects, X casts
key 2; shot "screen-2b-boss.png"      # boss preview
key 1
key e; key Down; key Down; key x; sleep 0.4; shot "screen-3-skills.png"
key e; key Down; key Down; key x; sleep 0.4; shot "screen-3b-upgrades.png"
key e; key Down; key Down; key Down; key Down; key x; sleep 0.4; shot "screen-4-prestige.png"
key e; key Down; key Down; key x; sleep 0.4; shot "screen-4b-achievements.png"
key e; shot "screen-5-stats.png"
key e; key Down; shot "screen-6-menu.png"

kill $LPID 2>/dev/null; kill $XPID 2>/dev/null
echo done
