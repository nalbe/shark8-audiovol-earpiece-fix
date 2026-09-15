# Shark8 Quiet Earpiece Fix (WB/RCV GSM dl_gain)

Blackview Shark 8 (MT6789/Helio G99, EEA, Android 13) - weak earpiece (handset) volume
during phone calls. Reproduced on two physical units: stock unrooted EEA and
rooted iodEOS GSI (native vendor). Hands-free and wired/BT are unaffected.

## Root cause

Call download gain (digital gain) on this platform lives in the XML-only tuning
stores under `/vendor/etc/audio_param/` (`ro.vendor.mtk_audio_tuning_tool_ver=V1`,
no NVRAM calibration in play - `/data/nvram` does not exist on this model).

`SpeechVol_AudioParam.xml`, unit `param_id="11"` (paths `WB,RCV,GSM` and
`WB,HAC,GSM`) carries a broken downlink gain table:

```
dl_gain = "22,19,16,4,8,5,2"    <- broken: step 4 is 4 dB instead of ~12 dB
```

Neighbouring tables are monotonic and sane:
- RCV (id 0):       `22,19,16,13,10,7,4`
- NB,RCV,GSM (id12):`22,19,16,12,8,5,2`
- SWB,RCV,GSM (id9):`22,19,16,12,8,5,2`

VoLTE calls run in WB mode -> WB,RCV,GSM applies. On the 4th of 7 volume steps
(roughly "middle" volume, where most people keep it) the earpiece gets 4 dB
instead of ~12 dB -> noticeably quiet receiver.

The gap (`4` vs expected `12`) looks hand-edited, matching suspicion it landed
with the DAS/ANFR power-limit firmware updates (V13/V14, SHARK8_EEA_M9905A).

Note: `SpeechVol_AudioParam.xml` is byte-identical on both stock and rooted
units, i.e. factory calibration, not per-unit variance.

## Fix

Patched table for `param_id="11"`:

```
dl_gain = "22,19,16,12,8,5,2"
ul_gain = 18 (unchanged)
stf_gain = 0 (unchanged)
```

Files:
- `files/speechvol_patched.xml` - patched file
- `files/speechvol_orig.xml` - pristine factory file
- `module/` - KernelSU module tree (vendor overlay layout)

## Caveat: KSU standalone module hangs boot

On this device a **standalone** KSU module that overlays `/vendor/etc/...`
(the `<module>/vendor/...` layout) reliably hangs boot (logo, before zygote),
even though the module tree itself is valid and SELinux context comes out right.
A separate system/vendor-layout module hangs the same. The RAW module overlay
(which already mounts `lowerdir=/data/adb/modules/RAW/vendor:/vendor`) loads
fine, so the working approach is to drop the file into `RAW/vendor/etc/audio_param/`.

## Apply

From a host with the device connected over adb (no reboot-to-recovery needed,
adb root suffices):

```sh
adb push files/speechvol_patched.xml /data/local/tmp/_patched_speechvol.xml
adb root
adb shell "mkdir -p /data/adb/modules/RAW/vendor/etc/audio_param && cp /data/local/tmp/_patched_speechvol.xml /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && chown root:root /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml && chmod 644 /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml"
adb reboot
```

Helpers: `scripts/apply.sh [serial]`, `scripts/revert.sh [serial]`.

## Verify

After reboot confirm the mounted file is patched:

```sh
adb root
adb shell "grep -n '22,19,16,12' /vendor/etc/audio_param/SpeechVol_AudioParam.xml"
```

Then make a real call and sweep the in-call volume around step 4/7. The step
jump should be even now (16 -> 12 dB).

## Revert

```sh
adb root
adb shell "rm -f /data/adb/modules/RAW/vendor/etc/audio_param/SpeechVol_AudioParam.xml"
adb reboot
```

Boot does not depend on the file; a parse failure at worst keeps the prior
gain table, it never bootloops.