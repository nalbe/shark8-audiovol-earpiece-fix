#!/bin/sh
# Shark8 quiet earpiece fix - revert helper (run on host, device connected via adb)
# Drops the patched file from the RAW module overlay and reboots.
set -e

DEV="${1:-}"
S=""
[ -n "$DEV" ] && S="-s $DEV"

adb $S root >/dev/null 2>&1
sleep 2
adb $S shell "rm -f /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && echo REVERTED"

echo "rebooting in 5s (Ctrl+C to abort)"
sleep 5
adb $S reboot