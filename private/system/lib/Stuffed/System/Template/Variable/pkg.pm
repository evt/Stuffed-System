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

$defs->{pkg} = {
	pattern	=> qr/^pkg(?:\.(.+?))?\.([^\.]+)$/o,
	handler	=> \&pkg,
	version	=> 1.0,
};

sub pkg {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $t = $self->{template};
	my ($pkg, $var) = @{$self->{params}};
	$pkg =~ s/\./:/g if true($pkg);

	if (true($pkg) and $pkg ne $t->{pkg}->__name) {
		$self->optimize('$system->pkg('.Stuffed::System::Utils::quote($pkg).')->__'.$var);
	} else {
		$self->optimize('$s->{pkg}->__'.$var);
	}
}

1;
