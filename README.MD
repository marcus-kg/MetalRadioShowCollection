This collection was started because i love radio shows with moderation, interviews, news ... AND METAL!  Most time i hate the music from the radio, but some shows are worth listening. These shows have broadcasting times that are useless for me. So here is the solution.

A perl script that reads some config-files ands start recording of specified radio shows.

# dependences

 - streamripper:  http://streamripper.sourceforge.net
 - cron :         part of most linux systems
 - bash :         ditto
 - perl :         ditto
thank you very much, developers of that software

# interesting links

 - crontab:   http://en.wikipedia.org/wiki/Cron
 - timezones: /usr/share/zoneinfo

# how to use

copy the example config file to /etc
$>copy ./src/etc-MetalRadioShowCollection.config /etc/MetalRadioShowCollection.config
edit it to match your system

append a line similar to this example to your /etc/crontab
2 * * * * root /usr/local/bin/MetalRadioShowCollection/src/metalrecorder.pl 2>&1" >> /dev/zero

restart the cron daemon
$>service cron restart

make sure the path to store the recorded files in already exists and is writeable
Create or edit some mrscf-files inside the mrscf_available directory.
Symlink your favorit files inside the mrscf_enabled directory.
 
