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

package Stuffed::System::Ajax::Hash;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $params = @_ ? {@_} : undef;

	my $aliases;

	# checking that all values are unique
	if ($params) {
		foreach my $key (keys %$params) {
			if (true($aliases->{$params->{$key}})) {
				die "Duplicate alias '$params->{$key}' for parameter '$key'!";
			}
			$aliases->{$params->{$key}} = $key;
		}
	}

	my $self = bless({
			params  => $params,
			aliases => $aliases,
		}, $class);

	return $self;
}

sub get_id {
	my $self = shift;
	return undef if not $self->{params};

	require Stuffed::System::Utils;

	my @pairs;
	foreach my $key (keys %{$self->{params}}) {
		next if false($system->in->query($key));

		foreach my $value ($system->in->query($key)) {
			next if not defined $value;

			push @pairs, $self->{params}{$key}.'='.Stuffed::System::Utils::encode_url($value);
		}
	}

	return join('&', @pairs);
}

sub restore_params_from_id {
	my $self = shift;
	my $hash_id = shift;
	return undef if not $self->{params};

	my $query = $system->in->__parse_query($hash_id);
	foreach my $key (keys %{$self->{params}}) {
		$system->in->query($key => $query->{$self->{params}{$key}});
	}

	return $self;
}

1;