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

$defs->{elsif} = {
	pattern	=> qr/^\s*$/o,
	single	=> 1,
	handler	=> \&elsif,
	version	=> 1.0,
};

sub elsif {
	my $self = shift;

	my $block = Stuffed::System::Template::Block->new(
		type		=> 'if',
		template	=> $self->{template},
		exp			=> $self->{exp},
		raw			=> $self->{raw},
		__elsif		=> 1,
	);
	
	$block->handle;
}

1;
