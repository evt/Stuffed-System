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

package Stuffed::System::Ajax;

$VERSION = 1.00;

use strict;

use Stuffed::System;

use base 'Exporter';
our @EXPORT_OK = qw(&return_error &return_html &return_js &return_json);

sub return_error {
	my $msg = shift;
	my $options = {@_};

	if (true($options->{fields}) and not ref $options->{fields}) {
		$options->{fields} = [$options->{fields}];
	}

	if (not $options->{no_headers}) {
		$system->out->header(Status => '500 Internal Server Error');

		if ($ENV{HTTP_X_EXPECT_JSON_IN_ERROR}) {
			$system->out->header('Content-Type' => 'application/x-javascript');
		} else {
			$system->out->header('Content-Type' => 'text/html');
		}
	}

	if ($ENV{HTTP_X_EXPECT_JSON_IN_ERROR}) {
		my $reply = {msg => $msg};
		if (ref $options->{fields} and @{$options->{fields}}) {
			$reply->{fields} = $options->{fields};
		}
		
		$msg = Stuffed::System::Utils::convert_to_json($reply);
	}

	$system->out->say($msg);
	$system->config->set(debug => 0);
	$system->stop;
}

sub return_html {
	my $msg = shift;
	my $options = {@_};
	$system->out->header('Content-Type' => 'text/html');
	$system->out->say($msg);
	$system->config->set(debug => 0);
	$system->stop;
}

sub return_js {
	my $msg = shift;
	my $options = {@_};
	$system->out->header('Content-Type' => 'application/x-javascript');
	$system->out->say($msg);
	$system->config->set(debug => 0);
	$system->stop;
}

sub return_json {
	my $hash = shift;

	$system->out->header('Content-Type' => 'application/x-javascript');

	require Stuffed::System::Utils;

#	my $json = Stuffed::System::Utils::produce_code($hash, json => 1, allow_blessed => 1);
	my $json = Stuffed::System::Utils::convert_to_json($hash);

	$system->out->say($json);
	$system->config->set(debug => 0);
	$system->stop;
}

1;