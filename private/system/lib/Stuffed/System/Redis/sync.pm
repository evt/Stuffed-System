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

package Stuffed::System::Redis::sync;
use strict;

our $VERSION = 0.1;

use Stuffed::System;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    
    croak "Package Redis::hiredis is not installed" if not eval "require Redis::hiredis";
    
    my $redis = Redis::hiredis->new;
    $redis->connect($args{host}, $args{port});

    return $redis;
}
