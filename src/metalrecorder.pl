#!/usr/bin/perl
#use strict;
#use warnings;
use Getopt::Std;

my $version = "00.000";

getopts('vhf:d:') or die "unknown option\n";

$opt_v and die "verion $version\n";
$opt_h and die "help will be printed here in future\n";

$opt_f and print "filen to read:       $opt_f\n";
$opt_d and print "recording in to dir: $opt_d\n";

$opt_f or die "need a file to red with -f <NAME_OF_FILE>\n";
$opt_d or die "dont know where to write! give a dir with -d <RECORDING_ROOT_DIR>\n"
