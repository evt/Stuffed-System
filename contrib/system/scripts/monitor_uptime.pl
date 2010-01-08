#!/usr/bin/perl

use strict;
use Data::Dumper;
use DBI;

# ============================================================================
# server top

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

#stty cols 500 < /dev/tty; 
my $uptime = `top -c -bn 1`;
#my ($current_average, $prev_average) = $uptime =~ /load average:\s+([\d\.]+),\s+([\d\.]+)/;
#exit if false($current_average);
$uptime =~ s/^\s+//;
$uptime =~ s/\s+$//;
exit if not defined $uptime or $uptime eq '';

my $dir = 'uptime';
mkdir('uptime') if not -d $dir;

my $time_point = time();
my ($year, $month, $day) = (localtime($time_point))[5, 4, 3];
$year += 1900;
$month += 1;

my $filename = $dir.'/'.$year.'-'.sprintf("%02d", $month).'-'.sprintf("%02d", $day).'.txt';
open(F, '>> '.$filename) || die "Can't open $filename for appending: $!";
if (not flock F, LOCK_EX | LOCK_NB) {
  die "File $filename can not be locked: $!" if not flock F, LOCK_EX;
}
print F "$uptime\n\n==[cut]===================================================\n\n";  
flock F, LOCK_UN;
close(F);

# 5 first lines
my $uptime_short = join("\n", (split(/[\r\n]+/, $uptime))[0..4]);

my $filename_short = $dir.'/'.$year.'-'.sprintf("%02d", $month).'-'.sprintf("%02d", $day).'.short.txt';
open(F, '>> '.$filename_short) || die "Can't open $filename_short for appending: $!";
if (not flock F, LOCK_EX | LOCK_NB) {
  die "File $filename_short can not be locked: $!" if not flock F, LOCK_EX;
}
print F "$uptime_short\n\n==[cut]===================================================\n\n";  
flock F, LOCK_UN;
close(F);

# ============================================================================
# deleting old logs

# delete files that are older then 7 days
my $threshold = time() - 60*60*24*7; # in secs

if (opendir(DIR, $dir)) {
  my @files = readdir(DIR);
  closedir(DIR);

  foreach my $file (@files) {  
    next if $file =~ /^\.+$/;
    next if not -f "$dir/$file";
    # skip the file if it's not one of the files created by this script
    next if $file !~ /^(mysql\-|\d\d\d\d\-)/;
    
    my $modified_time = (stat("$dir/$file"))[9];
    next if $modified_time > $threshold;
    
    unlink "$dir/$file";
  }
}

1;