#!/bin/bash
# Headless GUI test of D2 diagrams (SPEC N1c): a ```d2 block in Notes is
# drawn below its text, an error shows D2's message, an edit draws it again;
# a ```d2 block in a Q&A answer is drawn with its source folded below.
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
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
k ctrl+alt+1; k ctrl+shift+4; sleep 3                 # Notes
xdotool mousemove 1250 830; sleep 0.5
shot 1-notes
n=$(blue 1-notes 1000x700+340+90)
check "Notes draws the d2 block ($n blue pixels)" test "$n" -gt 200
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
alive
kill $APP; wait $APP 2>/dev/null
finish
