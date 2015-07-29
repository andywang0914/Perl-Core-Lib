
package JWebIO;

use strict;
use CGI;
use JVars;
my $local_webio;

sub new
{
	my ($class, $fastcgi) = @_;
    my $self = {
		
		_cookie	=> undef,
	};
	bless $self, $class;
	if (defined($fastcgi))
	{
		$self->{_cgi} = $fastcgi;
	}
	else
	{
			$self->{_cgi}= new CGI,	
		}
	if (!$self->{_cgi}) 
	{
		die "Unable to access Web Interface.";
	}
    return $self;
}

sub empty_cache
{
	my $class = shift;
	$local_webio = undef;	
	return '';
}

sub webio
{
	my ($class, $fastcgi) = @_;
	if (!$local_webio || defined($fastcgi)) 
	{
		$local_webio = new JWebIO($fastcgi);
	}
	return $local_webio;
}

sub cgi
{
	my $self = shift;
	return $self->{_cgi};
}

sub param
{
	my ($self, $name) = @_;
	if (!$local_webio) 
	{
		$local_webio = new JWebIO();
	}
	my $self = ref($self) ? $self : $local_webio;
	my $value = $self->cgi()->param($name);
	return $value;
}

sub get_web_cookie
{
	my ($self, $name) = @_;
	return $self->cgi()->cookie($name);
}


sub make_simple_cookie
{
	my ($self, $name, $v, $duration) = @_;
	return $self->append_single_cookie($name, $v, $duration);
}


sub append_single_cookie
{
	my ($self, $name, $v, $duration) = @_;
	my $d = JVars->cookie_domain();
	my $cgi = $self->cgi();
	my $cookie = $duration ? $cgi->cookie(-name => $name, -path => "/", -value => $v, -domain => $d, -expires => $duration)
						   : $cgi->cookie(-name => $name, -path => "/", -value => $v, -domain => $d);
	my @cookies = $self->{_cookie} ? @{$self->{_cookie}} : ();
	push @cookies, $cookie;
	$self->{_cookie} = \@cookies;
	return $self->{_cookie};
}

sub make_compact_cookie
{
    my ($self, $name, $values_ref, $duration) = @_;
    my $value = join('+|+', @{$values_ref});
	return $self->append_single_cookie($name, $value, $duration);
}

sub redirect
{
	my ($self, $url) = @_;
	my $cgi = $self->cgi();
	print $cgi->redirect("$url");	
}


sub all_parameters
{
	my $self = shift;
	my $self = ref($self) ? $self : $local_webio;
	my @all_parameters = $self->cgi()->all_parameters();
	return @all_parameters;
}

sub all_cookie_parameters
{
	my $self = shift;
	my $self = ref($self) ? $self : $local_webio;
	my @all_cookie_parameters;
	foreach (split(/; /,$ENV{'HTTP_COOKIE'})) 
	{
		my ($cookie,$value) = split(/=/);
		push @all_cookie_parameters, $cookie;

	}
	return @all_cookie_parameters;
}

sub all_parameters_info
{
	my $self = shift;
	my $self = ref($self) ? $self : $local_webio;		
	my %info;
	my @all_parameters = $self->all_parameters();
	foreach my $param (@all_parameters)
	{
		$info{$param} = $self->param($param);
	}
	my @all_cookie_parameters = $self->all_cookie_parameters();
	foreach my $param (@all_cookie_parameters)
	{
		$info{$param} = $self->get_web_cookie($param);
	}
	$info{'ip_address'} = $ENV{'REMOTE_ADDR'};
	return %info;
}
sub header_text
{
	my ($self, %header_info) = @_;
	my $cookie = $self->cookie();
	if (!$cookie) 
	{
		return $self->cgi()->header(-p3p=>'CAO PSA OUR', %header_info);
	}
	return $self->cgi()->header(-cookie=>$cookie, -p3p=>'CAO PSA OUR', %header_info);
}


sub cookie
{
	my ($self, $v) = @_;
	return $self->name_value('_cookie', $v);
}

sub name_value
{
	my ($self, $name, $value) = @_;
	if (defined($value)) 
	{
		$self->{$name} = $value;
	}
	return $self->{$name};
}

sub response
{
	my ($self, $html) = @_;
	my $character = JVars->character_set();
	my %header_info = (
			-charset	=> $character	,
		);
	print $self->header_text(%header_info);
	print $html;	
}
1;
