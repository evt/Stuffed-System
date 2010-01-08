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

package Stuffed::System::DBIDebug;

$VERSION = 1.0;

use strict;

use base 'Exporter';
our @EXPORT_OK = qw(
	&strings_exist_in_query &get_query_type &clean_filename &check_debug_db 
	&handle_debug_db_output
);

use Stuffed::System;

sub handle_debug_db_output {
	# this will return back on ajax requests
	#return if $system->out->context ne 'web';
	
	require Stuffed::System::Utils;
	
	my $threshold_secs = $system->config->get('warning_query_secs');

	my $stash = $system->stash('__dbi_all_queries') || [];
	
	my $html;

	for (my $rec_num = 0; $rec_num < scalar @$stash; $rec_num++) {
		my $record = $stash->[$rec_num];

		my $query = $record->{query};
		$query =~ s/^\s+|\s+$//gs;
		$query =~ s/[\r\n]/<br>/g;
		$query = Stuffed::System::Utils::quote($query);

		my $caller = $record->{'caller'};
		my $file = clean_filename($caller->[1]);

		my $stack = $record->{'stack'} || [];

		my $sub = '';

		if ($stack and @$stack) {
			$sub = "<a href=\"javascript:;\" onclick=\"document.getElementById(\\'stack_$rec_num\\').style.display = (document.getElementById(\\'stack_$rec_num\\').style.display == \\'none\\' ? \\'\\' : \\'none\\')\">$caller->[3]()</a>";
		} else {
			$sub = '<b>'.$caller->[3].'()</b>';
		}

		$html .= "debug.document.write('<span class=\"query_comment;\">$sub</span><br>');\n";

		if ($stack and @$stack){
			$html .= "debug.document.write('<div id=\"stack_$rec_num\" style=\"display: none;\">');\n";
			for (my $i = 0; $i < scalar @$stack; $i++) {
				my $frame = $stack->[$i];
				my $sub = ($stack->[$i+1] ? $stack->[$i+1][3].'()' : 'main()');

				my $file = clean_filename($frame->[1]);
				$html .= "debug.document.write('<span class=\"query_comment\">$sub, $file line $frame->[2];</span><br>');\n";
			}
			$html .= "debug.document.write('</div>');\n";
		}

		my $style = '';
		if ($threshold_secs and $record->{secs} > $threshold_secs) {
			$style = ' class="query_warn"';
		}
		$html .= "debug.document.write('<span$style>'+$query+';</span><br>');\n";

		$html .= "debug.document.write('<span class=\"query_comment\">$record->{secs} secs ($record->{rows} row".($record->{rows} == 1 ? '' : 's').")</span><br><br>');\n";
	}

	my $total_secs = $system->stash('__dbi_total_queries_time') || 0;

	$html = <<JS;
<script type="text/javascript">
var debug = window.open('about:blank', '_blank', 'width=900, height=700, scrollbars=1');
debug.document.open('text/html');
debug.document.write('<html>');
debug.document.write('<style>.query_warn {color: #c93;} .query_comment { font-size: 11px; color: #aaa; }</style>');
debug.document.write('<script type="text/javascript">function switchStack(id) { document.getElementById(id).style.display = (document.getElementById(id).style.display == \\\'none\\\' ? \\\'\\\' : \\\'none\\\') }</s'+'cript>');
debug.document.write('<body bgcolor="#f5f5f5"><pre>');
debug.document.write('<h2>$ENV{REQUEST_URI}</h2>Total execution time: $total_secs secs<br><br>');
$html
debug.document.write('</pre></body></html>');
debug.document.close();
</script>
JS

	$system->out->say($html);
}

sub check_debug_db {
	my $in_query = $system->in->query('__debug_db');
	my $in_cookie = $system->in->cookie('__debug_db');
	
	# a request to switch debugging off
	if (true($in_query) and $in_query == 0) {
		$system->out->cookie(name => '__debug_db', value => '', expires => '-30d') if $in_cookie;
		return undef;
	}
	
	return undef if not $in_query and not $in_cookie;
	
	my $ips = $system->config->get('allow_debug_db_ips');

	# no IPs allowed to use the debugging - debugging is switched off
	if (ref $ips ne 'ARRAY' or not @$ips) {
		$system->out->cookie(name => '__debug_db', value => '', expires => '-30d') if $in_cookie;
		return undef;
	}
	
	# better not to get the IP from the user object as we are only initing the database connection 
	# at this point and thus we can easily get in the recursion
	require Stuffed::System::Utils;
	my $current_ip = Stuffed::System::Utils::get_ip();
	
	my %ip_idx = map { $_ => 1 } @$ips;
	return undef if not $ip_idx{$current_ip}; 

	# debugging is allowed, switching it on;
	$system->out->cookie(name => '__debug_db', value => 1);
	return 1;
}

sub strings_exist_in_query {
	my $query = shift;
	my $strings = shift;
	return undef if ref $strings ne 'ARRAY' or not @$strings;

	my $exists = undef;

	foreach my $string (@$strings) {
		next if index($query, $string) < 0;
		$exists = 1;
		last;
	}

	return $exists;
}

sub get_query_type {
	my $query = shift;
	my $in = {
		# proper will correctly work with comments above the actual query, 
		# but it is around 14 times slower then the simple version		
		proper => undef,
		@_
	};

	my $type;

	if ($in->{proper}) {
		my @lines = split(/\n+/, $query);
		my $first_line;
		foreach my $line (@lines) {
			$line =~ s/^\s+//;
			next if $line eq '';
			my $chr = substr($line, 0, 1);
			next if $chr eq '#' or $chr eq '-';
			$first_line = $line;
			last;
		}

		my $space_pos = index($first_line, ' ');
		$type = lc(substr($first_line, 0, $space_pos));
	} else {
		my ($query_type) = $query =~ /^\s*(\S+)\s*/;
		$type = lc($query_type);
	}

	return $type;
}

sub clean_filename {
	my $file = shift;
	my $path = $system->path;
	$file =~ s/\s+\(autosplit[^\)]+\)//;
	$file =~ s/$path//;
	$file =~ s/\.\//\//;

	# windows paths
	$file =~ s/\\/\//g;
	return $file;
};

1;