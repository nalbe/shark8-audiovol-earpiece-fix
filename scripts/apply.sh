#!/bin/sh
# Shark8 quiet earpiece fix - apply helper (run on host, device connected via adb)
# Applies patched SpeechVol_AudioParam.xml through the already-mounted RAW module,
# because a standalone KSU module with a vendor overlay hangs boot on this setup.
set -e

DEV="${1:-}"
S=""
[ -n "$DEV" ] && S="-s $DEV"

adb $S push files/speechvol_patched.xml /data/local/tmp/_patched_speechvol.xml
adb $S root >/dev/null 2>&1
sleep 2
adb $S shell "mkdir -p /data/adb/modules/RAW/vendor/etc/audio_param && cp /data/local/tmp/_patched_speechvol.xml /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && chown root:root /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && chmod 644 /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && echo APPLIED"

echo "rebooting in 5s (Ctrl+C to abort)"
sleep 5
adb $S reboot