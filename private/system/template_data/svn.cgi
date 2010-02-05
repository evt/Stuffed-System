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

sub svn {
	my $self = shift;

	my $system_path = $system->path;
	my $revision;
	
	if (-r $system_path.'/.revision') {
		require Stuffed::System::File;
		my $f = Stuffed::System::File->new($system_path.'/.revision', 'r', {is_text => 1});
		($revision = $f->contents) =~ s/\D+//g;
		$f->close;
	}
	
	else {
		my $svnversion = $system->config->get('svnversion') || 'svnversion';
		
		$revision = `$svnversion $system_path`;
		if ($revision =~ /:/) {
			($revision) = $revision =~ /:(.+)$/;
		}
	}

	my $vars = { revision => $revision };

	return $vars;
}

1;
