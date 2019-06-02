#!/bin/bash
#PATH=~/jre1.8.0_161/bin:$PATH
#java -Xmx1024M -jar spigot-1.12.2.jar

MCHOME="/home/cfmain/minecraft_13"

cd $MCHOME

#check to see if a screen is already running, if so don't run a second one
SCRN_COUNT=`screen -ls |grep minecraft_13 | wc -l`

if [ "$SCRN_COUNT" -lt 1 ]; then

  if [ "x$1" == "x--loop" ]; then
    screen -d -m -S minecraft_13 ./mc_start.sh --loop
  else
    screen -d -m -S minecraft_13 ./mc_start.sh
  fi

else

  echo "$SCRN_COUNT screen(s) found, Ther should only be one running. Aborting..... new screen"
  exit 1

fi
