# class JFolder

package JFolder;

use strict;

sub new
{
	my ($class, $path) = @_;
    my $self = {
        _path		=> undef,
	};
	bless $self, $class;
	if ($path) 
	{
		$self->path($path);
	}
    return $self;
}

sub path
{
	my ($self, $v) = @_;
	if (defined($v)) 
	{
		$self->{_path} = $v;
	}
	else
	{
		return $self->{_path};
	}
}

sub remove_folder
{
	my ($class, $path) = @_;
	if ($path =~ /\/$/)
	{
		
	}
	else
	{
		$path .= '/';	
	}	
	my $home_dir = JVars->home_dir();
	if ($home_dir ne $path)
	{
		system("rm -rf $path");
	}
	return '';
}

sub safe_remove_folder
{
	my ($class, $folder_path, $email_message) = @_;
	if (!$folder_path)
	{
		return '';	
	}
	my $folder = new JFolder($folder_path);
	if ($folder->can_remove())
	{
		JFolder->remove_folder($folder_path);	
	}
	else
	{ 
		die 'Cannot Remove Folder';
	}	
	return '';
}

sub file_names
{
	my $self = shift;	
	$self->add_path_slash();	
	my @names;	
	if ($self->path()) 
	{		
		if (opendir(DIR, $self->path()))
		{
			my @filelist = grep ( !/^\./, readdir(DIR));
			closedir(DIR);
			foreach my $f (@filelist)
			{
				if (-f $self->path() . $f) 
				{
					push @names, $f;
				}
			}
		}
	}
	return @names;
}

sub add_path_slash
{
	my $self = shift;
	if ($self->path() && $self->path() !~ /\/$/) 
	{
		$self->path($self->path() . '/');
	}
	return $self->path();
}

sub files
{
	my $self = shift;
	my @fs;
	$self->add_path_slash();	
	if ($self->path()) 
	{
		if (opendir(DIR, $self->path()))
		{
			my @filelist = grep ( !/^\./, readdir(DIR));
			closedir(DIR);
			foreach my $f (@filelist)
			{
				if (-d $self>path() . $f) 
				{
				}
				elsif (-f $self->path() . $f)
				{
					push @fs, new JFile($self->path() . $f);
				}
			}
		}
	}
	return @fs;
}

sub sub_folders
{
	my $self = shift;
	$self->add_path_slash();
	my @folders;
	if ($self->path()) 
	{
		if (opendir(DIR, $self->path()))
		{
			my @filelist = grep ( !/^\./, readdir(DIR));
			closedir(DIR);
			foreach my $f (@filelist)
			{
				if (-d $self->path() . $f)
				{
					push @folders, new JFolder($self->path() . $f);
				}
			}
		}
	}
	return @folders;
}

sub name 
{
	my $self = shift;
	my $path = $self->path();
    $path =~ s#\\#/#g;
    my @sep_dirs = split('/', $path);
    my $len = @sep_dirs;
    return $sep_dirs[$len - 1];
}

sub create
{
	my $self = shift;
	my $path = $self->path();
	if (!$path)
	{
		return 0;
	}
	if (-e $path) 
	{
		return 0;
	}
	my $success = mkdir($path, 0755);
	chmod 0755, $path;
	return $success;
}


sub all_sub_files
{
	my $self = shift;
	my @files = $self->files();
	my @sub_folders =  $self->sub_folders();
	if(!@sub_folders)
	{
		return @files;
	}
	else
	{
		foreach my $sub_folder(@sub_folders)
		{
			my @temp_files = $sub_folder->all_sub_files();
			@files = (@files, @temp_files);
		}
		return @files;
	}
}

sub can_remove
{
	my $self = shift;
	my @files = $self->all_sub_files();
	my @sub_folders = $self->sub_folders();
	return !@files && !@sub_folders;
}


1;