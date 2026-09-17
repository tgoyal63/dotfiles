#!/bin/bash
osascript \
  -e 'tell application "Spotify"' \
  -e 'set targetVolume to sound volume - 5' \
  -e 'if targetVolume < 0 then set targetVolume to 0' \
  -e 'set sound volume to targetVolume' \
  -e 'end tell'
