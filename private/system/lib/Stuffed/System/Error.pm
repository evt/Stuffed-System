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
# Package: Stuffed::System::Error
#
# This class is used mainly to throw errors inside subs, that later are
# displayed in the templates. Also, <__just_die> function is specified to
# CGI::Carp when Stuffed::System initializes as a die handler.

package Stuffed::System::Error;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	return $self;
}

#use AutoLoader 'AUTOLOAD';
#__END__

# ============================================================================
# Group: Methods for working with web error instance

# Method: setup
#
# Creates and returns new web error instance
#
# Returns:
#
# <Stuffed::System::Error::Web> object

sub setup {
	my $self = shift;
	my $in = {
		__act	=> undef, # optional if you don't want to throw an error
		__sub	=> undef, # optional if you don't want to throw an error
		msg_pkg	=> undef, # optional if you don't want to throw an error with i18n message id
		form	=> undef,
		@_
	  };

	require Stuffed::System::Error::Web;
	return Stuffed::System::Error::Web->new(container => $self, %$in);
}

# Method: was_thrown
#
# Checks wether at least one error was already thrown or announced (note:
# setting up an error and throwing it or announcing it are different things).
#
# Returns:
#
# 1 - if error was thrown
# undef - if no error was thrown

sub was_thrown {
	my $self = shift;
	return ($self->{__stack} and @{$self->{__stack}} ? 1 : undef);
}

# Method: clear
#
# Removes any logged errors from the state, after that was_thrown will return
# undef as if no errors were thrown
#
# Returns:
#
# 1 - always

sub clear {
	my $self = shift;
	delete $self->{__stack};
	return 1;
}

# Method: get_error
#
# Returns the specified <Stuffed::System::Error::Web> object from the stack.
# Stack is used to save errors at the moment when they are thrown. So if no
# errors were thrown yet, this method will return undef.
#
# Parameters:
#
# 1st - specifies what error to return, could be "first", "last" or number of
#       the error in the stack (starting from 0)
#
# Returns:
#
# <Stuffed::System::Error::Web> object

sub get_error {
	my $self = shift;
	my $what = shift;

	# return undef if stack is not present or is empty
	return undef if not $self->{__stack} or not @{$self->{__stack}};

	# return the whole stack of errors if it was not specified what to return,
	# or the stack is empty (doesn't exist)
	return $self->{__stack} if false($what);

	if (lc($what) eq 'first') {
		return $self->{__stack}[0];
	} elsif (lc($what) eq 'last') {
		return $self->{__stack}[$#{$self->{__stack}}];
	} elsif ($what =~ /^\d+$/) {
		return $self->{__stack}[$what];
	}

	return undef;
}

# Method: __save_error
#
# Saves error in the stack at the moment when it is thrown. It is used
# internally by <Stuffed::System::Error::Web> class.
#
# Parameters:
#
# 1st - specifies <Stuffed::System::Error::Web> object
#
# Returns:
#
# <Stuffed::System::Error> object

sub __save_error {
	my $self = shift;
	my $error = shift;
	return undef if not $error;

	push @{$self->{__stack}}, $error;

	return $self;
}

sub __clean_file_for_log {
	my $file = shift;
	my $path = quotemeta($system->path);
	$file =~ s/\s+\(autosplit[^\)]+\)//;
	$file =~ s/$path//;
	$file =~ s/\.\//\//;

	# windows paths
	$file =~ s/\\/\//g;
	return $file;
}

# ============================================================================
# Group: General error methods

# Method: die
#
# Generally works the same as the core "die" function, if it was invoked
# from inside the Stuffed System. When invoked it prints out headers,
# using <Stuffed::System::Output::__print_header> and then calls <__just_die>.
#
# Parameters:
#
# 1st - specifies the die message

sub die {
	my $self = shift;
	my $message = shift;
	my $in = {
		kind_of => undef, # optional, the message will be logged, but process will not die
		@_
	  };
	return undef if false($message);

	if ($message !~ /\n$/) {
		my ($package, $filename, $line) = caller;
		$filename = __clean_file_for_log($filename);
		$message .= " at $filename line $line\n";
	}

	$system->out->__print_header if not $in->{kind_of};
	__just_die($message, @_);
}

# Method: log
#
# Is used to log an error message to the Stuffed System all errors log, if this type of 
# logging is turned on.

