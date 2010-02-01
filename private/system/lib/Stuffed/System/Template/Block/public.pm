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

$defs->{public} = {
	pattern	=> qr/^\s*([^\s]+)(?:\s+from\s+(\S+?))?(?:\s+using\s+(\S+?))?\s*$/o,
	single	=> 1,
	handler	=> \&public,
	version	=> 1.0,
};

use Stuffed::System::Utils qw(&quote);

sub public {
	my $self = shift;
	my $in = {
		params	=> undef,
		content	=> undef,
		@_
	};
	my $t = $self->{template};
	my ($params, $content) = map { $in->{$_} } qw(params content);
	return if not $params;

	my $f_path = $params->[0];
	return if not $f_path;

	my $pkg_name = $params->[1]; # optional
	$pkg_name = $t->{pkg}->__name if false($pkg_name);

	my $skin_id = $params->[2]; # optional
	$skin_id = $t->{skin}->id if false($skin_id);

	$f_path = $skin_id.'/'.$f_path;

	my $query = '?pkg=system&action=public&f_path='.$f_path.'&f_pkg='.$pkg_name;

	$t->add_to_compiled('push @p,$system->config->get(\'cgi_url\').'.quote($query).';');
}

1;
