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

package Stuffed::System::Mail;

$VERSION = 1.00;

use strict;

use Socket;
use Time::Local;
use Stuffed::System;

my $defaults = {
	retries			=> 1, # number of retries while connecting to smtp server
	delay			=> 1, # delay in seconds between retries
	encode_message	=> 1, # encode message with mime (if the module is available)
	mail_system		=> 'smtp',              # can also be 'sendmail'
	smtp_server		=> 'localhost',         # smtp server
	smtp_port		=> 25,                  # smtp server port
	sendmail_path	=> '/usr/sbin/sendmail', # path to sendmail
};

sub new {
	my $class = shift;
	my $self = {
		from    => undef,
		to      => [],
		subject => undef,
		message => undef,
		content => undef, # if you want to set subject as a part of message (using templates) - use "content" instead of "message"
		header  => {},
		@_
	  };
	return undef if false($self->{to});
	return undef if false($self->{from});
	return undef  if not $self->{content} and not $self->{message};
	$self->{to} = [$self->{to}] if ref $self->{to} ne 'ARRAY';

	# checking if we've got any empty to's now
	my $to_confirmed;
	foreach my $to (@{$self->{to}}) {
		next if false($to);
		push @$to_confirmed, $to;
	}
	return undef if not $to_confirmed;
	$self->{to} = $to_confirmed;

	$self = bless($self, $class);

	my $config = $system->config;

	$self->{mail_system} = true($config->get('mail_system')) ? $config->get('mail_system') : $defaults->{mail_system};

	if ($self->{mail_system} eq 'smtp') {
		$self->{smtp_server} = true($config->get('smtp_server')) ? $config->get('smtp_server') : $defaults->{smtp_server};
		$self->{smtp_port}   = true($config->get('smtp_port')) ? $config->get('smtp_port') : $defaults->{smtp_port};

		# extract port if server name like "mail.domain.com:2525"
		$self->{smtp_port} = $1 if $self->{smtp_server} =~ s/:(\d+)$//o;
	} else {
		$self->{sendmail_path} = true($config->get('sendmail_path')) ? $config->get('sendmail_path') : $defaults->{sendmail_path};
	}

	my ($date) = map {$self->{header}{$_}} grep {$_ =~ /^date$/i} keys %{$self->{header}};
	$self->{header}{'Date'} = $date || $self->__time_to_date;

	my ($mime) = map {$self->{header}{$_}} grep {$_ =~ /^mime-version$/i} keys %{$self->{header}};
	$self->{header}{'MIME-Version'} = $mime || '1.0';

	my ($type) = map {$self->{header}{$_}} grep {$_ =~ /^content-type/i} keys %{$self->{header}};
	$self->{header}{'Content-Type'} = $type || 'text/plain; charset="iso-8859-1"';

	# russian encoding
	# $in{header}{'Content-type'} ||= 'text/plain; charset="windows-1251"';

	if ($defaults->{encode_message}) {
		eval("use MIME::QuotedPrint");
		$self->{mime} &&= (!$@);
	}

	if ($self->{content}) {
		$self->{content} =~ s/^Subject:\s*(.+?)[\015\012]+//is;
		$self->{subject} = $1;
		$self->{message} = $self->{content};
	}

	# cleanup message, and encode if needed
	$self->{message} =~ s/\r\n/\n/go;  # normalize line endings, step 1 of 2 (next step after MIME encoding)

	if ($defaults->{encode_message} and
		not $self->{header}{'Content-Transfer-Encoding'}
		and $self->{header}{'Content-Type'} !~ /multipart/io)
	{
		if ($self->{mime}) {
			$self->{header}{'Content-Transfer-Encoding'} = 'quoted-printable';
			$self->{message} = encode_qp($self->{message});
		} else {
			$self->{header}{'Content-Transfer-Encoding'} = '8bit';
		}
	}

	$self->{message} =~ s/\n/\015\012/go; # normalize line endings, step 2.

	return $self;
}

sub send {
	my $self = shift;

	# if the message is said to be in UTF-8, we assume all headers are in it too and do some
	# MIME encoding
	if ($self->{header}{'Content-Type'} and $self->{header}{'Content-Type'} =~ /utf-8/i) {
		require Encode;
		$self->{$_} = Encode::encode("MIME-Header", $self->{$_}) for qw(from subject);
		$_ = Encode::encode("MIME-Header", $_) for @{$self->{to}}; 
	}

	return $self->__smtp if $self->{mail_system} eq 'smtp';
	return $self->__sendmail if $self->{mail_system} eq 'sendmail';
}

sub __sendmail {
	my $self = shift;

	foreach my $to (@{$self->{to}}) {

		#    open (MAIL,"|". $self->{sendmail_path} . " -t -f $self->{from}");
		open (MAIL,"|". $self->{sendmail_path} . " -t");

		print MAIL "To: $to\n";
		print MAIL "From: $self->{from}\n";

		foreach my $header (keys %{$self->{header}}) {
			print MAIL "$header: $self->{header}{$header}\n";
		}

		print MAIL "Subject: $self->{subject}\n\n";
		print MAIL $self->{message};

		close MAIL;
	}

	return 1;
}

