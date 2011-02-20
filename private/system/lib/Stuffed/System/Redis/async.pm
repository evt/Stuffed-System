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

package Stuffed::System::Redis::async;
use strict;

our $VERSION = 0.1;

use Stuffed::System;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    
    croak "Package AnyEvent::Redis is not installed" if not eval "require AnyEvent::Redis";
    
    my $redis = AnyEvent::Redis->new(
        host        => $args{host},
        port        => $args{port},
        on_error    => sub { $system->error->die(join(' ', @_), kind_of => 1) }
    );

    return $redis;
}