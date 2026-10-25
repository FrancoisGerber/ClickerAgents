#!/bin/bash
# Syntax check, then the headless suite over three screen sizes.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

luac -p game/main.lua game/layout.lua game/font.lua || exit 1
lua tests/headless.lua
