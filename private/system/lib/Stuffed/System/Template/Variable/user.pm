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

# History:
# 1.1 - added special case for $user.id

$defs->{user} = {
	pattern	=> qr/^user(?:\.(.+?))?\.([^\.]+)$/o,
	handler	=> \&user,
	version	=> 1.1,
};

sub user {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my ($pkg, $var) = @{$self->{params}};
	$pkg = $self->{template}{pkg}->__name if false($pkg);

	my $result;

	if ($var eq 'logged') {
		$result = '$system->user->logged';
	} elsif ($var eq 'id') {
		$result = '$system->user->id';
	} else {
		$result = '$system->user->profile('.Stuffed::System::Utils::quote($var);
		$result .= ',pkg=>'.Stuffed::System::Utils::quote($pkg) if $pkg ne 'system';
		$result .= ')';
	}

	return $self->optimize($result);
}

1;