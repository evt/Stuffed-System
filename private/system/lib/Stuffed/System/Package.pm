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

package Stuffed::System::Package;

$VERSION = 1.00;

use strict;
use vars qw($AUTOLOAD);

use Stuffed::System;

sub __new {
	my $class = shift;
	my $in = {
		name  => undef,
		@_
	  };
	my $name = $in->{name};

	# dot is an alternative separator for sub packages
	$name =~ s/\./:/g;
	
	# cleaning up the name (inherited mindlessly from system 3.x)
	$name =~ s/^:+|:+$//g;

	return $system->__get_pkg($name) if $system->__get_pkg($name);

	# checking that we haven't already started initialization of the specified
	# package, this is required for protection from a potential recursion
	if ($system->stash('__system_pkg_init'.$name)) {
		die "Recursion detected during package '$name' initialization!";
	}

	$system->stash('__system_pkg_init'.$name => 1);

	(my $package = $name) =~ s/:/::/g;

	# removing forbiden characters
	$package =~ s/[^\w:]/_/g;

	my $new_class = "Stuffed::System::Package::$package";

	eval <<CODE;
package $new_class; 
use base qw(Stuffed::System::Package); 
use Stuffed::System;
CODE

	die $@ if $@;

	my $self = bless({}, $new_class);

	my $pkg_path = $new_class->__create_path($name);

	# calculating physical path to this package, first using the
	# globally defined system path
	my $path = $system->path . "/private/$pkg_path";

	$self->{__path} = $path;
	$self->{__name} = $name;

	# then using the globally defined packages path
	if (not -d $path) {
		$path = $system->path('pkg') . "/private/$pkg_path";
		$self->__missing_error if not -d $path;
	}

	# system package lib is already in @INC
	$new_class->__add_to_inc($name);

	# parent package
	my ($parent) = $name =~ /^(.+?):[^:]+$/;
	$self->{__parent} = $system->pkg($parent) if true($parent);

	# loading config if it exists
	$self->{__config} = Stuffed::System::Config->new("$path/config/config.cgi");

	my $public_path = $self->{__config}->get('public_path');
	if (false($public_path) and $self->{__parent}) {
		$public_path = $self->{__parent}->__config->get('public_path');
	}
	if (false($public_path)) {
		$public_path = $system->config->get('public_path');
		$public_path = $system->path if false($public_path);
	}
	$self->{__public_path} = "$public_path/$pkg_path";

	my $public_url = $self->{__config}->get('public_url');
	if (false($public_url) and $self->{__parent}) {
		$public_url = $self->{__parent}->__config->get('public_url');
	}
	$public_url = $system->config->get('public_url') if false($public_url);
	$self->{__public_url} = "$public_url/$pkg_path";

	$self->__init;

	# removing init marker for this package
	$system->stash('__system_pkg_init'.$name => undef);

	# saving package in the the Stuffed System packages container
	$system->__save_pkg($self);

	# processing 'start' event for the package
	$self->__event('pkg_start')->process(pkg => $self);

	return $self;
}

