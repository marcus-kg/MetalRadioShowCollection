#!/usr/bin/perl
#use strict;
#use warnings;
use Getopt::Std;

my $version = "00.000";
my $recordingType;
my $url;
my $station;
my $show;
my $duartion;

getopts('vhf:d:') or die "unknown option\n";

$opt_v and die "version $version\n";
$opt_h and usage();

$opt_f and print "file to read:       |$opt_f|\n";
$opt_d and print "recording into dir: |$opt_d|\n";

$opt_f or die "need a file to red with -f <NAME_OF_FILE>\n";
$opt_d or die "dont know where to write! give a dir with -d <RECORDING_ROOT_DIR>\n";

readTeaxtFile($opt_f);
record();

# subs
################################

sub record{
    local $DateString;

    $DateString = `date +%Y-%m-%d`;

    if  ($recordingType eq "p"){
	print "record filePertrac\n";
    }elsif ($recordingType eq "s"){
	print "record Singlefile\n";
    }else{
	die "dont know how to record, Singelfile s or filePertrac p\n";
    }
}

sub readTeaxtFile{
    local $OneLine;
    open (FILE, $_[0]) or die die "can't open file >>$_[0]<<";
    while($OneLine = <FILE>){
	#print "$OneLine";
	$OneLine =~ m/radio station\s+([a-zA-Z0-9_]+)/i and $station = $1;
	$OneLine =~ m/radio show\s+([a-zA-Z0-9_]+)/i    and $show = $1;
	$OneLine =~ m(url2record\s+([a-zA-Z0-9_:/\.\-]+))i  and $url = $1;
	$OneLine =~ m/duration\s+([0-9]+)h/i   and $duartion = $1 * 3600;
	$OneLine =~ m/duration\s+([0-9]+)m/i   and $duartion = $1 * 60;
	$OneLine =~ m/duration\s+([0-9]+)min/i and $duartion = $1 * 60;
	$OneLine =~ m/duration\s+([0-9]+)s/i   and $duartion = $1;
	$OneLine =~ m/duration\s+([0-9]+)sec/i and $duartion = $1;
	if ($OneLine =~ m/recording type/i){
	    if ($OneLine =~ m/SingleFile/i) {
		$recordingType = "s";
	    } else {
		$recordingType = "p";
	    }
	}
    }
#    ($duration eq "") or die "no duration found in $_[0]\n";

    print "RecordingType       |$recordingType|\n";
    print "url                 |$url|\n";
    print "station             |$station|\n";
    print "show                |$show|\n";
    print "duration            |$duartion|\n";

}

sub usage{
    print "call : metalrecorder.pl -f <NAME_OF_COLLECTION_FILE>  -d <RADIO_SHOWS_ROOT_DIR>\n";
    print "typical usage is the call out of the /etc/crontab\n";
    print "other options:\n";
    print " -h : print this help\n";
    print " -v : print Version number\n";
    die;
}
