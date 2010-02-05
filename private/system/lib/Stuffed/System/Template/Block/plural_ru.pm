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

$defs->{plural_ru} = {
	pattern	=> qr/^\s*(\S+)\s+0="([^"]+)"\s+1="([^"]+)"\s+2="([^"]+)"\s*$/o,
	single	=> 1,
	handler	=> \&plural_ru,
	version	=> 1.0,
};

sub plural_ru {
	my $self = shift;
	my $in = {
		params	=> undef,
		content	=> undef,
		@_
	};
	my $t = $self->{template};
	my ($params, $content) = map { $in->{$_} } qw(params content);
	return if not $params;

	my $number = $t->compile(template => $params->[0], tag_start => '', tag_end => '', raw => 1);
	my $zero = $t->compile(template => $params->[1], tag_start => '<', tag_end => '>', raw => 1); 
	my $one = $t->compile(template => $params->[2], tag_start => '<', tag_end => '>', raw => 1);
	my $two = $t->compile(template => $params->[3], tag_start => '<', tag_end => '>', raw => 1);

	$t->add_to_top("require Stuffed::System::Utils; Stuffed::System::Utils->import('&plural_ru');");
	my $final = "plural_ru($number, $zero, $one, $two)";

	$self->{raw} ? $t->add_to_raw($final) : $t->add_to_compiled("push \@p,$final;");
}

1;
