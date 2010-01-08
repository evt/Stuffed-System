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

use strict;

use vars qw($defs);

use Stuffed::System;
use Stuffed::System::Utils qw(&quote);

# 1.3 - possible to specify part name instead of the template name for inclusion
# 1.2 - support for inclusion of template parts
# 1.1 - support for quote_single_quotes

$defs->{include} = {
	pattern	=> qr/^\s*([^\s]+)(?:\s+from\s+(\S+?))?(?:\s+using\s+(\S+?))?(?:\s+(.+?))?\s*$/o,
	single	=> 1,
	handler	=> \&include,
	version	=> 1.3,
};

sub include {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';
	my $t = $self->{template};
	my $pkg = $self->{params}[1];
	my $skin_id = $self->{params}[2];
	my $options_strings = $self->{params}[3];

	my ($string, $all_flags_string, $quote_single_quotes, $tmpl_part);

	my $file;
	if ($self->{params}[0] =~ "=" and false($options_strings)) {
		$options_strings = $self->{params}[0];
	} else {
		$file = $t->compile(template => $self->{params}[0], tag_start => '<', tag_end => '>', raw => 1);
	}

	if ($options_strings) {
		$options_strings =~ s/(?:^\s+|\s+$)//g;

		my @options = split(/\s+/, $options_strings);

		my @all_flags;

		foreach my $option (@options) {
			my ($name, $value) = $option =~ /^([^=]+)="([^"]+)"/;
			$name = lc($name);

			if ($name eq 'set_flag') {
				push @all_flags, $t->compile(template => $value, tag_start => '<', tag_end => '>', raw => 1);
			}

			elsif ($name eq 'quote_single_quotes') {
				$quote_single_quotes = 1;
			}

			elsif ($name eq 'part') {
				$tmpl_part = $value;
			}
		}

		if (@all_flags) {
			$all_flags_string = '['.join(',', @all_flags).']';
		}
	}
	
	$string = "push \@p,";
	$string .= "Stuffed::System::Utils::quote(" if $quote_single_quotes;

	if (true($pkg) and $pkg ne $t->{pkg}->__name) {
		$skin_id = (true($skin_id) ? quote($skin_id) : '$s->{skin}->id');
		$string .= "\$system->pkg('$pkg')->__template($file, skin_id=>$skin_id,language_id=>\$s->{language}->id";
		$string .= ",flags=>".$all_flags_string if $all_flags_string;
		$string .= ')->parse($v';
	} elsif ($file) {
		$string .= "\$s->{pkg}->__template($file";
		$string .= ",flags=>".$all_flags_string if $all_flags_string;
		if (true($skin_id)) {
			$string .= ",skin_id=>".quote($skin_id);
			$string .= ",pkg=>\$s->{pkg}";
		}
		$string .= ')->parse($v';
	} else {
		$string .= '$s->parse($v';
	}

	$string .= ',part=>'.quote($tmpl_part) if true($tmpl_part);
	$string .= ')';
	$string .= ", start => q('), no_border => 1, quote_nl => 1)" if $quote_single_quotes;
	$string .= ';';

	$t->add_to_compiled($string);
}

1;
