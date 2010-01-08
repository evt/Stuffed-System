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

package Stuffed::System::ManageSkins;

$VERSION = 1.00;

use Exporter; @ISA = qw(Exporter);
@EXPORT_OK = qw(&get_skin &get_all_skins);

use strict;

use Stuffed::System;
use Stuffed::System::Package;

sub get_skin {
	my $in = {
		pkg     => undef,
		skin_id => undef,
		@_
	  };
	my $pkg = $in->{pkg};
	my $skin_id = $in->{skin_id};
	return undef if false($pkg) or false($skin_id);

	# calculating physical path to the specified package
	my $pkg_path = Stuffed::System::Package->__create_path($pkg);
	my $skins_path = $system->path . "/private/$pkg_path/skins";

	return undef if not -d "$skins_path/$skin_id";

	my $config = Stuffed::System::Config->new("$skins_path/$skin_id.cgi");
	my $title = $config->get('title');

	return undef if false($title);

	return {id => $skin_id, title => $title, config => $config};
}

sub get_all_skins {
	my $in = {
		pkg => undef,
		@_
	  };
	my $pkg = $in->{pkg};
	return undef if false $pkg;

	# calculating physical path to the specified package
	my $pkg_path = Stuffed::System::Package->__create_path($pkg);
	my $path = $system->path . "/private/$pkg_path/skins";

	# package or skins directory doesn't exist
	return undef if not -d $path;

	my $skins;

	opendir(DIR, $path);
	while (my $file = readdir(DIR)) {
		next if $file =~ /^\.+$/ or not -f "$path/$file" or $file !~ /\.cgi$/;
		(my $dir = $file) =~ s/\.cgi$//;
		next if not -d "$path/$dir";
		my $config = Stuffed::System::Config->new("$path/$file");
		my $title = $config->get('title');
		next if false($title);
		push @$skins, {id => $dir, title => $title, config => $config};
	}
	closedir(DIR);

	if ($skins) {
		$skins = [sort {$a->{title} cmp $b->{title}} @$skins];
	}

	return $skins
}

1;