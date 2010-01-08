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

# <%text $awaits_approval from __system/common.cgi%>
# <span class="selected"><% $total_comments %></span>
# <%/text%>
# -- from is optional above, specifies the location of the file in the language where the string can be found

use strict;
use vars qw($defs);

$defs->{text} = {
	pattern	=> qr/\s*\$*([^=\s\%]+)(?:\s+from\s+(\S+))?\s*/o,
	handler	=> \&text,
	version	=> 1.0,
};

sub text {
	my ($self, $content) = @_;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my @lines = ();
	my $t = $self->{template};
	my $id = $self->{params}[0];

	# optional
	my $text_file = $self->{params}[1];

	my $final = '';

	$id =  $t->compile(template => $id, tag_start => '<', tag_end => '>', raw => 1);

	my $text_prefix = '$s->{text}';
	if (true($text_file)) {
		$text_prefix = '$s->{pkg}->__language->load('.Stuffed::System::Utils::quote($text_file).')';
	}

	# preparing for black magic with sprintf
	if (true($content)) {
		$content =~ s/^\s+|\s+$//gs;
		$content =~ s///s;

		# variables could be separated either with a new line, or with "@@"
		if ($content =~ /\@\@/) {
			@lines = split(/\@\@/, $content);
		} else {
			@lines = split(/[\n\r]+/, $content);
		}
		foreach (@lines) {
			$_ = $t->compile(template => $_, raw => 1);
		}
		$content = join(', ', @lines);
		$final = $text_prefix.'->get('.$id.",$content)";
	} else {
		$final = $text_prefix.'->get('.$id.')';
	}

	$self->{raw} ? $t->add_to_raw($final) : $t->add_to_compiled("push \@p,$final;");
}

1;
