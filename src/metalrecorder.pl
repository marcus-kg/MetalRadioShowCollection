#!/usr/bin/perl
#use strict;
#use warnings;
use Getopt::Std;

my $version = "00.000";
my $RecordingType;
my $url;
my $station;
my $show;
my $duration;
my $DateString;

getopts('vhtf:d:1:2:3:4:') or die "unknown option\n";

$opt_v and die "version $version\n";
$opt_h and usage();

$opt_f and print "file to read:       |$opt_f|\n";
$opt_d and print "recording into dir: |$opt_d|\n";

$opt_f or die "need a file to red with -f <NAME_OF_FILE>\n";
$opt_d or die "dont know where to write! give a dir with -d <RECORDING_ROOT_DIR>\n";
if (!-d $opt_d){ die "directory >>$opt_d<< not found\n";}

readTextFile($opt_f);

$DateString = `date +%Y-%m-%d`;
chomp($DateString);
record();

execAfterRecording();

# subs
################################

sub record{
     
    if ($RecordingType eq "p"){
	if ($opt_t){
	    print "streamripper $url -t -q -d $opt_d/$station-$show/$DateString/ -l $duration -s \n";
	}else{
            mkdir("$opt_d/$station-$show"); 
            if (!-d "$opt_d/$station-$show") { die "could not mkdir $opt_d/$station-$show\n"; }
	    mkdir("$opt_d/$station-$show/$DateString");
	    if (!-d "$opt_d/$station-$show/$DateString") { die "could not mkdir $opt_d/$station-$show/$DateString\n"; } 
	    `streamripper $url -t -q -d $opt_d/$station-$show/$DateString/ -l $duration -s`;
            `rm -r $opt_d/$station-$show/$DateString/incomplete/`;
	}
    }elsif ($RecordingType eq "s"){
	if ($opt_t){
	    print "streamripper $url -t -A -q -d $opt_d/$station-$show -a $show-$DateString/ -l $duration -s \n";
	}else{
	    mkdir("$opt_d/$station-$show");
            if (!-d "$opt_d/$station-$show"){ die "could not mkdir $opt_d/$station-$show\n"; }
            `streamripper $url -t -A -q -d $opt_d/$station-$show -a $show-$DateString/ -l $duration -s`;
            `rm $opt_d/$station-$show/*.cue`;
	}
    }else{
	die "dont know how to record, Singelfile s or filePertrac p\n";
    }
}

sub readTextFile{
    local $OneLine;
    open (FILE, $_[0]) or die die "can't open file >>$_[0]<<";
    while($OneLine = <FILE>){
	#print "$OneLine";
	$OneLine =~ s/#.*//; # cutt comments from # to eol
	$OneLine =~ m/radio\s*station\s+([a-zA-Z0-9_]+)/i   and $station = $1;
	$OneLine =~ m/radio\s*show\s+([a-zA-Z0-9_]+)/i      and $show = $1;
	$OneLine =~ m(url2record\s+([a-zA-Z0-9_:/\.\-]+))i  and $url = $1;
	$OneLine =~ m/duration\s+([0-9]+)\s*h/i   and $duration = ($1 * 3600);
	$OneLine =~ m/duration\s+([0-9]+)\s*m/i   and $duration = $1 * 60;
	$OneLine =~ m/duration\s+([0-9]+)\s*min/i and $duration = $1 * 60;
	$OneLine =~ m/duration\s+([0-9]+)\s*s/i   and $duration = $1;
	$OneLine =~ m/duration\s+([0-9]+)\s*sec/i and $duration = $1;
	if ($OneLine =~ m/recording\s*type/i){
	    if ($OneLine =~ m/Single\s*File/i){
		$RecordingType = "s";
	    } else {
		$RecordingType = "p";
	    }
	}
    }
    if ("$duration" eq "" ) {         die "no duration found in $_[0]\n"; }
    if ("$url" eq "" ) {              die "no url found in $_[0]\n";     }
    if ("$show" eq "" ) {             die "no show found in $_[0]\n";     }
    if ("$station" eq "" )       {    die "no station found in $_[0]\n";     }
    if ("$RecordingType" eq "" ) {    die "no RecordingType found in $_[0]\n";     }

    print "RecordingType       |$RecordingType|\n";
    print "url                 |$url|\n";
    print "station             |$station|\n";
    print "show                |$show|\n";
    print "duration            |$duration|\n";
}

sub usage{
    print "call : metalrecorder.pl -f <NAME_OF_COLLECTION_FILE>  -d <RADIO_SHOWS_ROOT_DIR>\n";
    print "typical usage is the call out of the /etc/crontab\n";
    print "other options:\n";
    print " -h     : print this help\n";
    print " -v     : print Version number\n";
    print " -t     : testrun, dont record or execute just display errors\n";
    print " -1..-5 : programs to execute when recording is finished\n";
    print "          use with: %dir, %url, %show, %station, %duration, %DateString\n";
    die;
}

sub substitute{
    $_[0] =~ s/%url/$url/g;
    $_[0] =~ s/%show/$show/g;
    $_[0] =~ s/%station/$station/g;
    $_[0] =~ s/%duration/$duration/g;
    $_[0] =~ s/%DateString/$DateString/g;
    
    if ($RecordingType eq "p"){                      # record one file per trac
        $_[0] =~ s/%dir/$opt_d\/$station\-$show\/$DateString\//g;
    } else {                                         # record one large file
        $_[0] =~ s/%dir/$opt_d\/$station\-$show\//g;
    }
    return $_[0];
}

sub execAfterRecording{
    local $aString;
    if ($opt_t){
        if ($opt_1){ 
            print "would execute |".substitute($opt_1)."|\n";
            if ($opt_2){    
                print "would execute |".substitute($opt_2)."|\n";
                if ($opt_3){    
                    print "would execute |".substitute($opt_3)."|\n";
                     if ($opt_4){    
                        print "would execute |".substitute($opt_4)."|\n";
                         if ($opt_5){    
                            print "would execute |".substitute($opt_5)."|\n";
                         }
                     }    
                }
            }
        }
    } else { # no testrun
        if ($opt_1){
            $aString = substitute($opt_1);
            `$aString`;
            if ($opt_2){    
                $aString = substitute($opt_2);
                `$aString`;
                if ($opt_3){
                    $aString = substitute($opt_3);
                    `$aString`;
                    if ($opt_4){    
                        $aString = substitute($opt_4);
                        `$aString`;
                        if ($opt_5){    
                            $aString = substitute($opt_5);
                            `$aString`;
                         }
                     }
                }
            }
        }
    }
} #endsub sub execAfterRecording

