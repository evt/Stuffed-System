# ============================================================================
#
#                        ___
#                    ,yQ$SSS$Q·,      ,:yQQQL
#                  j$$"`     `?$'  ,d$P"```Ó$$,
#           i_L   I$;            `$½`       `$$,
#                                 `          I$$
#           .:yQ$$$$,            ;        _,d$$'
#        ,d$$P"^```?$b,       _,'  ;  ,:d$$P"`
#     ,d$P"`        `"?$$Q#QP½`    $d$$P"`
#   ,$$"         ;       ``       ;$?'
#   $$;        ,dI                I$;
#   `$$,    ,d$$$`               j$I
#     ?$S#S$P'j$'                $$;         Copyright (c) Stuffed Guys
#       `"`  j$'  __....,,,.__  j$I              www.stuffedguys.org
#           j$$½"``           ',$$
#           I$;               ,$$'
#           `$$,         _.:u$$½`
#             "?$$Q##Q$$SP½"^`
#                `````
#
# ============================================================================

package Stuffed::System::CVS;

$VERSION = 1.00;

use strict;

use Stuffed::System;

sub new {
	my $class = shift;
	my $in = {
		dir	=> undef, # optional, cvs root dir, will default to system's root
		@_
	};
	$in->{dir} = $system->path if false($in->{dir});
	if (not -d $in->{dir}) {
		die "CVS directory '$in->{dir}' can't be found or opened!";
	}

	my $self = bless($in, $class);

	return $self;
}

