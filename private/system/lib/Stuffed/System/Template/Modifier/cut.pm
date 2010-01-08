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
use vars qw($defs);

$defs->{cut} = {
	handler				=> \&cut,
	version				=> 1.0,
	before_encode_html	=> 1, # run this modifier before encode_html
};

sub cut {
	my ($self, $var) = @_;
	return '' if false($var);

	my $length = $self->{param} =~ /^\d+$/ ?  $self->{param} : '';
	return "Stuffed::System::Utils::cut_string($var, $length)";
}

1;
