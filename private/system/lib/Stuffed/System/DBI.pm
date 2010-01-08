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

package Stuffed::System::DBI;

$VERSION = 1.10;

use strict;
use vars qw($AUTOLOAD);

use Stuffed::System;

# ============================================================================
# we use package variables for functions, because all normal subs inside the
# package should always correspond to actual DBI and STH methods

# ============================================================================
# object & class methods

sub new {
	my $class = shift;
	my $config = $system->config;
	my $db_type = $config->get('db_type');

	# recursion detected
	return undef if $system->stash('__system_connecting_to_db');

	$system->stash(__system_connecting_to_db => 1);

	if (not eval "require Stuffed::System::DBI::$db_type") {
		die "Database type '$db_type' is not supported by the DBI class in this installation of Stuffed System! $@\n";
	}

	my ($dbh, $dbh_read);

	my %conn_params = (
		db_name => $config->get('db_name'),
		db_host => $config->get('db_host'),
		db_port => $config->get('db_port'),
		db_user => $config->get('db_user'),
		db_pass => $config->get('db_pass'),
	  );

	# try 3 times to connect if the connection keeps failing
	for (1..3) {
		$dbh = "Stuffed::System::DBI::Base::$db_type"->new(%conn_params);
		last if $dbh;
	}

	die "Connection to the database failed!\n" if not $dbh;

	$dbh->{RaiseError} = 1; # die because of the errors

	# properly work with utf in the database:
	# properly get the data in utf
	$dbh->{mysql_enable_utf8} = 1;

	# properly insert the data in utf
	$dbh->do('SET NAMES utf8');

	# profile all database calls
	#  $dbh->{Profile} = "DBI::Profile";
	#  DBI->trace(0, 'dbi_prof.txt');

	my $self = $dbh;
	
	my $debug_db = undef;

	# checking if database debug mode should be enabled (in reality it is more like a profile mode)
	if (true($system->in->query('__debug_db')) or $system->in->cookie('__debug_db')) {
		require Stuffed::System::DBIDebug;
		$debug_db = Stuffed::System::DBIDebug::check_debug_db();
	}  
	
	my $enable_read_db = $config->get('enable_read_db');

	if ($enable_read_db) {
		%conn_params = (
			db_name => $config->get('read_db_name'),
			db_host => $config->get('read_db_host'),
			db_port => $config->get('read_db_port'),
			db_user => $config->get('read_db_user'),
			db_pass => $config->get('read_db_pass'),
		  );

		# try 3 times to connect if the connection keeps failing
		for (1..3) {
			$dbh_read = "Stuffed::System::DBI::Base::$db_type"->new(%conn_params);
			last if $dbh_read;
		}

		if ($dbh_read) {
			$dbh_read->{RaiseError} = 1; # die because of the errors
		} else {
			$enable_read_db = undef if not $dbh_read;
		}
	}

	# if debug is enabled we create our own proxy object for dbh and then later
	# for sth as well
	if ($debug_db or $enable_read_db) {
		require Stuffed::System::DBIDebug;

		tie(my %tiehash, $class . '::Tie') or return undef;

		# __stuffed_dbh should always be assigned first, TIEHASH will just disregard
		# any keys before __stuffed_dbh is assigned
		$tiehash{__stuffed_dbh} = $dbh;
		$tiehash{__stuffed_dbh_read} = $dbh_read;
		$tiehash{__stuffed_debug_db} = $debug_db;

		$self = bless(\%tiehash, $class);
	}

	$system->stash(__system_connecting_to_db => undef);

	return $self;
}

sub disconnect {
	my $self = shift;
	$self->{__stuffed_dbh}->disconnect(@_);
	$self->{__stuffed_dbh_read}->disconnect(@_) if $self->{__stuffed_dbh_read};
}

sub selectrow_array {
	return shift->do(@_);
}

sub selectrow_arrayref {
	return shift->do(@_);
}

sub selectrow_hashref {
	return shift->do(@_);
}

sub selectall_arrayref {
	return shift->do(@_);
}

sub selectall_hashref {
	return shift->do(@_);
}

sub selectcol_arrayref {
	return shift->do(@_);
}

