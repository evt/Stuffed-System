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

$defs->{session} = {
	pattern	=> qr/^session\.(?:(get)\.)?(.+)$/o,
	handler	=> \&session,
	version	=> 1.0,
};

sub session {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my ($get, $var) = @{$self->{params}};
	my $result;
	if (not $get) {
		$result = ($var =~ /^id|id_for_url$/ ? "\$system->session->$var" : '');
	} else {
		$result = '$system->session->get('.Stuffed::System::Utils::quote($var).')';
	}
	return $self->optimize($result);
}

1;
