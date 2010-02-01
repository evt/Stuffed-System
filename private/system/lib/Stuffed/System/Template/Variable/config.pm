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

$defs->{config} = {
	pattern	=> qr/^config(?:\.(.+?))?\.([^\.]+)$/o,
	handler	=> \&config,
	version	=> 1.0,
};

sub config {
	my $self = shift;
	my $in = {
		params	=> undef,
		@_
	};
	my $params = $in->{params};
	return if not $params;

	my $t = $self->{template};
	my ($pkg, $var) = @$params;
	$pkg =~ s/\./:/g if true($pkg);

	my $res_line;

	if (true($pkg) and $pkg ne $t->{pkg}->__name) {
		$res_line = '$system->pkg('.Stuffed::System::Utils::quote($pkg).')->__config->get('.Stuffed::System::Utils::quote($var).')';
	} else {
		$res_line = '$s->{pkg}->__config->get('.Stuffed::System::Utils::quote($var).')';
	}

	return $self->optimize($res_line);
}

1;
