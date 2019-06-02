#!/bin/bash
#determine java pid, and try nicely to kill the process, then kill with -9 if it's not behaving

#determine screen name
SCREEN_GROUP_ID=`ps -eaf |grep SCREEN |grep minecraft_13 | perl -ne '$_=~/^cfmain[\s\t]+(\d+)/; print qq{$1};'`

#determine group pid from screen ID
JAVA_GROUP_ID=`ps -eaf |grep mc_start | grep -v SCREEN | grep $SCREEN_GROUP_ID | perl -ne '$_=~/^cfmain[\s\t]+(\d+)/; print qq{$1};'`

#determine java PID
JAVA_ID=`ps -eaf |grep java |grep $JAVA_GROUP_ID | perl -ne '$_=~/^cfmain[\s\t]+(\d+)/; print qq{$1};'`


echo "SCREEN_GROUP_ID: $SCREEN_GROUP_ID"
echo "JAVA_GROUP_ID: $JAVA_GROUP_ID"
echo "JAVA_ID: $JAVA_ID"

echo "Nicely killing the jvm...."

kill $JAVA_ID

echo "Sleeping 10 seconds and checking again....."
sleep 10

PID_COUNT=`ps -eaf |grep java | grep $JAVA_ID |grep -v grep | wc -l`

if [ "$PID_COUNT" -gt 0 ]; then

  echo "JVM pid still there, killing with -9...."
  kill -9 $JAVA_ID

fi
