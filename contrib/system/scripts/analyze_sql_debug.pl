#!/usr/bin/perl

use strict;
use Data::Dumper;

if (@ARGV != 1) {
  print "Analyze SQL debug logs produced by Stuffed System.\n";
  print "Usage: perl analyze_sql_debug.pl file_to_analyze.log\n";
}

my $file = $ARGV[0];

open(F, "< $file") || die "Can't open file '$file' for reading: $@";

while (my $line = <F>) {
  next if $line !~ /total queries executed/i;
  last;  
}

my @query;
while (my $line = <F>) {
  # skip empty lines
  next if $line =~ /^\s*$/;

  # first line
  if (not @query or not $query[$#query]->{in_process}) {
    push @query, {} if not @query;
    $query[$#query]->{in_process} = 1;
    $query[$#query]->{stack} .= $line;
  } 
  
  # a stack line
  elsif ($line =~ /^\-\-/) {
    $query[$#query]->{stack} .= $line;
  }
  
  # total time line, last one 
  elsif ($line =~ /^([\d\.]+) secs/) {
    $query[$#query]->{secs} = $1;
    delete $query[$#query]->{in_process};
    push @query, {};
  }
  
  # sql query line
  else {
    $query[$#query]->{sql} .= $line;
  }
}

close(F);

# Analyzing sql queries

my $q_index;

foreach my $sql (@query) {
  next if $sql->{sql} eq '' or not defined $sql->{sql};
  (my $clean_sql = $sql->{sql}) =~ s/'\d+'/'xxx'/g;
  $q_index->{$clean_sql} += 1;
#  $q_index->{$sql->{sql}} += 1;
}

my @duplicate_sql;

foreach my $sql (sort {$q_index->{$b} <=> $q_index->{$a}} keys %$q_index) {
  next if $q_index->{$sql} <= 1;
  push @duplicate_sql, {sql => $sql, num => $q_index->{$sql}}; 
}

print Dumper(\@duplicate_sql);