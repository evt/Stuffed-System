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

$defs->{import} = {
	pattern	=> qr/^\s*([^\s]+)(?:\s+from\s+([\w:]+))?(?:\s+as\s+\$?([^\s]+))?(?:\s+(.+?))?\s*$/o,
	single	=> 1,
	handler	=> \&import,
	version	=> 1.1,
};

sub import {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my ($data_name, $pkg, $as, $query) = @{$self->{params}};

	my $t = $self->{template};
	$pkg ||= $t->{pkg}->__name;

	$t->add_to_top("require Stuffed::System::Template::Data;");
	my $compiled = 'my $sub=Stuffed::System::Template::Data->new(name=>'.Stuffed::System::Utils::quote($data_name).', pkg => $system->pkg('.Stuffed::System::Utils::quote($pkg).'), vars => $v);';

	my $name = (defined $as ? $as : $data_name);

	$compiled .= '$v->{'.Stuffed::System::Utils::quote($name).'}=$sub->execute';
	if (true($query)) {
		$compiled .= '('.$t->compile(template => $query, tag_start => '<', tag_end => '>', raw => 1).')';
	}
	$compiled .= ';';

	$t->add_to_compiled($compiled);
}

1;
