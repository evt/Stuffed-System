#!/usr/bin/perl

$| = 1;

use strict;

use File::Find;
use File::Path;
use Data::Dumper;
use FindBin qw($RealBin);		# Find this script real path
use Cwd;				# Report working directory

FindBin::again();			# Our path
chdir("$RealBin/../../..");		# Go to installation root

print "Searching for __compiled directories below ",cwd(),"..\n";

my @dirs;

finddepth(
	sub {
		return if $_ ne '__compiled' or not -d $_;
		push @dirs, $File::Find::dir.'/'.$_;
	}, 
	'.'
);

if (not @dirs) {
  print "No __compiled directories found.\n";
  exit;
}

print "Found ".@dirs." directories. Removing..\n\n";

foreach my $dir (@dirs) {
  print "  $dir.. ";
  rmtree($dir);
  print "ok!\n";
}

print "\nFinished!\n";