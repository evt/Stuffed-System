#!/usr/bin/perl

# This script is used to autosplit all modules that:
# 1. Are located in all lib/Stuffed directories down the path
# 2. Have .pm extension

# The script fill find all such modules recursively and will autosplit them
# in their respective lib/auto dirs

# Only modules that has AutoLoader support will be split (this is checked
# internally by autosplit routine).

$| = 1;

use FindBin qw($RealBin);		# Find this script real path
use Cwd;				# Report working directory
FindBin::again();			# Our path
chdir("$RealBin/../../..");		# Go to installation root

unshift @INC, "./private/system/lib";
require AutoSplit;

print 'Autosplit is running in ',cwd(),"...\n";
my @files = explore('.');

my $total = 0;

foreach my $file (@files) {
  next if $file !~ m#lib/Stuffed#;
  my ($dir) = $file =~ m#^(.+lib)#;
  next if not defined $dir;
  eval {AutoSplit::autosplit($file, "$dir/auto")};
  warn $@ if $@;
  $total += 1;
}

print "Autosplit finished ($total)!\n";

sub explore {
  my $dir = shift;
  return () if not defined $dir or $dir eq '';

  my @found = ();

  opendir(DIR, $dir) || die "Can't open directory $dir: $!";
  my @files = readdir(DIR);
  foreach my $file (@files) {
    next if "$dir/$file" eq "./$0";
    next if $file =~ /^\.+$/;
    # skip if this is a file and it doesn't have a '.pm' extension
    next if not -d "$dir/$file" and $file !~ /\.pm$/;
    if (-d "$dir/$file") {
      push @found, explore("$dir/$file");
    } else {
      push @found, "$dir/$file";
    }
  }
  closedir(DIR);

  return @found;
}