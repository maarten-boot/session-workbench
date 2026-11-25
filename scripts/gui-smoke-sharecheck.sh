#!/bin/bash
# Headless GUI test of the host dialog's shared file system helpers (SPEC
# F2c): VM share setup… shows the libvirt XML for the local prefix (Copy
# puts it on the clipboard; virtio-9p changes it); Check share runs on the
# agent host (localhost) with the values as typed, a missing remote prefix
# gives another result; Cancel leaves config.toml as it was.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-sharecheck.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
PROF=swshare$$
cleanup() { rm -rf "$HOME/.local/state/$PROF"; }
trap cleanup EXIT
rm -rf $OUT/share; mkdir -p $OUT/share; touch $OUT/share/alpha $OUT/share/beta
CFG=$OUT/config.toml
cat >$CFG <<TOML
[[hosts]]
name = "local"
ssh_target = "localhost"
local_prefix = "$OUT/share"
remote_prefix = "$OUT/share"
TOML
cp $CFG $OUT/config-before.toml
shot() { import -window root $OUT/$1.png; }
same() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d" " -f1)" = 0 ]; }
differ() { ! same "$@"; }
k() { xdotool key "$@"; sleep 0.6; }
click() { xdotool mousemove $1 $2 click ${3:-1}; sleep ${4:-1}; }
clip() { python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk,Gdk; print(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD).wait_for_text())" 2>/dev/null; }

$BIN -config $CFG -profile $PROF >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
click 100 103 3                          # right-click the host heading LOCAL
k e Return; sleep 1                      # Edit host…
shot 1-host-dialog
click 634 811 1 1.5                      # VM share setup…
shot 2-vmshare
click 410 535                            # Copy (the XML)
X=$(clip)
check "Copy puts the XML for the local prefix on the clipboard" grep -q "<source dir='$OUT/share'/>" <<<"$X"
check "virtiofs: shared memory and the virtiofs driver" grep -q "<driver type='virtiofs'/>" <<<"$X"
click 700 181 1 0.5; k Down; k Return    # Driver: virtio-9p
shot 3-vmshare-9p
check "virtio-9p changes the guide" differ 2-vmshare 3-vmshare-9p
k Tab; k space                           # the first Copy after the driver: the XML
X=$(clip)
check "virtio-9p XML: path driver, no shared memory" bash -c "grep -q \"<driver type='path'/>\" <<<\"\$1\" && ! grep -q memoryBacking <<<\"\$1\"" _ "$X"
k Escape                                 # back to the host dialog
shot 4-back
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
TITLE=500x60+440+55                      # the dialog's title and Name field (no toast, no focus ring)
crop 1-host-dialog $TITLE 1-title; crop 4-back $TITLE 4-title
check "Close goes back to the host dialog" same 1-title 4-title
click 510 811 1 4                        # Check share (ssh localhost)
for i in 1 2 3 4 5 6; do xdotool mousemove 700 600 click 5; done; sleep 0.8
shot 5-checked
check "Check share shows a result" differ 4-back 5-checked
# The remote prefix as typed (not saved): a folder that is not there.
click 700 540 1 0.3; k ctrl+a; xdotool type --delay 12 "$OUT/nothere"; k Tab; k space; sleep 4
shot 6-missing
check "a missing remote prefix gives another result" differ 5-checked 6-missing
k Escape                                 # Cancel the host dialog
alive
stop_app
check "Cancel leaves config.toml as it was" cmp -s $OUT/config-before.toml $CFG
finish