sub __smtp {
	my $self = shift;

	sub fail {
		$self->{error} .= join(" ", @_) . "\n";
		close S;
		return;
	}

	local $_;
	local $/ = "\015\012";

	# get local hostname for polite HELO
	my $localhost = (gethostbyname('localhost'))[0] || 'localhost';

	unless (socket S, AF_INET, SOCK_STREAM, (getprotobyname 'tcp')[2] ) {
		return fail("socket failed ($!)");
	}

	my $smtpaddr = inet_aton($self->{smtp_server}) || return fail("$self->{smtp_server} not found\n");

	my $retried = 0; my $connected;
	while ((not $connected = connect S, pack_sockaddr_in($self->{smtp_port}, $smtpaddr))
		and ($retried < $defaults->{retries}))
	{
		$retried++;
		$self->{error} .= "connect to $self->{smtp_server} failed ($!)\n";
		sleep $defaults->{delay};
	}

	return fail("connect to $self->{smtp_server} failed ($!) no (more) retries!") if not $connected;

	my ($oldfh) = select(S); $| = 1; select($oldfh);

	chomp($_ = <S>);
	return fail("Connection error from $self->{smtp_server} on port $self->{smtp_port} ($_)") if /^[45]/ or !$_;

	print S "HELO $localhost\015\012";
	chomp($_ = <S>);
	return fail("HELO error ($_)") if /^[45]/ or !$_;

	my $from = $self->{from} =~ /</ ? $self->{from} : "<$self->{from}>";
	print S "mail from: $from\015\012";
	chomp($_ = <S>);
	return fail("mail From: error ($_)") if /^[45]/ or !$_;

	foreach my $to (@{$self->{to}}) {
		my $_to = $to =~ /</ ? $to : "<$to>";
		print S "rcpt to: $_to\015\012";
		chomp($_ = <S>);
		return fail("Error sending to <$to> ($_)\n") if /^[45]/ or !$_;
	}

	# start data part
	print S "data\015\012";
	chomp($_ = <S>);
	return fail("Cannot send data ($_)") if /^[45]/ or !$_;

	# print headers
	foreach my $header (keys %{$self->{header}}) {
		print S "$header: ", $self->{header}{$header}, "\015\012";
	};

	# send subject
	print S "Subject: $self->{subject}\015\012";

	# send message body
	print S "\015\012", $self->{message}, "\015\012.\015\012";

	chomp($_ = <S>);
	return fail("message transmission failed ($_)") if /^[45]/ or !$_;

	# finish
	print S "quit\015\012";
	$_ = <S>;
	close S;

	return 1;
}

# convert a time() value to a date-time string according to RFC 822
sub __time_to_date {
	my ($self, $time) = @_;
	$time ||= time();

	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @wdays  = qw(Sun Mon Tue Wed Thu Fri Sat);
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = (localtime($time));

	my $offset = timegm(localtime) - time;
	my $timezone = sprintf("%+03d%02d", int($offset / 3600), $offset % 3600);

	return sprintf("%s, %d %s %04d %02d:%02d:%02d %s",
		$wdays[$wday], $mday, $months[$mon], $year+1900, $hour, $min, $sec, $timezone);
}

# =============================================================================
# attach all images from content to email and send it

