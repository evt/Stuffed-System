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

package Stuffed::System::User;

$VERSION = 1.00;

use strict;

use Stuffed::System;
use Stuffed::System::Utils;

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	return $self;
}

sub authorize {
	my $self = shift;
	my $params = {
		username		=> undef,
		password		=> undef,
		pass_encrypted	=> undef, # optional, tells that a specified password
		# is encrypted
		remember_login	=> undef, # remember username and password in the cookie
		@_
	  };

	$self->{auth_tried} = 1;

	my ($in, $out, $session) = ($system->in, $system->out, $system->session);

	# parameters passed directly to the authorize method
	if (true($params->{username}) and true($params->{password})) {
		my $user = $params->{username};
		my $pass = $params->{password};
		my $encrypted = $params->{pass_encrypted};

		# output a cookie with username and password if it was requested, or if
		# it was not requested, remove the potentially existing cookies
		if ($self->__load_user(username => $user, password => $pass, pass_encrypted => $encrypted)) {
			$self->login;
			if ($params->{remember_login}) {
				$out->cookie(name => 'auth_username', value => $user, expires => "+10y");
				$out->cookie(name => 'auth_password', value => $self->profile('password'), expires => "+10y");
			} else {
				$out->cookie(name => 'auth_username', value => "", expires => "-30d");
				$out->cookie(name => 'auth_password', value => "", expires => "-30d");
			}
		}
	}

	# parameters passed in the url
	if (not $self->{logged}) {
		if (true($in->query('auth_username')) and true($in->query('auth_password'))) {
			my $user = $in->query('auth_username');
			my $pass = $in->query('auth_password');

			# output a cookie with username and password if it was requested
			if ($self->__load_user(username => $user, password => $pass)) {
				$self->login;
				if ($in->query('remember_login')) {
					$out->cookie(name => 'auth_username', value => $user, expires => "+10y");
					$out->cookie(name => 'auth_password', value => $self->profile('password'), expires => "+10y");
				}
			}
		}
	}

	# parameters might be passed in the session
	if (not $self->{logged} and $session->is_valid) {
		if ($self->__load_user(
				username        => $session->get('auth_username'),
				password        => $session->get('auth_password'),
				pass_encrypted  => 1,
			)) {
			$self->login;
		}
	}

	# parameters passed in the cookie
	if (not $self->{logged}) {
		if (true($in->cookie('auth_username')) and true($in->cookie('auth_password'))) {
			my $user = $in->cookie('auth_username');
			my $pass = $in->cookie('auth_password');
			if ($self->__load_user(username => $user, password => $pass, pass_encrypted => 1)) {
				$self->login;

           # prolonging cookies for another 10 years, because login and password
           # in the cookie can be considered to be a request to remember them
				$out->cookie(name => 'auth_username', value => $user, expires => "+10y");
				$out->cookie(name => 'auth_password', value => $pass, expires => "+10y");
			} else {
				$out->cookie(name => 'auth_username', value => "", expires => "-30d");
				$out->cookie(name => 'auth_password', value => "", expires => "-30d");
			}
		}
	}

	return $self;
}

sub __load_user {
	my $self = shift;
	my $in = {
		username        => undef,
		password        => undef,
		pass_encrypted  => undef,
		@_
	  };
	return undef if false($in->{username}) or false($in->{password});

	require Stuffed::System::ManageUsers;
	$self->{profiles}{'system'} = Stuffed::System::ManageUsers::check_user(
		username        => $in->{username},
		password        => $in->{password},
		pass_encrypted  => $in->{pass_encrypted}
	  );

	return $self->{profiles}{'system'};
}

sub login {
	my $self = shift;
	return if not $self->in_db;

	# logging in currently loaded user
	$self->{logged} = 1;

	my $profile = $self->{profiles}{'system'};

	# updating last_visited time
	require Stuffed::System::ManageUsers;
	Stuffed::System::ManageUsers::refresh_user(id => $profile->{id});

	my $session = $system->session;

	my ($user, $pass) = ($profile->{username}, $profile->{password});
	my ($s_user, $s_pass) = ($session->get('auth_username'), $session->get('auth_password'));

	# we don't want to store username and password on every system run!
	if (false($s_user) or false($s_pass) or $s_user ne $user or $s_pass ne $pass) {
		$session->add(auth_username => $user, auth_password => $pass);
	}
}

sub profile {
	my $self = shift;
	my $key = shift;
	my $in = {
		pkg => undef, # optional parameter
		@_
	  };
	return undef if false($key);

	# if pkg is not specified we return a profile key for 'system' package
	my $pkg = true($in->{pkg}) ? $in->{pkg} : 'system';

	$self->authorize if not $self->{auth_tried};

	return undef if not $self->in_db;

	# we haven't loaded the user's profile for this package yet
	if (not exists $self->{profiles}{$pkg}) {
		my $id = $self->{profiles}{'system'}{id};
		my $user = Stuffed::System::Package->__get_user(id => $id, pkg => $pkg);
		if (defined $user) {

			# $user can be 0 which will mean that it was not found in the db
			$self->{profiles}{$pkg} = ref $user ? $user : undef;
		} else {

			# we only go here if the user loading function do not exist for thr
			# specified package ($user is undefined)
			require Stuffed::System::ManageUsers;
			$self->{profiles}{$pkg} = Stuffed::System::ManageUsers::get_user(
				id  => $id,
				pkg => $pkg,
			  );
		}
	}

	return $self->{profiles}{$pkg} ? $self->{profiles}{$pkg}{$key} : undef;
}

sub in_db {
	my $self = shift;
	$self->authorize if not $self->{auth_tried};
	return ($self->{profiles} && $self->{profiles}{'system'} ? 1 : undef);
}

sub logged {
	my $self = shift;
	$self->authorize if not $self->{auth_tried};
	return $self->{logged};
}

sub id {
	my $self = shift;
	$self->authorize if not $self->{auth_tried};
	return (
		$self->{profiles} &&
		  $self->{profiles}{'system'} &&
		  $self->{profiles}{'system'}{id} ?
		  $self->{profiles}{'system'}{id} :
		  undef
	);
}

# we are getting the IP dynamicly on purpose, because the actual user's IP could
# be overridden during the system run
sub ip { Stuffed::System::Utils::get_ip() }

sub logout {
	my $self = shift;
	return $self if not $self->logged;

	# expiring session if it exists
	$system->session->delete('auth_username');
	$system->session->delete('auth_password');

	# deleteing cookies
	$system->out->cookie(name => 'auth_username', value => '', expires => "-30d");
	$system->out->cookie(name => 'auth_password', value => '', expires => "-30d");

	$self->{logged} = undef;

	return $self;
}

sub is_robot {
	my $self = shift;
	if (not exists $self->{is_robot}) {
		if ($ENV{HTTP_USER_AGENT}) {
			$self->{is_robot} = $self->browser->robot || 0;
		}
		else {
			$self->{is_robot} = 1;
		}
	}
	return $self->{is_robot};
}

sub browser {
	my $self = shift;
	if (not $self->{browser_detect}) {
		require HTTP::BrowserDetect;
		$self->{browser_detect} = HTTP::BrowserDetect->new;
	}	
	return $self->{browser_detect}; 
}

1;