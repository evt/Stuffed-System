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

use Stuffed::System::Utils qw(&quote);

$defs->{stash} = {
	pattern	=> qr/^stash\.([^\.]+)(?:\.(.+))?$/o,
	handler	=> \&stash,
	version	=> 1.0,
};

sub stash {
	my $self = shift;
	return if not $self->{params} or ref $self->{params} ne 'ARRAY';

	my $var = $self->{params}[0];
	my $tail = $self->{params}[1];
	my $parsed_var = $self->{template}->compile(
		template	=> $var,
		tag_start	=> '<',
		tag_end		=> '>',
		raw			=> 1,
	  );
	my $parsed_tail;
	if (true($tail)) {
		$parsed_tail = join('->', map {
				'{'.$self->{template}->compile(template => $_, tag_start => '<', tag_end => '>', raw => 1).'}'
			  } split(/\./, $tail));
	}
	return $self->optimize('($system->stash('.$parsed_var.')'.($parsed_tail ? "||{})->$parsed_tail" : ')'));
}

1;
