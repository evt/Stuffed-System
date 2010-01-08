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

package Stuffed::System::Cache;

$VERSION = 1.00;

use strict;

use Stuffed::System;
use Digest::MD5 qw(&md5_hex);

sub new {
	my $class = shift;
	my $in = {
		id			=> undef, # id of the cached content
		store_mins	=> undef, # how long to store content in the cache (in mins)
		@_
	};
	my $id = $in->{id};
	my $store_mins = $in->{store_mins};
	return undef if false($id) or false($store_mins);

	# removing any non-digital characters
	$store_mins =~ s/\D//g;

	my $md5_id = md5_hex($id);
	$in->{id} = $md5_id;

	my $self = bless($in, $class);

	my $pre = $system->config->get('db_prefix');

	my $sth = $system->dbh->prepare("
delete from ${pre}system_cache where id = ? and added < now() - interval $store_mins minute
");
	$sth->execute($md5_id);
	$sth->finish;

	return $self;
}

sub get {
	my $self = shift;
	my $id = $self->{id};
	return undef if false($id);
	return $self->{content} if defined $self->{content};

	my $pre = $system->config->get('db_prefix');

	my $sth = $system->dbh->prepare("
select content, is_code from ${pre}system_cache where id = ? limit 1;
");
	$sth->execute($id);
	my $cache = $sth->fetchrow_hashref;
	$sth->finish;

	if ($cache->{is_code}) {
		require Storable;
		$self->{content} = Storable::thaw($cache->{content});
	}

	return $self->{content};
}

sub store {
	my $self = shift;
	my $content = shift;
	my $id = $self->{id};
	return undef if false($id);

	my $is_code = (ref $content ? 1 : 0);

	require Storable;
	$content = Storable::nfreeze($content) if $is_code;

	my $pre = $system->config->get('db_prefix');

	my $sth = $system->dbh->prepare("
insert into ${pre}system_cache set id = ?, added = now(), content = ?, is_code = ?
");
	$sth->execute($id, $content, $is_code);
	$sth->finish;

	return 1;
}

1;