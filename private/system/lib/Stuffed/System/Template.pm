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

package Stuffed::System::Template;

$VERSION = '1.35';

# History:
# 1.35 -- part is a separate method now, parse will take vars from the template object now by default
# 1.34 -- added support for intermediary units in blocks (primarily to support else and elsif in if blocks)
# 1.33 -- added strip_tabs and strip_new_lines options
# 1.32 -- renamed "$query." complex variable to "$q."
# 1.31 -- vars handler now forces encode_html wrapper on all vars unless decode_html modifier is specified
# 1.30 -- change of Stuffed::System::Utils::quote syntax
# 1.29 -- use utf8
# 1.28 -- renamed template subs to template data, moved the files to "template_data"
#         dir and changed the main class to Stuffed::System::Template::Data, the
#         import syntax remained the same
# 1.27 -- added concept of named parts to the templates, removed caching, it
#         will probably be re-implemented in the future from scratch
# 1.26 -- fixes in the optimizations in the raw parsing mode
# 1.25 -- fixes in the loop handler
# 1.22 -- added stripping html comments before compiling
# 1.21 -- significant optimization, templates with large vars data could be
#         up to 10-15 times faster now; instead of adding each new block to a
#         string $p, we now push them in an array @p and then just do
#         join('', @p) in the end.
# 1.20 -- include block now supports flags.
# 1.19 -- correctly handling empty templates now.

use strict;
use vars qw($AUTOLOAD);
use Stuffed::System;

my $tag_start = '<%';
my $tag_end = '%>';

