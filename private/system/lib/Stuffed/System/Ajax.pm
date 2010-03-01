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
our @EXPORT_OK = qw(&return_error &return_html &return_js &return_json &return_xml);

sub return_error {
	my $msg = shift;
	my $options = {
		fields		=> undef, # list of form fields that should be marked as containing errors
		no_headers	=> undef,
		@_
	};

	if (true($options->{fields}) and not ref $options->{fields}) {
		$options->{fields} = [$options->{fields}];
	}

	if (not $options->{no_headers}) {
		# IE will not give us access via JS to the iFrame with a status 500 document 
		if (not $system->out->context('iframe')) {
			$system->out->header(Status => '500 Internal Server Error');	
		}

		if ($ENV{HTTP_X_EXPECT_JSON_IN_ERROR}) {
			$system->out->header('Content-Type' => 'application/json');
		} else {
			$system->out->header('Content-Type' => 'text/html');
		}
	}

	if ($ENV{HTTP_X_EXPECT_JSON_IN_ERROR} || $system->out->context('iframe')) {
		my $reply = {msg => $msg};
		if (ref $options->{fields} and @{$options->{fields}}) {
			$reply->{fields} = $options->{fields};
		}
		
		$msg = Stuffed::System::Utils::convert_to_json($reply);
	}

	if ($system->out->context('iframe')) {
		require Stuffed::System::Utils;
		$msg = '<textarea is_error="1">'.Stuffed::System::Utils::encode_html($msg).'</textarea>';
	}

	__say($msg);
}

sub return_xml {
	__say(shift, 'text/xml');
}

sub return_html {
	my $msg = shift;
	
	if ($system->out->context('iframe')) {
		require Stuffed::System::Utils;
		$msg = '<textarea>'.Stuffed::System::Utils::encode_html($msg).'</textarea>';
	}
	
	__say($msg, 'text/html');
}

sub return_js {
	__say(shift, 'application/x-javascript');
}

sub return_json {
	my $hash = shift;

	require Stuffed::System::Utils;
	my $json = Stuffed::System::Utils::convert_to_json($hash);
	
	if ($system->out->context('iframe')) {
		require Stuffed::System::Utils;
		$json = '<textarea is_json="1">'.Stuffed::System::Utils::encode_html($json).'</textarea>';
	} else {
		$system->out->header('Content-Type' => 'application/json');		
	}

	__say($json);
}

sub __say {
	my ($content, $type) = @_;
	$system->out->header('Content-Type' => $type) if true($type);
	$system->out->say($content);
	$system->config->set(debug => 0);
	$system->stop;
}

1;