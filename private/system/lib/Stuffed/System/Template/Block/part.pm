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

$defs->{part} = {
	pattern	=> qr/\s*name=['"]([^'"]+)['"](?:\s+(standalone))?\s*/o,
	handler	=> \&part,
	version	=> 1.0,
};

sub part {
	my ($self, $content) = @_;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $t = $self->{template};
	my $part_name = $self->{params}[0];
	my $standalone = $self->{params}[1];
	my $compiled = $t->compile(template => $content);

	$t->add_to_parts($part_name => $compiled) if true($part_name);
	$t->add_to_compiled($compiled) if not $standalone;
}

1;
