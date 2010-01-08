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

package Stuffed::System::True;

$VERSION = 1.00;

use strict;
use vars qw(@ISA @EXPORT);

require Exporter; @ISA = qw(Exporter); @EXPORT = qw(true false);

sub true {
	return if not @_;
	for (@_) {
		return if not defined $_ or $_ eq '';
	}
	return 1;
}
sub false {
	return 1 if not @_;
	for (@_) {
		return if defined $_ and $_ ne '';
	}
	return 1;
}

1;