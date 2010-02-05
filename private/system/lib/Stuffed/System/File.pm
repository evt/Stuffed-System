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
# History
# 01/05/2006 - 1.02
#            * added is_binary option to set the file in the binary mode after opening
# 30/01/2005 - 1.01
#            * contents_as_arrayref method was added
# ============================================================================

package Stuffed::System::File;

$VERSION = 1.03;

use strict;

use Stuffed::System;

sub LOCK_SH { 1 }
sub LOCK_EX { 2 }
sub LOCK_NB { 4 }
sub LOCK_UN { 8 }

# possible options:
#   is_temp -- temporary file, should be deleted when the object will be destroyed
#   is_binary -- a binary file, we should use binmode on the file handle after opening
#	is_text -- a text file, we should set utf8 layer on it
#   access -- access rights (0766 for example) should be set on the file after opening

sub new {
	my $self = bless({}, shift);
	my ($name, $mode, $o) = @_;
	return if false($name);
	
	$self->{options} = (ref $o eq 'HASH' ? $o : {});
	$mode = 'r' if not $mode or $mode !~ /^(?:w|u|a)$/;
	$self->{name} = $name;
	$self->open($mode) || return;
	chmod $self->{options}{access}, $self->{name} if $o->{access};
	
	if ($o->{is_binary}) {
		$self->set_binmode;	
	} elsif ($o->{is_text}) {
		$self->set_textmode	
	} 
	
	# if system config was already loaded, check this setting, to load system config
	# we already have to use this code, thus the check
	elsif ($system->{__config} and $system->config->get('default_file_layer')) {
		if ($system->config->get('default_file_layer') eq 'binary') {
			$self->set_binmode;
		} else {
			$self->set_textmode;
		}
	}

	return $self;
}

sub mode { shift->{mode} }
sub name { shift->{name} }
sub opened { shift->{opened} }
sub locked { shift->{locked} }
sub handle { shift->{handle} }

sub set_binmode {
	my $self = shift;

	# opening file for reading if it is not already opened
	$self->open('r') if not $self->{handle} and true($self->{name});
	binmode $self->{handle}, ':raw' if $self->{opened};
	
	return $self;
}

sub set_textmode {
	my $self = shift;

	# opening file for reading if it is not already opened
	$self->open('r') if not $self->{handle} and true($self->{name});
	binmode $self->{handle}, ':encoding(UTF-8)' if $self->{opened};
	
	return $self;
}

sub lock {
	my $self = shift;
	return if not $self->{handle} or not $self->{mode};
	$self->unlock if $self->{locked};

	if ($self->{mode} eq 'r') {
		if (not flock $self->{handle}, LOCK_SH | LOCK_NB) {
			die "File $self->{name} can not be locked: $!" if not flock $self->{handle}, LOCK_SH;
		}
		$self->{locked} = 1;
	} else {
		if (not flock $self->{handle}, LOCK_EX | LOCK_NB) {
			die "File $self->{name} can not be locked: $!" if not flock $self->{handle}, LOCK_EX;
		}
		$self->{locked} = 1;
	}

	return 1;
}

sub unlock {
	my $self = shift;
	return if not $self->{handle};
	return 1 if not $self->{locked}; # return with true if file is not locked
	flock $self->{handle}, LOCK_UN or return;
	delete $self->{locked};
	return 1;
}

sub open {
	my ($self, $mode) = @_;

	local (*F);
	return if false($self->{name});

	return 1 if $self->{opened}; # return true if the file already opened

	if ($mode eq 'r') {
		return if not -r $self->{name} and not chmod(0644, $self->{name});
		return if not open(F, "< ".$self->{name});
		$self->{handle} = *F{IO};
		$self->{mode} = $mode;
		$self->lock || return;
	} elsif ($mode eq 'w') {
		return if -f $self->{name} and not -w $self->{name} and not chmod(0644, $self->{name});
		return if not open(F, "> " . $self->{name});
		$self->{handle} = *F{IO};
		$self->{mode} = $mode;
		$self->lock || return;
	} elsif ($mode eq 'a') {
		return if -f $self->{name} and not -w $self->{name} and not chmod(0644, $self->{name});
		return if not open(F, ">> " . $self->{name});
		$self->{handle} = *F{IO};
		$self->{mode} = $mode;
		$self->lock || return;
		seek($self->{handle}, 0, 2);
	} elsif ($mode eq 'u') {
		return if -f $self->{name} and not -w $self->{name} and not chmod(0644, $self->{name});
		return if not open(F, "+< " . $self->{name});
		$self->{handle} = *F{IO};
		$self->{mode} = $mode;
		$self->lock || return;
	} else {
		return;
	}

	return $self->{opened} = 1;
}

sub close {
	my $self = shift;
	return if not $self->{handle};
	return 1 if not $self->{opened}; # return with true if the file is not opened
	if ($self->{locked}) { $self->unlock || return }
	close $self->{handle} || return;
	delete $self->{$_} foreach (qw(mode opened handle));
	return $self;
}

# read all contents of the file in ascii mode
sub contents {
	my $self = shift;

	# opening file for reading if it is not already opened
	$self->open('r') if not $self->{handle} and true($self->{name});

	return if not $self->{handle} or $self->{mode} ne "r";
	my $handle = $self->{handle};
	return join('', <$handle>);
}

# read all lines of the file and return a ref to an array of lines
sub contents_as_arrayref {
	my $self = shift;

	# opening file for reading if it is not already opened
	$self->open('r') if not $self->{handle} and true($self->{name});

	return if not $self->{handle} or $self->{mode} ne "r";
	my $handle = $self->{handle};
	return [<$handle>];
}

# read and return one line
sub line {
	my $self = shift;

	# opening file for reading if it is not already opened
	$self->open('r') if not $self->{handle} and true($self->{name});

	return if not $self->{handle} or $self->{mode} ne "r";
	my $handle = $self->{handle};
	return scalar <$handle>;
}

sub print {
	my ($self, @contents) = @_;

	# opening file for writing if it is not already opened
	$self->open('w') if not $self->{handle} and true($self->{name});

	return if not @contents or not $self->{handle} or $self->{mode} eq "r";
	my $handle = $self->{handle};

	# use bytes/no bytes is a patch for Perl 5.8 so that it stops complaining
	# about "Wide character in print"; this is connected to the new way Perl 5.8
	# works with utf8 and filehandles
	use bytes;
	print $handle @contents;
	no bytes;

	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->close if $self->{opened};

	# deleting a file if it has an 'is_temp' property set on
	unlink $self->{name} if $self->{options}{is_temp};
}

1;