sub send_with_embed_images {
	my $self = shift;

	# text/plain => just sending email
	if ($self->{header}{'Content-Type'} !~ /text\/html/) {
		$self->send;
		return 1;
	}

	# if the message is said to be in UTF-8, we assume all headers are in it too and do some
	# MIME encoding
	if ($self->{header}{'Content-Type'} =~ /utf-8/i) {
		require Encode;
		$self->{$_} = Encode::encode("MIME-Header", $self->{$_}) for qw(from subject);
		$_ = Encode::encode("MIME-Header", $_) for @{$self->{to}}; 
	}
	
	my $data = {
		From			=> $self->{from},
		To				=> $self->{to},
		Subject			=> $self->{subject},
		( 
			map { $_ => $self->{header}{$_} } keys %{ $self->{header} } 
		),
		'Content-Type'	=> 'multipart/related; type="multipart/alternative"',
	};
	
	# searching for images in message body, wgetting them, attaching to email
	# and replacing img src attr with "cid:<attached-image-content-id>"

	my $new_message; # message after replacing src attr
	my $pics_to_attach; # Mail::Message::Body objects of wgetted images to attach to email
	my $img_counter = 0; # is used for naming attachments
	
	my $q_public_url = quotemeta( $system->config->get('public_url') );
	my $public_path = $system->config->get('public_path');

	# HTML::Parser handler for <img> tag: downloads image using src attr, attaches
	# image to email and replaces src attr with "cid:<image_content_id>"

	require Mail::Message;
	require Storable;
	require Digest::MD5;
	require Stuffed::System::File;

	my $start_handler = sub {
		my ($self, $attr, $tagname, $text) = @_;

		my $stash = $system->stash('__mail_embed_images');

		my $error = sub {
			$new_message .= $text;
			return;
		  };

		my $src = $attr->{src} if $attr;

		# processing only images with src attr defined
		return $error->() if $tagname ne 'img' or not $src;

		my $md5 = Digest::MD5::md5_hex($src);

		if (not exists $pics_to_attach->{$md5}) {

			# trying to find Mail::Message::Body object for the image in system stash
			my $body_pic = $stash->{$md5} ? Storable::thaw($stash->{$md5}) : undef ;

			# wgetting and attaching image in case we haven't already done that
			# (src attr is the key)
			if (not $body_pic) {
				my $image_file;

				# image src only has a path (no domain)
				if ($src !~ /^https?:\/\//) {
					
					# first, checking if the beginning of the src path is the same as our public path
					if ($src =~ /^$q_public_url/) {
						# in this case we actually know where the file is in the local file system
						$src =~ s/^$q_public_url/$public_path/;
						$image_file = $src if -r $src;
					}

					# if system's path is not found in src we add a default domain to the src and will try to get the image with LWP					
					if (false $image_file) {
						my $default_host = $system->config->get('default_host') || 'localhost'; 
						$src = '/'.$src if $src !~ /^\//;
						$src = 'http://'.$default_host.$src;
					}
				}

				my $unlink_file;

				if (false $image_file) {
					my $temp_dir = $system->path.'/private/system/temp';
					Stuffed::System::Utils::create_dirs($temp_dir) if not -d $temp_dir;
					$image_file = $temp_dir.'/mail_pic_'.$md5;
					$unlink_file = 1;
	
					require LWP::Simple;
					my $code = LWP::Simple::getstore($src, $image_file);
					return $error->() if $code ne '200' or not -e $image_file;
				}

				require MIME::Base64;
				open(F, '<', $image_file);
				local $/ = undef;
				my $pic_encoded = MIME::Base64::encode_base64(<F>);
				close(F);

				my $img_type;
				
				# first trying Image::Magick
				eval { 
					require Image::Magick;
					my $image = Image::Magick->new;
					$image->Read($image_file);
					$img_type = lc( $image->Get('magick') );
				};

				# then trying Imager
				if (false($img_type)) {
					eval { 
						require Imager;
						my $image = Imager->new || die Imager->errstr;
						$image->read(file => $image_file) || die $image->errstr;
						$img_type = lc( $image->tags(name => 'i_format') );
					};
				}

				# if everything fails, we will try to get the image type from the image extension
				if (false($img_type)) {
					($img_type) = lc($src) =~ /\.([^\.]+)$/;
				} 
				
				if (false($img_type)) {
					die "Unable to detect the image format in the mail message!";
				}

				$img_counter++;

				$body_pic = Mail::Message::Body->new(
					data				=> $pic_encoded,
					#mime_type			=> "image/$img_type; name=\"$img_counter.$img_type\"\nContent-ID:<$md5>",
					mime_type			=> "image/$img_type; name=\"$img_counter.$img_type\"",
					transfer_encoding	=> "base64",
				);
				
				# hacking deep inside Mail::Message internal object structure to 
				# add additional Content-ID header that we need here
				$body_pic->{MMB_transfer}[1] .= "Content-ID:<$md5>\n";
				
				# original -
#				'MMB_transfer' => bless( [
#                                            'Content-Transfer-Encoding',
#                                            ' base64
#				'
#                                          ], 'Mail::Message::Field::Fast' ),
				
				$stash->{$md5} = Storable::freeze($body_pic);

				unlink $image_file if $unlink_file;
			}

			$pics_to_attach->{$md5} = $body_pic;
		}

		$text =~ s/\s+src=(['"])[^'"]+\1/ src="cid:$md5"/;
		$new_message .= $text;

		$system->stash(__mail_embed_images => $stash) if $stash;
	};

	require HTML::Parser;
	HTML::Parser->new(
		api_version	=> 3,
		handlers	=> [
			default	=> [sub { $new_message .= shift }, 'text'],
			start	=> [$start_handler, 'self, attr, tagname, text'],
		  ],
	  )->parse($self->{message})->eof || die "Error while parsing images from message: $!";

	# no images found in the template, using standard send
	if (not $pics_to_attach or not keys %$pics_to_attach) {
		$self->send;
		return 1;
	}

	# the first part of the message is text part
	my $body_msg = Mail::Message::Body->new(
		data		=> $new_message."\n",
		mime_type	=> $self->{header}{'Content-Type'},
	  );

	$data->{attach} = [ $body_msg, values %$pics_to_attach ];
	
	my $msg = Mail::Message->build(%$data);
	
	if ($self->{mail_system} eq 'smtp') {
		$msg->send(
			via			=> 'smtp',
			hostname	=> $self->{smtp_server},
			port		=> $self->{smtp_port},
		)
	}
	else {
		$msg->send;
	}


	return 1;
}

1;