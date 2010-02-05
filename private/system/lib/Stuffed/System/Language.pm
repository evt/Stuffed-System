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

package Stuffed::System::Language;

$VERSION = 1.00;

use strict;

use Stuffed::System::True;
use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		id  => undef, # language id
		pkg => undef, # pkg object
		@_
	  };
	return if not ref $in->{pkg} or false($in->{id});
	my $path = $in->{pkg}->__path;

	my $self = bless({pkg => $in->{pkg}}, $class);

	# downgrading language to default
	if (not -d "$path/languages/$in->{id}" and $in->{id} ne 'default') {
		$in->{id} = 'default';
	}

	if (-d "$path/languages/$in->{id}") {
		$self->{id} = $in->{id};
		$self->{path} = "$path/languages/$self->{id}";
		$self->{config} = Stuffed::System::Config->new("$path/languages/$self->{id}.cgi");
		$self->{config}->set(id => $self->{id});
	}

	return $self;
}

sub load {
	# file specified a filename to load relative to the language directory
	my ($self, $file) = @_;
	return Stuffed::System::Language::Text->new($self, $file);
}

sub exists { true($_[0]->{id}) }
sub id     { $_[0]->{id}   }
sub path   { $_[0]->{path}   }
sub config { $_[0]->{config} }

# ============================================================================

package Stuffed::System::Language::Text;

use vars qw($VERSION);
use Stuffed::System;

$VERSION = 1.00;

sub new {
	my ($class, $language, $file) = @_;
	return undef if false($file);

	my $self = bless({language => $language, file => $file}, $class);

	my $filename = "$language->{path}/$file";

	# caching
	my $cache = $system->stash('__language_cache') || {};
	if ($cache->{$filename}) {
		$self->{content} = $cache->{$filename};
		return $self;
	}

	# specified filed not available for reading
	if (not -r $filename) {
		$self->{content} = {};
		return $self;
	}

	# reading from a file
	{
		no strict 'vars';
		local $text = {};
		my $f = Stuffed::System::File->new($filename, 'r', {is_text => 1});
		eval($f->contents); die $@ if $@;
		$f->close;
		$cache->{$filename} = $text;
		$self->{content} = {%$text};
	}

	$system->stash(__language_cache => $cache);

	return $self;
}

sub get {
	my ($self, $key, @params) = @_;

	# if the key doesn't exist in the current file, we try to load the same
	# file from the default language (if the current language exists and it is
	# not default already) and take the key from there (this is a fallback
	# procedure).
	if (
		false($self->{content}{$key}) and
		$self->{language}->exists and
		$self->{language}->id ne 'default')
	{

		# creating a default language object if we haven't done it already
		$self->{language}{__default_language} = Stuffed::System::Language->new(
			id  => 'default',
			pkg => $self->{language}{pkg},
		  ) if not $self->{language}{__default_language};

		# loading current file for the default language if we haven't done so
		if (not $self->{__default_file}) {
			$self->{__default_file} = $self->{language}{__default_language}->load($self->{file});
		}

		return $self->{__default_file}->get($key, @params);
	} else {
		return (@params ? sprintf($self->{content}{$key}, @params) : $self->{content}{$key});
	}
}

1;