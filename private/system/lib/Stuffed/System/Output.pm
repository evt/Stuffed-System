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

package Stuffed::System::Output;

$VERSION = 1.00;

use strict;

use open qw( :std :encoding(UTF-8) );

use Stuffed::System;

sub new {
	my $class = shift;
	my $config = $system->config;

	my $in = {

		# prefix prepended to all cookie names
		cookies_prefix => true($config->get('cookies_prefix')) ? $config->get('cookies_prefix') : '',

		# path that will be used with all cookies
		cookies_path   => true($config->get('cookies_path')) ? $config->get('cookies_path') : '/',

		# domain that will be used with all cookies
		cookies_domain => true($config->get('cookies_domain')) ? $config->get('cookies_domain') : '',

		# should the cookies be flagged as 'secure'
		cookies_secure => undef,

		@_
	  };

	my $self = bless({headers => {}}, $class);

	foreach (qw(cookies_prefix cookies_path cookies_domain cookies_secure)) {
		$self->{$_} = $in->{$_};
	}

	$self->{context} = true($ENV{HTTP_HOST}) ? ($ENV{HTTP_X_REQUESTED_WITH} eq 'XMLHttpRequest' ? 'ajax' : 'web') : 'shell';

	# setting p3p policy header if p3p policy is enabled in config
	if ($config->get('p3p_enable')) {
		my $p3p_header;
		$p3p_header .= q( policyref=") . $config->get('p3p_policy_location') . q(") if $config->get('p3p_policy_location');
		$p3p_header .= q( CP=") . $config->get('p3p_compact_policy') . q(");
		$self->header(P3P => $p3p_header) if $p3p_header;
	}

	return $self;
}

sub say {
	my ($self, @content) = @_;
	return if not @content;

	# indicates that something was already sent out with 'say'
	$self->{output} = 1;

	$self->__print_header;

	# eval is required to prevent "Connection reset" errors under mod_perl which
	# occur when a client aborts the connection (during print I guess)
	eval {
		print @content;
	};
}

sub context {
	my $self = shift;
	my $type = lc(shift);
	
	# checking iFrame context here to avoid initializing Input.pm on every init of Output.pm
	if (not $self->{__checked_iframe_context}) {
		if ($system->in->query('__x_requested_with') eq 'iframe') {
			$self->{context} = 'iframe';
		}
	}
	
	return $self->{context} if false($type);

	if ($type eq 'web') {
		return 1 if $self->{context} eq 'web' or $self->{context} eq 'ajax' or $self->{context} eq 'iframe';
	}
	elsif ($type eq 'ajax') {
		return 1 if $self->{context} eq 'ajax' or $self->{context} eq 'iframe';
	}
	elsif ($type eq 'iframe') {
		return 1 if $self->{context} eq 'iframe';
	}
	elsif ($type eq 'shell') {
		return 1 if $self->{context} eq 'shell';
	}

	return undef;
}

sub output  { $_[0]->{output} }

sub charset {
	my $self = shift;
	my $charset = shift;

	# possible to specify '' and remove the charset
	return $self->{charset} if not defined $charset;

	$self->{charset} = (true($charset) ? $charset : undef);
}

sub __print_header {
	my $self = shift;
	my $in = {
		redirect            => undef,
		permanent_redirect  => undef,
		@_
	  };

	# use __print_header only if we are in a web environment
	return if not $self->context('web');

	if (not $self->{printed}) {
		if ($self->{cookies}) {
			foreach my $cookie (@{$self->{cookies}}) {
				my $string = "$cookie->{name}=$cookie->{value};";
				$string .= " expires=$cookie->{expires};" if true($cookie->{expires});
				$string .= " path=$cookie->{path};" if true($cookie->{path});
				$string .= " domain=$cookie->{domain};" if true($cookie->{domain});
				$string .= " secure" if $cookie->{secure};
				$self->header('Set-Cookie' => $string);
			}
			delete $self->{cookies};
		}

		if ($in->{redirect}) {
			$self->header('Status' => 301) if $in->{permanent_redirect};
			$self->header('Location' => $in->{redirect});
		} else {
			# content-type not specified, setting the default text/html content-type
			if (false($self->header('Content-Type'))) {
				my $type = 'text/html';
				$type .= "; charset=$self->{charset}" if $self->{charset};
				$self->header('Content-Type' => $type);
			}

			# text/html content-type specified, but no charset, adding charset if it is available
			elsif ($self->header('Content-Type') !~ /charset/ and $self->{charset}) {
				my $type = $self->header('Content-Type');

				# sanitizing the end
				$type =~ s/\s+$//;
				$type =~ s/;$//;
				if ($type =~ /text\/html$/ or $type =~ /javascript/) {
					$type .= "; charset=$self->{charset}";
					$self->header('Content-Type' => $type);
				}
			}
		}

		my $system_id = $system->config->get('system_id');
		$system_id = 'n/a' if false($system_id);
		$self->header('X-Stuffed-System' => $system_id);

		my $headers = '';
		my $status;
		foreach my $name ($self->header) {
			if ($name =~ /^status$/i) {
				$status = {name => $name, value => $self->header($name)};
				next;
			}
			foreach my $value ($self->header($name)) {
				$headers .= "$name: $value\n"
			}
		}

		# mod_perl 1 or 2
		if ($ENV{MOD_PERL}) {
			my $r;

			# mod_perl 2.0
			if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
				$r = Apache2::RequestUtil->request;
			}

			# mod_perl 1.0
			else {
				$r = Apache->request;
			}

			$r->status_line($status->{value}) if $status;
			$r->send_cgi_header("$headers\n");
		}

		# cgi
		else {
			print "$status->{name}: $status->{value}\n" if $status;
			print "$headers\n";
		}

		delete $self->{headers};
		$self->{printed} = 1;
	}
}

