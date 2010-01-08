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

$defs->{error} = {
	pattern	=> qr/^error\.([^\.]+)(?:\.([^\.]+))?$/o,
	handler	=> \&error,
	version	=> 1.0,
};

use Stuffed::System::Utils qw(&quote);

sub error {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $err_num = $self->{params}[0];
	my $err_method = $self->{params}[1];

	my $compiled = '$system->error->get_error('.quote($err_num).')';
	if (true($err_method)) {
		$compiled .= '->'.$err_method;
	}

	return $self->optimize($compiled);
}

1;
