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

package Stuffed::System::Skin;

$VERSION = 1.00;

use strict;
use vars qw($AUTOLOAD);

use Stuffed::System::True;

sub new {
	my $this = shift;
	my $in = {
		id  => undef, # id of the skin
		pkg => undef, # pkg object
		@_
	  };
	return if not ref $in->{pkg} or false($in->{id});
	my $self = bless($in, $this);

	my $pkg = $in->{pkg};

	# downgrading the skin to Default if the requested is not found
	if ($self->{id} ne 'default' and
		(not -d $pkg->__path."/skins/$self->{id}" or
			not -r $pkg->__path."/skins/$self->{id}.cgi"))
	{
		$self->{id} = 'default';
	}

	$self->{path} = $pkg->__path."/skins/$self->{id}";

	$self->{config} = Stuffed::System::Config->new($pkg->__path."/skins/$self->{id}.cgi");
	$self->{config}->set(public_path => $pkg->__public_path . "/skins/$self->{id}");
	$self->{config}->set(public_url => $pkg->__public_url . "/skins/$self->{id}");

	my $languages = $self->{config}->get('supported_languages');
	if ($languages and ref $languages eq 'ARRAY') {
		my $found;
		foreach (@$languages) {
			$found = 1 if $_ eq $pkg->__language->id;
		}
		$self->{config}->set(language => ($found ? $pkg->__language->id : $languages->[0]));
	}

	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my ($method) = $AUTOLOAD =~ /([^:]+)$/;
	eval "sub $method { \$_[0]->{$method} } 1;" || die $@;
	return $self->$method(@_);
}

# is needed because we have AUTOLOAD here, if DESTORY is missing, Perl will call
# AUTOLOAD when destoying the object
sub DESTROY {}

1;