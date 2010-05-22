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

package Stuffed::System;

# Stuffed System global version
$VERSION = 4.00;

use strict;

# in case this file was loaded directly somewhere we load CGI::Carp again
# (there should be no speed penality for us if this was already done in
# index.cgi)
use CGI::Carp qw(fatalsToBrowser);

our $system;

use Stuffed::System::True;

use base 'Exporter';
our @EXPORT = qw($system &true &false &dump);

sub new {
	my ($class, $sys_path, $pkg_path) = @_;
	return undef if not defined $sys_path;
	$pkg_path = $sys_path if not defined $pkg_path;
	$system = bless({
			__sys_path => $sys_path,
			__pkg_path => $pkg_path,
		}, $class);
	$system->__init;

	if ($system->config->get('system_stopped') and not $ENV{STUFFED_IGNORE_SYSTEM_STOP}) {

		# disabling all system events
		my $events = $system->stash('__disabled_events');
		$events->{system}{__all} = 1;
		$system->stash(__disabled_events => $events);

		$system->pkg('system')->stopped;
		$system->stop;
	}

	return $system;
}

sub run {
	my $self = shift;

	# always initializing system package to process 'start' event for the
	# whole system before anything else
	$self->pkg('system');

	# calling a path dispatcher (which has its own pluggable event)	
	$self->__dispatch;

	my $q = $self->in->q;

	my $pkg = $q->__pkg || $self->{__config}->get('default_pkg');
	die "No suitable packages were found! You need to specify a package name in order to proceed!\n" if false($pkg);
	
	# if the name of the package starts with a colon, we add the default package from system config in front
	if ($pkg =~ /^:/) {
		$pkg = $self->{__config}->get('default_pkg') . $pkg;
	}

	my $act = $q->__act;
	if (true($act) and $act =~ /^_/) {
		die q(Name of the action can not start with the underscore "_"!);
	}

	# default action in all packages should be called 'index'
	$act = 'index' if false($act);

	my $sub = $q->__sub;

	# default subroutine is called 'default' (surprise!)
	$sub = 'default' if false($sub);

	my $pkg = $self->pkg($pkg);
	
	my %reserved_idx = map { s/^&//; $_ => 1 } grep { /^[^\$%@*]/ } @EXPORT;
	if ($reserved_idx{$act}) {
		$pkg->__missing_error(
			action_name => $act,
			is_reserved	=> 1,
		);
	} 
	elsif ($reserved_idx{$sub}) {
		$pkg->__missing_error(
			action_name => $act,
			sub_name	=> $sub,
			is_reserved	=> 1,
		);
	}
	
	$pkg->$act()->$sub(@_);

	return $self;
}

sub pkg {
	my $self = shift;
	my $pkg_name = shift;
	return if false($pkg_name);

	require Stuffed::System::Package;
	return Stuffed::System::Package->__new(name => $pkg_name);
}

sub stash {
	my $self = shift;
	my $key = shift;
	$self->{__stash}{$key} = shift if scalar @_;
	return $self->{__stash}{$key};
}

sub __get_pkg {
	my $self = shift;
	my $pkg_name = shift;
	return (true($pkg_name) ? $self->{pkg_name} : undef);
}

sub __save_pkg {
	my $self = shift;
	my $pkg = shift;
	return undef if not $pkg;
	$self->{__pkgs}{$pkg->__name} = $pkg;
}

sub __init {
	my $self = shift;
	
	if (not -r "$self->{__sys_path}/private/system/config/config.cgi") {
		die "Critical error! System configuration file is missing!\n";
	}

	# setting our own error handler via CGI::Carp interface, should be done
	# after checking config, otherwise die above won't work as it relies on
	# Stuffed::System::Output which itself relies on the presence of the system
	# config.
	require Stuffed::System::Error;
	$self->{error} = Stuffed::System::Error->new;
	CGI::Carp::set_message(\&Stuffed::System::Error::__just_die);

	# loading system configuration
	require Stuffed::System::Config;
	$self->{__config} = Stuffed::System::Config->new("$self->{__sys_path}/private/system/config/config.cgi");

	# starting benchmark timer
	require Stuffed::System::Bench;
	$self->{__bench} = Stuffed::System::Bench->new;

	require Stuffed::System::File;
	require Stuffed::System::Utils;

	# removing all restrictions from the access rights mask
	umask 0000;

	return $self;
}

sub __dispatch {
	my $self = shift;
	my $q = $system->in->q;
	
	# plugins running on this event can delete __path query parameter and this will 
	# automatically disable the default logic below
	$self->pkg('system')->__event('route')->process;
	
	my $path = $q->__path;
	return if false($path);
	
	# standard system 4 dispatch routes --
	# /subpkg/, /subpkg/action/, /subpkg/action/sub.html (main package is taken from default_pkg in system config)
	# /action/, /action/sub.html 
	# /system/, /system/action/, /system/action/sub.html
	
	if  ($path =~ m|^system/?([^/]+)?/?(?:([^/]+)?\.html)?$|) {
		my ($act, $sub) = ($1, $2);
		$q->__pkg('system');
		$q->__act($act) if true($act);
		$q->__sub($sub) if true($sub);
	}

	elsif ($path =~ m|^([^/]+)/?(?:([^/]+)?\.html)?$|) {
		my ($act, $sub) = ($1, $2);
		$q->__act($act);
		$q->__sub($sub) if true($sub);		
	}
	
	elsif ($path =~ m|^([^/]+)/([^/]+)/?(?:([^/]+)?\.html)?$|) {
		my ($pkg, $act, $sub) = ($1, $2, $3);
		$q->__pkg(':'.$pkg);
		$q->__act($act);
		$q->__sub($sub) if true($sub);		
	}
}

sub dbh {
	my $self = shift;
	return $self->{dbh} if $self->{dbh};
	require Stuffed::System::DBI;
	return $self->{dbh} = Stuffed::System::DBI->new;
}

sub in {
	my $self = shift;
	return $self->{in} if $self->{in};
	require Stuffed::System::Input;
	return $self->{in} = Stuffed::System::Input->new;
}

sub out {
	my $self = shift;
	return $self->{out} if $self->{out};
	require Stuffed::System::Output;
	$self->{out} = Stuffed::System::Output->new;
	if ($self->config->get('default_charset')) {
		$self->{out}->charset($self->config->get('default_charset'));
	}
	return $self->{out};
}

sub user {
	my $self = shift;
	return $self->{user} if $self->{user};
	require Stuffed::System::User;
	return $self->{user} = Stuffed::System::User->new;
}

sub session {
	my $self = shift;
	return $self->{session} if $self->{session};
	require Stuffed::System::Session;
	return $self->{session} = Stuffed::System::Session->new;
}

sub path     {
	my ($self, $type) = @_;
	$type && $type eq 'pkg' ? $self->{__pkg_path} : $self->{__sys_path};
}

sub config { $_[0]->{__config} }
sub error  { $_[0]->{error} }
sub dump   { 
	shift @_ if ref $_[0] eq __PACKAGE__;
	Stuffed::System::Utils::dump(@_) 
}
	
sub on_destroy {
	my ($self, $code) = @_;
	return undef if not $code;
	push @{$self->{on_destroy}}, $code;
}

sub stop {
	my $self = shift;
	my $in = {
		die_completely => undef, # optional, under mod_perl will terminate the current
		# process completely, should be used when called by
		# a child after the fork
		@_
	  };

	# processing 'stop' event
	$self->pkg('system')->__event('stop')->process(pkg => $self);
	
	# database debugging is switched on, handle the debugging information
	if ($self->{dbh} and $self->{dbh}{__stuffed_debug_db}) {
		Stuffed::System::DBIDebug::handle_debug_db_output();
	}

	# only output if debug is switched on and there was some output beforehand
	# we need output beforehand to escape the situation when CGI::Carp has
	# already printed out an error
	if ($self->{__config}->get('debug') and $self->out->output and $self->out->context eq 'web') {
		my $content = qq(<script type="text/javascript">\n);
		$content .= qq(defaultStatus = ');
		$content .= 'Processing time: '.$self->{__bench}->get_raw.'. ' if $self->{__bench};
		$content .= 'Mod_perl enabled. ' if $ENV{MOD_PERL};
		$content .= qq(';\n</script>);
		$self->out->say($content);
	}
	
	# if the system is being stopped already and we are in a web context and 
	# nothing has been sent to the browser still we output a dummy response to
	# avoid getting a 500 error from the web server
	if ($self->out->context('web') and not $self->out->output) {
		$self->out->say("");
	} 

	# disconnect from the database if we were connected
	$self->dbh->disconnect if $self->{dbh};

	# destroyong system and all initialized objects
	undef $system;

	CORE::exit() if not $ENV{MOD_PERL} or $in->{die_completely};

	# mod_perl 2.0
	if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
		ModPerl::Util::exit();
	}

	# mod_perl 1.0
	else {
		Apache::exit();
	}
}

sub DESTROY {
	my $self = shift;
	return if ref $self->{on_destroy} ne 'ARRAY';

	delete $self->{$_} for grep {$_ ne 'on_destroy'} keys %$self;
	$_->() for @{$self->{on_destroy}};
}

1;