#!/usr/bin/perl
#use strict;            # im am unable to use strict together with getopts
#use warnings;
use Getopt::Std;

my $version = "00.001"; # will be counted up anytime  
my $RecordingType;      # p => one file Per trac | s => one Single File
my $url;                # URL of the audiostream to record
my $station;            # the name of the radio station is used to creare a directoryname 
my $show;               # the name of the show is the secon part of the directoryname
my $duration;           # in seconds / how log the show should be recorded 
my $DateString;         # YYYY-MM-DD also part of recorded file- and directory name 

@ARGV or usage();       # missing any parameter

getopts('rvhtf:d:1:2:3:4:5:') or die "unknown option\n";

$opt_v and die "version $version\n";
$opt_h and usage();

$opt_f and print "collection file to read:  |$opt_f|\n";
$opt_d and print "recording into dir:       |$opt_d|\n";

$opt_f or die "need a file to red with -f <NAME_OF_COLLECTIOB_FILE>\n";
$opt_d or die "dont know where to write! give a dir with -d <RECORDING_ROOT_DIR>\n";
if (!-d $opt_d){ die "directory >>$opt_d<< not found\n";}

readCollectionFile($opt_f);

$DateString = `date +%Y-%m-%d`; #YYYY-MM-DD
chomp($DateString);
record();

execAfterRecording();

# subs
###############################################################################

# FUNCTION
#   do it! start streamripper and give it its information.
#   if parameter -t (testrun) is given the string to start streamripper is
#   just printed out but not executed.
# PARAMETERS
#   non
# RETURNS
#   nothing
###############################################################################
sub record{
    if ($RecordingType eq "p"){
        if ($opt_t){
            print "streamripper $url -t -q -d $opt_d/$station-$show/$DateString/ -l $duration -s \n";
        }else{ # no testrun => do it
            mkdir("$opt_d/$station-$show"); 
            if (!-d "$opt_d/$station-$show") { die "could not mkdir $opt_d/$station-$show\n"; }

            mkdir("$opt_d/$station-$show/$DateString");
            if (!-d "$opt_d/$station-$show/$DateString") { die "could not mkdir $opt_d/$station-$show/$DateString\n"; } 
            `streamripper $url -t -q -d $opt_d/$station-$show/$DateString/ -l $duration -s`;
            if ($opt_r){
                `rm -r $opt_d/$station-$show/$DateString/incomplete/`;
            }
        }
    }elsif ($RecordingType eq "s"){
        if ($opt_t){
            print "streamripper $url -t -A -q -d $opt_d/$station-$show -a $show-$DateString/ -l $duration -s \n";
        }else{ # no testrun => do it
            mkdir("$opt_d/$station-$show");
            if (!-d "$opt_d/$station-$show"){ die "could not mkdir $opt_d/$station-$show\n"; }
            `streamripper $url -t -A -q -d $opt_d/$station-$show -a $show-$DateString/ -l $duration -s`;
            if ($opt_r){
                `rm $opt_d/$station-$show/*.cue`;
            }
        }
    }else{ # not p nor s => what?
        die "dont know how to record, Singelfile s or filePertrac p\n";
    }
} # end sub record

# FUNCTION
#   reads one of the collection file and checks all
#   information if it is possible to start recording with it
# PARAMETERS
#   name of collection file to read
# RETURNS
#   nothing
###############################################################################
sub readCollectionFile{
    local $OneLine;
    open (FILE, $_[0]) or die die "can't open collection file >>$_[0]<<";
    while($OneLine = <FILE>){
        #print "$OneLine";
        $OneLine =~ s/#.*//; # cut comments from >>#<< to eol
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
    } # end of file reading

    # see if all necessary information is given
    if ( "$duration" eq "" )          { die "no duration found in $_[0]\n";      }
    if ( "$url" eq "" )               { die "no url found in $_[0]\n";           }
    if ( "$show" eq "" )              { die "no show found in $_[0]\n";          }
    if ( "$station" eq "" )           { die "no station found in $_[0]\n";       }
    if ( "$RecordingType" eq "" )     { die "no RecordingType found in $_[0]\n"; }

    # tell the user what i understood, or not
    print "RecordingType             |$RecordingType|\n";
    print "url                       |$url|\n";
    print "station                   |$station|\n";
    print "show                      |$show|\n";
    print "duration                  |$duration|\n";
} # end sub readCollectionFile

# FUNCTION
#   prinit usage information and die
#   espacialy all command line optopns and variabls
# PARAMETERS 
#   non
# RETURNS
#   nothing
###############################################################################
sub usage{
    print "call : metalrecorder.pl -f <NAME_OF_COLLECTION_FILE>  -d <RADIO_SHOWS_ROOT_DIR>\n";
    print "typical usage is the call out of the /etc/crontab\n";
    print "other options:\n";
    print " -h     : print this help\n";
    print " -t     : testrun, dont record or execute just display errors\n";
    print " -v     : print Version number\n";
    print " -r     : remove (delete) all *.cue-files | the incomplete subdir\n";
    print " -1..-5 : programs to execute when recording is finished\n";
    print "          use with: %dir, %file, %url, %show, %station, %duration, %DateString\n";
    die;
}

# FUNCTION
#   by given parameter -1..-5 the program to be executed after the recording is finished
#   could receive information in special %... macros
#   this funtion substiutes the %... macro with correct string
# PARAMETERS 
#   the string behind the -1 .. -5 option 
# RETURNS
#   the same string with the substitutions
###################################################################################################
sub substitute{
    $_[0] =~ s/%url/$url/g;
    $_[0] =~ s/%show/$show/g;
    $_[0] =~ s/%station/$station/g;
    $_[0] =~ s/%duration/$duration/g;
    $_[0] =~ s/%DateString/$DateString/g;
    
    if ($RecordingType eq "p"){                      # record one file per trac
        $_[0] =~ s/%dir/$opt_d\/$station\-$show\/$DateString\//g;
        $_[0] =~ s/%file/$show\-$DateString/g;
    } else {                                         # record one large file
        $_[0] =~ s/%dir/$opt_d\/$station\-$show\//g;
        $_[0] =~ s/%file/DifferentNamesForEachFile/g;
    }
    return $_[0];
}

# FUNCTION
#   This function executes the programs given at the command line options
#   -1 .. -5 inclusive the given parameters and its substitutions %...
#   if testrun parameter -t is given nothing will be executed, it will just be 
#   printed out to see if the substitions works as expected.
# PARAMETERS
#   non
# RETURNS
#   nothing
###############################################################################
sub execAfterRecording{
    local $aString;
    if ($opt_t){ # just print out to check substs
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
    } else { # no testrun real execution
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

