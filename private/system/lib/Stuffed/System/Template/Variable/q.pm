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

$defs->{q} = {
	pattern => qr/^q\.(.+)$/o,
	handler => \&q,
	version => 1.0,
  };

sub q {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my $var = $self->{params}[0];
	my $parsed = $self->{template}->compile(
		template  => $var,
		tag_start => '<',
		tag_end   => '>',
		raw       => 1,
	  );
	return $self->optimize('$in->query('.$parsed.')');
}

1;
