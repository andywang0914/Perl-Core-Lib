
package JFile;

use strict;
use File::Copy;
use HTTP::Request::Common;
use LWP::UserAgent;
use JVars;
use JDateTime;
use Archive::Extract;
use Algorithm::Diff qw(diff);
use Image::Size;
use Tie::File;

my %local_file_type =
(
'pdf'	=>	'application/pdf',
'ppt'	=>	'application/x-download',
'swf'	=>	'application/x-shockwave-flash',
'tar'	=>	'application/x-download',
'zip'	=>	'application/x-download',
'rar'	=>	'application/x-download',
'jpg'	=>	'image/jpeg',
'jpeg'	=>	'image/jpeg',
'png'	=>	'image/png',
'gif'	=>	'image/gif',
'bmp'   =>  'image/bmp',
'doc'	=>	'application/msword',
'xls'	=>	'application/vnd.ms-excel',
'txt'	=>	'text/plain',
'html'	=>	'text/html',
'htm'	=>	'text/html',
'docx'	=>	'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
'xlsx'	=>	'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
'pptx'	=>	'xapplication/vnd.openxmlformats-officedocument.presentationml.presentation',
'wps'	=>	'application/msword',
'csv'	=>	'application/x-download',
'eml'	=>	'email_customer',
'rtf'	=>	'application/msword',
'odt'	=>	'application/x-download',
'msg'	=>	'email_customer',
'unknow'	=>	'unknow',
);



sub new
{
	my ($class, $path) = @_;
	my $self = {
		_path		=> undef,
		_content	=> undef,
		_exist		=> undef,
	};
	bless $self, $class;
	if ($path)
	{
		$self->path($path);
	}
	return $self;
}

sub exist
{
	my $self = shift;
	if (!defined($self->{_path}))
	{
		return 0;
	}
	if (!defined($self->{_exist}))
	{
		$self->{_exist} = (-e $self->{_path});
	}
	return $self->{_exist};
}

sub path
{
	my ($self, $path) = @_;
	if (defined($path))
	{
		$self->{_path} = $path;
	}
	return $self->{_path};
}

sub filename
{
	my $self = shift;
	my $path = $self->path();
	$path =~ s#\\#/#g;
	my @sep_dirs = split('/', $path);
	my $len = @sep_dirs;
	return $sep_dirs[$len - 1];
}

sub content
{
	my ($self, $content) = @_;
	if (defined($content))
	{
		$self->{_content} = $content;
	}
	return $self->{_content};
}

sub read_to_content
{
	my $self = shift;
	return (defined($self->{_path}) ? $self->content(JFile->read_content($self->{_path})) : undef);
}

sub save
{
	my ($self, $content) = @_;
	if (defined($content))
	{
		$self->{_content} = $content;
	}
	if (defined($self->{_path}))
	{
		JFile->save_content($self->{_path}, $self->{_content});
		return "";
	}
	else
	{
		return "File not defined";
	}
}

sub empty
{
	my $self = shift;
	$self->{_content} = " ";
	$self->save();
}

sub remove
{
	my $self = shift;
	if ($self->path())
	{
		return unlink $self->path();
	}
	return 0;
}

sub upload_from
{
	my ($self, $local_file, $max_size) = @_;
	my $path = $self->path();
	if (!$path)
	{
		return "No target file to upload";
	}
	if (-d $path)
	{
		JEmail->report_dev_error('Home Dir protect', qq{upload_from:  $path});
		return '';
	}
	my $filename = $self->filename();
	my $tmp = "/tmp/$filename";
	open (OUTFILE, ">$tmp");
	my $buffer;
	my $total_size = 0;
	binmode OUTFILE;
	while (my $byteread=read($local_file, $buffer, 1024))
	{
		$total_size += $byteread;
		if ($max_size && $total_size > $max_size)
		{
			my $err_msg = qq{content exceeds the limit of $max_size};
			$max_size = $max_size/1000000;
			$err_msg = "content exceeds the limit of $max_size";
			return $err_msg;
		}
		print OUTFILE $buffer;
		$self->{_content} .= $buffer;
	}
	close(OUTFILE);
	copy($tmp, $path) || die $!;
	chmod 0644, $tmp;
	unlink $tmp || die $!;
	chmod 0644, $path;
	return '';

}