sub do {
	my $self = shift;
	return undef if not $self->{__stuffed_dbh};

	my @do_params = @_;

	my $caller = [caller(0)];
	$caller->[3] = (caller(1))[3];

	my $stuffed_method = 'do';
	if ($caller->[3] =~ /^Stuffed::System::DBI::select([^:]+)$/) {
		$stuffed_method = 'select'.$1;
	}

	my $debug_db = $self->{__stuffed_debug_db};
	my ($bench, $dbh);

	my $query_type = Stuffed::System::DBIDebug::get_query_type($do_params[0]);
	if ($query_type eq 'select' and $self->{__stuffed_dbh_read}) {
		my $query_read_db = 1;

		my $skip_read_tables = $system->config->get('skip_read_tables');
		if (ref $skip_read_tables eq 'ARRAY' and @$skip_read_tables) {
			my $exist = Stuffed::System::DBIDebug::strings_exist_in_query($do_params[0], $skip_read_tables);
			$query_read_db = undef if $exist;
		}

		$dbh = $self->{__stuffed_dbh_read} if $query_read_db;
	}

	$dbh = $self->{__stuffed_dbh} if not $dbh;
	$bench = Stuffed::System::Bench->new if $debug_db;

	# only do the debugging stuff if debugging is switched on (we could
	# just be in a read database overlay)
	return $dbh->$stuffed_method(@do_params) if not $debug_db;

	my ($result, @results);
	if (wantarray) {
		@results = $dbh->$stuffed_method(@do_params);
	} else {
		$result = $dbh->$stuffed_method(@do_params);
	}

	my $exec_secs = $bench->get_raw;

	my $stack;

	my $counter = 0;
	while (my @frame = caller($counter)) {
		push @$stack, \@frame;
		$counter += 1;
	}

	my $rows = $self->rows;
	my $query = $do_params[0];

	my $stash = $system->stash('__dbi_all_queries') || [];
	push @$stash, {
		'query'   => $query,
		'secs'    => $exec_secs,
		'caller'  => $caller,
		'stack'   => $stack,
		'rows'    => $rows,
	  };
	$system->stash('__dbi_all_queries' => $stash);

	my $current_total = $system->stash('__dbi_total_queries_time');
	$system->stash('__dbi_total_queries_time' => $current_total + $exec_secs);

	return (wantarray ? @results : $result);
}

sub prepare {
	my $self = shift;
	return undef if not $self->{__stuffed_dbh};

	my $debug_db = $self->{__stuffed_debug_db};

	my $sth = Stuffed::System::DBI::STH->new($self, @_);

	# if debug is not enabled then we return the original DBI sth object at this point
	return $sth if not $debug_db;

	my $caller = [caller(0)];
	$caller->[3] = (caller(1))[3];

	my $stack;

	my $counter = 0;
	while (my @frame = caller($counter)) {
		push @$stack, \@frame;
		$counter += 1;
	}

	$sth->{__stuffed_prepare_caller} = $caller;
	$sth->{__stuffed_prepare_stack} = $stack;

	# saving the original request
	$sth->{__stuffed_query} = $_[0];

	return $sth;
}

