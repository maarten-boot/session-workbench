#!/bin/bash
# Headless GUI test of D2 diagrams (SPEC N1d): a ```d2 block in Notes is
# drawn below its text, an error shows D2's message, an edit draws it again;
# a ```d2 block in a Q&A answer is drawn with its source folded below;
# right-click → Copy image puts a drawing on the clipboard as a PNG at twice
# its size (read back with scripts/clipimage).
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-d2.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT; rm -rf $OUT/notes
. "$(dirname "$0")/smoke-lib.sh"
CFG=$OUT/config.toml
cat >$CFG <<TOML
[ui]
theme = "light"
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "s-d2"
name = "diagrams"
host = "local"
local_path = "/tmp"
start_mode = "shell"
TOML
mkdir -p $OUT/notes/s-d2
cat >$OUT/notes/s-d2/Home.md <<'MD'
# Diagrams
```d2
web -> api: REST
api -> db
```
Broken:
```d2
a -> {
```
MD
mkdir -p $XDG_DATA_HOME/session-workbench/qa
python3 - $XDG_DATA_HOME/session-workbench/qa/s-d2.json <<'PY'
import json, sys
a = "The flow:\n\n```d2\nclient -> server: ask\nserver -> client: answer\n```\n\nDone."
json.dump({"turns": [{"time": "2026-11-17T10:00:00Z", "question": "Draw the flow", "answer": a, "usage": {}}]}, open(sys.argv[1], "w"))
PY
k() { xdotool key "$@"; sleep 0.5; }
shot() { import -window root $OUT/$1.png; }
# blue <shot> <geometry>: how many pixels there have D2's default line
# colour (#0D32B2): the diagram is drawn.
blue() { convert $OUT/$1.png -crop $2 +repage -fill black +opaque 'srgb(13,50,178)' -fill white -opaque 'srgb(13,50,178)' -format '%[fx:int(mean*w*h)]' info:; }
# clipimage reads the clipboard's image (the same library as the app).
(cd "$(dirname "$0")/.." && go build -o $OUT/clipimage ./scripts/clipimage) || exit 1
# size <name> <w> <h>: "ok" when <name>.png is a PNG of about w x h pixels (±10%).
size() { python3 -c 'import struct,sys; b=open(sys.argv[1],"rb").read(24); w,h=struct.unpack(">II",b[16:24]); W,H=int(sys.argv[2]),int(sys.argv[3]); print("ok" if b[:8]==b"\x89PNG\r\n\x1a\n" and abs(w-W)<=W/10 and abs(h-H)<=H/10 else f"{w}x{h}")' $OUT/$1.png $2 $3; }
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
k ctrl+alt+1; k ctrl+shift+4; sleep 3                 # Notes
xdotool mousemove 1250 830; sleep 0.5
shot 1-notes
n=$(blue 1-notes 1000x700+340+90)
check "Notes draws the d2 block ($n blue pixels)" test "$n" -gt 200
# Right-click on the drawing: Copy image puts it on the clipboard as a PNG
# at twice its size.
xdotool mousemove 540 330 click 3; sleep 0.8
shot 1a-menu
xdotool mousemove 590 350 click 1; sleep 1.5                 # Copy image
xdotool mousemove 1250 830; sleep 0.3
check "Notes: Copy image puts a PNG on the clipboard" $OUT/clipimage $OUT/notes-copy.png
# The drawing is about 110 x 450 pixels on screen: the PNG twice that.
expect "Notes: the PNG is twice the drawing's size" "ok" "$(size notes-copy 220 900 2>&1)"
# An edit in the block: drawn again shortly after (the old picture stays
# meanwhile), and saved.
convert $OUT/1-notes.png -crop 600x500+480+260 +repage $OUT/1-diagram.png
xdotool mousemove 900 228 click 1; sleep 0.5                 # end of "api -> db"
xdotool key End; xdotool type --delay 20 -- ' -> cache'; sleep 3
xdotool mousemove 1250 830; sleep 0.5
shot 2-edited
convert $OUT/2-edited.png -crop 600x500+480+260 +repage $OUT/2-diagram.png
check "the edit draws it again" test "$(compare -metric AE $OUT/1-diagram.png $OUT/2-diagram.png null: 2>&1 | cut -d' ' -f1)" != 0
n=$(blue 2-edited 1000x700+340+90)
check "still a diagram after the edit ($n blue pixels)" test "$n" -gt 200
check "the edit is saved" grep -q 'api -> db -> cache' $OUT/notes/s-d2/Home.md
# Q&A: the answer's d2 block is drawn, its source folded below.
k ctrl+shift+6; sleep 3; xdotool mousemove 1250 830; sleep 0.5
shot 3-qa
# Left of where Notes' page tree ends: only Q&A has a picture there.
n=$(blue 3-qa 160x600+305+130)
check "Q&A draws the answer's d2 block ($n blue pixels)" test "$n" -gt 200
# Right-click on the answer's drawing (about 140 x 290 on screen): Copy image first.
xdotool mousemove 360 300 click 3; sleep 0.8
shot 3a-qa-menu
xdotool mousemove 410 320 click 1; sleep 1.5                 # Copy image
xdotool mousemove 1250 830; sleep 0.3
check "Q&A: Copy image puts a PNG on the clipboard" $OUT/clipimage $OUT/qa-copy.png
expect "Q&A: the PNG is twice the drawing's size" "ok" "$(size qa-copy 276 576 2>&1)"
# After an image, the app's text copy still works: select the question, Copy.
xdotool mousemove 400 161 click 1 click 1; sleep 0.3          # double-click "the"
xdotool mousemove 400 161 click 3; sleep 0.8
shot 3b-text-menu
xdotool mousemove 440 179 click 1; sleep 1                    # Copy
expect "text copy works after an image copy" "the" "$($OUT/clipimage -text /dev/stdout 2>&1)"
alive
kill $APP; wait $APP 2>/dev/null
finish
