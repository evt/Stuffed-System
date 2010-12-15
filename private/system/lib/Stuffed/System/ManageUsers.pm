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

package Stuffed::System::ManageUsers;

$VERSION = 1.00;

use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
	&get_user &check_user &refresh_user &create_user &update_user &delete_user
	&username_exists
);

use Stuffed::System;

#use AutoLoader 'AUTOLOAD';
#__END__

sub get_user {
	my $in = {
		id	=> undef,
		pkg	=> undef,
		@_
	};
	my $id = $in->{id};
	my $pkg = $in->{pkg};
	return undef if not $id or $id =~ /\D/ or false($pkg);

	my $pre = $system->config->get('db_prefix');
	$pkg =~ s/:/_/g;

	my $sth = $system->dbh->prepare("
select * from ${pre}${pkg}_users where id = ?
	");
	$sth->{RaiseError} = 0;
	$sth->execute($id);
	my $record = $sth->fetchrow_hashref;
	$sth->finish;

	return $record;
}

sub check_user {
	my $in = {
		username		=> undef,
		password		=> undef,
		pass_encrypted	=> undef,
		@_
	  };
	my $username = $in->{username};
	my $password = $in->{password};
	return undef if false($username) or false($password);

	my $pre = $system->config->get('db_prefix');

	my $sql_password;
	if ($in->{pass_encrypted}) {
		$sql_password = $system->dbh->quote($password).' as supplied_password';
	} else {
		$sql_password = 'md5('.$system->dbh->quote($password).') as supplied_password';
	}

	my $sth = $system->dbh->prepare("
select 
	*,
	$sql_password
from ${pre}system_users
where username = ?
having supplied_password = password
	");
	$sth->execute($username);
	my $record = $sth->fetchrow_hashref;
	$sth->finish;

	return $record;
}

sub refresh_user {
	my $in = {
		id	=> undef,
		ip	=> undef,
		@_
	  };
	my ($id, $ip) = @$in{qw(id ip)};
	return undef if not $id or $id =~ /\D/;

	my $pre = $system->config->get('db_prefix');

	my $sth = $system->dbh->prepare("
update ${pre}system_users 
set last_visited = ?, last_used_ip = ?
where id = ?
	");
	$sth->execute(time(), $ip, $id);
	$sth->finish;

	return 1;
}

sub username_exists {
	my $in = {
		username 	=> undef,
		id			=> undef, # optional
		@_
	};
	my $username = $in->{username};
	my $id = $in->{id};
	return undef if false $username;

	my $pre = $system->config->get('db_prefix');
	
	my $add_where = '';
	if ($id) {
		$add_where = 'and id != '.$system->dbh->quote($id);
	}

	my $sth = $system->dbh->prepare("
select count(*) from ${pre}system_users where username = ? $add_where
	");
	$sth->execute($username);
	my $found = $sth->fetchrow_array;
	$sth->finish;
	
	return $found;
}

sub create_user {
	my $in = {
		username => undef,
		password => undef,
		@_
	  };

	my $sql_password;
	if ($system->config->get('use_crypt_for_pass')) {
		$in->{password} = crypt($in->{password}, $in->{username});
		$sql_password = $system->dbh->quote($in->{password});
	} else {
		$sql_password = 'md5('.$system->dbh->quote($in->{password}).')';
	}

	my @fields = qw(username);

	if (username_exists(username => $in->{username})) {
		$system->stash(__system_create_user_error => 'username_exists');
		return undef;
	}

	my $pre = $system->config->get('db_prefix');

	my $sth = $system->dbh->prepare("
insert into ${pre}system_users set added = ?, password = $sql_password,".
join(', ', map {"$_ = ?"} @fields)
	);

	$sth->{RaiseError} = 0;

	my $id;

	# user was not added
	if (not $sth->execute(time(), map {$in->{$_}} @fields)) {
		$system->stash(__system_create_user_error => $sth->errstr);
		if (username_exists(username => $in->{username})) {
			$system->stash(__system_create_user_error => 'username_exists');
		}
	} else {
		$id = $system->dbh->{mysql_insertid};	
	}

	$sth->finish;

	return $id;
}

sub update_user {
	my $in = {
		id       => undef,
		@_
	  };
	my $id = $in->{id};
	return undef if not $id or $id =~ /\D/;

	my @fields = qw(username);

	my $pre = $system->config->get('db_prefix');

	my $sql_password = '';

	if (username_exists(username => $in->{username}, id => $id)) {
		$system->stash(__system_update_user_error => 'username_exists');
		return undef;
	}

	if (true($in->{password})) {
		if ($system->config->get('use_crypt_for_pass')) {
			my $username = $in->{username};
			if (false($username)) {
				my $sth = $system->dbh->prepare("
select username from ${pre}system_users where id = ?
				");
				$sth->execute($id);
				$username = $sth->fetchrow_array;
				$sth->finish;
			}
			$in->{password} = crypt($in->{password}, $username);
			$sql_password = 'password = '.$system->dbh->quote($in->{password}).', ';
		} else {
			$sql_password = 'password = md5('.$system->dbh->quote($in->{password}).'), ';
		}
	}

	@fields = grep {exists $in->{$_}} @fields;
	return 1 if not @fields and false($sql_password);

	my $sql_extra = '';
	if (@fields) {
		$sql_extra = join(', ', map {"$_ = ?"} @fields) . ', ';
	}

	my $result = 1;

	my $sth = $system->dbh->prepare("
update ${pre}system_users 
set $sql_extra $sql_password modified = ? 
where id = ?
	");
	$sth->{RaiseError} = undef;
	if (not $sth->execute((map {$in->{$_}} @fields), time, $id)) {
		$system->stash(__system_update_user_error => $sth->errstr);
		if (username_exists(username => $in->{username}, id => $id)) {
			$system->stash(__system_update_user_error => 'username_exists');
		}
		$result = undef;
	}
	$sth->finish;

	return $result;
}

sub delete_user {
	my $in = {
		id => undef,
		@_
	  };
	return undef if not $in->{id};

	my $pre = $system->config->get('db_prefix');

	$system->dbh->do("delete from ${pre}system_users where id = $in->{id}");

	return 1;
}

1;