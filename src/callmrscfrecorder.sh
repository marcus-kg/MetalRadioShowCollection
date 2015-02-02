#!/bin/sh

# call this shell-script for example every hour via crontab
# 2 * * * * root /home/marcus/src/MetalRadioShowCollection/src/callmrscfrecorder.sh >/dev/null 2>&1

# read the install dir from global config file in /etc/...
MRSCF_BASE=`cat /etc/MetalRadioShowCollection.config | grep '^mrscfDirectory' | sed 's/mrscfDirectory[ \t][ \t]*//'`

# path with the enabled collection files
MRSCF_PATH="$MRSCF_BASE/mrscf_enabled/*.mrscf"

# execute recording for all files found
for FILE in $MRSCF_PATH
do
    # testrun just show waht would happen
     $MRSCF_BASE/src/metalrecorder.pl -t -f $FILE
    
    # real start recording
    # $MRSCF_BASE/src/metalrecorder.pl -f $FILE &
done
