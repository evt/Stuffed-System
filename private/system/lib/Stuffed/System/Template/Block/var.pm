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

$defs->{var} = {
	pattern	=> qr/\s*\$([^=\s\%]+)(?:\s+([^\$]+))?\s*/o,
	single	=> 1,
	handler	=> \&var,
	version	=> 1.0,
};

my $not_complex;

sub var {
	my ($self, $final) = (shift, undef);
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $t = $self->{template};

	while (@{$self->{params}}) {
		my ($var, $params) = splice @{$self->{params}}, 0, 2;

		my $mods = [];

		if ($params) {
			push @$mods, {type => $1, param => $2} while $params =~ /([^=\s]+)="([^"]+)"/g;
		}

		my ($parsed, $complex);

		# potential complex var
		# note: we aslo create a cache of the complex vars that do not exist
		if (($complex) = $var =~ /([^\.]+)\./ and not $not_complex->{$complex}) {
			my $o = $t->variable(type => $complex, exp => $var);
			$o ? ($parsed = $o->handle) : ($not_complex->{$complex} = 1);
		}

		# tricky logic below to handle nested variables in this variable
		# most trouble appear becase we might have a nested variable wich
		# will use dot inside to specify several levels that we need to support
		if (not defined $parsed) {
			$var = $t->compile(
				template  => $var,
				tag_start => '<',
				tag_end   => '>',
				raw       => 1,
			  );

			my $parts = [split(/'\.|\.'/, $var)];

			my @line = ();
			my $final_parts = [];
			foreach my $part (@$parts) {
				if ($part !~ /^\$/) {
					$part = "'$part" if $part !~ /^'/;
					$part = "$part'" if $part !~ /'$/;
					my @inside = split(/\./, $part);
					if (@inside > 1) {
						my $first = (shift @inside) . "'";
						push @line, $first;
						push @$final_parts, join('.', @line);
						foreach my $one (@inside) {
							$one = "'$one" if $one !~ /^'/;
							$one = "$one'" if $one !~ /'$/;
							push @$final_parts, $one;
						}
						@line = ();
					} else {
						push @line, $part;
					}
				} else {
					push @line, $part;
				}
			}

			push @$final_parts, join('.', @line) if @line;

			$parsed = "\$v";
			for (my $i = 0; $i < scalar @$final_parts; $i++) {
				my $line = $final_parts->[$i];
				$parsed .= ($i == 0 ? '->' : '')."{$line}";
			}
		}

		if (true($parsed)) {
			# with forced encode_html, decode_html modifier just means no forced encode_html
			my $asked_for_decode;

			my (@before_encode_html, @after_encode_html);

			foreach my $mod (@$mods) {
				if ($mod->{type} eq 'decode_html') {
					$asked_for_decode = 1;
					next;					
				}
				next if $mod->{type} eq 'encode_html';
				
				my $modifier = $t->modifier(type => $mod->{type}, param => $mod->{param});
				if ($modifier->{before_encode_html}) {
					push @before_encode_html, $modifier;
				} else {
					push @after_encode_html, $modifier;
				}
			}
			
			# forcing encode_html, unless a decode_html modifier was also specified,
			# current solution is based on checking for the 'raw' flag which is passed when the variable
			# is parsed as a part of another handler, it might be that this will not be sufficient for
			# encoding html in all proper places (although the tests so far showed that everything works 
			# as needed), in that case a new paramater could be added similar to 'raw' and on the same level
			# and for example loop will pass it and ask not to encode, because encode particularly for loop
			# doesn't make sense at all, if this solution with raw will have problems, we can try using
			# this other idea then.
			
			$parsed = $_->handle($parsed) for @before_encode_html;
			
			if (not $self->{raw} and not $asked_for_decode) {
				$parsed = $t->modifier(type => 'encode_html', param => 1)->handle($parsed);
			}

			$parsed = $_->handle($parsed) for @after_encode_html;
						
			if ($params and $params =~ /^or(?:\s+(["'])([^\1]+)\1)?/) {
				$final .= "true($parsed) ? $parsed : ";
				$final .= Stuffed::System::Utils::quote($2) if defined $2;
			} else {
				$final .= $parsed;
			}
		}
	}

	if (true($final)) {
		$self->{raw} ? $t->add_to_raw($final) : $t->add_to_compiled("push \@p,$final;");
	}
}

1;