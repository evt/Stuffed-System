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

package Stuffed::System::Utils;

$VERSION = 1.00;

use strict;
use utf8;

use base 'Exporter';
our @EXPORT_OK = qw(
	&decode_url &encode_url &addnl2br &br2nl &check_email &email_is_valid &clone &convert_time
	&cp &create_dirs &create_random &decode_html &dump &encode_html &in_array
	&match &name2url &nl2br &nl2space &parse_urls &produce_code &quote &get_ip
	&prepare_float &encode_xml &decode_xml &match_strings &format_thousands
	&text_format &title_case &time_elapsed &cut_string
	&resize_image &pub_file_mod_time &strip_js_comments &clean_html
	&prepare_file_size &add_param_to_url &create_pages &get_number_suffix
	&get_hash_cookie &set_hash_cookie &discover_functions &html_entities
	&get_url_param &convert_from_json &convert_to_json &get_guest_country_code
	&extract_paths_from_html &merge_files_together &plural_ru &get_image_info
);

use Stuffed::System;

sub decode_url {
	my ($string) = @_;
	return "" if not defined $string;
	
	$string =~ tr/+/ /;
	$string =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
	utf8::decode($string);
	$string =~ s/\r\n/\n/g;
	
	return $string; 
}

sub encode_url {
	my ($string) = @_;
	return "" if not defined $string;

	utf8::encode($string);
	$string =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/ge;
	
	return $string;
}

sub get_ip {
	my $ip;

	if ( $ENV{HTTP_X_FORWARDED_FOR} ) {
		($ip) = split( /\s*,\s*/, $ENV{HTTP_X_FORWARDED_FOR} );
	}
	if ( $ip !~ /^\d+\.\d+\.\d+\.\d+$/ ) {
		$ip = $ENV{REMOTE_ADDR};
	}
	if ( $ip !~ /^\d+\.\d+\.\d+\.\d+$/ ) {
		$ip = '0.0.0.0';
	}
	return $ip;
}

sub html_entities {
	my $string          = shift;
	my $chars_to_encode = shift;
	return undef if false($string);

	require HTML::Entities;
	return $chars_to_encode
	  ? HTML::Entities::encode_entities( $string, $chars_to_encode )
	  : HTML::Entities::encode_entities($string);
}

#use AutoLoader 'AUTOLOAD';
#__END__

# stolen from 
# http://search.cpan.org/~andy/Lingua-Ru-Numeric-Declension-1.1/lib/Lingua/RU/Numeric/Declension.pm
sub plural_ru {
  my ($number, $plural, $nominative, $genitive) = @_;

  return $plural if $number =~ /1.$/;

  my ($last_digit) = $number =~ /(.)$/;

  return $nominative if $last_digit == 1;
  return $genitive if $last_digit > 0 && $last_digit < 5;
  return $plural;	
}

sub merge_files_together {

	# this is used in the md5 name of the merged file
	my $merger_version = '1.00';

	# structure returned by "extract_paths_from_html" function
	my $groups = shift;
	return '' if not $groups;

	my $site_root = $system->stash('__calculated_site_root');
	if ( not $site_root ) {
		my $pub_path = $system->config->get('public_path');
		my $pub_url  = quotemeta( $system->config->get('public_url') );
		( $site_root = $pub_path ) =~ s/$pub_url$//;

		$system->stash( __calculated_site_root => $site_root );
	}

	require Digest::MD5;

	my @lines;
	my @create_files;

	my $system_path = $system->pkg('system')->__public_path . '/merged';
	my $system_url  = $system->pkg('system')->__public_url . '/merged';

	foreach my $type (qw(css js)) {
		next if not $groups->{$type};

		foreach my $group_id ( keys %{ $groups->{$type} } ) {
			if ( $group_id eq 'as_is' ) {
				push @lines, @{ $groups->{$type}{as_is} };
				next;
			}

			my ( $latest_m, @files, $last_file );

			foreach my $path ( @{ $groups->{$type}{$group_id} } ) {
				my $file_path = $path->{ ( $type eq 'css' ? 'href' : 'src' ) };

				# cleaning the path to file from potential URL parameters, this has
				# be done at this stage AGAIN because the path can contain template
				# variables, which would only be substituted when the template is
				# actually PARSED and this function is called
				$file_path =~ s/\?.+$//;

				my $full_path = $site_root . $file_path;

				# convert to as_is
				if ( not -r $full_path ) {
					if ( $type eq 'css' ) {
						push @lines,
						    '<link href='
						  . quote( $path->{href}, start => '"' )
						  . " $path->{all_attr}>";
					}
					elsif ( $type eq 'js' ) {
						push @lines,
						    '<script src='
						  . quote( $path->{src}, start => '"' )
						  . " $path->{all_attr}></script>";
					}
					next;
				}

				my $m = ( stat($full_path) )[9];
				$latest_m = $m if not $latest_m or $latest_m < $m;

				$last_file = $path;

				push @files, $file_path;
			}

			next if not @files;

			my $merged_file_name =
			  Digest::MD5::md5_hex( join( ' - ', @files, $merger_version ) )
			  . ".$type";
			my $merged_full_name = $system_path . '/' . $merged_file_name;
			my $merged_m         = ( stat($merged_full_name) )[9];

			# regenerate
			if ( not defined $merged_m or $merged_m < $latest_m ) {
				push @create_files,
				  {
					file_name => $merged_file_name,
					full_name => $merged_full_name,
					files     => \@files,
					attr      => $last_file->{all_attr},
					type      => $type,
				  };
			}
			else {
				if ( $type eq 'css' ) {
					push @lines,
					    '<link href="'
					  . $system_url . '/'
					  . $merged_file_name . '?__m='
					  . $merged_m . '" '
					  . $last_file->{all_attr} . '>';
				}
				elsif ( $type eq 'js' ) {
					push @lines,
					    '<script src="'
					  . $system_url . '/'
					  . $merged_file_name . '?__m='
					  . $merged_m . '" '
					  . $last_file->{all_attr}
					  . '></script>';
				}
			}
		}
	}

	if (@create_files) {
		create_dirs($system_path) if not -d $system_path;

		require Stuffed::System::File;

		foreach my $file (@create_files) {
			my @all;
			foreach my $file_name ( @{ $file->{files} } ) {
				my $f = Stuffed::System::File->new( $site_root . $file_name, 'r', {is_text => 1} ) || 
					die "Can't open file $site_root$file_name for reading during merging operation: $!";
				my $contents = $f->contents;
				$f->close;

				# checking if contents have a new line in the end on ; as the last
				# non-space character, adding new line if required
				if ( $file->{type} eq 'js'
					 and $contents !~ /[\015\012]+$/
					 and $contents !~ /;\s*$/ )
				{
					$contents .= "\n";
				}

#				push @all, "/* $file_name */", $contents;
				push @all, $contents;
			}

			my $f = Stuffed::System::File->new( $file->{full_name}, 'w', {is_text => 1} )
			  || die "Can't create file $file->{full_name}: $!";
			$f->print( join( '', @all ) )->close;
			my $m = time();

			if ( $file->{type} eq 'css' ) {
				push @lines,
				    '<link href="'
				  . $system_url . '/'
				  . $file->{file_name} . '?__m='
				  . $m . '" '
				  . $file->{attr} . '>';
			}
			elsif ( $file->{type} eq 'js' ) {
				push @lines,
				    '<script src="'
				  . $system_url . '/'
				  . $file->{file_name} . '?__m='
				  . $m . '" '
				  . $file->{attr}
				  . '></script>';
			}
		}
	}

	return join( "\n", @lines );
}

