#!/usr/bin/perl

use FindBin qw($RealBin);		# Find this script real path
FindBin::again();			# Our path

print "Processing files.. ";

my $in = {};

# skip __compiled directories
$in->{'ex-dir'} = [qw(__compiled __cache)];

foreach my $param (@ARGV) {
  my ($key, $value) = $param =~ /^--([^=]+)=(.+)$/;
  push @{$in->{$key}}, $value;
}

my ($total, $size) = explore("$RealBin/../../../");
$size = sprintf("%0.2f", $size/1024);

print "done!\n$total lines of Perl code were found in files with a total size of $size kb!\n";

sub explore {
  my $dir = shift;
  return 0 if not defined $dir or $dir eq '';

  my ($total_lines, $total_size) = (0, 0);

  if ($in->{'ex-dir'}) {
    foreach my $ex (@{$in->{'ex-dir'}}) {
      return $total_lines, $total_size if $dir =~ /$ex/;
    }
  }

  opendir(DIR, $dir) || die "Can't open directory $dir: $!";
  my @files = readdir(DIR);
  foreach my $file (@files) {
    next if "$dir/$file" eq "./$0";
    next if $file =~ /^\.+$/;
    next if not -d "$dir/$file" and $file !~ /(?:\.cgi|\.pl|\.pm)$/;
    if (-d "$dir/$file") {
      my ($lines, $size) = explore("$dir/$file");
      $total_lines += $lines;
      $total_size += $size;
    } else {
      my ($lines, $size) = count("$dir/$file");
      $total_lines += $lines;
      $total_size += $size;
    }
  }
  closedir(DIR);

  return $total_lines, $total_size;
}

sub count {
  my $file = shift;
  return 0 if not defined $file or $file eq '';

  my ($total, $size) = (0, 0);

  open(F, $file) || die "Can't open file $file: $!";
  while (my $line = <F>) {
    next if $line =~ /^\s*#/ or $line =~ /^\s+$/;
    #last if $line =~ /^\_\_END\_\_/ or $line =~ /^1;/;
    $total += 1;
    $size += length($line);
  }
  close(F);

  return $total, $size;
}
