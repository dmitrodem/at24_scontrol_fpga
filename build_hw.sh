#!/bin/sh
GW_IDE=/mnt/ORICO/u/dist/gowin/Gowin_V1.9.11.02_linux/IDE
export LD_LIBRARY_PATH=$GW_IDE/lib
exec $GW_IDE/bin/gw_sh run.tcl