sub get_commit_messages {
	my $self = shift;
	my $in = {
		author_names	=> undef, # optonal, will replace author usernames with supplied names
		only_author		=> undef, # optinal, will return only messages for this author
		@_
	};
	my $author_names = $in->{author_names} || {};
	my $only_author = $in->{only_author};

	my $pre = $system->config->get('db_prefix');

	my ($dates, $messages);

	my @where_arr;
	if (true $only_author) {
		push @where_arr, 'author = '.$system->dbh->quote($only_author);
	}

	my $where_str = (@where_arr ? 'where '.join(' and ', @where_arr) : '');

	require Time::Local;

	require Stuffed::System::Utils;

# time_submitted is always in GMT as this is how CVS reports all its dates and times
	my $sth = $system->dbh->prepare("
select * 
from ${pre}system_cvs_messages
$where_str
order by time_submitted desc
limit 100
");
	$sth->execute;
	while (my $row = $sth->fetchrow_hashref) {
		$row->{message} = Stuffed::System::Utils::parse_urls($row->{message});

		# 2009-04-22 09:07:42
		my ($year, $month, $day, $hour, $min, $sec) = split(/\D+/, $row->{time_submitted});

		$month -= 1;
		$row->{epochsec} = Time::Local::timegm($sec, $min, $hour, $day, $month, $year);
		my ($sec, $min, $hour, $mday, $mon, $year) = localtime($row->{epochsec});
		$mon += 1;
		$year += 1900;

		$row->{date_submitted} = sprintf("%04d-%02d-%02d", $year, $mon, $mday);
		$row->{only_time} = sprintf("%02d:%02d", $hour, $min);

		if (exists $author_names->{$row->{author}}) {
			$row->{author_name} = $author_names->{$row->{author}};
		} else {
			$row->{author_name} = $author_names->{author};
		}

		push @{$dates->{$row->{date_submitted}}}, $row;
	}
	$sth->finish;

	if ($dates) {
		foreach my $date (sort {$b cmp $a} keys %$dates) {
			push @$messages, {
				date  => $date,
				list  => $dates->{$date},
			  };
		}
	}

	return $messages;
}

sub update_commit_messages {
	my $self = shift;
	my $in = {
		tag_pattern	=> undef, # optional, only consider tags that match the specified regexp pattern
		@_
	  };

	my $pre = $system->config->get('db_prefix');

	# we get max date with a big safe margin, this is needed to notice when
	# messages without the tag, got a tag now (we need to update such messages in
	# the database)
	my $max_date = $system->dbh->selectrow_array("
select max(time_submitted) - interval 14 day 
from ${pre}system_cvs_messages
");

	my $messages = $self->download_commit_messages(
		from        => $max_date,
		tag_pattern => $in->{tag_pattern},
	);

	if ($messages) {
		require Date::EzDate;

		my $border_messages_idx;

		if ($max_date) {
			my $sth = $system->dbh->prepare("
select *, md5(message) as md5_id
from ${pre}system_cvs_messages
where time_submitted >= (? - interval 5 minute)
");
			$sth->execute($max_date);
			while (my $row = $sth->fetchrow_hashref) {
				$row->{ez_date} = Date::EzDate->new($row->{time_submitted});
				push @{$border_messages_idx->{$row->{md5_id}}}, $row;
			}
			$sth->finish;
		}

		my $sth = $system->dbh->prepare("
insert into ${pre}system_cvs_messages
set time_submitted = ?, author = ?, tag = ?, message = ?
");
		my $sth_update = $system->dbh->prepare("
update ${pre}system_cvs_messages
set tag = ?
where message_id = ?
");

		my $format = '{year}-{month number base 1}-{day of month} {hour}:{min}:{sec}';

		my $update_tag;

		MESS: foreach my $m (@$messages) {

			# message with the same md5_id was found in the border messages from the db,
			# checking if the time is close enough
			if ($border_messages_idx->{$m->{md5_id}}) {
				foreach my $border_mess (@{$border_messages_idx->{$m->{md5_id}}}) {
					if ($m->{author} eq $border_mess->{author} and abs($m->{ez_date}{epochsec} - $border_mess->{ez_date}{epochsec}) < 60*5) {

            # if the message in the database didn't have a tag and a new message
            # we've got from CVS has it, we want to update the message in the
            # database with a new tag (the revision went to live finally)
						if (false($border_mess->{tag}) and true($m->{tag})) {
							$sth_update->execute($m->{tag}, $border_mess->{message_id});
						}

						next MESS;
					}
				}
			}

			$sth->execute($m->{ez_date}{format} = $format, $m->{author}, $m->{tag}, $m->{message});
		}

		$sth->finish;
		$sth_update->finish;
	}

	return $self;
}

sub download_commit_messages {
	my $self = shift;
	my $in = {
		from        => undef, # optional, get commit messages starting from this time
		tag_pattern => undef, # optional
		@_
	  };

	my $tag_pattern = $in->{tag_pattern};

	require Digest::MD5;
	require Date::EzDate;

	my ($messages, $file, $revision, $mode);

	my $cvs_from = ($in->{from} ? "-d '>=$in->{from}'" : '');

	# 2>&1 redirects ALL output to the pipe (that's a shell function)
	# -z9 enables maximum compression
	# -S Suppress the header if no revisions are selected
	open CVS, "cvs -z9 log $cvs_from -S $self->{dir} 2>&1 |";
	while (my $line = <CVS>) {
		$line =~ s/[\r\n]+$//;

		if ($mode eq 'tags') {
			my ($tag, $revision) = $line =~ /^\t(.+):\s+([\d\.]+)$/;

			if (true($tag)) {
				# skip this tag if tag pattern was specified and current tag doesn't match it
				next if $tag_pattern and $tag !~ /$tag_pattern/;

				# one revision can be connected to several tags, but we are only
				# interested in the latest tag (because it will be the first tag
				# assigned to the revision, since that's how CVS returns the tags
				# list to us)
				$file->{tags}{$revision} = $tag;
				next;
			} else {
				$mode = undef;
			}
		}

		if ($mode eq 'revision') {

			# this line seems to appear only on the initial additions of files to the rep
			if ($line =~ /^branches:\s+/) {
				# this will skip the current revision block
				$mode = undef;
				next;
			}

			if ($line =~ /^date:\s+([^;]+);\s+author:\s+([^;]+)/) {
				$revision->{date} = $1;
				$revision->{author} = $2;
				$revision->{ez_date} = Date::EzDate->new($revision->{date});

				# nothing changed, ignoring revision
				if ($line =~ /lines:\s+\+0\s+\-0$/) {
					$mode = undef;
				}

				next;
			}

			# end of revision
			if ($line =~ /^(?:\-+|=+)$/) {
				if (true($revision->{message})) {
					my $md5_id = Digest::MD5::md5_hex($revision->{message});
					$revision->{md5_id} = $md5_id;

					my $save_revision = 1;

                 # message with such digest ID is already saved, checking if its
                 # time is close enough or not to the current one
					if ($messages->{$md5_id}) {
						foreach my $r (@{$messages->{$md5_id}}) {
							if ($r->{author} eq $revision->{author} and abs($r->{ez_date}{epochsec} - $revision->{ez_date}{epochsec}) < 60*5) {

                   # we found a message with the same md5 id and with the same
                   # time as the current revision +- 5 mins, not saving revision
								$save_revision = undef;
								last;
							}
						}
					}

					push @{$messages->{$md5_id}}, $revision if $save_revision;
				}

				$mode = undef;
				next;
			}

			next if $line =~ /^\*\*\*\s+empty log message/;
			next if $line =~ /^['"]+$/;
			next if $line =~ /^no message$/;

			# if we get here then we have a commit message in $line
			$revision->{message} .= (defined $revision->{message} ? "\n" : '') . $line;
		}

		# new file
		if ($line =~ /^Working file:\s+(.+)$/) {
			$file = {name => $1};
			$mode = undef;
			next;
		}

		# list of tags starts
		if ($line =~ /^symbolic names:/) {
			$mode = 'tags';
			next;
		}

		if ($line =~ /^revision\s+([\d\.]+)$/) {
			$mode = 'revision';
			$revision = {
				id  => $1,
				tag => $file->{tags}{$1},
			  };
		}
	}
	close CVS;

	my $final;

	if ($messages) {
		push @$final, @{$messages->{$_}} for keys %$messages;
		$final = [sort {
				$a->{ez_date}{epochsec} <=> $b->{ez_date}{epochsec}
			  } @$final];
	}

	return $final;
}

sub get_current_tag {
	my $self = shift;

	my $path = $self->{dir}.'/CVS/Tag';
	return undef if not -r $path;

	my $f = Stuffed::System::File->new($path, 'r');
	my $tag = $f->line;
	$f->close;

	$tag =~ s/^\s+|\s+$//g;
	$tag =~ s/^[T|N]//;

	return $tag;
}

sub get_annotated_files {
	my $self = shift;
	my $in = {
		dir			=> undef, # physical path to the directory or file to annotate
		revision_id	=> undef, # optional, revision to use with the -r parameter
		verbose		=> undef, # optional
		@_
	  };
	my $dir = $in->{dir};
	return undef if false($dir);

	my $current_tag = $self->get_current_tag;
	$in->{revision_id} = $current_tag if true($current_tag) and not $in->{revision_id};

	my $annotate = 'cvs -z9 annotate';
	$annotate .= " -r $in->{revision_id}" if $in->{revision_id};

	my ($files_idx, $mode, $file);

	# 2>&1 redirects ALL output to the pipe (that's a shell function)
	open CVS, "$annotate $dir 2>&1 |";
	while (my $line = <CVS>) {
		$line =~ s/[\r\n]+$//;

		if (not $mode and $line =~ /^Annotations for (.+)$/) {
			my $physical = $1;
			(my $filename = $physical) =~ s/^$dir\///;
			print "  $filename".(true($in->{revision_id}) ? " ($in->{revision_id})" : '')."..\n" if $in->{verbose};

			$file = {
				physical	=> $physical,
				relative	=> $filename,
				binary		=> undef,
				lines		=> [],
			  };

			$mode = 'ann_begin';
			next;
		}

		# skip *****
		if ($mode eq 'ann_begin') {
			$mode = 'file_begin';
			next;
		}

		# binary file
		if ($mode eq 'file_begin' and $line =~ /Skipping binary file/) {
			$file->{binary} = 1;
			$files_idx->{$file->{relative}} = $file;
			$mode = undef;
			next;
		}

		if ($mode eq 'file_begin' or $mode eq 'file') {

			# empty line -- end of file
			if (false($line)) {
				$files_idx->{$file->{relative}} = $file;
				$mode = undef;
				next;
			}

			# normal line of a file contents
			else {
				my ($revision, $author, $date, $content) = $line =~ /^(\S+)\s+\((\S+)\s+(\S+)\):\s(.*)$/;
				push @{$file->{lines}}, {
					revision	=> $revision,
					author		=> $author,
					date		=> $date,
					content		=> $content,
				  };

				$mode = 'file';
				next;
			}
		}

	}
	close CVS;

	# Due to how CVS outputs annotate data we don't have a chance to catch the
	# end of the last file in annotate in the cylce above, so do this additional
	# check here
	if ($file and not $files_idx->{$file->{relative}}) {
		$files_idx->{$file->{relative}} = $file;
	}

	return $files_idx;
}

sub get_logged_revisions {
	my $self = shift;
	my $in = {
		filename  => undef, # physical path to the file to log
		@_
	  };
	my $filename = $in->{filename};
	return undef if false($filename);

	my ($revision, $revisions_idx, $mode);

	require Time::Local;

# 2>&1 redirects ALL output to the pipe (that's a shell function)
# -z9 enables maximum compression
# -N Do not print the list of tags for this file. This option can be very useful when
# your site uses a lot of tags, so rather than "more"'ing over 3 pages of tag
# information, the log information is presented without tags at all.
	open CVS, "cvs -z9 log -N $filename 2>&1 |";
	while (my $line = <CVS>) {
		$line =~ s/[\r\n]+$//;

		if ($mode eq 'revision') {

   # this line seems to appear only on the initial additions of files to the rep
			if ($line =~ /^branches:\s+/) {
				next;
			}

			if ($line =~ /^date:\s+([^;]+);\s+author:\s+([^;]+)/) {
				$revision->{author} = $2;

				# CVS returns dates and times in GMT
				$revision->{date} = $1;
				my ($year, $month, $day, $hour, $min, $sec) = $revision->{date} =~ /^(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)$/;
				$month -= 1;

				$revision->{epochsec} = Time::Local::timegm($sec, $min, $hour, $day, $month, $year);

				next;
			}

			# end of revision
			if ($line =~ /^(?:\-+|=+)$/) {
				$revisions_idx->{$revision->{id}} = $revision;

				$mode = undef;
				next;
			}

			$line = '' if $line =~ /^\*\*\*\s+empty log message/;
			$line = '' if $line =~ /^['"]+$/;
			$line = '' if $line =~ /^no message$/;

			# if we get here then we have a commit message in $line
			$revision->{message} .= (defined $revision->{message} ? "\n" : '') . $line;
		}

		if ($line =~ /^revision\s+([\d\.]+)$/) {
			$mode = 'revision';
			$revision = {id => $1};
		}
	}
	close CVS;

	return $revisions_idx;
}

1;
