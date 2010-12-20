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

package Stuffed::System::Error::Web;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		__act		=> undef,
		__sub		=> undef,
		container	=> undef, # Stuffed::System::Error instance
		msg_pkg		=> undef, # optional
		form		=> undef, # optional
		@_
	  };

	foreach (qw(container)) {
		return undef if false($in->{$_});
	}

	my $self = bless($in, $class);
	return $self;
}

# Method: announce
#
# Announces an error to the system exactly the same way as <throw> does it, but
# doesn't launch any sub at the end, just returns back to the calling code
# after the error was announced.
#
# Parameters:
#
# Same is in <throw> method.

sub announce {
	my $self = shift;
	my $in = {
		message    => undef, # message text
		msg_id     => undef, # i18n message id
		msg_params => undef, # i18n message params, ARRAY ref
		fields     => undef, # ARRAY ref
		@_
	  };

	$self->throw(%$in, __no_launch => 1);
}

# Method: throw
#
# Adds a specified error to the errors container so that it becomes visible
# to any code that wants to check if there was an error and launches a
# sub that was specified when the error was setup.
#
# If you don't want to launch a sub and want to handle the error situation
# yourself (but you still want to tell the system that there was an error) --
# look at the <announce> method instead.
#
# Parameters:
#
# message - error message text
# msg_id - i18n text id if you want to look up the actual message text in a
# language file
# msg_params - ARRAY ref, parameters that you want to pass to i18n routine
# fields - ARRAY ref, erroneous form fields, that should be marked in the
# template

sub throw {
	my $self = shift;
	my $in = {
		message		=> undef, # message text
		msg_id		=> undef, # i18n message id
		msg_params	=> undef, # i18n message params, ARRAY ref
		fields		=> undef, # ARRAY ref
		__no_launch	=> undef, # internal param, not for public use
		@_
	  };

	if (not $in->{__no_launch}) {
		foreach (qw(__act __sub)) {
			return undef if false($self->{$_});
		}
	}

	$self->{fields} = $in->{fields};

	# i18n
	if (true($in->{msg_id})) {
		my $msg_pkg = $self->{msg_pkg} || ($self->{__act} ? $self->{__act}->__pkg : undef);
		$msg_pkg = $system->pkg($msg_pkg) if not ref $msg_pkg;
		if ($msg_pkg) {
			my @params = ref $in->{msg_params} eq 'ARRAY' ? @{$in->{msg_params}} : undef;
			my $errors = $msg_pkg->__language->load('__system/errors.cgi');
			my $string = $errors->get($in->{msg_id}, @params);
			$self->{message} = true($string) ? $string : $in->{msg_id};
		} else {
			$self->{message} = $in->{msg_id};
		}
	}

	# plain message
	else {
		$self->{message} = $in->{message};
	}

	# saving error in the container before throwing
	$self->{container}->__save_error($self);

	if (not $in->{__no_launch}) {
		my $sub = $self->{__sub} || 'default';
		$self->{__act}->$sub();
	}
}

sub form { $_[0]->{form} }
sub message { $_[0]->{message} }
sub fields { $_[0]->{fields} }

1;
