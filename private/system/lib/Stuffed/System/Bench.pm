# ============================================================================
#
#                        ___
#                    ,yQ$SSS$Q',      ,'yQQQL
#                  j$$"`     `?$'  ,d$P"```'$$,
#           i_L   I$;            `$``       `$$,
#                                 `          I$$
#           .:yQ$$$$,            ;        _,d$$'
#        ,d$$P"^```?$b,       _,'  ;  ,:d$$P"
#     ,d$P"`        `"?$$Q#QPw`    $d$$P"`
#   ,$$"         ;       ``       ;$?'
#   $$;        ,dI                I$;
#   `$$,    ,d$$$`               j$I
#     ?$S#S$P'j$'                $$;         Copyright (c) Stuffed Guys
#       `"`  j$'  __....,,,.__  j$I              www.stuffedguys.org
#           j$$'"``           ',$$
#           I$;               ,$$'
#           `$$,         _.:u$$:`
#             "?$$Q##Q$$SP$"^`
#                `````
#
# ============================================================================

package Stuffed::System::Bench;

$VERSION = 1.00;

use strict;

my $seq = [qw(Time::HiRes Benchmark)];

sub new {
	my $class = shift;
	my $in = {@_};
	my $self = bless({}, $class);

	my $sequence = $in->{seq} || $seq;

	foreach my $class (@$sequence) {
		(my $method = '__'.$class) =~ s/::/_/;
		die "Class \"$class\" is not supported" if not defined &{"Stuffed::System::Bench::$method"};
		return $self if $self->$method();
	}
}

# is used to clone everything from the original object except the log
sub clone {
	my $self = shift;

	my $clone = bless({}, ref $self);
	$clone->{$_} = $self->{$_} for qw(start count raw);

	return $clone;
}

sub __Time_HiRes {
	my $self = shift;
	eval {require Time::HiRes} || return;
	$self->{start} = [Time::HiRes::gettimeofday()];
	$self->{count} = sub {
		Time::HiRes::tv_interval($self->{start}) . " seconds";
	};
	$self->{raw} = sub {
		Time::HiRes::tv_interval($self->{start});
	};
	return $self;
}

sub __Benchmark {
	my $self = shift;
	eval {require Benchmark} || return;
	$self->{start} = Benchmark->new;
	$self->{count} = sub {
		(Benchmark::timestr(Benchmark::timediff(Benchmark->new,
					$self->{start}))) =~ /(\S+\s+CPU)\)$/; $1 . "";
	  };
	$self->{raw} = $self->{count};
	return $self;
}

sub as_js {
	my $self = shift;
	my $content  = qq(<script type="text/javascript"><!--\n);
	$content .= qq(defaultStatus = 'Processing time: );
	$content .= $self->{count}->() . qq(.';\n//--></script>);
	return $content;
}

sub as_text { $_[0]->{count}->() }
sub get_raw { $_[0]->{raw}->() }

sub log {
	my ($self, $msg) = @_;

	push @{$self->{__log}}, {
		secs  => $self->get_raw,
		msg   => $msg
	  };

	return $self;
}

sub get_log {
	my $self = shift;
	my $in = {
		separator	=> undef,
		only_last	=> undef, # optional, asks to get only the last record in the log
		@_
	};
	return undef if not $self->{__log};

	if ($in->{only_last}) {
		my $entry = $self->{__log}[-1];
		return "$entry->{secs} - $entry->{msg}";
	}

	my $separator = defined $in->{separator} ? $in->{separator} : "\n";

	my @log;
	my $last_secs = 0;
	foreach my $entry (@{$self->{__log}}) {
		my $elapsed = sprintf("%.2f", $entry->{secs}-$last_secs);
		$last_secs = $entry->{secs};

		# 6 digits after the point is for when Time::HiRes is used, maybe the ideal
		# length should be determined dynamically from the first value in the log,
		# the main goal is to make the length of the secs the same across all log
		# entries, this makes it easier to compare them when looking at the log
		push @log, sprintf("%.6f", $entry->{secs})." ($elapsed) - $entry->{msg}";
	}

	return join($separator, @log);
}

1;