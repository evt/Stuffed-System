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

use Stuffed::System;
use Stuffed::System::File;

sub default {
	my $self = shift;

	my $in = $system->in;
	my $out = $system->out;

	my $just_finish = sub {
		$system->out->say('');
		$system->stop;
	};

	my $f_path = $in->query('f_path');
	$just_finish->() if false($f_path);

	my $f_pkg = $in->query('f_pkg');
	$just_finish->() if false($f_pkg);

	# cleaning up the path
	my @path = grep {true($_) and $_ !~ /^\.+$/} split(/[\/\\]/, $f_path);
	my $file = join('/', @path);

	my $pkg = $system->pkg($f_pkg);
	$just_finish->() if false($pkg);

	$file = $pkg->__public_path.'/'.$file;
	$just_finish->() if not -r $file;

	# trying to determine the mime type;
	my $mime = {
		'gif'	=> 'image/gif',
		'jpg'	=> 'image/jpg',
		'png'	=> 'image/png',
		'ico'	=> 'image/x-icon',
		'html'	=> 'text/html',
		'txt'	=> 'text/plain',
		'pdf'	=> 'application/pdf',
		'css'	=> 'text/css',
		'js'	=> 'text/javascript',
	};

	my ($f_ext) = $file =~ /\.([^\.]+)$/;
	my $f_mime = (true($f_ext) and $mime->{$f_ext} ? $mime->{$f_ext} : undef);

	#  my $contents = Stuffed::System::File->new($file, 'r')->contents;
	my $f = Stuffed::System::File->new($file, 'r');
	$just_finish->() if not $f;

	binmode $f->handle;
	my $contents = $f->contents;
	$f->close;

	$system->config->set(debug => undef);

	binmode STDOUT;

	# $out->header('Content-Length' => length($contents));
	$out->header('Content-Type' => $f_mime) if $f_mime;
	$out->header('Expires' => localtime(time+60*60*24*180).' GMT');
	$out->header('Cache-Control' => 'max-age=15552000, private');
	$out->say($contents);

	$system->stop;
}

1;