#!/usr/bin/perl

$| = 1;

use strict;

use File::Find;
use Data::Dumper;
use FindBin qw($RealBin);		# Find this script real path
use Cwd;				# Report working directory

FindBin::again();			# Our path
chdir("$RealBin/../../..");		# Go to installation root

print "Collecting skins directories below ",cwd()," with access rights different from 0777..\n";

my @dirs;

find(
	sub {
		my $full_path = $File::Find::dir.'/'.$_;
		
		if (-d $_ and $full_path =~ /\/private\/.+\/skins\// and $full_path !~ /\/(?:\.svn|__compiled)/) {
			my $mode = (stat($_))[2] & 07777;
			push @dirs, $full_path if $mode != 0777;	
		}
	}, 
	'.'
);

if (@dirs) {
	print "Found ".@dirs." directories. Changing access rights to 0777..\n";
	
	foreach my $dir (@dirs) {
	  print "  $dir.. ";
	  chmod 0777, $dir;
	  print "ok!\n";
	}
}

my $merged_dir = "./public/system/merged";
my $temp_dir = "./private/system/temp";

print "Checking if temp and merged directories exist..\n";

if (not -e $merged_dir) {
	print "  $merged_dir doesn't exist, creating it and setting access rights to 0777..\n";
	mkdir $merged_dir;
	chmod 0777, $merged_dir;
}

if (not -e $temp_dir) {
	print "  $temp_dir doesn't exist, creating it and setting access rights to 0777..\n";
	mkdir $temp_dir;
	chmod 0777, $temp_dir;
}

print "\nFinished!\n";