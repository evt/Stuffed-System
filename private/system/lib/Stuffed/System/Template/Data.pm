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

package Stuffed::System::Template::Data;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		name	=> undef, # name of the data to initialize
		pkg		=> undef, # current package object
		vars	=> undef, # template variables
		@_
	};
	return if false($in->{name}) or false($in->{pkg});
	(my $pkg = $in->{pkg}->__name) =~ s/:/::/g;
	$pkg = 'Stuffed::System::Template::Data::'.$pkg;
	my $data_name = $pkg.'::'.$in->{name};
	my $data_path = $in->{pkg}->__path.'/template_data';
	if (not defined &{$data_name}) {
		my $error = sub {die "Data named \"$in->{name}\" is not supported in package \"".$in->{pkg}->__name."\"!\n"};
		$error->($in->{name}) if not -e $data_path."/$in->{name}.cgi";
		eval qq(package $pkg; use Stuffed::System; ) .
		  qq(require "$data_path/$in->{name}.cgi") || die $@;
		$error->($in->{name}) if not defined &{$data_name};
	}

	my $self = bless({
			pkg		=> $in->{pkg},
			name	=> $data_name,
			path	=> $data_path,
			vars	=> $in->{vars}
		}, $class);

	return $self;
}

sub execute {
	my ($self, $query) = @_;
	return if $self->false($self->{name});
	if (true($query)) {
		while ($query =~ /([^=\s]+)="([^"]*?)"/g) {
			$self->add_query($1, $2);
		}
	}
	no strict 'refs';
	return &{$self->{name}}($self);
}

sub add_query {
	my ($self, $key, $value) = @_;
	return undef if false($self->{name}) or false($key) or false($value);
	push @{$self->{query}{$key}}, $value;
}

sub get_query {
	my ($self, $key) = @_;
	return undef if false($self->{name});
	return ($self->{query} ? [keys %{$self->{query}}] : undef) if false($key);
	return undef if false($self->{query}{$key});
	return wantarray ? @{$self->{query}{$key}} : $self->{query}{$key}[0];
}

sub delete_query {
	my ($self, $key) = @_;
	return if false($self->{name}) or false($key);
	delete $self->{query}{$key};
}

sub DESTROY {}

1;