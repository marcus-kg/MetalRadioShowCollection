#!/bin/bash
# script to record a radio show

printparameters()
{
    echo "params:"
    echo "1: RadioRecordingRootDir"
    echo "2: NameOfStation"
    echo "3: NameOfShow"
    echo "4: Duration in s"
    echo "5: p | s  #  filePertrack |  SingleFile"
    echo "6: UrlToRecord"
    echo "7: ProgramToExecuteAfterRecording # optional"
    echo "example: recordradioshow /home/marcus/radioshows RadioBob BobsHarteSaite 7200 p \"/usr/local/bin/mail recorded_BobsHarteSaite\""
}

# parameterchecking
# #############################################################################

# call with less than 5  parameters
if [ -z "$5" ]; then
    echo "call wit less than 5 parameters is undefined"
    printparameters
    exit 1
fi

# call with more than 7 parameters
if [ -n "$8" ]; then
    echo "call with more then 6 parameters undefined"
    printparameters
    exit 2
fi

# test if the rootdir exists
if [ ! -d "$1" ]; then
    echo "directory $1 not found"
        exit 3
fi

# if the radiostation dir not exists, create it and check again
if [ ! -d "$1/$2" ]; then
    mkdir $1/$2
    if [ ! -d "$1/$2" ]; then
        echo "unable to create dir: $1/$2"
        exit 4
    fi    
fi

# if the radishow dir not exists, create it and check again
if [ ! -d "$1/$2/$3" ]; then
    mkdir $1/$2/$3
    if [ ! -d "$1/$2/$3" ]; then
        echo "unable to create dir: $1/$2/$3"
        exit 5
    fi    
fi

# check if the duration is an numerical value
if [ "$4" -le 0 ]; then
    echo "unknown duration parameter 4: $4"
    exit 6
fi
# #############################################################################
# parameterchecking

# recording
# #############################################################################
DATE_STRING=`date +%Y-%m-%d`

# single file or filePerTrack recording
if [ "$5" = "p" ]; then # filePerTrackRecording
    mkdir "$1/$2/$3/$DATE_STRING"
    if [ ! -d "$1/$2/$3/$DATE_STRING" ]; then
        echo "unable to create dir: $1/$2/$3/$DATE_STRING"
        exit 7
    fi
    streamripper $6 -t -q -d $1/$2/$3/$DATE_STRING/ -l $4 -s
    rm -r $1/$2/$3/$DATE_STRING/incomplete/
elif [ "$5" = "s" ]; then  # Singlefilerecording
    streamripper $6 -t -A -q -d $1/$2/$3/ -a $3-$DATE_STRING -l $4 -s
    rm $1/$2/$3/*.cue
else
    echo "unkown parameter 5: $5 "
    printparameters
    exit 99
fi

$7

# everithing seems to be good
exit 0 