sub __missing_error {
	my $self = shift;
	my $in = {
		action_name => undef,
		sub_name    => undef,
		is_reserved	=> undef,
		@_
	  };
	my $action_name = $in->{action_name};
	my $sub_name = $in->{sub_name};
	my $is_reserved = $in->{is_reserved};

	# we only die if 404 error was not requested in system config
	if (not $system->config->get('use_404')) {
		if (true($action_name) and true($sub_name)) {
			if ($is_reserved) {
				die qq(Name "$sub_name" is reserved in Stuffed System and can't be used as a name of a sub (in action "$action_name" from package "$self->{__name}").\n);
			} else {
				die qq(Subroutine "$sub_name" is not supported in action "$action_name" from package "$self->{__name}".\n);	
			}
		} elsif (true($action_name)) {
			if ($is_reserved) {
				die qq(Name "$action_name" is reserved in Stuffed System and can't be used as a name of an action (in package "$self->{__name}").\n);
			} else {
				die qq(Action "$action_name" is not supported in package "$self->{__name}".\n);	
			}
		} else {
			die qq(Package \"$self->{__name}\" is not supported.\n);
		}
	}

	# if 404 URL was specified we redirect there
	elsif (true($system->config->get('error_404_URL'))) {
		$system->out->redirect($system->config->get('error_404_URL'));
		$system->stop;
	}

	# or we just print out a standard 404 error message and headers
	else {
		$system->out->error_404;
	}
}

sub __clean_query {
	my $self = shift;
	$system->in->clean_query(@_);
	return $self;
}

sub __template {
	my $self = shift;
	my $file = shift;

	require Stuffed::System::Template;
	return Stuffed::System::Template->new(file => $file, pkg => $self, @_);
}

sub __skin {
	my $self = shift;

	return $self->{__skin} if $self->{__skin};

	# initializing skin
	my $skin_id = $self->{__config}->get('skin_id');
	$skin_id ||= $self->{__parent}->__skin->id if $self->{__parent};
	$skin_id ||= 'default'; # dafault skin if everything else fails

	require Stuffed::System::Skin;
	$self->{__skin} = Stuffed::System::Skin->new(id => $skin_id, pkg => $self);

	return $self->{__skin};
}

sub __language {
	my $self = shift;

	return $self->{__language} if $self->{__language};

	# initializing language
	my $language_id = $self->{__config}->get('language_id');
	$language_id ||= $self->{__parent}->__language->id if $self->{__parent};
	$language_id ||= $system->config->get('language_id');
	$language_id ||= 'default'; # default language if everything else fails

	require Stuffed::System::Language;
	$self->{__language} = Stuffed::System::Language->new(
		id  => $language_id,
		pkg => $self,
	  );

	return $self->{__language};
}

sub __init {
	my $self = shift;
	my $class = ref $self;
	if (not defined &{$class.'::__init'}) {
		my $file = "$self->{__path}/config/__init.cgi";
		if (-r $file) {

			# if __init file exists for the current package we compile it
			eval "package $class; require '$file'; 1;" || die $@;
		} else {

			# if the file doesn't exist we create an empty sub __init instead
			eval "package $class; sub __init {}; 1;" || die $@;
		}
	}
	$self->__init;
}

sub __check_privs {
	my $self = shift;
	my $class = ref $self;

	if (not defined &{$class.'::__check_privs'}) {
		my $file = "$self->{__path}/config/__check_privs.cgi";
		if (-r $file) {

			# if __check_privs file exists for the current package we compile it
			eval "package $class; require '$file'; 1;";
			die $@ if $@;
		} else {

           # if the file doesn't exist we create empty sub __check_privs instead
			eval "package $class; sub __check_privs {}; 1;";
			die $@ if $@;
		}
	}

	if (not defined &{$class.'::__check_privs'}) {
		die "Unable to initialize privileges for $self->{__name}!";
	}

	$self->__check_privs(@_);
}

sub __event {
	my ($self, $event) = @_;
	return if false($event);
	if (not $self->{__events}{$event}) {
		require Stuffed::System::Event;
		$self->{__events}{$event} = Stuffed::System::Event->new(name => $event, pkg => $self);
	}
	return $self->{__events}{$event};
}

sub __error {
	my ($self, $entry, @params) = @_;
	my $errors = $self->__language->load('__system/errors.cgi');
	my $string = $errors->get($entry, @params);
	return (true($string) ? $string : $entry);
}

sub __add_to_inc {
	my ($class, $pkg) = @_;
	return if false($pkg);

	my $path = $system->path.'/private/'.$class->__create_path($pkg);
	my %inc_idx = map {$_ => 1} @INC;
	return if $inc_idx{"$path/lib"};

	unshift @INC, "$path/lib" if -d "$path/lib";
}

sub __create_path { join('/packages/', split(/:/, $_[1])) }

sub __get_user {
	my $class = shift;
	my $in = {
		id  => undef,
		pkg => undef,
		@_
	  };
	my $id = $in->{id};
	my $pkg = $in->{pkg};
	return undef if not $id or false($pkg);

	my $user;

	my $pkg_path = $system->path.'/private/'.$class->__create_path($pkg);
	my $filename = "$pkg_path/config/get_user.cfg";
	if (-r $filename) {
		my $file = Stuffed::System::File->new($filename, 'r', {is_text => 1});
		if ($file) {
			my $package = $file->line;
			$package =~ s/^\s+//; $package =~ s/\s+$//;
			my $function = $file->line;
			$function =~ s/^\s+//; $function =~ s/\s+$//;
			$file->close;
			if (true($package) and true($function)) {
				$class->__add_to_inc($pkg);
				eval "require $package" || die $@;

            # if user was not found, we assign $user to 0, indicating that we've
            # checked, but have found nothing
				no strict 'refs';
				$user = &{$package.'::'.$function}(id => $id) || 0;
			}
		}
	}

	return $user;
}

sub AUTOLOAD {
	my $self = shift;

	# getting current package name from the current object
	my $class = ref $self;

	if (not $class or $class !~ /Stuffed::System::Package/) {
		die qq(Function or method "$AUTOLOAD" is not supported!\n);
	}

	my ($action_name) = $AUTOLOAD =~ /([^:]+)$/;

	# removing forbidden characters (Perl won't compile a sub with them below)
	$action_name =~ s/^\d+|[^A-Za-z0-9_]+//g;

	if ($action_name =~ /^_/) {
		eval "sub $action_name { \$_[0]->{$action_name} } 1;";
		die "[$action_name] ".$@ if $@;
		return $self->$action_name();
	}

	eval <<CODE;
package $class;

use Stuffed::System::Action; 

sub $action_name {
  return Stuffed::System::Action->__new(
    pkg   => shift, 
    name  => '$action_name',
  );
}
CODE

	die "[$action_name] ".$@ if $@;

	$self->__check_privs($action_name);
	return $self->$action_name(@_);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

1;