sub copy_from_url
{
	my ($self, $url) = @_;
	return  $self->content_from_url($url) ? $self->save() : "URL $url is either empty or does not exist.";
}

sub content_from_url
{
	my ($self, $url) = @_;
	my $ua = new LWP::UserAgent;
	my $res = $ua->request(HTTP::Request::Common::GET("$url"));
	$self->{_content} = ($res->is_success) ? $res->content : '';
	return $self->{_content};
}

sub copy_to
{
	my ($self, $path) = @_;
	my $p = $self->path();
	if ($p && $path && -e $p)
	{
		copy($p, $path);
	}
}

sub increase_version
{
	my ($self, $total) = @_;
	my $filename = $self->path();
	if (-e $filename)
	{
		my $new_file = $filename . ".$total";
		for (my $i=$total-1; $i>0; $i--)
		{
			my $old_file = $filename . ".$i";
			if (-e $old_file)
			{
				rename($old_file, $new_file);
			}
			$new_file = $old_file;
		}
		rename($filename, $new_file);
	}
}

sub save_by_version
{
	my ($self, $total) = @_;
	$self->increase_version($total);
	$self->save();
}

sub save_content
{
	my ($class, $filename, $content, $ignore_to_big5) = @_;
	if ( -d $filename)
	{
		die 'Folder Detected';
	}
	open(SAVEFILE, ">$filename");
	print SAVEFILE $content;
	close(SAVEFILE);
	chmod 0644, $filename;
}

sub version_save
{
	my ($class, $total, $filename, $content) = @_;
	my $f = new JFile($filename);
	$f->content($content);
	$f->save_by_version($total);
	return "";
}

sub version_save_content
{
	my ($class, $dir, $total, $name, $content) = @_;
	$class->version_save($total, $dir . $name, $content);
}

sub read_content
{
	my ($class, $filename) = @_;
	if (-e $filename)
	{
		my $admin_email = JVars->admin_email();
		open(BODYFILE, "$filename") || die "Please notify $admin_email for this error: " . $!;
		my @lines = <BODYFILE>;
		close(BODYFILE);
		my $content = join('', @lines);
		return $content;
	}
	return '';
}


sub read_content_lines
{
	my ($class, $filename) = @_;
	my @lines;
	if (-e $filename)
	{
		my $admin_email = JVars->admin_email();
		open(BODYFILE, "$filename") || die "Please notify $admin_email for this error: " . $!;
		@lines = <BODYFILE>;
		close(BODYFILE);
		my $content = join('', @lines);
		return $content;
	}
	return @lines;
}

sub download_file
{
	my ($self, $type) = @_;
	my $filename = $self->path();
	open(DL, $filename);
	my $len = -s $filename;
	binmode(DL); # req'd for Win, ignored on others
	print "Content-type: application/$type\nContent-length: $len\n\n";
	print <DL>;
	close(DL);
}

sub remove_file
{
	my ($class, $filename) = @_;
	return unlink $filename;
}

