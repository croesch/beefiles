#!/bin/bash
# Monitors memory usage and prints maximum memory usage over
# the monitored time.
# Currently monitors memory every 10 seconds -> peaks in
# 10 second window aren't recognized

FILE=$(mktemp)
MAX=0

function e {
  echo "$1" | tee -a $FILE
}

while true
do
  date
  echo "file used: $FILE"
  echo "-----"
  echo

  USED=$(free -m | head -n 3 | tail -n 1 | awk ' { print $3 } ')
  e "used: ${USED}M"
  e "old max: ${MAX}M"
  MAX=$(($MAX>$USED?$MAX:$USED))
  e "new max: ${MAX}M"
  
  sleep 10
  clear
  echo "" > $FILE
done
