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

package Stuffed::System::Config;

$VERSION = 1.00;

use strict;

use Stuffed::System::True;
use Stuffed::System::File;

sub new {
	my ($class, $file) = @_;
	return if false($file);
	my $self = bless({file => $file}, $class);

	return $self->reload;
}

sub reload {
	my $self = shift;
	my $file = $self->{file};

	if (not $file or not -f $file) {
		$self->{options} = {};
		return $self;
	}

	{
		no strict 'vars';
		local $config = {};

		for (1..3) {
			eval(Stuffed::System::File->new($file, 'r')->contents);

			# no error, we stop trying
			last if not $@;

			sleep(1);
		}

		die $@ if $@;

		$self->{options} = $config;
	}

	return $self;
}

sub get_all {
	my $self = shift;
	return $self->{options};
}

sub get {
	my ($self, $key) = @_;
	return keys %{$self->{options}} if false($key);
	return $self->{options}{$key};
}

sub set {
	my ($self, @pairs) = @_;
	return if not @pairs;
	while (@pairs) {
		my ($key, $value) = splice(@pairs, 0, 2);
		$self->{options}{$key} = $value;
	}
	return $self;
}

sub save {
	my ($self, $data, $in) = (shift, shift, {overwrite => undef, @_});
	return if false($self->{file});

	# if $data is not specified we just write all parameters from the
	# current config object in a file
	$data ||= {};

	(my $dir = $self->{file}) =~ s/[\/\\][^\/\\]+$//;
	Stuffed::System::Utils::create_dirs($dir) if not -d $dir;

	my $config = Stuffed::System::File->new($self->{file}, 'w', {access => 0666}) || die "Can't open file $self->{file} for writing: $!";

	# removing all parameters from this config object if "overwrite" param
	# was specified
	$self->{options} = {} if $in->{overwrite};

	# adding all keys from $data to the current config object, if
	# some keys already exist in current config object then they are
	# overwritten with new values
	foreach my $key (keys %$data) {
		$self->{options}{$key} = $data->{$key};
	}

	my @lines;
	foreach my $key (sort keys %{$self->{options}}) {
		$key = Stuffed::System::Utils::quote($key) if $key =~ /\W/;
		push @lines, "\$config->{$key} = ".Stuffed::System::Utils::produce_code($self->{options}{$key}, spaces => 1).';';
	}

	$config->print(join("\n", @lines)."\n\n1;");
	$config->close;
}

1;