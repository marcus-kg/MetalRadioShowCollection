#!/usr/bin/perl
#use strict;            # im am unable to use strict together with getopts
#use warnings;
use Getopt::Std;
use File::Path qw(make_path);

my $version = "0.0.2";  # will be counted up anytime  
my $RecordingType;      # p => one file Per trac | s => one Single File
my $url;                # URL of the audiostream to record
my $station;            # the name of the radio station is used to creare a directoryname 
my $show;               # the name of the show is the second part of the directoryname
my $duration;           # in seconds / how log the show should be recorded 
my $DateString;         # YYYY-MM-DD also part of recorded file- and directory name 
my $configfile;         # Name of the configuration file to read
my @toExec;             # the list of programs to be executed after recording is finished
my $mrscfDirectory;     # Directory of the collection files *.mrscf
my $GarbageCollection;  # if set to yes in config file: in single file recording the *.cue files are deleted and in one file per trac recordings the inclomplete directory will be deleted 
#my $recordingDirectory; # the root dir of recording here in directorys will be created for every show
my $recDirSingleFile;
my $recDirFielPerTrac;
my $fileNameSingleFile;
my $additionalParameter;# appendet to Streamripper

@ARGV or usage();       # missing any parameter

getopts('vhtf:c:') or die "unknown option\n";

$opt_v and die "version $version\n";
$opt_h and usage();

if ($opt_c){
    $configfile = $opt_c; 
}else{
    $configfile = "/etc/MetalRadioShowCollection.config";
}

$opt_f or die "need a file to read with -f <NAME_OF_COLLECTION_FILE>\n";
$DateString = `date +%Y-%m-%d`; #YYYY-MM-DD
chomp($DateString);

readConfigFile($configfile, $opt_f);
readCollectionFile("$mrscfDirectory/$opt_f");

