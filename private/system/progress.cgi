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

sub default {
	my $self = shift;

	my $upload_id = $ENV{HTTP_X_PROGRESS_ID};
	if (false($upload_id)) {
		return_error("Progress id is not specified, progress information is not available.");
	}

	my $info = $system->in->get_upload_info(upload_id => $upload_id);

	my $content = '';

	if (%$info) {
		if ($info->{upload_finished}) {
			$content = "new Object({ 'state' : 'done' })";
		}
		elsif ($info->{content_length}) {
			my $read = $info->{content_read} || 0;
			$content = "new Object({ 'state' : 'uploading', 'received' : $read, 'size' : $info->{content_length}})";
		}
	} else {
		$content = "new Object({ 'state' : 'starting' })";
	}

	$system->out->html($content);
}

1;
