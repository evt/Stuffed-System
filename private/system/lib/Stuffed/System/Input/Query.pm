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

package Stuffed::System::Input::Query;

$VERSION = 1.00;

use strict;
use vars qw($AUTOLOAD);

sub AUTOLOAD {
	my $self = shift;
	
	my ($key) = our $AUTOLOAD =~ /([^:]+)$/;
	
	my (@r, $r);
	
	if (wantarray) {
		@r = $self->{__in}->query($key, @_);
	} else {
		$r = $self->{__in}->query($key, @_);
	}
	
	return wantarray ? @r : $r; 
}

sub DESTROY {}

1;