sub new {
	my $self = bless({}, shift);
	my $in = {
		pkg					=> undef, # package object
		act					=> undef, # optional, action object, will be used to get vars during parsing
		file				=> undef, # template can be initialized either from a file
		template			=> undef, # or from a plain piece of template
		text				=> undef,
		tmplname			=> undef, # name of the template file (if using a text template)
		tag_start			=> undef,
		tag_end				=> undef,
		skin_id				=> undef, # optional, will be used to override the skin object contained in the supplied package object
		language_id			=> undef, # optional, will be used to override the language object contained in the supplied package object
		flags				=> undef, # optional, ARRAY ref of flags that should be accessible in the current template
		do_404_if_absent	=> undef, # if the template file is absent, display 404 error instead of die-ing (status 500)
		strip_html_comments	=> undef, # optional, will override the same option from system config (should be defined to work)
		strip_tabs			=> undef, # optional, will override the same option from system config (should be defined to work)
		strip_new_lines		=> undef, # optional, will override the same option from system config (should be defined to work)
		@_
	  };
	return if not ref $in->{pkg};

	$self->{pkg} = $in->{pkg};
	$self->{act} = $in->{act};

	if (true($in->{skin_id})) {
		require Stuffed::System::Skin;
		$self->{skin} = Stuffed::System::Skin->new(
			id  => $in->{skin_id},
			pkg => $in->{pkg},
		  );
	} else {
		$self->{skin} = $self->{pkg}->__skin;
	}

	if (true($in->{language_id})) {
		require Stuffed::System::Language;
		$self->{language} = Stuffed::System::Language->new(
			id  => $in->{language_id},
			pkg => $in->{pkg},
		  );
	} else {
		$self->{language} = $self->{pkg}->__language;
	}

	if (ref $in->{flags} eq 'ARRAY') {
		foreach my $flag_name (@{$in->{flags}}) {
			$self->{flags}{$flag_name} = 1;
		}
	}

	foreach my $option (qw(strip_html_comments strip_tabs strip_new_lines)) {
		$self->{$option} = defined $in->{$option} ? $in->{$option} : $system->config->get($option);
	}	
	
	$self->{tag_start} = defined $in->{tag_start} ? $in->{tag_start} : $tag_start;
	$self->{tag_end} = defined $in->{tag_end} ? $in->{tag_end} : $tag_end;

	if (true($in->{file})) {

		# we treat a file with a physical path as a plain text file, we also
		# consider the root in this case to be document root of this web site,
		# this is done to mimic SSI behaviour
		if ($in->{file} =~ /^(?:[\/\\]|\w:)/) {
			my $filename = $ENV{DOCUMENT_ROOT}.$in->{file};
			my $f = Stuffed::System::File->new($filename, 'r', {is_text => 1}) || die "Can't open plain file $in->{file}: $!";
			$self->{plain} = $f->contents;
			$f->close;
		} else {
			my $filename = $self->{skin}->path."/$in->{file}";

			# full path to the template (usually physical)
			$self->{file} = $filename;

			# short path to the template (usually relative)
			$self->{tmplname} = $in->{file};

			$self->{text} = $in->{text} || $self->{language}->load("$in->{file}.cgi");

			if (not -r $filename) {
				if ($in->{do_404_if_absent}) {
					$system->out->error_404;
				} else {
					die "Template '$filename' doesn't exist or can't be opened for reading!";
				}
			}

			my ($cgifile, $exists) = $self->check_compiled($filename);
			
			if ($exists) {
				no strict 'vars';
				local $compiled = {};

				# this part was intentionally done without a usual Perl's "require",
				# because under mod_perl a process could start reading a compiled template
				# before it was actually written completely by another process; this
				# resulted in Perl compile errors; our File class uses locks when
				# opening files, so such problem never happens with it.
				my $tmpl = Stuffed::System::File->new($cgifile, 'r', {is_text => 1}) || die "Can't open compiled template $cgifile for reading: $!";
				my $code = $tmpl->contents;
				$tmpl->close;
				eval $code || die "Fatal error encountered while evaling template \"$cgifile\":\n$@\n";

				$self->{compiled} = $compiled;

				# checking version of Stuffed::System::Template that was used to compile the
				# template, if it is not equal to the current Stuffed::System::Template version
				# we recompile the template
				$exists = undef if $compiled->{version} != $Stuffed::System::Template::VERSION;
				
				# checking if various compile options were the same when the
				# template was compiled as it is now, if it is not so we force template
				# recompilation
				foreach my $option (qw(strip_html_comments strip_tabs strip_new_lines)) {
					next if $compiled->{$option} eq $self->{$option};

					$exists = undef;
					last;	
				}
			}
			
			if (not $exists) {
				my $f = Stuffed::System::File->new($filename, 'r', {is_text => 1}) || die "Can't open template $filename: $!";
				$self->{template} = $f->contents;
				$f->close;

				# cleaning html
				if ($self->{strip_html_comments} or $self->{strip_new_lines} or $self->{strip_tabs}) {
					require Stuffed::System::Utils;
					my $stripped_html = Stuffed::System::Utils::clean_html(
						html				=> $self->{template},
						filename			=> $filename,
						strip_html_comments	=> $self->{strip_html_comments},
						strip_new_lines		=> $self->{strip_new_lines},
						strip_tabs			=> $self->{strip_tabs},
					  );
					$self->{template} = $stripped_html if true($stripped_html);
				}

				my $code = $self->__finalize_compiled($self->compile);

				my $f = Stuffed::System::File->new($cgifile, 'w', {is_text => 1}) || die "Can't write compiled template '$cgifile'. $!";
				$f->print($code)->close;

				no strict 'vars';
				local $compiled = {};
				eval $code || die "Fatal error encountered while compiling template \"$self->{tmplname}\":\n$@\n";
				$self->{compiled} = $compiled;
			}
		}
	} elsif (true($in->{template})) {
		$self->{template} = $in->{template};
		$self->{text} = $in->{text} if $in->{text};
		$self->{tmplname} = defined $in->{tmplname} ? $in->{tmplname} : 'unknown';

		my $code = $self->__finalize_compiled($self->compile);

		no strict 'vars';
		local $compiled = {};
		eval $code || die "Fatal error encountered while compiling template \"$self->{tmplname}\":\n$@\n";
		$self->{compiled} = $compiled;
	} else {
		return $self;
	}

	return $self;
}