sub redirect {
	my ($self, $redirect) = @_;
	my $in = {
		permanent => undef,
		@_
	  };
	if (false($redirect)) {
		$redirect = $system->config->get('cgi_url');
	} elsif ($redirect =~ /^\?/) {

    # adding cgi_url before the redirect string if redirect string starts with ?
		$redirect = $system->config->get('cgi_url').$redirect;
	}

	# if redirect doesn't start with http(s) then we add http_host from
	# environment
	if ($redirect !~ /^http/) {
		$redirect = 'http'.($ENV{HTTPS} ? 's' : '')."://$ENV{HTTP_HOST}".
		  ($redirect =~ /^\// ? '' : '/').$redirect;
	}

	$self->__print_header(redirect => $redirect, permanent_redirect => $in->{permanent});

 # always stopping the system after a redirect, if you want a different behaviou
 # use __print_header method as it is used above
	$system->stop;
}

sub header {
	my ($self, $key, $value) = (shift, shift, shift);
	my $in = {
		overwrite => undef, # optional, the value will be overwritten if the key already exists
		@_
	  };

	# if the key is not defined we return all headers names
	return keys %{$self->{headers}} if false($key);

	if (true($value)) {
		if ($self->{printed} and $self->context('web')) {

			# this causes problems if die is called after say
			# die "Can't set headers. Headers already sent out.";
			return undef;
		}

		delete $self->{headers}{$key} if $in->{overwrite};

		# setting the value to the key, value can be a ref to an array
		if (ref $value eq 'ARRAY') {
			push @{$self->{headers}{$key}}, @$value;
		} else {
			push @{$self->{headers}{$key}}, $value;
		}
	}

	return if not $self->{headers}{$key};

	if (wantarray) {
		return @{$self->{headers}{$key}};
	} else {
		return $self->{headers}{$key}[$#{$self->{headers}{$key}}];
	}
}

sub cookie {
	my $self = shift;
	return if not @_;

	my $in = {
		name    => undef,
		value   => undef,
		expires => undef,
		path    => undef, # optional
		domain  => undef, # optional
		secure  => undef, # optional
		@_
	  };

	if ($self->{printed} and $self->context('web')) {
		die "Can't set cookies. Headers already sent out.";
	}

	my $domain = (defined $in->{domain} ? $in->{domain} : $self->{cookies_domain} ? $self->{cookies_domain} : undef);

	# domain was not specified and we are currently on at least a second level
	# domain (dot is present)
	if (false($domain) and index($ENV{HTTP_HOST}, '.') > -1) {

		# cutting out www. (and other variations like ww.) in the begginning
		($domain = $ENV{HTTP_HOST}) =~ s/^w+\.//;

      # always adding wildcard dot in the beginning of the domain name if we set
      # it here ourselves based on the HTTP_HOST
		$domain = '.'.$domain;
	}

	push @{$self->{cookies}}, {
		name    => $self->{cookies_prefix} . $in->{name},
		value   => Stuffed::System::Utils::encode_url($in->{value}),
		expires => $self->__expires($in->{expires}),
		path    => (defined $in->{path} ? $in->{path} : $self->{cookies_path} ? $self->{cookies_path} : undef),
		domain  => $domain,
		secure  => (defined $in->{secure} ? $in->{secure} : $self->{cookies_secure} ? $self->{cookies_secure} : undef),
	  };
}

sub __expires {
	my ($self, $time) = @_;

	return undef if not $time;

	my @mon = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
	my @wday = qw/Sun Mon Tue Wed Thu Fri Sat/;

	my %calculator = (
		s => 1,
		m => 60,
		h => 60*60,
		d => 60*60*24,
		M => 60*60*24*30,
		y => 60*60*24*365
	  );

	# format for time can be in any of the forms...
	# "now" -- expire immediately
	# "+180s" -- in 180 seconds
	# "+2m" -- in 2 minutes
	# "+12h" -- in 12 hours
	# "+1d"  -- in 1 day
	# "+3M"  -- in 3 months
	# "+2y"  -- in 2 years
	# "-3m"  -- 3 minutes ago(!)
	# If you don't supply one of these forms, we assume you are
	# specifying the date yourself

	my $offset; my $final;
	if (not defined $time or $time eq "now") {
		$final = time;
	} elsif ($time =~ /^\d+/) {
		$final = $time;
	} elsif ($time =~ /^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
		$final = time + (($calculator{$2} || 1) * $1);
	} else {
		$final = $time;
	}

	my $sc = '-';

	# (cookies use '-' as date separator, HTTP uses ' ')

	my ($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($final);
	$year += 1900;

	return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
		$wday[$wday],$mday,$mon[$mon],$year,$hour,$min,$sec);
}

sub error_404 {
	my $self = shift;
	
	require Stuffed::System::Utils;
	my $request_uri = Stuffed::System::Utils::encode_html(Stuffed::System::Utils::decode_url($ENV{REQUEST_URI}));

	my $HTML = <<HTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head>
<title>404 Not Found</title>
</head>
<body>
<h1>Not Found</h1>
<p>The requested URL $request_uri was not found on this server.</p>
<hr>
<i>Stuffed System $Stuffed::System::VERSION</i>
</body>
</html>
HTML

	$self->header('Status' => '404 Not Found');
	$self->say($HTML);

	$system->stop;
}

1;