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

package Stuffed::System::Session;

$VERSION = 1.00;

use strict;

use Stuffed::System;
use Stuffed::System::Utils;

sub new {
	my $class = shift;
	my $self = bless({clean => undef}, $class);

	$self->{ip} = sprintf("%02x%02x%02x%02x", split(/\./, Stuffed::System::Utils::get_ip()));

	my $in = $system->in;
	my $config = $system->config;

	# default settings
	$self->{settings} = {

		# 1 hour
		sessions_lifetime     => 3600,

		# 1 - store ip in cookie in case of dynamic ip changing, 0 - do not
		sessions_ip_in_cookie => 1,
		table                 => $config->get('db_prefix').'system_sessions'
	  };

	foreach (qw(sessions_lifetime sessions_ip_in_cookie)) {
		$self->{settings}{$_} = $config->get($_) if true($config->get($_));
	}

	# creating unique signature for the current user
	$self->{signature} = $self->__create_signature;

	# if storing ip in cookie is switched on and there IS an ip in the cookie we
	# create an alternative signature for the user
	if ($self->{settings}{sessions_ip_in_cookie} and $in->cookie('user_ip')) {
		$self->{signature_cookie} = $self->__create_signature($in->cookie('user_ip'));
	}

	# checking if session id was passed via url and if it is legal
	if ($in->query('sid')) {
		$self->__check_session($in->query('sid'));
	}

	# checking if session id was passed via cookies and if it is legal
	if (not $self->is_valid and $in->cookie('sid') and ($in->cookie('sid') ne $in->query('sid'))) {
		$self->__check_session($in->cookie('sid'));
	}

	return $self;
}

sub id { $_[0]->{id} }
sub is_valid { true($_[0]->{id}) ? 1 : 0 }
sub id_for_url { "sid=$_[0]->{id}" }
sub get_content { $_[0]->{content} };

sub is_new {
	my $self = shift;
	$self->__create_session if not $self->is_valid;
	return $self->{__just_created};
}

sub get {
	my ($self, $key) = @_;
	return if not $self->{content};
	return keys %{$self->{content}} if false($key);
	return $self->{content}{$key};
}

sub __create_signature {
	my ($self, $use_ip) = @_;
	(my $browser = $ENV{HTTP_USER_AGENT} || '') =~ s/\s+//g;

	# signature should be at least 100 characters long
	return substr(($use_ip || $self->{ip}).$browser, 0, 99);
}

# adding specified data to existing session content
sub add {
	my ($self, $data) = (shift, {@_});
	return if not %$data;

	$self->__create_session if not $self->is_valid;
	$self->{content}{$_} = $data->{$_} foreach keys %$data;

	return $self->__update_session;
}

# replacing existing session content with the new data
sub save {
	my ($self, $data) = (shift, {@_});
	return if not %$data;

	$self->__create_session if not $self->is_valid;
	$self->{content} = $data;

	return $self->__update_session;
}

# excepts multiple keys
sub delete {
	my ($self, @keys) = (@_);
	return $self if not $self->is_valid or not @keys or not $self->{content};

	delete $self->{content}{$_} foreach @keys;

	return $self->__update_session;
}

sub __unpack {
	my ($self, $string) = @_;

	require Storable;
	return Storable::thaw($string);
}

sub __pack {
	my ($self, $content) = @_;
	$content ||= $self->{content};
	return if not $content or not ref $content;

	require Storable;
	return Storable::nfreeze($content);
}

sub expire {
	my ($self, $id) = @_;
	$id ||= $self->{id};
	return if false($id);

	# user is a robot, no real session for them and no db access
	if (not $system->user->is_robot) {
		my $sth = $system->dbh->prepare("delete from $self->{settings}{table} where id = ?");
		$sth->execute($id);
		$sth->finish;
	}

	# clearing the session object
	$self->{$_} = '' foreach (qw(id session content));

	# deleting sid cookie
	$system->out->cookie(name => 'sid', value => '', expires => '-30d');

	# deleting current user ip in the cookie if this option is switched on
	if ($self->{settings}{sessions_ip_in_cookie}) {
		$system->out->cookie(name => 'user_ip', value => '', expires => '-30d');
	}

	return $self;
}

sub __cleanup {
	my $self = shift;
	return if $self->{clean};
	my $target_time = time - $self->{settings}{sessions_lifetime};

	# user is a robot, no real session for them and no db access
	if (not $system->user->is_robot) {
		$system->dbh->do("delete from $self->{settings}{table} where used < $target_time");
	}

	$self->{clean} = 1;
}

sub __update_session {
	my $self = shift;
	return if not $self->is_valid or false($self->{content});

	# user is a robot, no real session for them and no db access
	if (not $system->user->is_robot) {
		my $sth = $system->dbh->prepare("update $self->{settings}{table} set used = unix_timestamp(now()), content = ? where id = ?");
		$sth->execute($self->__pack, $self->{id});
		$sth->finish;
	}

	return $self;
}

sub __create_session {
	my $self = shift;
	$self->{id} = Stuffed::System::Utils::create_random(32);

	# user is a robot, no real session for them and no db access
	if (not $system->user->is_robot) {
		my $sth = $system->dbh->prepare("insert into $self->{settings}{table} set id = ?, used = unix_timestamp(now()), signature = ?");
		$sth->execute($self->{id}, $self->{signature});
		$sth->finish;
	}

	# expires when browser window is closed, only set if the user doesn't have
	# the same cookie with the same session id already
	if ($system->in->cookie('sid') ne $self->{id}) {
		$system->out->cookie(name => 'sid', value => $self->{id});
	}

	# saving current user ip in the cookie if this option is switched on and the
	# user doesn't aready have the same cookie with the same IP
	if ($self->{settings}{sessions_ip_in_cookie} and $system->in->cookie('user_ip') ne $self->{ip}) {
		$system->out->cookie(name => 'user_ip', value => $self->{ip}, expires => '+'.$self->{settings}{sessions_lifetime}.'s');
	}

	$self->{__just_created} = 1;

	return $self;
}

sub __check_session {
	my ($self, $id) = @_;
	return $self if not $id or $system->user->is_robot;

	# it should be enough to do the cleanup when a session id is checked
	$self->__cleanup;

	my $sth = $system->dbh->prepare("select * from $self->{settings}{table} where id = ?");
	$sth->execute($id);
	my $session = $sth->fetchrow_hashref;

	return $self if not $session;

	if ($self->{signature} ne $session->{signature}) {
		if ($self->{settings}{sessions_ip_in_cookie} and $self->{signature_cookie}) {
			return $self if $session->{signature} ne $self->{signature_cookie};
		} else {
			return $self;
		}
	}

	$self->{content} = $self->__unpack($session->{content});
	$self->{session} = $session;
	$self->{id} = $id;

	# session was successfully initialized, we renew its last usage time and also signature,
	# because it might have been changed due to the IP changing
	$sth = $system->dbh->prepare("
update $self->{settings}{table} 
set used = unix_timestamp(now()), signature = ? 
where id = ?
	");
	$sth->execute($self->{signature}, $id);
	$sth->finish;

	if ($system->in->cookie('sid') ne $id) {
		$system->out->cookie(name => 'sid', value => $id);
	}

	# saving current user ip in the cookie if this option is switched on
	if ($self->{settings}{sessions_ip_in_cookie} and $system->in->cookie('user_ip') ne $self->{ip}) {
		$system->out->cookie(name => 'user_ip', value => $self->{ip});
	}

	return $self;
}

1;