sub log {
	my $self = shift;
	my $in = {
		msg			=> undef, # text of the error message to log
		fields		=> undef, # optional ARRAY ref of form fields related to the error message
		stack		=> undef, # optional call stack (could be slightly changed from the actual one in a die handler, so it is passed as a param)
		is_critical	=> undef, # critical flag for the error (such as coming from a die handler)
		@_
	};
	my ($msg, $fields, $stack, $is_critical) = @$in{qw(msg fields stack is_critical)};
	
	my $config = $system->config;
	
	# logging error in all errors log if log_all_errors option is on in config
	return undef if not $config or not $config->get('log_all_errors');
	
	# no new lines are allowed in the message, as all of the message and additional information should be on one line in the log
	$msg =~ s/[\r\n]+/ /g;
	
	# turning multiple spaces into one
	$msg =~ s/\s+/ /g;
	
	# kill spaces in the beginning and the end of the message
	$msg =~ s/^\s+|\s+$//g;
	
	my $stack_line = '';
	
	if (ref $stack ne 'ARRAY' or not @$stack) {
		my $counter = 0;
		while (my @frame = caller($counter)) {
			push @$stack, \@frame;
			$counter += 1;
		}
	}

	my $frame = $stack->[0];
	my $sub = ( $stack->[1] ? $stack->[1][3] . '()' : 'main()' );
	my $file = __clean_file_for_log( $frame->[1] );
	$stack_line = "$sub, $file line $frame->[2]";	
	
	require Stuffed::System::Utils;
	my $ip = Stuffed::System::Utils::get_ip();

	my $url = '';

	if ($ENV{REQUEST_URI}) {
		$url = true($ENV{HTTP_HOST}) ? 'http'.($ENV{HTTPS} eq 'on' ? 's' : '').'://'.$ENV{HTTP_HOST} : '';
		$url .= $ENV{REQUEST_URI}; 
	}
	
	my $referrer = $ENV{HTTP_REFERER} || '';
	
	my $filename = $config->get('all_errors_file');

	# relative path, we add system path in front
	if (true($filename) and $filename !~ /^\//) {
		$filename = $system->path . '/' . $filename
	}

	# file not specified, using default file name and location
	elsif (false($filename)) {
		$filename = $system->path . '/private/.ht_errors.all.log';
	}
	
	my $content = '[' . localtime() . '] ' . $ip;
	$content .= ' [C]' if $is_critical;
	$content .= ' "' . $msg . '"';
	$content .= ' "' . ( ref $fields eq 'ARRAY' and @$fields ? join(', ', @$fields) : '' ) . '"';
	$content .= ' "' . $stack_line . '"';
	$content .= ' "' . $url . '"';
	$content .= ' "' . $referrer . '"';
	
	__append_to_file(
		filename	=> $filename,
		content		=> $content,   
	);
		
}

# ============================================================================
# Group: Internal functions and methods, not meant to be used outside this package

sub __append_to_file {
	my $in = {
		filename	=> undef,
		content		=> undef,
		@_
	};
	my ($filename, $content) = @$in{qw(filename content)};
	return undef if false($filename) or false($content);
	
	return undef if not open(LOG, '>> '.$filename);

	flock LOG, 2 | 4;
	print LOG $content . "\n";
	flock LOG, 8;
	
	close(LOG);
}

# Function: __log_error
#
# Tries to log a specified error to the Stuffed System error log (if logging
# is switched on). The location of the log file is taken from "critical_errors_file"
# parameters in system config. If it is not specified the default location
# is used: "private/.ht_errors.log".
#
# Parameters:
#
# 1st - specifies the error message

sub __log_error {
	my $message = shift;
	return undef if false($message);

	my $config = $system->config;
	
	# logging error in the system error log if log_errors option is on in config
	return undef if not $config or not $config->get('log_critical_errors'); 

	my $filename = $config->get('critical_errors_file');

	# relative path, we add system path in front
	if (true($filename) and $filename !~ /^\//) {
		$filename = $system->path . '/' . $filename
	}

	# file not specified, using default file name and location
	elsif (false($filename)) {
		$filename = $system->path . '/private/.ht_errors.critical.log';
	}

	require Stuffed::System::Utils;
	my $ip = Stuffed::System::Utils::get_ip();
	
	chomp(my $log_message = $message);
	
	__append_to_file(
		filename	=> $filename,
		content		=> '[' . scalar localtime() . " - $ip] $log_message\n",
	); 	
}

# Function: __just_die
#
# A die handler, it is specified as a reference to CGI::Carp when Stuffed System
# initializes. It will try to log an error to the Stuffed System error
# log (if logging is switched on). At the end, it always stops the system
# (with <Stuffed::System::stop>).
#
# Parameters:
#
# 1st - specifies the die message