sub __finalize_compiled {
	my $self = shift;
	my $code = shift;

	#  return '' if false($code);

	my $top = '';
	if (ref $self->{compiled_top} eq 'HASH') {
		$top = join('', keys %{$self->{compiled_top}})."\n";
	}

	my $parts = '';
	if (ref $self->{compiled_parts} eq 'HASH' and keys %{$self->{compiled_parts}}) {
		foreach my $name (sort keys %{$self->{compiled_parts}}) {
			$parts .= <<CODE;
\$compiled->{parts}{$name}=sub{
my \$s=shift \@_;my \$v=\$s->{vars};my \@p=();my \$in=\$system->in;
$top$self->{compiled_parts}{$name}
return join('',\@p);
};
CODE
		}
	}

	my $time = localtime();
	my $code = <<CODE;
# Generated: $time
#
# This is a compiled version of a Stuffed Template. Don't make modifications
# to this file, modify the original template instead.

use utf8;no warnings;\$compiled->{version}='$Stuffed::System::Template::VERSION';\$compiled->{strip_html_comments}='$self->{strip_html_comments}';\$compiled->{strip_tabs}='$self->{strip_tabs}';\$compiled->{strip_new_lines}='$self->{strip_new_lines}';\$compiled->{code}=sub{
my \$s=shift \@_;my \$v=\$s->{vars};my \@p=();my \$in=\$system->in;
$top$code
return join('',\@p);
};
$parts
1;
CODE

	return $code;
}

sub part {
	my $self = shift;
	my $part = shift;
	$self->{part} = true($part) ? $part : undef;
	return $self; 	
}

sub parse {
	my $self = shift;

	# vars should be passed as a ref to 'HASH'	
	my $vars = shift;

	my $in = {
		part	=> undef, # optional, parse the specified part of the template, not the main template
		@_
	};

	# if vars are not passed we try to grab them from "vars" key of the action object in the template object
	if (not defined $vars and $self->{act}) {
		$vars = $self->{act}{vars};
	}
	
	my $part = $in->{part};

	# if part was not specified in the parameters to parse, we try to grab it from the template object
	$part = $self->{part} if false($part);
	
	# we always reset part during parsing if it was specified through the template object 
	delete $self->{part};
	
	# we return plain text if plain text was loaded (property exists)
	if (exists $self->{plain}) {
		return (true($self->{plain}) ? $self->{plain} : '');
	}

	$self->{vars} = ref $vars eq 'HASH' ? $vars : {};

	if (true($part) and not $self->{compiled}{parts}{$part}) {
		die "Requested part '$part' of the template was not properly compiled, can't execute.";
	}

	if (not $self->{compiled}{code}) {
		die "Template '$self->{tmplname}' was not properly compiled, can't execute."
	}

	# specifying the name of the top template in the stash
	if (false($system->stash('__top_template'))) {
		$system->stash(__top_template => $self->{tmplname});
	}

	my $stack = $system->stash('__tmpl_stack') || [];

	# templates stack is empty, this is the first template we are parsing (not
	# a sub template included in another template)
	if (not @$stack) {
		$system->stash(__last_template => $self->{tmplname});
	}
	push @$stack, $self->{tmplname};
	$system->stash(__tmpl_stack => $stack);

	my $parsed;

	# executing compiled template
	if (true($part)) {
		$parsed = $self->{compiled}{parts}{$part}($self);
	} else {
		$parsed = $self->{compiled}{code}($self);
	}

	pop @$stack;
	$system->stash(__tmpl_stack => $stack);

	return (true($parsed) ? $parsed : '');
}

# checking if the compiled template file should be recompiled or used as is
sub check_compiled {
	my ($self, $file) = @_;
	return if false($file);

	my ($path, $filename) = $file =~ /^(.+?)([^\\\/]+)$/;
	$path .= '__compiled';

	if (not -d $path) {
		mkdir($path, 0777) || die "Can't create directory [ $path ] for compiled templates: $!\n";
	}
	my $cgi_file = "$path/$filename.cgi";
	return ($cgi_file, undef) if not -e $cgi_file;

	my $cgi_modtime = (stat($cgi_file))[9];
	my $tmpl_modtime = (stat($file))[9];

	return $cgi_file, $cgi_modtime >= $tmpl_modtime;
}

sub AUTOLOAD {
	require Stuffed::System::Template::Parser if not defined &Stuffed::System::Template::compile;
	die "Can't locate function [ $AUTOLOAD ]" if not defined &$AUTOLOAD;
	no strict 'refs'; return &{"$AUTOLOAD"}(@_);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

1;