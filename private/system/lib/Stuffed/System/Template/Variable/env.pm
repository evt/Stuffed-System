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

use strict;
use vars qw($defs);

$defs->{env} = {
	pattern	=> qr/^env\.(.+)$/o,
	handler	=> \&env,
	version	=> 1.0,
};

sub env {
	my $self = shift;
	my $in = {
		params	=> undef,
		@_
	};
	my $params = $in->{params};
	return if not $params;

	my $t = $self->{template};
	my $var = $params->[0];
	if ($var eq 'all') {
		return 'join("<br>\n", map {"$_ => $ENV{$_}"} sort keys %ENV)';
	} elsif ($var eq 'current_url') {
		$t->add_to_top("my \$current_url='http'.(lc(\$ENV{HTTPS}) eq 'on' ? 's' : '').'://'.\$ENV{HTTP_HOST}.\$ENV{REQUEST_URI};");
		return '$current_url';
	} else {
		return '$ENV{'.Stuffed::System::Utils::quote(uc($var)).'}';
	}
}

1;
