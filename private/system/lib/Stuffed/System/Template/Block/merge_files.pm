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

$defs->{merge_files} = {
	pattern	=> qr/^\s*$/o,
	handler	=> \&merge_files,
	version	=> 1.0,
};

sub merge_files {
	my ($self, $content) = @_;
	my $t = $self->{template};

	require Stuffed::System::Utils;
	my ($as_is, $paths) = Stuffed::System::Utils::extract_paths_from_html(
		html      => $content,
		tmpl_obj  => $t,
	  );

	my $code = Stuffed::System::Utils::produce_code($paths);

	$t->add_to_top("require Stuffed::System::Utils; Stuffed::System::Utils->import('&merge_files_together');");
	my $final = '';
	if (true($as_is)) {
		$final = $t->compile(template => $as_is, raw => 1).'.';
	}
	$final .= 'merge_files_together('.$code.')';

	$self->{raw} ? $t->add_to_raw($final) : $t->add_to_compiled("push \@p,$final;");
}

1;