sub extract_paths_from_html {
	my $in = {
			   html     => undef,
			   tmpl_obj => undef,
			   @_
	};
	my $html     = $in->{html};
	my $tmpl_obj = $in->{tmpl_obj};
	return undef if false($html) or not $tmpl_obj;

	require HTML::TreeBuilder;
	my $tree = HTML::TreeBuilder->new_from_content($html);

	my @js  = $tree->look_down( _tag => 'script' );
	my @css = $tree->look_down( _tag => 'link' );

	return undef if not @js and not @css;

	require Digest::MD5;
	require Data::Dumper;

	my $groups;
	my $attr_skip = {
					  js => {
							  '/' => 1,
							  src => 1,
					  },
					  css => {
							   '/'  => 1,
							   href => 1,
					  },
	};

	my @as_is;

	foreach my $element (@js) {
		my $path = { $element->all_external_attr };

		my $cleaned_path;

		$cleaned_path->{all_attr} = join( ' ',
							  map { $_ . '=' . quote( $path->{$_}, start => '"' ) }
							  grep { not $attr_skip->{js}{$_} } keys %$path );
		delete $cleaned_path->{all_attr} if false( $cleaned_path->{all_attr} );

		# checking immediately if the full URL is specified as a path
		if ( $path->{src} =~ /^https?:\/\// ) {
			push @as_is, $element->as_HTML('');
			next;
		}

		# cleaning the path to file from potential URL parameters
		$path->{src} =~ s/\?.+$//;

		$cleaned_path->{src} = sub {
			$tmpl_obj->compile( template => $path->{src}, raw => 1 );
		};

		my $group_id =
		  Digest::MD5::md5_hex(
						  Data::Dumper::Dumper(
							  {
								map { $_ => $path->{$_} }
								grep { not $attr_skip->{js}{$_} } keys %$path
							  }
						  )
		  );

		push @{ $groups->{js}{$group_id} },
		  {
			element => $element,
			path    => $cleaned_path,
		  };
	}

	foreach my $element (@css) {
		my $path = { $element->all_external_attr };

		my $cleaned_path;

		$cleaned_path->{all_attr} = join( ' ',
							 map { $_ . '=' . quote( $path->{$_}, start => '"' ) }
							 grep { not $attr_skip->{css}{$_} } keys %$path );
		if ( true( $cleaned_path->{all_attr} ) ) {
			$cleaned_path->{all_attr} .= $path->{'/'};
		}
		else {
			delete $cleaned_path->{all_attr};
		}

		# checking immediately if the full URL is specified as a path
		if ( $path->{href} =~ /^https?:\/\// ) {
			push @as_is, $element->as_HTML('');
			next;
		}

		# cleaning the path to file from potential URL parameters
		$path->{href} =~ s/\?.+$//;

		$cleaned_path->{href} = sub {
			$tmpl_obj->compile( template => $path->{href}, raw => 1 );
		};

		my $group_id =
		  Digest::MD5::md5_hex(
						 Data::Dumper::Dumper(
							 {
							   map { $_ => $path->{$_} }
							   grep { not $attr_skip->{css}{$_} } keys %$path
							 }
						 )
		  );

		push @{ $groups->{css}{$group_id} },
		  {
			element => $element,
			path    => $cleaned_path,
		  };
	}

	# if only one file in any group, move it to as_is, no sense to create one
	# file, only with that file contents inside
	foreach my $type (qw(js css)) {
		next if not $groups->{$type};

		foreach my $group_id ( keys %{ $groups->{$type} } ) {
#			if ( @{ $groups->{$type}{$group_id} } > 1 ) {
				$groups->{$type}{$group_id} =
				  [ map { $_->{path} } @{ $groups->{$type}{$group_id} } ];
#				next;
#			}

#			my $element = $groups->{$type}{$group_id}[0]{element};
#			push @as_is, $element->as_HTML('');
#
#			delete $groups->{$type}{$group_id};
		}

		delete $groups->{$type} if not %{ $groups->{$type} };
	}

	my $system_path = $system->pkg('system')->__public_path . '/merged';
	create_dirs($system_path) if not -d $system_path;

	# removing merged files that are older then threshold, if some of the
	# files are still required, they would be regenerated automatically
	my $threshold_sec = time() - 24 * 60 * 60 * 7;    # 7 days

	opendir( DIR, $system_path )
	  || die "Can't open merge directory [ $system_path ] for reading: $!";
	my @old_files = map { "$system_path/$_" } grep {
		      $_ !~ /^\.+$/
		  and -f "$system_path/$_"
		  and ( stat("$system_path/$_") )[9] < $threshold_sec
	} readdir(DIR);
	closedir(DIR);

	unlink for @old_files;

	return ( join( '', @as_is ), $groups );
}

