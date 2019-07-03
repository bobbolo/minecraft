#!/bin/bash
PATH=~/jre1.8.0_161/bin:$PATH

MCHOME=/home/cfmain/minecraft_13
LOOPFILE=${MCHOME}/remove_to_stop_loop.txt
JVM_OPTS="-Xms8192M -Xmx8192M -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:gc.log -XX:+UseG1GC -XX:MaxGCPauseMillis=50"

cd $MCHOME

if [ "x$1" == "x--loop" ]; then

  if [ -f $LOOPFILE ]; then

    echo "${LOOPEIFLE} exists! is Minecraft already running? Check the process and remove the file first"
    exit 1

  else
    echo "Starting with loop... creating file: ${LOOPFILE}"
    touch $LOOPFILE
  fi

fi

#check if there is a loopfile then do infinite while loop
if [ -f $LOOPFILE ]; then
  while [ -f $LOOPFILE ]
  do
    echo "${LOOPFILE} exists, restarting minecraft."
  java ${JVM_OPTS} -jar spigot-1.14.3.jar
    echo "Sleeping for 5 seconds....."
    sleep 5
  done

echo "${LOOPFILE} is gone, no longer looping....."

else
  #since there is no loop file, just single shot the minecraft server
  echo "Starting minecraft without loop......."
  java ${JVM_OPTS} -jar spigot-1.14.3.jar
fi

echo "Script exiting...."