sub print_file
{
	my ($class, $filename, $real_name) = @_;
	my $content_type = JFile->file_type_lookup($filename);
	if(!$content_type)
	{
		return "unknow file type";
	}
	my $print_download;
	if ($content_type eq "application/x-download" || $content_type eq "application/octet-stream")
	{
		my $save_name = JFile->get_filename_from_full_path($filename);
		$save_name =~ s/ //img;
		$real_name = $real_name ? $real_name : $save_name;
		if (open(FILE, $filename))
		{
			my $len = -s $filename;
			binmode(FILE); # req'd for Win, ignored on others
			print "Content-type: $content_type\n";
			print "Content-length: $len\n";
			print "Content-Disposition:attachment;filename=\"$real_name\"\n";
			print "\n";
			print <FILE>;
			close(FILE);
		}
	}
	else
	{
		my $save_name = JFile->get_filename_from_full_path($filename);
		$real_name = $real_name ? $real_name : $save_name;
		if (open(FILE, $filename))
		{
			my $len = -s $filename;
			binmode(FILE); # req'd for Win, ignored on others
			print "Content-type: $content_type\nContent-length: $len\n";
			print "Content-Disposition:attachment;filename=\"$real_name\"\n";
			print "\n";
			print <FILE>;
			close(FILE);
		}
	}
	return '';
}

sub file_type_lookup
{
	my ($class, $filename) = @_;
	my @types = keys %local_file_type;
	foreach my $t (@types)
	{
		if ($filename =~ /.$t$/i)
		{
			return $local_file_type{$t};
		}
	}
}
sub unzip_to
{
	my ($class, $filename, $to) = @_;
	my $ae = Archive::Extract->new( archive => "$filename", type => 'tgz' );
	my $ok = $ae->extract( to => "$to" )  or die "Can't extract: " . $ae->error();
	my $outdir  = $ae->extract_path();
	return $outdir;
}


sub get_filename_from_full_path
{
	my ($class, $path) = @_;
	$path =~ s#\\#/#g;
	my @sep_dirs = split('/', $path);
	my $len = @sep_dirs;
	my $filename = $sep_dirs[$len - 1];
	$filename =~ s/#//g;
	return $filename;
}

sub remove_dir_files
{
	my ($class, $dir, $match) = @_;
	if (!$match)
	{
		return 0;
	}
	$match = JUtility->trim_string($match);
	if (!$match || length($match) < 2)
	{
		return 0;
	}
	opendir(TARGETDIR, $dir);
	foreach my $name (readdir(TARGETDIR))
	{
		if ($name =~ /$match/)
		{
			unlink $dir . $name;
		}
	}
	return 1;
	closedir(TARGETDIR);
}

sub append_to_file
{
	my ($class, $filename, $content) = @_;
	open(SAVEFILE, ">>$filename");
	print SAVEFILE $content;
	close(SAVEFILE);
}

sub last_modify_time
{
	my ($class, $filename) = @_;
	if (-e $filename)
	{
		my @file_info = stat($filename);
		my $seconds = $file_info[9];
		return JDateTime->seconds_to_date_time($seconds);
	}
	return '';
}

sub get_image_width_and_height
{
	my ($class, $imgname) = @_;
	my ($width, $height) = imgsize($imgname);
	return ($width, $height);
}

sub get_file_size
{
	my ($class, $file) = @_;
	my $total_size = 0;
	if (-e $file)
	{
		my @args = stat ($file);
		$total_size = $args[7];
	}
	return $total_size;
}

sub tail_file
{
	my ($class, $filename, $last_lines) = @_;
	my @array;
	tie @array, 'Tie::File', $filename;
	my $total_lines = @array;
	my $start_index = $total_lines - $last_lines;
	my $i;
	my $string;
	for ($i = $start_index; $i < $total_lines; $i++)
	{
		$string .= $array[$i] . "\n";
	}
	return $string;
}

sub tail_file_array
{
	my ($class, $filename, $last_lines) = @_;
	my @array;
	tie @array, 'Tie::File', $filename;
	my $total_lines = @array;
	my $start_index = $total_lines - $last_lines;
	if ($start_index <0)
	{
		$start_index = 0;
	}
	my $i;
	my @return_array;
	for ($i = $start_index; $i < $total_lines; $i++)
	{
		push @return_array, $array[$i];
	}
	return @return_array;
}

1;
