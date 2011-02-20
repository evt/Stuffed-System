#!/usr/bin/env perl -w
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

use CGI::Carp qw(fatalsToBrowser);

# not sure which perl version is the minimal now (could be 5.10 for all I know)
# require 5.005_03;

$| = 1;

# physical path of the folder where "private" folder is located, which
# contains "system" package;
# if it is undefined then we use the current folder from which this
# index.cgi file was launched (standard behaviour)
my $sys_path = undef;

# optional physical path of an additional packages folder, which in a
# standard situation is equal to the $sys_path above;
# if it is undefined then we use the current folder from which this
# index.cgi file was launched (standard behaviour)
my $pkg_path = undef;

# calculating physical path to the current directory
if (not defined $pkg_path) {
	my $regexp = qr/^(.+)([\/\\])[^\2]+$/o;
	if ($ENV{DOCUMENT_ROOT}) {
		$pkg_path = $ENV{DOCUMENT_ROOT}.$ENV{SCRIPT_NAME} if -e $ENV{DOCUMENT_ROOT}.$ENV{SCRIPT_NAME};
		$pkg_path = $ENV{SCRIPT_FILENAME} if not defined $pkg_path;
		($pkg_path) = $pkg_path =~ /$regexp/;
	}
	($pkg_path) = $0 =~ /$regexp/ if not defined $pkg_path or $pkg_path eq '';
	if (not defined $pkg_path or $pkg_path eq '' or not -e $pkg_path) {
		$pkg_path = '.';
	} else {
		$pkg_path =~ s/\\/\//g;
	}
}

# if system path was not specified, then it becomes equal to the
# packages path
$sys_path = $pkg_path if not defined $sys_path;

unshift @INC, $pkg_path, "$sys_path/private/system/lib";

$ENV{STUFFED_STACK_START} += 1 while caller($ENV{STUFFED_STACK_START} || 0);

require Stuffed::System;
my $system = Stuffed::System->new($sys_path, $pkg_path);

$system->run->stop;	

1;