sub AUTOLOAD {
	my $self = shift;
	my ($method) = $AUTOLOAD =~ /([^:]+)$/;
	return undef if not $self->{__stuffed_dbh};
	return $self->{__stuffed_dbh}->$method(@_);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

# ============================================================================

package Stuffed::System::DBI::STH;

use vars qw($AUTOLOAD);
use Stuffed::System;

sub new {
	my $class = shift;
	my $s_dbh = shift;
	return undef if not $s_dbh or not ref $s_dbh or not ref $s_dbh->{__stuffed_dbh};

	my $dbh;
	my $debug_db = $s_dbh->{__stuffed_debug_db};

	my $query_type = Stuffed::System::DBIDebug::get_query_type($_[0]);
	if ($query_type eq 'select' and $s_dbh->{__stuffed_dbh_read}) {
		my $query_read_db = 1;

		my $skip_read_tables = $system->config->get('skip_read_tables');
		if (ref $skip_read_tables eq 'ARRAY' and @$skip_read_tables) {
			my $exist = Stuffed::System::DBIDebug::strings_exist_in_query($_[0], $skip_read_tables);
			$query_read_db = undef if $exist;
		}

		$dbh = $s_dbh->{__stuffed_dbh_read} if $query_read_db;
	}

	if (not $dbh) {
		$dbh = $s_dbh->{__stuffed_dbh};
	}

	my $sth = $dbh->prepare(@_);
	return $sth if not $debug_db;

	# with no debugging we return the original DBI sth object,
	# also, no need to pass debug and dbh_read params further, because
	# if our own sth object is used to do an execute method then this always
	# means that debug is switched on and also that we've already checked
	# the query type and should just use the stored DBH object in our work
	tie(my %tiehash, $class . '::Tie') or return undef;
	$tiehash{__stuffed_sth} = $sth;
	$tiehash{__stuffed_dbh} = $dbh;

	my $self = bless(\%tiehash, $class);

	return $self;
}

# this method is only used when debug is switched on, with just read database
# enabled we will never get here because in "prepare" method we will return
# the original DBI sth object
sub execute {
	my $self = shift;
	return undef if not $self->{__stuffed_sth};

	my @exec_params = @_;

	my $bench = Stuffed::System::Bench->new;

	my ($result, @results);
	if (wantarray) {
		@results = $self->{__stuffed_sth}->execute(@exec_params);
	} else {
		$result = $self->{__stuffed_sth}->execute(@exec_params);
	}

	my $exec_secs = $bench->get_raw;

	my $dbh = $self->{__stuffed_dbh};

	my $query = $self->{__stuffed_query};
	if (@exec_params) {
		$query =~ s/\?/%s/g;
		$query = sprintf($query, map {$dbh->quote($_)} @exec_params);
	}

	my $rows = $self->rows;
	my $stack = $self->{__stuffed_prepare_stack};

	my $stash = $system->stash('__dbi_all_queries') || [];
	push @$stash, {
		'query'   => $query,
		'secs'    => $exec_secs,
		'caller'  => $self->{__stuffed_prepare_caller},
		'stack'   => $stack,
		'rows'    => $rows,
	  };
	$system->stash('__dbi_all_queries' => $stash);

	my $current_total = $system->stash('__dbi_total_queries_time');
	$system->stash('__dbi_total_queries_time' => $current_total + $exec_secs);

	return (wantarray ? @results : $result);
}

sub AUTOLOAD {
	my $self = shift;
	my ($method) = $AUTOLOAD =~ /([^:]+)$/;
	return undef if not $self->{__stuffed_sth};
	return $self->{__stuffed_sth}->$method(@_);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

# ============================================================================

package Stuffed::System::DBI::Tie;

use Tie::Hash;
use vars qw(@ISA);
@ISA = 'Tie::StdHash';

sub TIEHASH {
	my $class = shift;
	my $self = bless ({}, $class);
	return $self;
}

sub STORE {
	my ($self, $key, $value) = @_;
	return undef if not $self->{__stuffed_dbh} and $key ne '__stuffed_dbh';
	if ($key =~ /^__stuffed/) {
		return $self->{$key} = $value;
	} else {
		return $self->{__stuffed_dbh}{$key} = $value;
	}
}

sub FETCH {
	my ($self, $key) = @_;
	return undef if not $self->{__stuffed_dbh};
	if ($key =~ /^__stuffed/) {
		return $self->{$key};
	} else {
		return $self->{__stuffed_dbh}{$key};
	}
}

sub DELETE {
	my ($self, $key) = @_;
	return undef if not $self->{__stuffed_dbh};
	if ($key =~ /^__stuffed/) {
		return delete $self->{$key};
	} else {
		return delete $self->{__stuffed_dbh}{$key};
	}
}

# ============================================================================

package Stuffed::System::DBI::STH::Tie;

use Tie::Hash;
use vars qw(@ISA);
@ISA = 'Tie::StdHash';

sub TIEHASH {
	my $class = shift;
	my $self = bless ({}, $class);
	return $self;
}

sub STORE {
	my ($self, $key, $value) = @_;
	return undef if not $self->{__stuffed_sth} and $key ne '__stuffed_sth';
	if ($key =~ /^__stuffed/) {
		return $self->{$key} = $value;
	} else {
		return $self->{__stuffed_sth}{$key} = $value;
	}
}

sub FETCH {
	my ($self, $key) = @_;
	return undef if not $self->{__stuffed_sth};
	if ($key =~ /^__stuffed/) {
		return $self->{$key};
	} else {
		return $self->{__stuffed_sth}{$key};
	}
}

sub DELETE {
	my ($self, $key) = @_;
	return undef if not $self->{__stuffed_sth};
	if ($key =~ /^__stuffed/) {
		return delete $self->{$key};
	} else {
		return delete $self->{__stuffed_sth}{$key};
	}
}

1;
