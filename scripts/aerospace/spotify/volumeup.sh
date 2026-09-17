#!/bin/bash
osascript \
  -e 'tell application "Spotify"' \
  -e 'set targetVolume to sound volume + 5' \
  -e 'if targetVolume > 100 then set targetVolume to 100' \
  -e 'set sound volume to targetVolume' \
  -e 'end tell'