# Stolen from http://www.perl.com/pub/a/2005/02/03/rpc_design.html?page=3
sub discover_functions {
	my $in = {
		'package' =>
		  undef
		, # optional, look for functions in this package, otherwise will look in the caller's package
		'prefix' =>
		  undef
		,    # optional, prefix that function that would be returned should have
		@_
	};
	my $package = $in->{'package'}
	  || caller();    # get the package name of the caller
	my $prefix = $in->{prefix};    # optional prefix
	my %map;

	# disable check for symbolic references
	no strict 'refs';

	# loop over all entries in the caller package's namespace
	while ( my ( $k, $v ) = each %{ $package . '::' } ) {
		my $sym = $package . '::' . $k; # construct the full name of each symbol
		next unless $k =~ /^$prefix/;  # allow only entries starting with prefix
		my $r = *{$sym}{'CODE'};       # take reference to the CODE in the glob
		next unless $r;    # reference is empty, no code under this name, skip
		$map{$k} = $r;     # reference points to CODE, assign it to the map
	}

	return ( %map ? \%map : undef );
}

sub create_pages {
	my $in = {
		total           => undef,    # total records
		page            => undef,    # currently chosen page
		per_page        => undef,    # records per page
		show            => undef,    # how many pages to show (optional)
		first_page_name => undef,    # name of the first page (optional)
		last_page_name  => undef,    # name of the last page (optional)
		@_
	};
	my $total    = $in->{total};
	my $page     = $in->{page};
	my $per_page = $in->{per_page};
	my $show     = $in->{show};

	my $first_page_name = $in->{first_page_name};
	$first_page_name = 'First' if false($first_page_name);

	my $last_page_name = $in->{last_page_name};
	$last_page_name = 'Last (%s)' if false($last_page_name);

	my $pages;

	my $results      = 0;
	my $current_page = 1;
	while ( $results < $total ) {
		push @$pages,
		  {
			num     => $current_page,
			name    => $current_page,
			current => ( $page == $current_page ? 1 : undef )
		  };
		++$current_page;
		$results += $per_page;
	}

	return undef if not $pages;

	if ( scalar @$pages == 1 ) {
		$pages = undef;
	}
	elsif ( $show and scalar @$pages > $show ) {
		my $add_first;
		my $last_page = $pages->[-1];
		my $show_half = int( $show / 2 );

		# "first" page
		if ( $page >= $show_half ) {
			if ( $last_page->{num} - $page >= $show_half ) {
				splice( @$pages, 0, $page - $show_half );
			}
			else {
				splice( @$pages, 0, -$show );
			}
			$add_first = 1;
		}

		# "last" page
		if ( scalar @$pages >= $show + 1 ) {
			splice( @$pages, $show, -1 );
			$last_page->{name} = sprintf( $last_page_name, $last_page->{num} );
		}

		# re-adding the first page here to make the last page calculations
		# easier above
		unshift @$pages,
		  {
			num  => 1,
			name => sprintf( $first_page_name, 1 ),
		  }
		  if $add_first;
	}

	return $pages;
}

