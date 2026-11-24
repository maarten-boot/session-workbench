#!/bin/bash
# Headless GUI test of the sidebar colors (SPEC §4.6 Sidebar): colors from
# the config paint the sidebar, a host heading, a folder heading and a dot;
# text on the dark background is white, on the light headings black; a color
# typed on Settings → Sidebar is saved and shown; a dot that hardly shows on
# the background is named in words.
# usage: xvfb-run -a -s "-screen 0 1400x900x24" scripts/gui-smoke-sidebarcolors.sh <binary> <outdir>
BIN=$1; OUT=$2; mkdir -p $OUT
. "$(dirname "$0")/smoke-lib.sh"
mkdir -p $OUT/p1
CFG=$OUT/config.toml
cat >$CFG <<TOML
groups = ["Work"]
[ui]
sidebar_bg = "#203040"
dot_idle = "#ff00ff"
[ui.host_colors]
local = "#ffe0a0"
[ui.folder_colors]
Work = "#a0e0ff"
[[hosts]]
name = "local"
ssh_target = "localhost"
[[sessions]]
id = "s-col$$"
name = "one"
host = "local"
group = "Work"
local_path = "$OUT/p1"
start_mode = "shell"
TOML
k() { xdotool key "$@"; sleep 0.5; }
shot() { xdotool mousemove 800 600; sleep 0.8; import -window root $OUT/$1.png; }
SIDEBAR=240x750+61+86                                # below the sidebar's head
# pixels <shot> <color>: how many pixels of the sidebar have exactly that color.
pixels() { convert $OUT/$1.png -crop $SIDEBAR +repage -fill black +opaque "$2" -fill white -opaque "$2" -format '%[fx:round(mean*w*h)]' info:; }
many() { [ "$(pixels $1 $2)" -ge $3 ]; }
$BIN -config $CFG >>$OUT/app.log 2>&1 &
APP=$!
wait_window
sleep 3; xdotool windowactivate --sync $W 2>/dev/null
shot 1-colors
check "the sidebar background (#203040)" many 1-colors '#203040' 20000
check "the folder heading (#a0e0ff)" many 1-colors '#a0e0ff' 1500
check "the host heading (#ffe0a0)" many 1-colors '#ffe0a0' 1000
check "the dot not connected yet (#ff00ff)" many 1-colors '#ff00ff' 20
check "white text on the dark background" many 1-colors '#ffffff' 50
check "black text on the light headings" many 1-colors '#000000' 50
# Settings → Sidebar: the background typed, a dot that hardly shows.
k ctrl+shift+comma; sleep 0.8
xdotool mousemove 330 467 click 1; sleep 0.6         # Sidebar (tabs on the left)
shot 2-page
WARN=640x30+470+425                                  # under the dot fields
crop() { convert $OUT/$1.png -crop $2 +repage $OUT/$3.png; }
xdotool mousemove 968 205 click 1; k ctrl+a; xdotool type '#f8f8f0'   # Background
shot 3-light; crop 3-light $WARN warn-3; crop 2-page $WARN warn-2
xdotool mousemove 968 307 click 1; k ctrl+a; xdotool type '#f4f4f4'   # Dot: not connected yet, hardly visible
shot 4-dot; crop 4-dot $WARN warn-4
differ() { [ "$(compare -metric AE $OUT/$1.png $OUT/$2.png null: 2>&1 | cut -d' ' -f1)" != 0 ]; }
# Magenta stands out from #203040 (4.3:1), not from #f8f8f0 (2.9:1): named.
check "a dot below 3:1 against the new background is named" differ warn-2 warn-3
check "and only then" bash -c "$(declare -f differ); OUT=$OUT; ! differ warn-3 warn-4" 
xdotool mousemove 1090 616 click 1; sleep 1.5       # Save (lower: the warning takes a line)
shot 5-saved
check "the background is saved" grep -q '^ *sidebar_bg = "#f8f8f0"' $CFG
check "the dot is saved" grep -q '^ *dot_idle = "#f4f4f4"' $CFG
check "the host color is kept" grep -q '^ *local = "#ffe0a0"' $CFG
check "the sidebar takes the new background" many 5-saved '#f8f8f0' 20000
check "black text on it" many 5-saved '#000000' 50
alive
stop_app
finish
