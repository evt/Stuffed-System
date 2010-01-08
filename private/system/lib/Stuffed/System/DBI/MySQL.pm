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

package Stuffed::System::DBI::Base::MySQL;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		db_name => undef,
		db_host => undef,
		db_port => undef, # optional
		db_user => undef, # optional
		db_pass => undef, # optional
		@_
	};
	
	foreach (qw(db_name db_host)) {
		return if false($in->{$_});
	}
	
	eval { require DBI }; die "Can't load DBI! $@" if $@;
	my $dsn = "DBI:mysql:$in->{db_name}:$in->{db_host}";
	$dsn .= ":$in->{db_port}" if $in->{db_port};

	my $dbh = DBI->connect($dsn, $in->{db_user}, $in->{db_pass}, {
			PrintError => 0, # don't warn about errors
		});

	# this can be useful when used in the following configuration:
	# html pages are in win1251 encoding and mysql database is in koi8 encoding
	# this lines will force mysql to autoconvert all data during input/output
	# $dbh->do("set character set cp1251_koi8");

	return $dbh;
}

1;