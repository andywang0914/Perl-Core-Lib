package JEmail;

use strict;
use MIME::Lite;
my $local_email_program = '/var/qmail/bin/qmail-inject';
sub new
{
	my ($class) = @_;
	my $self = { # these are object data: need accessors/setters
		_from		=> '',
		_to			=> '',
		_cc			=> '',
		_type		=> 'text/plain',
		_charset	=> '',
		_subject	=> '',
		_message	=> '',
		_body		=> '',
		_ip			=> '',
		_date		=> '',
		_from_name	=> '', # optional
		_to_name	=> '', # optional
		_x_priority	=> '', # optional
	};
	bless $self, $class;
	return $self;
}

sub mail_from
{
	my ($self, $from) = @_;
	if ($from) 
	{
		$self->{_from} = $from;
	}
	return $self->{_from};
}

sub mail_to
{
	my ($self, $to) = @_;
	if ($to) 
	{
		$self->{_to} = $to;
	}
	return $self->{_to};
}

sub mail_cc
{
	my ($self, $cc) = @_;
	if ($cc) 
	{
		$self->{_cc} = $cc;
	}
	return $self->{_cc};
}

sub mail_type
{
	my ($self, $t) = @_;
	if ($t) 
	{
		$self->{_type} = $t;
	}
	return $self->{_type};
}

sub charset
{
	my ($self, $c) = @_;
	if ($c) 
	{
		$self->{_charset} = $c;
	}
	return $self->{_charset};
}

sub subject
{
	my ($self, $subject)  = @_;
	if($subject)
	{
		$self->{_subject} = $subject;
	}
	return $self->{_subject};
}

sub message
{
	my ($self, $message)  = @_;
	if($message)
	{
		$self->{_message} = $message;
	}
	return $self->{_message};
}

sub body
{
	my ($self, $body) = @_;
	if ($body)
	{
		$self->{_body} = $body;
	}
	return $self->{_body};
}

sub ip
{
	my ($self, $ip) = @_;
	if ($ip)
	{
		$self->{_ip} = $ip;
	}
	return $self->{_ip};
}

sub date
{
	my ($self, $d) = @_;
	if ($d) 
	{
		$self->{_date} = $d;
	}
	return $self->{_date};
}

sub from_name
{
	my ($self, $v) = @_;
	if ($v) 
	{
		$self->{_from_name} = $v;
	}
	return $self->{_from_name};
}

sub to_name
{
	my ($self, $v) = @_;
	if ($v) 
	{
		$self->{_to_name} = $v;
	}
	return $self->{_to_name};
}

sub x_priority
{
	my ($self, $v) = @_;
	if ($v)
	{
		$self->{_x_priority} = $v;
	}
	return $self->{_x_priority};
}

sub is_html
{
	my ($class, $c) = @_;
	return ($c =~ /<br/i || $c =~ /<table/i || $c =~ /<p/i || $c =~ /<a/i || $c =~ /center>/i);
}

sub to_html
{
	my ($class, $text, $force) = @_;
	if (!$class->is_html($text) || $force)
	{
		$text =~ s/\r\n/<br\/>/g;
		$text =~ s/\n/<br\/>/g;
	}
	return $text;
}

sub send_mail
{
	my ($class, $charset, $sender, $subject, $receiver, $rcvName, $msg, $bcc_address, $attachments_ref, $attachments_names_ref) = @_;
	if (!$receiver || !$sender || !$msg || !$subject)
	{
		return "";
	}
	my $mailer = MIME::Lite->new(
	From	 	=> $sender,
	To      	=> $receiver,
	Subject 	=> $subject,
	Bcc	 		=> $bcc_address,
	Data	 	=> $msg,
	Encoding 	=> 'quoted-printable',
	Type    	=> 'text/html',
	);
	$mailer->attr("content-type.charset", $charset);
	$mailer->add("Return-Path", $sender);	
	#Add the attachments
	my @attachments;
	my @attachments_names;
	if($attachments_ref)
	{
		@attachments = @{$attachments_ref};
	}
	if($attachments_names_ref)
	{
		@attachments_names = @{$attachments_names_ref};
	}
	my $attachment_length = @attachments;
	for (my $i = 0; $i < $attachment_length; $i++)
	{
		my $attachment = $attachments[$i];
		my $file_type = JFile->file_type_lookup($attachment);
		my $file_name = $attachments_names[$i];
		if(!$file_name)
		{
			$file_name = JFile->get_filename_from_full_path($attachment);
		}
		$mailer->attach(
		Type     => $file_type,
		Encoding => "base64",
		Path     => $attachment,
		Filename => $file_name
		);
	}
	my ($uid, $domain) = split('@', $sender);
	$ENV{'MAILUSER'} = "$uid";
	MIME::Lite->send('sendmail', "$local_email_program");
	$mailer->send();
	return "";
}

1;
