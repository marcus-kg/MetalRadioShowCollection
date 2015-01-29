#!/usr/bin/perl
use strict;

use File::Path qw(make_path);
#use Date::Calc qw(Delta_DHMS);

my $a = "123456789987654321";
print $a."\n";
$a =~ s/1|5/a/g;
# =~ s/2/b/;

my $Str = "/home/marcus/lsmf/ls-mf2/2013-12-13";
make_path("$Str");

print $a."\n";
