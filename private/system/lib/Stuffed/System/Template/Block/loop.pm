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

# History
# 1.1 — renamed internal special loop variables (like "loop_first") to start with __

$defs->{loop} = {
	pattern	=> qr/^\s*([^=\s\%]+)(?:\s+as\s+([^=\s\%]+))?(?:\s+(steps|one_step)\s*=\s*"?(.+?)"?)?\s*$/o,
	handler	=> \&loop,
	version	=> 1.1,
};

sub loop {
	my $self = shift;
	my $in = {
		params	=> undef,
		content	=> undef,
		@_	
	};
	my $t = $self->{template};
	my ($params, $content) = map { $in->{$_} } qw(params content);
	return if not $params;

	my ($var, $as, $step_type, $steps) = @$params;

	$as = true($as) ? $as : $var;

	my $compiled = '';

	my $as_code = $t->compile(template => $as, tag_start => '', tag_end => '', raw => 1);
	if ($as_code !~ /^\$v/) {
		die
		  "Tag [ $as_code ] can't be used as a variable in the loop in template [ $t->{tmplname} ]!\n";
	}

	$compiled .= 'my $var='. $t->compile(template => $var, tag_start => '', tag_end => '', raw => 1).';';
	$compiled .= 'if (ref $var eq \'ARRAY\') {';

	# saving original var
	$compiled .= "my \$saved=$as_code;$as_code=undef;";

	$steps = $t->compile(template => $steps, tag_start => '<', tag_end => '>', raw => 1) if true($steps);

	if ($step_type eq 'steps') {
		$compiled .= $as_code.'={};';

		$compiled .= 'my $loop=[@$var];';

		$compiled .= 'my $st='.$steps.';';
		$compiled .= 'my $counter=0;my $all_counter=0;my $loop_length=@$loop;';
		$compiled .= 'while(@$loop) {';

		# calculating how many records should be in the current step
		$compiled .= 'my $r=@$loop/$st;';
		$compiled .= 'my $steps=($r<=int($r)?int($r):int($r)+1);';

		# decreasing step
		$compiled .= '$st--;';

		# setting special loop variables
		$compiled .= $as_code.'->{__loop_length}=$loop_length;';
		$compiled .= $as_code.'->{__loop_first}=1 if @$loop == @$var;';
		$compiled .= $as_code.'->{__loop_odd}=1 if ++$counter%2;';
		$compiled .= $as_code.'->{__loop_idx}=++$all_counter;';

		# creating new loop variable
		$compiled .= $as_code . '->{step}=[splice @$loop,0,$steps];';

		$compiled .= $as_code.'->{__loop_last}=1 if @$loop == 0;';

		$compiled .= $t->compile(template => $content);

		$compiled .= 'delete '.$as_code.'->{__loop_length};';
		$compiled .= 'delete '.$as_code.'->{__loop_first};';
		$compiled .= 'delete '.$as_code.'->{__loop_odd};';
		$compiled .= 'delete '.$as_code.'->{__loop_idx};';
		$compiled .= 'delete '.$as_code.'->{__loop_last};';
		$compiled .= '}';

		# restoring original var
		$compiled .= "$as_code=\$saved;";
	}
	elsif ($step_type eq 'one_step') {
		$compiled .= $as_code.'={};';
		$compiled .= 'my $loop = [@$var];';
		$compiled .= 'my $counter=0;my $all_counter=0;my $loop_length=@$loop;';
		$compiled .= 'while (@$loop) {';

		# setting special loop variables
		$compiled .= $as_code.'->{__loop_length}=$loop_length;';
		$compiled .= $as_code.'->{__loop_first}=1 if @$loop == @$var;';
		$compiled .= $as_code.'->{__loop_odd}=1 if ++$counter%2;';
		$compiled .= $as_code.'->{__loop_idx}=++$all_counter;';

		# creating new loop variable
		$compiled .= $as_code.'->{step}=[splice @$loop,0,'.$steps.'];';

		$compiled .= $as_code.'->{__loop_last}=1 if @$loop == 0;';

		# adding empty variable hashes so that number of array elements will be
		# equal to $step_value
		$compiled .= 'for (my $i=@{'.$as_code.'->{step}};$i<'.$steps.';$i++) {';
		$compiled .= 'push @{'.$as_code.'->{step}}, {};';
		$compiled .= '}';

		$compiled .= $t->compile(template => $content);

		$compiled .= 'delete '.$as_code.'->{__loop_length};';
		$compiled .= 'delete '.$as_code.'->{__loop_first};';
		$compiled .= 'delete '.$as_code.'->{__loop_odd};';
		$compiled .= 'delete '.$as_code.'->{__loop_idx};';
		$compiled .= 'delete '.$as_code.'->{__loop_last};';

		$compiled .= '}';

		# restoring original var
		$compiled .= "$as_code = \$saved;";
	}
	else {

		# setting special loop variables
		$compiled .= 'if (ref $var->[0]) {$var->[0]{__loop_first}=1;';
		$compiled .= '$var->[$#$var]{__loop_last}=1;}';

		$compiled .= 'my $counter=0;my $loop_length=@$var;';
		$compiled .= 'foreach my $element (@$var){';
		$compiled .= 'if (ref $element) {';
		$compiled .= '$element->{__loop_length}=$loop_length;';
		$compiled .= '$element->{__loop_odd}=1 if ++$counter%2;';
		$compiled .= '$element->{__loop_idx}=$counter;}';
		$compiled .= "$as_code=\$element;";
		$compiled .= $t->compile(template => $content);
		$compiled .= '}';

		# deleting special variables
		$compiled .= 'if (ref $var->[0]) {delete $var->[0]{__loop_first};';
		$compiled .= 'delete $var->[$#$var]{__loop_last};}';

		# restoring original var
		$compiled .= "$as_code=\$saved;";
	}

	$compiled .= '}';

	$t->add_to_compiled($compiled);
}

1;
