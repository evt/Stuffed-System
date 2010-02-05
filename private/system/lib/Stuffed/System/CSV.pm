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

# This class builds upon Text::CSV module, its only purpose is to handle
# correctly multiline records in CSV files. Everything else is done by
# Text::CSV.

package Stuffed::System::CSV;

$VERSION = 1.00;

use strict;

use Stuffed::System;
use Text::CSV;

sub new {
	my $class = shift;
	my $in = {
		delimiter	=> undef, # records delimiter
		file		=> undef, # file object or file name
		contents	=> undef, # an ARRAY ref, each element represents a line of the csv file
		encoding	=> undef, # supported is 'ISO-8859-1' (default) and UTF8
		@_
	  };
	if (true($in->{contents}) and ref $in->{contents} ne 'ARRAY') {
		die "File contents should be specified as an ARRAY ref to the constructor method!";
	}
	$in->{encoding} = lc($in->{encoding});
	my $self = bless($in, $class);

	# unknown encoding specified
	if (true($self->{encoding}) and $self->{encoding} !~ /^(?:utf8|iso\-8859\-1)$/) {
		delete $self->{encoding};
	}

	$self->{encoding} = 'iso-8859-1' if false($self->{encoding});

	$self->{text_csv} = Text::CSV->new(delimiter => $in->{delimiter});

	return $self;
}

sub add_fields {
	my $self = shift;
	my @fields = @_;

	# do the autoconversion
	if ($self->{encoding} ne 'iso-8859-1') {
		require Encode;
		@fields = map {Encode::encode($self->{encoding}, $_)} @fields;
	}

	$self->{text_csv}->combine(@fields);
	push @{$self->{contents}}, $self->{text_csv}->string;

	return $self;
}

sub output_as_file {
	my $self = shift;
	my $in = {
		filename => undef, # optional
		@_
	  };
	my $filename = $in->{filename};
	$filename = Stuffed::System::Utils::create_random(12).'.csv' if false($filename);

	$system->out->header('Content-Type' => 'text/csv');
	$system->out->header('Content-Disposition' => "attachment; filename=\"$filename\"");
	$system->config->set(debug => 0);
	if ($self->{contents}) {
		$system->out->say(join("\n", @{$self->{contents}}));
	}
}

sub save_as_file {
	my $self = shift;
	my $in = {
		filename => undef, # optional
		@_
	  };
	my $filename = $in->{filename};
	$filename = Stuffed::System::Utils::create_random(12).'.csv' if false($filename);

	require Stuffed::System::File;
	my $file = Stuffed::System::File->new($filename, 'w', {is_text => 1});
	if ($file) {
		$file->print(join("\n", @{$self->{contents}}));
		$file->close;
	}

	return 1;
}

sub __prepare_file {
	my $self = shift;

	# if the file was specified, but it is not opened yet, we open it
	if (true($self->{file}) and not ref $self->{file}) {
		require Stuffed::System::File;
		$self->{file} = Stuffed::System::File->new($self->{file}, 'r', {is_text => 1}) || die "Can't open file '$self->{file}': $!";
	}

   # if the file was specified, but it is opened in a non-reading mode, we close
   # it and open in the reading mode, which we need
	elsif (ref $self->{file} and $self->{file}->mode ne 'r') {
		$self->{file}->close;
		$self->{file}->open('r');
	}
}

sub test_delimiter {
	my $self = shift;

	my $line;
	my $i = 0;
	while (false($line)) {
		$line = (ref $self->{file} ? $self->{file}->line : $self->{contents}[$i]);

		# if $line is not defined then we reached the end of file or contents
		last if not defined $line;

		# removing all spaces from lines that contain ONLY spaces
		$line =~ s/^\s+$//g;

		$i += 1;
	}

	# closing and opening the file to reset the pointer
	if (ref $self->{file}) {
		$self->{file}->close;
		$self->{file} = Stuffed::System::File->new($self->{file}, 'r', {is_text => 1}) || die "Can't open file '$self->{file}': $!";
	}

	return $self->{text_csv}->parse($line);
}

sub get_fields {
	my $self = shift;

	my ($status, $line, @fields);

	$self->__prepare_file;

	# until we successfully parse a line, we continue to get new lines from the
	# file, appending them to the previous line and trying to parse the new line
	# with Text::CSV
	while (not $status) {
		my $next_line = $self->__get_line;

		# if $next_line is not defined then we reached the end of file or contents
		last if not defined $next_line;

		$line .= $next_line;

		$status = $self->{text_csv}->parse($line);
		@fields = $self->{text_csv}->fields;
	}

	return @fields;
}

sub __get_line {
	my $self = shift;

	my $line;
	while (false($line)) {
		$line = (ref $self->{file} ? $self->{file}->line : shift @{$self->{contents}});

		# if $line is not defined then we reached the end of file or contents
		last if not defined $line;

		# removing all spaces from lines that contain ONLY spaces
		$line =~ s/^\s+$//g;
	}

	return $line;
}

1;