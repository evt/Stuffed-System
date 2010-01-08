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

	if (not $system->out->context('web')) {
		$system->out->say("System stopped.\n");
		$system->stop;
	}

	if ($ENV{REQUEST_METHOD} eq 'GET') {
		$self->{vars}{url} = 'http'.($ENV{HTTPS} eq 'on' ? 's' : '').'://'.$ENV{HTTP_HOST}.$ENV{REQUEST_URI};
	}

	my $content = $self->__template->parse($self->{vars});
	$system->out->say($content);
	$system->stop;
}

1;