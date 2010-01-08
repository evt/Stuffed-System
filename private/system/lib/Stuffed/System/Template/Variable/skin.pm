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

use Stuffed::System::Utils qw(&quote);

$defs->{skin} = {
	pattern	=> qr/^skin(?:\.(.+?))?\.([^\.]+)$/o,
	handler	=> \&skin,
	version	=> 1.0,
};

sub skin {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $t = $self->{template};
	my $skin = $t->{skin}->id;
	my ($pkg, $var) = @{$self->{params}};
	$pkg =~ s/\./:/g if true($pkg);

	my $res_line;

	if (true($pkg) and $pkg ne $t->{pkg}->__name) {
		$res_line = 'Stuffed::System::Skin->new(id=>'.quote($skin).',pkg=>$system->pkg('.quote($pkg).'))->config->get('.quote($var).')';
	} else {
		$res_line = '$s->{skin}->config->get('.quote($var).')';
	}

	return $self->optimize($res_line);
}

1;
