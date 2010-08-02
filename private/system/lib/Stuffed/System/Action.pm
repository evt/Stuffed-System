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

package Stuffed::System::Action;

$VERSION = 1.00;

use strict;

use Stuffed::System;
use Digest::MD5;

sub __new {
	my $class = shift;
	my $in = {
		pkg   => undef,
		name  => undef,
		@_
	};

	my $pkg = $in->{pkg};
	my $name = $in->{name};
	return undef if not $pkg or false($name);

	my $pkg_class = ref $pkg;
	my $pkg_path = $pkg->__path;
	my $action_file_path = "$pkg_path/$name.cgi"; 

	# "b" is just a prefix which doesn't mean anything, we need the first character to be a letter in the package name
	my $base_class = $pkg_class.'::b'.Digest::MD5::md5_hex($action_file_path);
	my $action_class = $base_class.'::action';

	my $already_compiled = undef;
	{
		no strict 'refs';
		$already_compiled = defined ${ $base_class.'::VERSION' };		
	}

	if (not $already_compiled) {
		my $compile_action_if_it_exists = '';
	
		if (-e $action_file_path) {
			$compile_action_if_it_exists = "require \"$action_file_path\";";
		}
	
		# action file doesn't exist, checking if any of the "public" templates exist for the action
		else {
			my $has_templates = undef;
	
			opendir(DIR, $pkg->__skin->path);
			while (my $file = readdir(DIR)) {
				if ($file =~ /^\Q$name\E\./) {
					$has_templates = 1;
					last;
				}
			}
			closedir(DIR);
	
			$pkg->__missing_error(action_name => $name) if not $has_templates;
		}

		eval <<CODE;
package $base_class;
use base 'Stuffed::System::Action';
use Stuffed::System;

our \$VERSION = '1.00';

$compile_action_if_it_exists

package $action_class;
use base 'Stuffed::System::Action';
CODE

		die $@ if $@;
	} 

	my $self = bless({
		__pkg			=> $pkg,
		__name			=> $name,
		__base_class	=> $base_class,
		__is_public		=> 1,
	}, $action_class);

	return $self;
}


sub __template {
	my $self = shift;
	my $file = shift;

	if (false($file)) {
		my ($sub) = (caller(1))[3] =~ /::([^:]+)$/;;
		$file = ($system->out->context('ajax') ? 'ajax/' : '') . $self->{__name} . ($sub eq 'default' ? '' : ".$sub") . '.html';
	}

	require Stuffed::System::Template;
	return Stuffed::System::Template->new(
		file	=> $file, 
		pkg		=> $self->__pkg,
		act		=> $self, 
		@_
	);
}

# official way to call a private sub in the action
sub __private {
	my $self = shift;

	if ($self->{__is_public}) {
		return bless({
			__pkg			=> $self->__pkg,
			__name			=> $self->__name,
			__public		=> $self,
			__is_private	=> 1,
		}, $self->{__base_class});
	} else {
		return $self;
	} 
}

sub __public {
	my $self = shift;
	return ($self->{__is_private} ? $self->{__public} : $self);
}

sub __init {
	my $self = shift;
	return undef if not defined &{ $self->{__base_class}.'::__init' };

	my $action_class = ref $self;
	eval <<CODE;
package $action_class;
sub __init {
	$self->{__base_class}::__init(\@_);
}
CODE

	die $@ if $@;
	
	return $self->__init(@_);
}

sub __stack {
	my $self = shift;
	my $in = {
		running		=> undef,
		finished	=> undef,
		@_
	};
	my $running = $in->{running};
	my $finished = $in->{finished};
	return undef if false($running) and false($finished);
	
	$system->stash(__sub_stack => []) if not $system->stash('__sub_stack');
	my $stack = $system->stash('__sub_stack');
	
	if (true($running)) {
		push @$stack, {
			pkg_name	=> $self->__pkg->__name,
			action_name	=> $self->__name,
			sub_name	=> $running,
		}
	} else {
		my $sub = pop @$stack;
		if (
			$sub->{pkg_name} ne $self->__pkg->__name or
			$sub->{action_name} ne $self->__name or
			$sub->{sub_name} ne $finished 
		) {
			die "Poped wrong sub from the action stack - \"$sub->{pkg_name}/$sub->{action_name}/$sub->{sub_name}\", expected: \"".$self->__pkg->__name.'/'.$self->__name."/$finished\".";
		}
	}
	
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $action_class = ref $self;

	my ($sub_name) = our $AUTOLOAD =~ /([^:]+)$/;
	
	if (not $action_class or $action_class !~ /Stuffed::System::Package/) {
		die qq(Function or method "$sub_name" is not supported in this action!\n);
	}

	if ($sub_name =~ /^_/) {
		eval "sub $sub_name { \$_[0]->{$sub_name} } 1;" || die $@;
		return $self->$sub_name();
	}
	
	my $public_subs_idx;
	{
		no strict 'refs';
		$public_subs_idx = {
			map { $_ =~ s/^&//; $_ => 1 } @{ $self->{__base_class}.'::PUBLIC' }
		};
	}
	# default sub is always public
	$public_subs_idx->{default} = 1;
	
	# sub is declared as public and is defined in the action file — we compile a wrapper method for it
	if ($public_subs_idx->{$sub_name} and defined &{ $self->{__base_class}.'::'.$sub_name }) {
		eval <<CODE;
package $action_class;
sub $sub_name {
	my \$self = shift;

	\$self->__init('$sub_name');

	\$self->__stack(running => '$sub_name');

	my (\@r, \$r);
	if (wantarray) {
		\@r = $self->{__base_class}::$sub_name(\$self, \@_);
	} else {
		\$r = $self->{__base_class}::$sub_name(\$self, \@_);
	}

	\$self->__stack(finished => '$sub_name');
	
	return wantarray ? \@r : \$r; 
}
CODE

		die $@ if $@;
		
		my (@r, $r);
		if (wantarray) {
			@r = $self->$sub_name(@_);
		} else {
			$r = $self->$sub_name(@_);
		}
  
		return wantarray ? @r : $r; 
	}

	# we get here if sub was not declared as public in the action file or it is
	# not defined in the action file, we now check if there is maybe a public
	# template present for this sub in the skin
	my $tmpl_file = $self->__name.($sub_name eq 'default' ? '' : ".$sub_name").'.html';
	my $tmpl_path = $self->__pkg->__skin->path.'/'.$tmpl_file;

	if (-e $tmpl_path) {
		eval <<CODE;
package $action_class;
use Stuffed::System;
sub $sub_name {
	my \$self = shift;

	\$self->__init('$sub_name');
	
	\$self->__stack(running => '$sub_name');
	
	my \$template = \$self->__template('$tmpl_file');
	\$system->out->say(\$template->parse(\$self->{vars}));
	
	\$self->__stack(finished => '$sub_name');
	
	\$system->stop;
}
CODE

		die $@ if $@;
		
		return $self->$sub_name(@_);
	} 

	# at this point we failed to compile the requested sub, so we 
	# just die with an error and get on with our lives
	$self->__pkg->__missing_error(
		action_name => $self->{__name},
		sub_name    => $sub_name,
	);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

1;