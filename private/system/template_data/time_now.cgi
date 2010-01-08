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

sub time_now {
	my $self = shift;
	my $vars = {};

	my @values = localtime();

	$vars->{sec} = $values[0];
	$vars->{min} = $values[1];
	$vars->{hour} = $values[2];
	$vars->{mday} = $values[3];
	$vars->{mon} = $values[4]+1; # 1 is January
	$vars->{year} = $values[5]+1900;
	$vars->{wday} = $values[6] || 7; # sunday is 7

	return $vars;
}

1;