sub __just_die {
	my $message = shift;
	my $in = {
		kind_of 			=> undef, # optional, the message will be logged, but process will not die
		skip_last_in_stack	=> undef, # optional, skip last entry in stack 
		@_
	  };
	my $config = $system->config;
	
	my $trace;

	my @stack;
	my $counter = 0;
	while (my @frame = caller($counter)) {
		push @stack, \@frame;
		$counter += 1;
	}
	
	splice(@stack, 0, 1) if $in->{skip_last_in_stack};
	
	# cutting out everything before the main system eval from the stack
	if ($ENV{STUFFED_STACK_START}) {
		@stack = reverse @stack;
		splice(@stack, 0, $ENV{STUFFED_STACK_START});
		@stack = reverse @stack;
	}
	
	# cleaning up a bit first
	my @final_stack;
	for (my $i = 0; $i < scalar @stack; $i++) {
		my $sub = ($stack[$i+1] ? $stack[$i+1][3] : '');

		# skipping CGI::Carp routines as they always repeat since our die handler
		# works through the CGI::Carp's handler
		next if $sub eq 'CGI::Carp::die';

		if ($sub eq 'Stuffed::System::Error::__just_die') {
			# mod_perl 2.0
			if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
				ModPerl::Util::exit();
			}
	
			# mod_perl 1.0
			elsif ($ENV{MOD_PERL}) {
				Apache::exit();
			}
	
			else {
				CORE::exit();
			}
		}
		
		push @final_stack, $stack[$i];
	}
	@stack = @final_stack;

	my $message_line_info;

	for (my $i = 0; $i < scalar @stack; $i++) {
		my $frame = $stack[$i];
		my $sub = ($stack[$i+1] ? $stack[$i+1][3].'()' : 'main()');
		my $file = __clean_file_for_log($frame->[1]);

		$message_line_info = " at $file line $frame->[2]." if false $message_line_info;

		$trace .= "-- $sub, $file line $frame->[2];\n";
	}

	# ============================================================================	

	if ( CGI::Carp::ineval() ) {
		CORE::die( $message . ($message !~ /\n$/ ? $message_line_info . "\n" : '' ) );		
	}

	# ============================================================================
	# additional logic if this is a DBI error

	my $database_info = '';

	if ($message =~ /^DBD::mysql/ and $config) {
		$database_info = '<main@'.$config->get('db_host').':'.$config->get('db_name').'> ';
		if ($config->get('enable_read_db')) {
			$database_info .= '<read@'.$config->get('read_db_host').':'.$config->get('read_db_name').'> ';
		}
	}

	# ============================================================================
	
	Stuffed::System::Error->new->log(
		msg			=> $database_info . $message,
		stack		=> \@stack,
		is_critical	=> 1,
	);

	# ============================================================================

	my @add_message;
	
	if ($ENV{REQUEST_URI}) {
		my $url = true($ENV{HTTP_HOST}) ? 'http'.($ENV{HTTPS} eq 'on' ? 's' : '').'://'.$ENV{HTTP_HOST} : '';
		$url .= $ENV{REQUEST_URI}; 
		push @add_message, "URL: $url";
	}
	
	if ($ENV{HTTP_REFERER}) {
		push @add_message, "Referrer: $ENV{HTTP_REFERER}";
	}

	if (true($trace)) {
		push @add_message, "Stack trace:\n$trace";
	}

	# ============================================================================

	__log_error(
		$database_info . $message . ( @add_message ? ($message !~ /\n$/ ? "\n" : '') . join("\n", @add_message) : '' )
	);

	return if $in->{kind_of};

	$message .= $message_line_info if $message !~ /\n$/;

	if ($system->out->context('web')) {
		$message =~ s/[\r\n]+$//;
		$message =~ s/\n/<br>/sg;

		my $HTML;

		if ($config and $config->get('display_critical_errors')) {
			if ($system->out->context('ajax')) {
				$HTML = <<HTML;
<div><strong>System error has just occured:</strong></div>
<div>$message</div>
HTML
			} else {
				$HTML = <<HTML;
<div style="font-size: 11pt;">
<strong style="font-size: 16pt;">System error has just occured:</strong>

<p style="color: #555; padding: 10px; border: 1px dotted black;">$message</p>

We are sorry for any inconvenience this error might have caused. Be assured that we
are already working on solving the problem.
</div>
HTML
			}
		} else {
			if ($system->out->context('ajax')) {
				$HTML = <<HTML;
<div><strong>A critical system error has just occured!</strong></div>
<div>We are sorry for any inconvenience this error might have caused. Be assured that we
are already working on solving the problem.<div>
HTML
			} else {
				$HTML = <<HTML;
<div style="font-size: 11pt;">
<strong style="font-size: 16pt;">A critical system error has just occured!</strong><br><br>

We are sorry for any inconvenience this error might have caused. Be assured that we
are already working on solving the problem.
</div>
HTML
			}
		}
		
		if ($system->out->context('iframe')) {
			require Stuffed::System::Utils;
			# IE will not give us access via JS to the iFrame with a status 500 document, so we use this hack instead
			$HTML = '<textarea is_error="1">'.Stuffed::System::Utils::encode_html($HTML).'</textarea>';
			$system->out->say($HTML);
		} else {
			$system->out->error_500($HTML);
		}
	} else {
		print $message;
	}

	$system->stop;
}

1;