sub add_param_to_url {
	my $in = {
		url   => undef,
		param => undef,    # ex. sid=value
		@_
	};
	my $url   = $in->{url};
	my $param = $in->{param};
	return $url if false($url) or false($param);

	my ($param_name) = $param =~ /^([^=]+)/;
	return $url if false($param_name);

	my $q_param_name = quotemeta($param_name);

	# removing the same param from the URL
	$url =~ s/\&?$q_param_name=[^\&#\$]+//gi;

	$param = ( index( $url, '?' ) > -1 ? '&' : '?' ) . $param;
	if ( $url =~ /#/ ) {
		$url =~ s/#/$param#/;
	}
	else {
		$url .= $param;
	}

	return $url;
}

# ==============================================================================

sub get_url_param {
	my $url   = shift || return;
	my $param = shift || return;
	require URI;
	require URI::QueryParam;
	my $uri = URI->new($url);
	return if not $uri;
	return $uri->query_param($param);
}

# ==============================================================================

sub pub_file_mod_time {
	my $url = shift;
	return undef if false($url);

	my $site_root = $system->stash('__calculated_site_root');

	if ( not $site_root ) {
		my $pub_path = $system->config->get('public_path');
		my $pub_url  = quotemeta( $system->config->get('public_url') );
		( $site_root = $pub_path ) =~ s/$pub_url$//;

		$system->stash( __calculated_site_root => $site_root );
	}

	my $file_path = $site_root . $url;
	return $url if not -f $file_path;

	$url .=
	  ( $file_path =~ /\?/ ? '&' : '?' ) . '__m=' . ( stat($file_path) )[9];

	return $url;
}

=head1 time_elapsed($seconds)

Returns a human readable string of how much time has elapsed based on the
provided seconds.

=cut
sub time_elapsed {
	my $elapsed = shift;
	my $in = {
			   no_secs => undef,
			   @_
	};
	my $no_secs = $in->{no_secs};
	if ( not $elapsed ) {
		return ( $no_secs ? '0 mins' : '0 secs' );
	}

	my $hours = int( $elapsed / 60 / 60 );
	my $mins  = int( $elapsed / 60 ) - $hours * 60;

	# seconds could be fractional, so we use int on their value too
	my $secs = int( $elapsed - ( int( $elapsed / 60 ) * 60 ) );

	my $msg;
	if ( $hours > 0 ) {
		$msg .= "$hours hour" . ( $hours != 1 ? 's' : '' );
		$msg .= ' ' if $mins > 0 or $secs > 0;
	}
	if ( $mins > 0 or ( $hours > 0 and $secs > 0 ) ) {
		$msg .= "$mins min" . ( $mins != 1 ? 's' : '' );
		$msg .= ' ' if $secs > 0;
	}
	if ( $secs > 0 and not $no_secs ) {
		$msg .= "$secs sec" . ( $secs != 1 ? 's' : '' );
	}

	if ( $no_secs and false($msg) ) {
		$msg = '0 mins';
	}

	return $msg;
}

sub format_thousands {
	my $num = shift;
	return $num if not $num or length($num) <= 3;

	my ($fraction) = $num =~ /(\.\d+)$/;
	if ( true($fraction) ) {
		$num =~ s/\.\d+$//g;
	}
	else {
		$fraction = '';
	}

	my $temp_line_str;
	my @chars = split( '', $num );
	while ( @chars > 3 ) {
		my $order3 = pop(@chars);
		$order3 = pop(@chars) . $order3;
		$order3 = pop(@chars) . $order3;

		$temp_line_str = ',' . $order3 . $temp_line_str;
	}

	return join( '', @chars ) . $temp_line_str . $fraction;
}

=head1 prepare_float($float_value)

Prepares float value (usually) submitted via a web form for saving in the database.

=cut
sub prepare_float {
	my $value = shift @_;
	return if not defined $value;

	$value =~ s/,/\./g;
	$value =~ s/[^\d\.]//g;

	return $value;
}

sub addnl2br {
	my @strings = @_;
	return if not @strings;
	foreach (@strings) { next if not defined; s/<br\/?>/<br\/>\n/sg; }
	return wantarray ? @strings : $strings[0];
}

sub br2nl {
	my @strings = @_;
	return if not @strings;
	foreach (@strings) { next if not defined; s/<br>/\n/sg; }
	return wantarray ? @strings : $strings[0];
}

sub email_is_valid { check_email(@_) }

sub check_email { ( $_[0] || return ) =~ /^[^\@\s,;]+\@[^\.\s,;]+\.[^\s,;]+$/ }

=head1 clone

Makes complete copy of the data structure. Uses Storable which should be
installed.

=cut
sub clone {
	my $data = shift;
	return $data if not ref $data;

	require Storable;
	return Storable::dclone($data);
}

=head1 convert_time I<direction>, I<time>

Can convert time between three zones: system, user and gmt. Prefers to use 
$system->user->profile('timezone') to get user's timezone. If false value 
will be returned (possibly, user.cookie pkg is used) then it takes the 
value from $system->config->get('users_timezone').

One of these variables must be defined.

Example:

    # to save the time in the db in gmt format
    Stuffed::System::Utils::convert_time('sys2gmt'); 

    # converts time from the db to user's local time
    Stuffed::System::Utils::convert_time('gmt2usr', $time_from_db);

    # converts time from user's localtime to gmt 
    Stuffed::System::Utils::convert_time('usr2gmt', $time_from_user);

=cut
sub convert_time {
	my ( $direction, $time ) = @_;
	return if not $direction;
	$time = time if $direction =~ /^sys2gmt|sys2usr$/;
	return if not $time;

	my ( $sys_zone, $usr_zone ) = ( 0, 0 );

	return $time - ( $sys_zone * 60 * 60 ) if $direction eq 'sys2gmt';
	return $time - ( ( $sys_zone - $usr_zone ) * 60 * 60 )
	  if $direction eq 'sys2usr';
	return $time + ( $sys_zone * 60 * 60 ) if $direction eq 'gmt2sys';
	return $time - ( ( $usr_zone - $sys_zone ) * 60 * 60 )
	  if $direction eq 'usr2sys';
	return $time - ( $usr_zone * 60 * 60 ) if $direction eq 'usr2gmt';
	return $time + ( $usr_zone * 60 * 60 ) if $direction eq 'gmt2usr';
}

sub cp {
	my ( $source, $target ) = @_;

	return if false($source) or false($target);

	# opening files and putting them in the binmode
	my ( $s, $t );

	if ( ref $source ) {
		$s = $source;
		if ( not $s->opened ) {
			$s->open('r')
			  || die "Can't open file [ " . $s->name . " ] for reading: $!";
		}
		elsif ( $s->mode ne 'r' ) {
			die "Source file should be in a read mode!";
		}
	}
	else {
		$s = Stuffed::System::File->new( $source, 'r', {is_binary => 1} )
		  || die "Can't open file [ $source ] for reading: $!";
	}

	if ( ref $target ) {
		$t = $target;
		if ( not $t->opened ) {
			$t->open('w')
			  || die "Can't open file [ " . $s->name . " ] for writing: $!";
		}
		elsif ( $t->mode eq 'r' ) {
			die "Target file should be in a write, append or update mode!";
		}
	}
	else {
		$t = Stuffed::System::File->new( $target, 'w', {is_binary => 1} )
		  || die "Can't open file [ $target ] for writing: $!";
	}

	# initializing the read counter
	my $read = 0;

	# getting size of the source file
	my ( $mode, $size ) = ( stat( $s->name ) )[ 2, 7 ];

	# copying process
	my ( $buffer, $to_read, $left );
	while ( $read < $size ) {
		$left = $size - $read;
		$to_read = ( $left > 4096 ? 4096 : $left );
		sysread $s->handle, $buffer, $to_read;
		syswrite $t->handle, $buffer, length($buffer);
		$read += $to_read;
	}

	# done copying, closing files
	$t->close;
	$s->close;

	chmod( $mode & 0777 ), $t->name;

	return $s, $t;
}

sub create_dirs {
	my ( $path, $mode ) = @_;
	return if false($path);
	$mode ||= 0777;

	my @dirs = grep { $_ ne '' } split( /\//, $path );
	my $newpath = ( substr( $path, 0, 1 ) eq '/' ? '/' : '' );
	foreach my $dir (@dirs) {
		if ( not -d $newpath . $dir ) {
			my $ok = mkdir( $newpath . $dir, $mode );
			if ( not $ok and not -d $newpath . $dir ) {
				die "Can't create \"$newpath$dir\" directory: $!!";
			}
		}
		$newpath .= "$dir/";
	}

	return 1;
}

sub create_random {
	my ($length) = shift @_;
	my $options = {
		letters_lc => undef,    # use lower case letters
		letters_uc => undef,    # use upper case letters
		digits     => undef,    # use digits
		@_
	};
	$length = 20 if not $length;

	my $no_options = 1;
	foreach (qw(letters_lc letters_uc digits)) {
		if ( $options->{$_} ) {
			$no_options = undef;
			last;
		}
	}

	my @chars = ();
	push @chars, ( 'a' .. 'z' ) if $no_options or $options->{letters_lc};
	push @chars, ( 'A' .. 'Z' ) if $no_options or $options->{letters_uc};
	push @chars, ( 0 .. 9 )     if $no_options or $options->{digits};

	my $string;

	for ( my $i = 0 ; $i < $length ; $i++ ) {
		$string .= $chars[ int( rand(@chars) ) ];
	}
	return $string;
}

sub dump {
	my $data    = shift;
	my $options = {@_};
	require Data::Dumper;
	my $dump = Data::Dumper::Dumper($data);

	if ( true( $options->{file} ) ) {
		require Stuffed::System::File;
		my $f = Stuffed::System::File->new( $options->{file}, 'w', {is_text => 1} );
		return undef if not $f;
		$f->print($dump)->close;
		return 1;
	}

	my $result = '<pre>' . $dump . '</pre>';
	return $result if $options->{return};
	$system->out->say($result);
	exit if not $options->{no_exit};
}

sub decode_html {
	my @strings = @_ or return;
	my %html = (
		'&lt;'		=> '<',
		'&gt;'		=> '>',
		'&quot;'	=> '\"',
		'&#39;'		=> '\'',
		'&amp;'		=> '&',
		'&nbsp;'	=> ' ',
	);
	for (grep { defined } @strings) {
		s/(&lt;|&gt;|&quot;|&#39;|&amp;)/$html{$1}/go;
	}
	return wantarray ? @strings : $strings[0];
}

sub encode_html {
	my @strings = @_ or return;
	my %html = (
		'<'		=> '&lt;',
		'>'		=> '&gt;',
		'"'		=> '&quot;',
		'\''	=> '&#39;',
		'\r'	=> '',
		'&'		=> '&amp;',
	);
	for (grep { defined } @strings) {
		s/(<|>|"|'|\r|&)/$html{$1}/go;
	}
	return wantarray ? @strings : $strings[0];
}

sub decode_xml {
	my @strings = @_ or return;
	my %xml = (
		'&lt;'		=> '<',
		'&gt;'		=> '>',
		'&quot;'	=> '\"',
		'&amp;'		=> '&',
	);
	for (grep { defined } @strings) {
		s/(&lt;|&gt;|&quot;|&amp;)/$xml{$1}/go;
	}
	return wantarray ? @strings : $strings[0];
}

sub encode_xml {
	my @strings = @_ or return;
	my %xml = (
		'<'		=> '&lt;',
		'>'		=> '&gt;',
		'"'		=> '&quot;',
		'&'		=> '&amp;',
	);
	for (grep { defined } @strings) {
		s/(<|>|"|&)/$xml{$1}/go;
	}
	return wantarray ? @strings : $strings[0];
}

=head1 in_array I<element>, I<array>

It will check if scalar C<element> exists in the array C<array>.

Returns 1 when the first occurence of the C<element> inside C<array> is 
found. Otherwise returns false (hopefully).

=cut
sub in_array {
	my ( $key, @array ) = @_;
	return undef if not defined $key or not @array;
	foreach (@array) { return 1 if $_ eq $key }
}

# match two hashes (order doesn't matter) or plain variables
# returns 1 if their values (and keys) are identical, 0 otherwise
# returns 1 if both vars are not defined or empty
sub match {
	my ( $var1, $var2 ) = @_;

	# two parameters and not defined, so they match
	return 1 if not defined $var1 and not defined $var2;

	# one is a ref, another is not = no match
	return 0 if not ref $var1 and ref $var2;
	return 0 if not ref $var2 and ref $var1;

	# refs on different things, they don't match
	return 0 if ( ref $var1 and ref $var2 ) and ( ref $var1 ne ref $var2 );

	if ( ref $var1 eq 'HASH' ) {

		# different number of keys in the hash - they don't match
		return 0 if scalar( keys %$var1 ) != scalar( keys %$var2 );

		foreach my $key (%$var1) {
			if ( not ref $var1->{$key} ) {
				return 0 if $var1->{$key} ne $var2->{$key};
			}
			elsif ( not match( $var1->{$key}, $var2->{$key} ) ) {
				return 0;
			}
		}
	}
	elsif ( ref $var1 eq 'ARRAY' ) {

		# different number of elements in array - they don't match
		return 0 if scalar @$var1 != scalar @$var2;

		for ( my $i = 0 ; $i <= $#{$var1} ; $i++ ) {
			if ( not ref $var1->[$i] ) {
				return 0 if $var1->[$i] ne $var2->[$i];
			}
			elsif ( not match( $var1->[$i], $var2->[$i] ) ) {
				return 0;
			}
		}
	}
	elsif ( not ref $var1 ) {
		return 0 if $var1 ne $var2;
	}
	else {

		# a ref that we don't support (we only support HASH and ARRAY)
		return 0;
	}

	return 1;
}

sub name2url {
	my $name = shift;
	return '' if false($name);

	# removing all charachters that are not letters, digits, points, underscores, spaces
	$name =~ s/[^\w\.\d]+/_/g;
	
	# removing underscores in the beginning and end of the string
	$name =~ s/^_+|_+$//g;

	# also forcing lower case
	return lc($name);
}

sub nl2br {
	my @strings = @_;
	return if not @strings;
	foreach (@strings) { next if not defined; s/\n\r?/<br\/>/sg; }
	return wantarray ? @strings : $strings[0];
}

sub nl2space {
	my @strings = @_;
	return if not @strings;
	foreach (@strings) { next if not defined; s/\n\r?/ /sg; }
	return wantarray ? @strings : $strings[0];
}

sub parse_urls {
	my ($string) = @_;
	return if false($string);

	$string =~
	  s/((?:https?|ftp):\/\/[^\s]+)/<a href="$1" target="_blank">$1<\/a>/sg;
	$string =~
	  s/([^\/])(www\.[^\s]+)/$1<a href="http:\/\/$2" target="_blank">$2<\/a>/sg;
	$string =~
	  s/([\.\w\-]+@[\.\w\-]+\.[\.\w\-]+)/<a href="mailto:$1">$1<\/a>/sg;

	return $string;
}

=head1 product_code(ARRAY_REF|HASH_REF, [spaces => 1])

If "spaces" parameter is specified then everything in the data structure
that will be created (keys, values, etc) will be separated with single spaces.
This is more readable and is meant to be used for information that might
be presented to the end user.

If "json" parameter is specified '=>' is substituted with ':' and "undef" with 
"null".

=cut
sub produce_code {
	my ( $data, $options ) = ( shift, {@_} );

	my $space = $options->{spaces} ? ' ' : '';
	my $arrow = $options->{json}   ? ':' : '=>';

	return ( $options->{json} ? 'null' : 'undef' ) if not defined $data;
	if ( false($data) or not ref $data ) {

		# killing new line characters completely, changing them to \n won't make
		# it a new line if that content will be inserted in the final html page,
		# some string.replace(/\\n/g, "\n") would be required as well
		$data =~ s/[\r\n]/ /g if $options->{json};
		return quote($data);
	}

	if ( $options->{allow_blessed} ) {
		delete $options->{allow_blessed} if not eval "require Scalar::Util";
	}

	my $result;
	my $ref_type =
	  ( $options->{allow_blessed} ? Scalar::Util::reftype($data) : ref $data );

	if ( $ref_type eq 'HASH' ) {
		my @items = ();
		foreach ( keys %$data ) {
			push @items,
			    quote($_) 
			  . $space 
			  . $arrow 
			  . $space
			  . produce_code( $data->{$_}, %$options );
		}
		$result = '{' . join( ",$space", @items ) . '}';
	}

	elsif ( $ref_type eq 'ARRAY' ) {
		my @items = ();
		foreach (@$data) {
			push @items, produce_code( $_, %$options );
		}
		$result = '[' . join( ",$space", @items ) . ']';
	}

# if it's a CODE ref, we launch the code an expect it to return the content to us quoted as neccessary
	elsif ( $ref_type eq 'CODE' ) {
		$result = $data->();
	}

	return $result;
}

=head1 quote(STRING, START_QUOTE, [ END_QUOTE ], [ NO_BORDER ])

  # quoting a string with double quotes
  my $str = Stuffed::System::Utils::quote('a string with "double quotes"', start => q("));

  # returns "a string with \"double quotes\""
  print $str;

This is a universal quoting function that can use any two single characters as
quotes. The main purpose of the function is to escape the quoting characters
properly inside the STRING.

End quoting character is optional. If it is not specified, then we use the
start quoting chracter for the end quote.

Start quoting character is optional too. If it is not specified then we use 
single quotes as the default quoting characters - '';

If optional NO_BORDER flag is specified then the charcters that are being quoted
are not added automatically to the beginning and the end of the STRING.

=cut
sub quote {
	#my ( $string, $start, $end, $no_border ) = @_;
	
	my $string = shift;
	my $in = {
		start		=> undef,
		end			=> undef,
		no_border	=> undef,
		quote_nl	=> undef, # turn new line symbols into \n
		@_
	};
	my $start = $in->{start};
	my $end = $in->{end};
	my $no_border = $in->{no_border};
	my $quote_nl = $in->{quote_nl};
	
	$start = "'" if false($start);
	$end   = $start if false($end);
	if ( false($string) ) {
		return if $no_border;
		return $start . $end if not $no_border;
	}

	# escaping quoting characters and the escaping '\' itself inside the string
	$string =~ s/([\\$start$end])/$1 eq '\\' ? "\\\\" : "\\$1"/sge;
	$string =~ s/[\r\n]/\\n/g if $quote_nl;

	return ( $no_border ? '' : $start ) . $string . ( $no_border ? '' : $end );
}

sub match_strings {
	my $string1 = shift;
	my $string2 = shift;

	$string1 =~ s/^\s+//;
	$string1 =~ s/\s+$//;
	$string2 =~ s/^\s+//;
	$string2 =~ s/\s+$//;

	# turning a string into an array and converting everything to lowercase
	my @words1 = map { lc($_) } split( /[\r\n\s]+/, $string1 );
	my @words2 = map { lc($_) } split( /[\r\n\s]+/, $string2 );

	return 0 if not @words1 or not @words2;

	# We need to calculate
	# 1. How many words from the first array have a match in the second array
	# 2. The same for the second array, matching words in the first array
	# 3. We need to take into account repeating words (2 repeating words in
	#    the first array do not match 1 word in the second, only 1 word does).

	my ( $words1_idx, $words2_idx );

	$words1_idx->{$_} += 1 foreach @words1;
	$words2_idx->{$_} += 1 foreach @words2;

	my $matched;

	foreach my $word (@words1) {
		next if not $words2_idx->{$word};
		$matched += 1;
		$words2_idx->{$word} -= 1;
	}

	foreach my $word (@words2) {
		next if not $words1_idx->{$word};
		$matched += 1;
		$words1_idx->{$word} -= 1;
	}

	my $total_words = @words1 + @words2;
	my $match_percent = sprintf( "%.2f", $matched / ( $total_words / 100 ) );

	return $match_percent;
}

sub text_format {
	my $txt    = shift;
	my $length = shift;

	$txt =~ s/\r//g;
	my @lines = split( /\n/, $txt );
	my @formatted;

	while (@lines) {
		my $line = shift @lines;
		if ( length($line) > $length
			 and ( my $index = index( $line, ' ', $length ) ) > -1 )
		{
			push @formatted, substr( $line, 0, $index );
			unshift @lines, substr( $line, $index + 1 );
		}
		elsif ( $line ne '' and @lines and $lines[0] ne '' ) {
			$lines[0] = $line . ' ' . $lines[0];
		}
		else {
			push @formatted, $line;
		}
	}

	return join( "\n", @formatted );
}

sub title_case {
	my $string = shift;
	return $string if false($string);

	# generating a unique string with 20 lower case letters, which we will use
	# to mark artifically inserted spaces, which we will need to cut out at the end
	my $cut_id;
	while ( not defined $cut_id or $string =~ /$cut_id/ ) {
		$cut_id = create_random( 20, letters_lc => 1 );
	}

	my $split_chr = quotemeta('.,!-/()\\[]"');

	$string =~ s/([$split_chr])(\S)/$1$cut_id $2/g;
	my @words = split( /\s+/, $string );

	for ( my $i = 0 ; $i < scalar @words ; $i++ ) {

		# if the word contains a number then we think this is a postcode or
		# something similar and keep the original case of the word
		next if $words[$i] =~ /\d/;
		$words[$i] = ucfirst( lc( $words[$i] ) );
	}

	$string = join( ' ', @words );
	$string =~ s/$cut_id\s//g;

	return $string;
}

sub cut_string {
	my $string = shift;
	my $length = shift;
	return '' if false($string) or not $length;
	return $string if length($string) <= $length;

	my $sub_string = substr( $string, 0,           $length );
	my $next_chr   = substr( $string, $length - 1, 1 );

	# ends with a space already
	if ( $sub_string =~ /\s+$/ ) {
		$sub_string =~ s/\s+$//s;
	}

	# next character in line was space or full stop
	elsif ( $next_chr eq ' ' or $next_chr eq '.' ) {
		$sub_string =~ s/\s+$//s;
	}

	# we are probably in the middle of the word
	else {
		$sub_string =~ s/\s+\S+$//s;
	}

	$sub_string .= '...';

	return $sub_string;
}

sub get_image_info {
	my $in = {
		image_data => undef, 
		@_
	};
	my $image_data = $in->{image_data};
	return undef if not $image_data;

	my ( $x, $y, $format );

	if (eval { require Image::Magick }) {
		my $image = Image::Magick->new;
		$image->BlobToImage($image_data);
		( $x, $y, $format ) = map { lc($_) } $image->Get( 'columns', 'rows', 'magick' );
	} 
	elsif (eval { require Imager }) {
		my $image = Imager->new || die Imager->errstr;
		$image->read(data => $image_data) || die $image->errstr;
		$x = $image->getwidth;
		$y = $image->getheight;
		$format = $image->tags(name => 'i_format');
	} 
	
	# if all failed to load we just return the original data
	else {
		return undef;
	}

	return $x, $y, $format;
}

sub resize_image {
	my $in = {
		image_data				=> undef, # required, binary image data
		width					=> undef, # either width or height is required, target width of image
		height					=> undef, # either width or height is required, target height of image
		exact					=> undef, # optional flag, that will force the width and height specified, cropping the image if required
		crop_vertical_at_top	=> undef, # optional, works along with 'exact' parameter, vertical images will be cropped at top instead of the middle
		accept_formats			=> undef, # optional, array ref of file formats that should be accepted (jpeg, gif, etc) 
		@_
	};
	my $image_data = $in->{image_data};
	my $width = $in->{width};
	my $height = $in->{height};
	my $exact = $in->{exact};
	my $crop_vertical_at_top = $in->{crop_vertical_at_top};
	my $accept_formats = $in->{accept_formats};
	
	return undef if false($image_data) or (false($width) and false($height));

	my ($image, $x, $y, $format, $usingMagick, $usingImager);

# ---------------------------------------------------------------------------

	if (eval { require Image::Magick }) {
		$usingMagick = 1;
		
		$image = Image::Magick->new;
		$image->BlobToImage($image_data);
		( $x, $y, $format ) = map { lc($_) } $image->Get( 'columns', 'rows', 'magick' );
	} 
	elsif (eval { require Imager }) {
		$usingImager = 1;
		
		$image = Imager->new || die Imager->errstr;
		$image->read(data => $image_data) || die $image->errstr;
		$x = $image->getwidth;
		$y = $image->getheight;
		$format = $image->tags(name => 'i_format');
	} 
	
	# if all failed to load we just return the original data
	else {
		return $image_data;
	}
	
	$width = $x if false($width);
	$height = $y if false($height); 

# ---------------------------------------------------------------------------
	
	if (ref $accept_formats eq 'ARRAY') {
		my $accept_idx = { map { lc($_) => 1 } @$accept_formats };
		return undef if not $accept_idx->{$format};
	}
	
	# no transformations required, returning image back
	if ($x <= $width and $y <= $height) {
		return $image_data;
	}
	
	my $geometry;
	if ($exact) {
		if ( $x > $y ) {
			$geometry->{y} = $height;
		}
		else {
			$geometry->{x} = $width;
		}
	}
	else {
		$geometry = {
			x 	=> $width,
			y	=> $height,
		};
	}

# ---------------------------------------------------------------------------
	
	if ($usingMagick) {
		$image->Resize( 
			geometry => 
				($geometry->{x} ? $geometry->{x} : '').'x'.
				($geometry->{y} ? $geometry->{y} : '')
		);
		
		# new x and y sizes
		($x, $y) = $image->Get( 'columns', 'rows' );
	} 
	elsif ($usingImager) {
		$image = $image->scale(
			xpixels	=> $geometry->{x},
			ypixels	=> $geometry->{y},
			type	=> 'min', # the smaller of the two sizes is chosen
			qtype	=> 'mixing', # 'mixing' — slower, better qual, 'normal' - faster, lower quality
		);
		
		# new x and y sizes
		$x = $image->getwidth;
		$y = $image->getheight;
	}

# ---------------------------------------------------------------------------

	# cropping image now because the size is still not exact (and exact was requested)
	if ($exact and ( $x != $width || $y != $height )) {
		if ($usingMagick) {
			$geometry = $width . 'x' . $height;

			# horizontal
			if ( $x > $y ) {
				my $x_offset = int( ( $x - $width ) / 2 );
				$geometry .= '+' . $x_offset . '+0';
			}
			
			# vertical
			else {
				my $y_offset = $crop_vertical_at_top ? 0 : int( ( $y - $height ) / 2 );
				$geometry .= '+0+' . $y_offset;
			}
			
			$image->Crop($geometry);	
		} 
		elsif ($usingImager) {
			if ($crop_vertical_at_top and $x < $y) {
				$image = $image->crop(left => 0, top => 0, width => $width, height => $height);
			} else {
				$image = $image->crop(width => $width, height => $height);	
			}
		}
		
	}

# ---------------------------------------------------------------------------

	if ($usingMagick) {
		my @blobs = $image->ImageToBlob;
		return $blobs[0];
	} 
	
	elsif ($usingImager) {
		my $new_data; $image->write(data => \$new_data, type => $format);
		return $new_data;
	}	

	# all failed, returning original image	
	return $image_data
}

sub strip_js_comments {
	my $js = shift;

	# only remove JS comments, correctly doesn't remove //--> (requires $1$2$3 substitution)
	# $content should only have the JS code for this regexp to work correctly
	my $js_comments = qr!
		(
			[^"'/]+ |
			(?:"[^"\\]*(?:\\.[^"\\]*)*"[^"'/]*)+ |
			(?:'[^'\\]*(?:\\.[^'\\]*)*'[^"'/]*)+
		) |
	
		(//\s*-->) |
	
		/
		(?:
			\*[^*]*\*+ (?: [^/*][^*]*\*+ )*/\s*\n?\s* |
			/[^\n]*(\n|$)
		)
	!xo;

	$js =~ s/$js_comments/$1$2$3/sg;
	
	return $js;
}

sub clean_html {
	my $in = {
		html				=> undef,
		filename			=> undef,
		strip_html_comments	=> undef, # strip html comments
		strip_new_lines		=> undef, # strip new lines
		strip_tabs			=> undef, # strip tabs
		@_
	};
	my ( $html, $filename, $strip_html_comments, $strip_new_lines, $strip_tabs ) = map { $in->{$_} } qw(
		html filename strip_html_comments strip_new_lines strip_tabs
	);
	return undef if not $filename or $filename !~ /\.(?:html?|js|xml)$/i;

	# trying to get file contents if they haven't been passed
	if ( not defined $html and -f $filename ) {
		require Stuffed::System::File;
		my $f = Stuffed::System::File->new( $filename, 'r', {is_text => 1} ) || die $!;
		$html = $f->contents;
		$f->close;
	}

	return $html if false($html);
	
	$html =~ s/\t+//sg if $strip_tabs;
	  
	return $html if not eval { require HTML::Parser };

	# stripping html comments
	my $stripped_html;

	my $p = HTML::Parser->new(
		api_version => 3,
		handlers    => [
			start => [ 
				sub {
					# $text contains opening tag itself here
					my ($self, $tagname, $text) = @_;
					
					$stripped_html .= $text;
					
					# for all the tags for which we will NOT set a "text" handler here, their insides will be processed by the default handler below					
					if ($tagname eq 'script') {
						$self->handler( 
							text => sub {
								# $text contains the text surrounded by the opening and closing tag
								my $text = shift;
								
								if ($strip_html_comments) {
									$text = strip_js_comments($text);	
								}

								if ($strip_new_lines) {
									# if we have ";" at the end of the line (can be followed by spaces or tabs) then we remove the new line symbol 
									# as we think the JS won't break as there is a ; in place.
									$text =~ s/;\s*[\r\n]/;/g;
									
									$text =~ s/[\r\n]+\s+[\r\n]+/\n/g;
									$text =~ s/[\r\n]+/\n/sg;
									$text =~ s/ +/ /sg;
								}
								
								$stripped_html .= $text;
								
							}, 
							"text"
						);
					} 
					
					elsif ($tagname eq 'style') {
						$self->handler( 
							text => sub {
								my $text = shift;

								if ($strip_new_lines) {
									# removing empty lines as well
									$text =~ s/[\r\n]+\s+[\r\n]+//g;
									$text =~ s/[\r\n]+//g;
									# many spaces to one space (\s includes \t, \r and \n!)
									$text =~ s/ +/ /g;
								}

								$stripped_html .= $text;
							}, 
							"text"
						);
						
					}
					
					# keep text as is for the insides of these tags					
					elsif ($tagname eq 'pre') {
						$self->handler( 
							text => sub { $stripped_html .= shift }, "text"
						);
					}

					else {
						return;
					}
			
					# we should set "text" handler back to default one after processing the tag inner text
					$self->handler( 
						end => sub {
							# $text contains closing tag itself
							my ($self, $text) = @_;
							$stripped_html .= $text;
							
							$self->handler(text => undef);
							$self->handler(end => undef);
						}, 
						"self, text" 
					);
				}, 
				'self, tagname, text' 
			],
		
			default => [ 
				sub {
					my $text = shift; 
					
					if ($strip_new_lines) {
						# removing empty lines as well
						$text =~ s/[\r\n]+\s+[\r\n]+/ /g;
						$text =~ s/[\r\n]+/ /g;
						$text =~ s/ +/ /g;
					}
					
					$stripped_html .= $text; 
				}, 
				'text' 
			],
			
			comment => [
				sub {
					my $text = shift;

					# conditional comment start
					# <!--[if (gt IE 5)&(lt IE 7)]>
					if ( not $strip_html_comments or $text =~ /^<!\-\-\[[^\]]+\]>/ ) {
						$stripped_html .= $text;
					}
				},
				'text'
			],
		],
	);
	
	$p->parse($html)->eof || die "Error while stripping html comments from file $filename: $!";
	
	# strip new lines, tabs and spaces between html tags if there are only such symbols
#	if ($strip_new_lines) {
#		$stripped_html =~ s/([^%]>)\s+(<[^%])/$1$2/sg;
#	}
	
	return $stripped_html;
}

sub prepare_file_size {
	my $size = shift || return;
	my $units = {
		Bytes	=> 1,
		Kb		=> 1024,
		Mb		=> 1024 * 1024,
		Gb		=> 1024 * 1024 * 1024,
	};
	foreach my $unit ( sort { $units->{$b} <=> $units->{$a} } keys %$units ) {
		my $s = sprintf( "%.2f", $size / $units->{$unit} );
		next if $s == 0;
		$size = $s . ' ' . $unit;
		last;
	}
	1 while $size =~ s/(\d)(\d\d\d)(?!\d)/$1 $2/;
	return $size;
}

sub get_hash_cookie {
	my $name = shift || return;
	my $cookie = $system->in->cookie($name);
	return if not $cookie;
	require Storable;
	require Compress::Zlib;
	return Storable::thaw( Compress::Zlib::uncompress($cookie) );
}

sub set_hash_cookie {
	my $name = shift || return;
	my $hash = shift || return;
	my %params = (
				   expires => undef,
				   @_
	);
	require Storable;
	require Compress::Zlib;
	my $cookie = Compress::Zlib::compress( Storable::nfreeze($hash), 9 );
	$system->out->cookie(
						  name    => $name,
						  value   => $cookie,
						  expires => $params{expires},
	);
	return 1;
}

# =======================================================================

sub get_number_suffix {
	my $n = shift;
	return '' if not $n or $n =~ /\D/;
	return 'th' if $n == 11 or $n == 12 or $n == 13;
	$n %= 10;
	return 'st' if $n == 1;
	return 'nd' if $n == 2;
	return 'rd' if $n == 3;
	return 'th';
}

# =======================================================================

sub convert_from_json {
	my $json = shift;
	require JSON;
	return JSON->new->decode($json);
}

# =======================================================================

sub convert_to_json {
	my $ref = shift;
	require JSON;
	JSON->import('-convert_blessed_universally');
	return JSON->new->allow_blessed->convert_blessed->encode($ref);
}

# =======================================================================

1;