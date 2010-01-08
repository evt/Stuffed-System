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

$defs->{dump} = {
	pattern	=> qr/^\s*(\S+)\s*$/o,
	single	=> 1,
	handler	=> \&dump,
	version	=> 1.1,
};

sub dump {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my $t = $self->{template};
	my $var = $self->{params}[0];
	if ($var eq 'vars') {
		$var = '$v';
	} else {
		$var = $t->compile(template => $var, tag_start => '', tag_end => '', raw => 1);
	}
	return if not $var;

	$t->add_to_compiled("push \@p,\$system->dump($var,return=>1);");
}

1;
