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

package Stuffed::System::Redis;
use strict;

our $VERSION = 0.1;

use Stuffed::System;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    my $type = $args{type};
    
    my $config = $system->config;
    
    my $host = $config->get('redis_host');
    my $port = $config->get('redis_port');
    croak "No host or port specified for redis in system config" if not $host or not $port;
    
    if (not eval "require Stuffed::System::Redis::$type") {
        croak "Redis backend type of '$type' is not supported";
    }

    my $redis;
    
    # try 3 times to connect if the connection keeps failing
    for (1..3) {
        $redis = "Stuffed::System::Redis::$type"->new(
            host        => $host,
            port        => $port,
            on_error    => sub { $system->error->die(join(' ', @_), kind_of => 1) }
        );
        last if $redis;
    }
  
    croak "Connection to the redis of type '$type' failed!\n" if not $redis;

    my $self = $redis;
  
    return $self;
}

# ============================================================================


1;