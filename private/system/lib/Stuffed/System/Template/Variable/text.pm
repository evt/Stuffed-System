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

# <%$text.__system.common.awaits_approval%>
# __system.common is optional and translates into __system/common.cgi file path

use strict;
use vars qw($defs);

$defs->{text} = {
	pattern	=> qr/^text(?:\.(.+?))?\.([^\.]+)$/o,
	handler	=> \&text,
	version	=> 1.0,
};

sub text {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my ($text_file, $var) = @{$self->{params}};
	$text_file =~ s|\.|/|g if true($text_file);

	my $text_prefix = '$s->{text}';
	if (true($text_file)) {
		$text_prefix = '$s->{pkg}->__language->load('.Stuffed::System::Utils::quote($text_file.'.cgi').')';
	}

	return $self->optimize($text_prefix.'->get('.Stuffed::System::Utils::quote($var).')');
}

1;
