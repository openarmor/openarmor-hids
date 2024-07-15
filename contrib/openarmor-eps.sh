#!/bin/sh
# Calculate openarmor events per second
# Author Michael Starks openarmor [at] michaelstarks [dot] com
# License: GPLv3

if [ ! -e /etc/openarmor-init.conf ]; then
  echo openarmor does not appear to be installed on this system. Goodbye.
  exit 1
else
  grep -q agent /etc/openarmor-init.conf && echo This script can only be run on the manager. Goodbye. && exit 1
fi

#Reset counters
COUNT=0
EPSSUM=0
EPSAVG=0
#Source openarmor Dir
. /etc/openarmor-init.conf

for i in $(grep 'Total events for day' ${DIRECTORY}/stats/totals/*/*/openarmor-totals-*.log | cut -d: -f3); do
  COUNT=$((COUNT+1))
  DAILYEVENTS=$i
  EPSSUM=$(($DAILYEVENTS+$EPSSUM))
done

EPSAVG=$(($EPSSUM/$COUNT/(86400)))

echo Your total lifetime number of events collected is: $EPSSUM
echo Your total daily number of events average is: $(($EPSSUM/$COUNT))
echo Your daily events per second average is: $EPSAVG
