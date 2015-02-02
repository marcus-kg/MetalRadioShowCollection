#!/usr/bin/perl
use POSIX qw(tzset);

my $tzstring;
my $was = localtime;
print "It was      $was\n";

#$ENV{TZ} = 'America/Los_Angeles';
$tzstring = "America/Los_Angeles";
#$tzstring = "lsnf/driss";
$ENV{TZ} = $tzstring;
if ( not -e "/usr/share/zoneinfo/".$tzstring ){
    print "gibbetnet\n";
}

$was = localtime;
print "It is still $was\n";

tzset;

my $now = localtime;
print "It is now   $now\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  localtime(time);
$year = $year + 1900;
    

print "sec   = $sec\n";
print "min   = $min\n";
print "hour  = $hour\n";
print "mday  = $mday\n";
print "mon   = $mon\n";
print "year  = $year\n";
print "wday  = $wday\n";
print "yday  = $yday\n";
print "isdst = $isdst\n";
print `date +%W`;
print "\n";
##
## possible Values can be found with
## find /usr/share/zoneinfo/ | less
##