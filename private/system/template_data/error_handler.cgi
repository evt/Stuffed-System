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
use Stuffed::System::Utils qw(&quote);

=pod

Usage in template

<%import error_handler from system suppress_browser_handler="1"%>
<%$error_handler.custom_message_start%>Custom error message here.\nThat was a new line symbol for alert.<%$error_handler.custom_message_end%>
<%$error_handler.js%>

Sub parameters

* show_custom_message

  Can be any true value or 'only_in_ie', the latter will only enable the
  custom message if the current browser is detected as any version of IE.
  Automatically suppresses the default browser handler.
  
* use_default_custom_message

  Asks to use the default custom message (in English) instead of specifying
  a "custom" custom message inside the page/template.
  
* suppress_browser_handler

  Asks to prevent the default browser error handler/message from firing.

=cut

sub error_handler {
	my $self = shift;
	my $vars = {};

	my $cgi_url = $system->config->get('cgi_url');

	if ($self->get_query('show_custom_message') eq 'only_in_ie') {
		require HTTP::BrowserDetect;
		$self->delete_query('show_custom_message') if not HTTP::BrowserDetect->new->ie;
	}

	my $alert_str = '';
	if ($self->get_query('show_custom_message')) {
		if ($self->get_query('use_default_custom_message')) {
			my $default_msg =<<ERROR;
An error has just occured on this page! 

The page might still remain usable for you.

We are sorry for any inconvenience this error might have caused. 
Be assured that we are already working on solving the problem.
ERROR
			(my $default_msg = quote($default_msg, start => "'")) =~ s/\n/\\n/g;
			$alert_str = "if(!__stuffedEHI.a){alert($default_msg);__stuffedEHI.a=1}";
		} else {
			$alert_str = "if(!__stuffedEHI.a&&typeof __stuffedECM != 'undefined'){alert(__stuffedECM);__stuffedEHI.a=1}";
		}
	}

	my $return_str = 'return ';
	if ($self->get_query('suppress_browser_handler') or $self->get_query('show_custom_message')) {
		$return_str .= 'true';
	} else {
		$return_str .= 'false';
	}

	$vars->{js} = <<JS;
<script type="text/javascript">var __stuffedEHI=new Image();window.onerror=function(m,u,l){var a=encodeURIComponent;__stuffedEHI.src='${cgi_url}?pkg=system&action=browser_error'+'&m='+a(m)+'&u='+a(u)+'&l='+a(l)+'&r='+a(document.referrer)+'&c='+a(window.location.href)+'&__='+Math.random(100);${alert_str}${return_str}}</script>
JS

	$vars->{custom_message_start} = q(<script type="text/javascript">var __stuffedECM=');
	$vars->{custom_message_end} = q('</script>);

	return $vars;
}

1;