if (recordThisWeek()){
    record();
    execAfterRecording();
}

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
    my $ThisSectionIsForMe;         # bool yes bevor the first section is known and if the current section matches the collectionFileName
    
    ($cfgFileName, $collectionFileName) = @_;
    
    $ThisSectionIsForMe = 1;        # when start reading the file the lines above the first section are globale settings
    $GarbageCollection  = 0;        # do not delete to much
    open (CFGFILE, $cfgFileName) or die die "can't open config file |$cfgFileName|";
    while($OneLine = <CFGFILE>){
        $OneLine =~ s/\s*#.*//;     # cut comments from >>#<< to eol
        #print "$OneLine";
        if ( $OneLine =~ m /\[$collectionFileName\]/ ){ # this is my [SECTION]
            $ThisSectionIsForMe = 1;
        }elsif ( $OneLine =~ m /\[[\w\-\.]+\]/ ){       # found a [SECTION] but other than mine
            $ThisSectionIsForMe = 0;
        }elsif ( $ThisSectionIsForMe ){                 # other lines are only inresting if they are insiede my [SECTION]
            # directories an file Name
            $OneLine =~ m/mrscfDirectory\s+([\w-\.\/]+)/i     and $mrscfDirectory     = $1;            
            $OneLine =~ m/RecordingDirectoryForOneSingleFile\s+([\w-\.\/\%]+)/i and $recDirSingleFile = $1;
            $OneLine =~ m/FileNameForOneSingleFile\s+([\w-\.\/\%]+)/i and $fileNameSingleFile = $1;
            $OneLine =~ m/RecordingDirectoryOneFilePerTrac\s+([\w-\.\/\%]+)/i and $recDirFielPerTrac = $1;
            # GarbageCollection y[es] or n[o]
            $OneLine =~ m/GarbageCollection\s+y/i and $GarbageCollection  = 1;
            $OneLine =~ m/GarbageCollection\s+n/i and $GarbageCollection  = 0;
            # list of programs to execute after recording
            $OneLine =~ m/execAfterRecording_([0-9]+)\s+(.+$)/i and $toExec[$1] = $2;
            # additional parameters to Streamripper
            $OneLine =~ m/additionalParameter\s+(.+)/i and $additionalParameter = $1;
        }
    } # and while oneLine 

    # missing some obligatory information => write message and exit
    #$mrscfDirectory     eq "" and die "No directory given to find the collection-File *. mrscf: need a mrscfDirectory entry in $cfgFileName\n";
    #$recordingDirectory eq "" and die "No directory given to store the music: need a recordingDirectory entry in $cfgFileName\n"; 

    # print waht i understood in the config file
    print "ConfigFile:               |$cfgFileName|\n";
    print "CollectionFile:           |$collectionFileName|\n";
    print "mrscfDirectory:           |$mrscfDirectory|\n";
    print "Recording into S:         |$recDirSingleFile|\n";
    print "Name of large file:       |$fileNameSingleFile|\n";
    print "Recording into P:         |$recDirFielPerTrac|\n";
    print "GarbageCollection:        "; ($GarbageCollection)? print "yes\n": print "no\n";
    print "additionalParameter:      |$additionalParameter|\n";    
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
    if ($RecordingType eq "p"){ # one file per trac
        if ($opt_t){            # testrun
            print "streamripper $url -t -q -d $recDirFielPerTrac -l $duration -s $additionalParameter\n";
        }else{                  # no testrun => do it
            make_path("$rrecDirFielPerTrac"); 
            if (!-d "$recDirFielPerTrac") { die "could not mkdir $recDirFielPerTrac\n"; }

            `streamripper $url -t -q -d $recDirFielPerTrac -l $duration -s $additionalParameter`;
            if ($GarbageCollection){
                `rm -r $recordingDirectory/$station-$show/$DateString/incomplete/`;
            }
        }
    }elsif ($RecordingType eq "s"){ # record into one single file
        if ($opt_t){                # testrun 
            print "streamripper $url -t -A -q -d $recDirSingleFile -a $fileNameSingleFile -l $duration -s $additionalParameter\n";
        }else{                      # no testrun => do it
            make_path("$recDirSingleFile");
            if (!-d "$recDirSingleFile"){ die "could not mkdir $recDirSingleFile\n"; }
            
            `streamripper $url -t -A -q -d $recDirSingleFile -a $fileNameSingleFile -l $duration -s $additionalParameter`;
            if ($GarbageCollection){
                `rm $recordingDirectory/$station-$show/*.cue`;
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
        $OneLine =~ m/weeks2record\s+(.+)/i       and $weeks2record = $1;
        $OneLine =~ m/duration\s+([0-9]+)\s*h/i   and $duration = $1 * 3600;
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
    
    # substitute the strings for directoriy- and file names
    $recDirFielPerTrac = substitute( $recDirFielPerTrac ); 
    $fileNameSingleFile = substitute( $fileNameSingleFile );
    $recDirSingleFile = substitute( $recDirSingleFile );

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
    print "duration / s              |$duration|\n";
    print "substitued\n";
    print "Recording into S          |$recDirSingleFile|\n";
    print "Name of large file        |$fileNameSingleFile|\n";
    print "Recording into P          |$recDirFielPerTrac|\n";

    if ($weeks2record eq ""){
        print "weeks2record              EVERY\n";
    }else{
        print "weeks2record              |$weeks2record|\n";
    }
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
} # sub usage{

# FUNCTION
#   This function substituts the %... macros given in the config file with the 
#   >>execAfterRecording_[0-9]<< key
# PARAMETERS 
#   the string behind the >>execAfterRecording_[0-9]<< key 
# RETURNS
#   the same string with the substitutions
###################################################################################################
sub substitute{
    $_[0] =~ s/\%UrlOfStreamToRecord/$url/ig;
    $_[0] =~ s/\%NameOfRadioShow/$show/ig;
    $_[0] =~ s/\%NameOfRadioStation/$station/ig;
    $_[0] =~ s/\%RecordingDurationIn_s/$duration/ig;
    $_[0] =~ s/\%DateString/$DateString/ig;
    if ($RecordingType eq "p"){                      # record one file per trac
        $_[0] =~ s/%RecordingDirectory/$recDirFielPerTrac/ig;
        $_[0] =~ s/%RecordingFileName/various/ig;
    } else {                                         # record one large file
        $_[0] =~ s/%RecordingDirectory/$recDirSingleFile/ig;
        $_[0] =~ s/%RecordingFileName/$fileNameSingleFile/ig;
    }
    return $_[0];
} # end sub substitute{

# FUNCTION
#   This function executes the programs given in the config file with the 
#   >>execAfterRecording_[0-9]<< key
#   if testrun parameter -t is given nothing will be executed, it will just be 
#   printed out to see if the substitions works as expected.
# PARAMETERS
#   non
# RETURNS
#   nothing
###############################################################################
sub execAfterRecording{
    local $aString;
    foreach (@toExec){
	$aString = substitute($_);
	if ($opt_t){ # just print out to check substs
            print "execute |$aString|\n";
	} else {     # no testrun real execution
            `$aString`;
        }
    }
} #endsub sub execAfterRecording

# FUNCTION
#   if ths week should be recordet this function returns true
# PARAMETERS
#   non
# RETURNS
#   true if this is on of the matching weeks
###############################################################################
sub recordThisWeek{
    local $ThisWeek = `date +%W`;
    chomp($ThisWeek);

    if ($weeks2record eq "") { return 1; } # if no weeks2rekord are given, every week is right
    if ((uc($weeks2record) eq "ODD")  and (($ThisWeek % 2) == 1)) { return 1; }
    if ((uc($weeks2record) eq "EVEN") and (($ThisWeek % 2) == 0)) { return 1; }
    foreach(split(/,/, $weeks2record)){  if ($_ == $ThisWeek)     { return 1; }  }
    return 0;
} # end sub sub recordThisWeek

