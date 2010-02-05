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

package Stuffed::System::Event;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		name	=> undef, # name of the event to initialize
		pkg		=> undef, # package object
		@_
	  };
	my $name = $in->{name};
	my $pkg = $in->{pkg};
	return if false($name) or false($pkg);

	my $self = bless({
			name	=> $name, # name of the event
			pkg		=> $pkg,
			file	=> $pkg->__path.'/events/'.$name,
			listed	=> [],    # listed plugins in the event file
			plugins	=> [],    # actually compiled plugins for this event
		}, $class);

	my $disabled_events = $system->stash('__disabled_events');

	# all events in the current package are disabled
	return $self if $disabled_events->{$pkg->__name}{__all};

	# current event in the current package is disabled
	return $self if $disabled_events->{$pkg->__name}{$name};

	# we load the event file or return if we can't open it
	my $file = Stuffed::System::File->new($self->{file}, 'r', {is_text => 1}) || return $self;
	while (my $line = $file->line) {
		# cleaning the line
		$line =~ s/^\s+|\s+$//sg;
		next if false($line) or substr($line, 0, 1) eq '#';
		push @{$self->{listed}}, $line;
	}
	$file->close;

	my $cache = $system->stash('__plugins_cache') || {};

	# trying to compile all listed plugins
	foreach my $plugin (@{$self->{listed}}) {
		if (not $cache->{$plugin}) {
			my $code = $self->__compile_plugin($plugin);
			next if ref $code ne 'CODE';
			$cache->{$plugin} = $code;
		}

		push @{$self->{plugins}}, {name => $plugin, code => $cache->{$plugin}};
	}

	$system->stash(__plugins_cache => $cache);

	return $self;
}

sub process {
	my ($self, @params) = @_;

	foreach my $plugin (@{$self->{plugins}}) {
		$plugin->{code}->($self, @params);
	}

	return @params;
}

sub pkg { $_[0]->{pkg} }
sub name { $_[0]->{name} }
sub has_plugins { @{$_[0]->{plugins}} ? 1 : 0 }
sub list_plugins { my $self = shift; map {$_->{name}} @{$self->{plugins}} }

sub __compile_plugin {
	my ($self, $plugin) = @_;
	return if false($plugin);

	my ($pkg, $p_name) = $plugin =~ /^(.+?):([^:]+)$/;
	my $p_file = $system->path.'/private/'.Stuffed::System::Package->__create_path($pkg)."/plugins/$p_name.cgi";
	return if not -r $p_file;

	my $package = "Stuffed::System::Plugins::$pkg";

	eval <<CODE;
package $package; 
use Stuffed::System;
require "$p_file";
CODE
	die "Error compiling plugin $plugin: $@" if $@;
	return if not defined &{$package.'::'.$p_name};

	return \&{$package.'::'.$p_name};
}

1;