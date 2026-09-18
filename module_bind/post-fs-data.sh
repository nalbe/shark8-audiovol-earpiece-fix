#!/system/bin/sh
# Shark8 earpiece volume fix - bind variant.
# Bind-mounts the patched SpeechVol_AudioParam.xml over the /vendor copy.
# No vendor/ tree in this module -> KernelSU sets up NO overlay -> no boot hang.
MODDIR=${0%/*}
SRC="$MODDIR/SpeechVol_AudioParam.xml"
TGT=/vendor/etc/audio_param/SpeechVol_AudioParam.xml

if [ ! -f "$SRC" ]; then
  log -p e -t earpiece_fix "source missing: $SRC"
  exit 1
fi

chown root:root "$SRC" 2>/dev/null
chmod 644 "$SRC" 2>/dev/null
chcon u:object_r:vendor_file:s0 "$SRC" 2>/dev/null

if ! mount --bind "$SRC" "$TGT" 2>/dev/null; then
  log -p e -t earpiece_fix "bind mount failed: $SRC -> $TGT"
  exit 1
fi

log -p i -t earpiece_fix "bound $SRC -> $TGT"
exit 0