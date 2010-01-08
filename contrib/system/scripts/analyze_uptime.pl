#!/usr/bin/perl

use strict;
use Data::Dumper;

exit_usage() if not @ARGV;
  
my ($params, $filename);
foreach my $param_string (@ARGV) {
  if ($param_string =~ /^\-\-/) {
    my ($key, $value) = $param_string =~ /^\-\-([^=]+)(?:=(.+))?$/;
    $params->{$key} = $value;
    next;
  } 
  
  $filename = $param_string;
}

exit_usage() if false($filename);
exit_usage() if not $params->{'report-type'};

# ============================================================================
# general parsing of the file

my @top = ({});
my $proc_lines = 0;

open(F, '< '.$filename) || die "Can't open file $filename for reading: $!";
while (my $line = <F>) {
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  # skip empty lines
  next if false($line);
  
  if ($line =~ /^top\s+\-\s+([\d:]+)/) {
    $top[$#top]->{timestamp} = $1;
    my ($current_average, $prev_average) = $line =~ /load average:\s+([\d\.]+),\s+([\d\.]+)/;    
    $top[$#top]->{load} = $current_average;
    next;
  } 
  
  if ($line =~ /^==\[cut\]==/) {
    $top[$#top+1] = {};
    $proc_lines = 0;
    next;
  } 
  
  if ($line =~ /^Tasks:\s+\d+\s+total,\s+(\d+)\s+running/i) {
    $top[$#top]->{proc_running} = $1;
    ($top[$#top]->{proc_zombie}) = $line =~ /,\s+(\d+)\s+zombie$/i;
    next;
  }
  
  if ($line =~ /^Mem:\s+\d+k?\s+total,\s+\d+k?\s+used,\s+(\d+k?)\s+free/i) {
    $top[$#top]->{mem_free} = $1;
    next;
  }
  
  # main content starts
  if ($line =~ /^PID\s+USER\s+PR/) {
    $proc_lines = 1;
    next;
  }
  
  if ($proc_lines) {
    # skipping processes that take 0 CPU
    my ($load) = $line =~ /^\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/;
    next if not $load;
    
    push @{$top[$#top]->{content}}, $line;
  }
}

if (@top) {
  delete $top[$#top] if not $top[$#top] or not keys %{$top[$#top]};
}

close(F);

# ============================================================================

my $results;

if ($params->{'report-type'} == 1) {
  $results = report_one(
    max_load  => $params->{'max-load'},
    top       => \@top
  );
}

print Dumper($results);

exit;

# ============================================================================
# reports

sub report_one {
  my $in = {
    max_load  => undef,
    top       => undef,
    @_
  };
  my $max_load = $in->{max_load};
  my $top = $in->{top};
  return undef if false($max_load);
  return undef if ref $top ne 'ARRAY';
  
  my $results;
  
  foreach my $record (sort {$b->{load} <=> $a->{load}} @$top) {
    last if $record->{load} < $max_load;
    push @$results, $record;
  }
  
  if ($results) {
    $results = [sort {$a->{timestamp} cmp $b->{timestamp}} @$results];
  }
  
  return $results;
}

# ============================================================================
# functions

sub exit_usage {
  print "Analyzes 'top' dumps and produces pre-defined reports.\n";
  print "Usage: perl abalyze_uptime.pl file_to_analyze --report-type=n --max-load=n\n";
  exit;
}

sub true { 
 return if not @_;
 for (@_) {
   return if not defined $_ or $_ eq '';
 }
 return 1;
}

sub false { 
 return 1 if not @_;
 for (@_) {
   return if defined $_ and $_ ne '';
 }
 return 1;
}
 