#!/usr/bin/perl
use strict;
# use LWP::Simple;
use LWP::UserAgent;

my $ua = new LWP::UserAgent;
$ua->timeout(120);
my $url='http://www.earthtools.org/timezone-1.1/50.1109221/8.3267853';
#my $url='http://www.earthtools.org/timezone-1.1/50.1109221/38.3267853';
my $request = new HTTP::Request('GET', $url);
my $response = $ua->request($request);
my $content = $response->content();
my $timethere;

# $content =~ m/<isotime>2012-07-10 21:38:09 +0100</isotime>/;
$content =~ m{\<isotime\>(\d\d\d\d)\-(\d\d)-(\d\d) (\d\d)\:(\d\d)\:(\d\d) \+(\d\d\d\d)\</\isotime\>};

my $year = $1;
my $month = $2;
my $dayofmonth = $3;
my $houre = $4;
my $minute = $5;
my $second = $6;
my $offset = $7;

print $content;

print "year:$year month:$month dayofmonth:$dayofmonth houre:$houre minute:$minute second:$second offset:$offset\n";

