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

use Stuffed::System;

sub default {
	my $self = shift;
	$system->user->logout if $system->user->logged;

	my ($redirect, $back) = (undef, $system->in->query('back'));

	if (true($back) and $back =~ /^http:\/\// and $back !~ /logout/) {
		$redirect = $back;
	}

	if (false($redirect) and true($ENV{HTTP_REFERER}) and $ENV{HTTP_REFERER} !~ /logout/) {
		$redirect = $ENV{HTTP_REFERER};
	}

	if (false($redirect)) {
		$redirect = $system->config->get('cgi_url');
	}

	$system->out->redirect($redirect);
	$system->stop;
}

1;
