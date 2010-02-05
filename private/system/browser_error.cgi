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
use Stuffed::System::Utils qw(&get_ip);
use Stuffed::System::File;

sub default {
	my $self = shift;
	my $in = $system->in;

	if ($system->config->get('log_browser_errors')) {
		my $msg = $in->query('m');
		my $url = $in->query('u');
		my $actual_url = $in->query('c');
		my $line = $in->query('l');
		my $referrer = $in->query('r');
		my $ip = get_ip();

		require HTTP::BrowserDetect;
		if (HTTP::BrowserDetect->new->firefox and $msg =~ /^Error loading script/i) {
			__blank_gif();
		}

		my $log_filename = $system->config->get('browser_errors_file');

		# relative path, we add system path in front
		if (true($log_filename) and $log_filename !~ /^\//) {
			$log_filename = $system->path.'/'.$log_filename
		}

		# file not specified, using default file name and location
		elsif (false($log_filename)) {
			$log_filename = $system->path.'/private/.ht_errors.browser.log';
		}

		my $file = Stuffed::System::File->new($log_filename, 'a', {is_text => 1});
		if ($file) {
			$file->print('['.localtime()." - $ip] $msg\n");
			if ($url eq $actual_url) {
				$file->print("URL: $url (line $line)\n");
			} else {
				$file->print("Error URL: $url (line $line)\n");
				$file->print("Actual URL: $actual_url\n");
			}
			$file->print("Browser: $ENV{HTTP_USER_AGENT}\n");
			$file->print("Referrer: $referrer\n") if $referrer;
			$file->print("\n");
			$file->close;
		}
	}

	__blank_gif();
}

sub __blank_gif {
	my $blank_gif = "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x21\xf9\x04\x01\x00\x00\x00\x00\x2c\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x44\x01\x00\x3b";

	binmode STDOUT;
	$system->config->set(debug => undef);
	$system->out->header('Content-Length' => length($blank_gif));
	$system->out->header('Content-Type' => 'image/gif');
	$system->out->say($blank_gif);
	$system->stop;
}

1;
