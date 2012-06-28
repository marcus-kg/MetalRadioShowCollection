This collection was started because i love radioshows with moderation, interviews, news ...
AND METAL!  Most time i hate the music from the radio but some shows are worth to listning.
These shows have broadcasting times that are useless for me. So here is the solution.

dependences
-----------
streamripper:  http://streamripper.sourceforge.net
cron :         part of most linux systems
bash :         ditto
perl :         ditto
thank you verry much, developers of that software

interesting links
-----------------
crontab   http://en.wikipedia.org/wiki/Cron

how to use
----------
in the directory of this README.TXT file execute:
$>copy ./src/etc-MetalRadioShowCollection.config /etc/MetalRadioShowCollection.config
edit it to match your system

apend a line similar to this example to your /etc/crontab
$>echo "2 21 * * MON root /usr/local/bin/MetalRadioShowCollection/src/metalrecorder.pl tinnitus.mrscf >>/dev/nul 2>&1" >> nix.txt
        \__________/      \_____________________________________/                      \____________/
       crontab string      your path to te collecion, set also in                      show to record
    found inside *.mrscf   /etc/MetalRadioShowCollection.config

restart the cron deamon
$>service cron restart

make sure the path to store the recorded files in already exists and is writable
