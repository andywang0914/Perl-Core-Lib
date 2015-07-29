package JVars;

use strict;

sub cookie_domain
{
	my $class = shift;
	return '.domain.com';
}

sub domain
{
	my $class = shift;
	return 'http://www.domain.com';
}

sub character_set
{
	my $class = shift;
	return 'iso-8859-1';
}

sub admin_email
{
	my $class = shift;
	return 'admin@xxx.com';	
}

sub google_key
{
	my $class = shift;
	return 'Google Key Needed';	
}
1;

