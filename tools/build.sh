#!/bin/bash
# Package the game: game/ -> clickeragents.love -> port/ -> ClickerAgents.zip
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

rm -f /tmp/clickeragents.love ClickerAgents.zip
(cd game && zip -9 -q -r /tmp/clickeragents.love . -x '*.love')   # every module, not a file list
cp /tmp/clickeragents.love port/clickeragents/clickeragents.love
# the pak ships the same artwork the repo and the device images folder get
mkdir -p port/clickeragents/images
cp art/logo.png port/clickeragents/images/logo.png
cp art/cover.png port/clickeragents/images/cover.png
(cd port && zip -9 -q -r ../ClickerAgents.zip ClickerAgents.sh clickeragents/ port.json gameinfo.xml README.md screenshot.png cover.png)

echo "clickeragents.love  $(sha256sum port/clickeragents/clickeragents.love | cut -c1-16)  $(du -h port/clickeragents/clickeragents.love | cut -f1)"
echo "ClickerAgents.zip   $(sha256sum ClickerAgents.zip | cut -c1-16)  $(du -h ClickerAgents.zip | cut -f1)"
