#!/bin/sh

OLD_DISPLAY=${DISPLAY}
vncserver :42 -geometry 1600x1200 -depth 16
export DISPLAY=:42

"$@"

export DISPLAY=${OLD_DISPLAY}
vncserver -kill :42
