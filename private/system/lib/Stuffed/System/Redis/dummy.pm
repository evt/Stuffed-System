# ============================================================================
#
#                        ___
#                    ,yQ$SSS$Q',      ,'yQQQL
#                  j$$"`     `?$'  ,d$P"```'$$,
#           i_L   I$;            `$``       `$$,
#                                 `          I$$
#           .yQ$$$$,            ;        _,d$$'
#        ,d$$P"^```?$b,       _,'  ;  ,d$$P"
#     ,d$P"`        `"?$$Q#QPw`    $d$$P"`
#   ,$$"         ;       ``       ;$?'
#   $$;        ,dI                I$;
#   `$$,    ,d$$$`               j$I
#     ?$S#S$P'j$'                $$;         Copyright (c) Stuffed Guys
#       `"`  j$'  __....,,,.__  j$I              www.stuffedguys.com
#           j$$'"``           ',$$
#           I$;               ,$$'
#           `$$,         _.u$$:`
#             "?$$Q##Q$$SP$"^`
#                `````
#
# ============================================================================
# ============================================================================

package Stuffed::System::Redis::dummy;
use strict;

our $VERSION = 0.1;

use Stuffed::System;

our $AUTOLOAD;

sub new {
    my ($class, %args) = @_;
    
    return bless({}, $class);
}

sub AUTOLOAD {}
sub DESTROY {}

1;