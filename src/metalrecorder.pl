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
my $configfile;         # Name of the configuration file to read
my @toExec;             # the list of programs to be executed after recording is finished
my $collectionDir;      # Directory of the collection files *.mrscf

@ARGV or usage();       # missing any parameter

getopts('vhtf:c:') or die "unknown option\n";

$opt_v and die "version $version\n";
$opt_h and usage();

if ($opt_c){
    $configfile = $opt_c; 
}else{
    $configfile = "/etc/MetalRadioShowCollection.config";
} 
print "config file read:         |$configfile|\n";

$opt_f or die "need a file to red with -f <NAME_OF_COLLECTION_FILE>\n";

readConfigFile($configfile, $opt_f);
$opt_f and print "collection file to read:  |$collectionDir/$opt_f|\n";

readCollectionFile("$collectionDir/$opt_f");

$DateString = `date +%Y-%m-%d`; #YYYY-MM-DD
chomp($DateString);
record();

execAfterRecording();

# subs
###############################################################################

# FUNCTION
#   read and interprete the config file
#   and display errors
# PARAMETERS
#   Name of the config file
# RETURNS
#   nothing
###############################################################################
sub readConfigFile
{   
    my $cfgFileName;
    my $collectionFileName;
    my $ThisSectionIsForMe; # bool yes bevor the first section is known and if the current section matches the collectionFileName
    
    {$cfgFileName, $collectionFileName} = @_;
    
    $ThisSectionIsForMe = 1;
    open (CFGFILE, $cfgFileName;) or die die "can't open config file >>$_[0]<<";
    while($OneLine = <CFGFILE>){
        #print "$OneLine";
        $OneLine =~ s/\s*#.*//; # cut comments from >>#<< to eol
        if ( $OneLine =~ m /\[$collectionFileName\]/ ){
            $ThisSectionIsForMe = 1;
        }elsif ( $OneLine =~ m /\[[\w\-\.]+\]/ ){
            $ThisSectionIsForMe = 0;
        }elsif ( $ThisSectionIsForMe ){
            $OneLine =~ m/mrscfDirectory\s+([\w\-\.]+)/i and $collectionDir = $1;            
            $OneLine =~ m/$garbageCollection\s+y/s; 
            
            $$collectionDir eq "" and die "No Directoy given to find the collection-File *. mrscf";
            
            print "collection dir:         |collectionDir|\n";
        }
  
    }  # 
    if (!-d $opt_d){ die "directory >>$opt_d<< not found\n";}
} # end sub readConfigFile

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
    print "usage : metalrecorder.pl -f <NAME_OF_COLLECTION_FILE>\n"; 
    print "typical usage is the call out of the /etc/crontab\n";
    print "other options:\n";
    print "if -c option is not given >>/etc/MetalRadioShowCollection.config<< will be read\n";
    print " -c <NAME> : altetnative config file >\n";
    print " -h        : print this help\n";
    print " -t        : testrun, dont record or execute just display errors\n";
    print " -v        : print Version number and exit\n";
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
        foreach (@toExec){
            print "would execute |".substitute($_)."|\n";
        }
    } else { # no testrun real execution
        foreach (@toExec){
            $aString = substitute($_);
            `$aString`;
        }
    }
} #endsub sub execAfterRecording

