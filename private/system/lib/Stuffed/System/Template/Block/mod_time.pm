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

$defs->{mod_time} = {
	pattern	=> qr/^\s*$/o,
	handler	=> \&mod_time,
	version	=> 1.0,
};

sub mod_time {
	my ($self, $content) = @_;
	my $t = $self->{template};

	my $final = $t->compile(template => $content, raw => 1);

	$t->add_to_top("require Stuffed::System::Utils; Stuffed::System::Utils->import('&pub_file_mod_time');");
	$final = 'pub_file_mod_time('.$final.')';

	$self->{raw} ? $t->add_to_raw($final) : $t->add_to_compiled("push \@p,$final;");
}

1;
