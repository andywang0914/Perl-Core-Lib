
package JUtility;

use strict;
use Geo::IP;
use JVars;
use Scalar::Util qw(looks_like_number);

sub to_url_name
{
	my ($class, $name, $force_taketours) = @_;
	$name = lc($name);
	$name =~ s/[^a-z0-9]/-/g;
	$name =~ s/-+/-/g;
	return $name;
}

sub check_or_create_dir
{
	my ($class, $path) = @_;
	if (-e $path)
	{
		return 1;
	}
	else
	{
		my @created = mkpath($path, {mode => 0755});
		chmod 0755, $path;
		return @created != ();
	}
}

sub round_down
{
	my ($class, $number) = @_;
	return eval sprintf("%d", $number);
}

sub round_off
{
	my ($class, $number) = @_;
	return eval sprintf("%d", $number + 0.5);
}

sub ip_record_by_addr
{
	my ($class, $ip) = @_;
	my $record;
	if($ip)
	{
		my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
		if ($gi)
		{
			$record = $gi->record_by_addr($ip);
		}
	}
	return $record;
}

sub parse_description
{
	my ($class, $desc) = @_;
    my $a_record;
    my %recordHash;
	while ($desc =~	/<([^&]*)>(.*?)<(\/\1)>/sg)
	{
		$recordHash{$1} = $2;
	}
    while ($desc =~ /<([^\>]*)>/sg)
    {
		$a_record = $1;
		while ($a_record =~ /&(\S+)\s*(.+)$/sg)
		{
			$recordHash{$1} = $2;
		}
	}
	return %recordHash;
}


sub subtract_arrays
{
	my ($class, $arr_ref1, $arr_ref2) = @_;
	my @array1 = @{$arr_ref1};
	my @array2 = @{$arr_ref2};
	my @result;
	my $item;
	my %counts;
	foreach $item (@array1)
	{
		$counts{$item} = 1;
	}
	foreach $item (@array2)
	{
		if ($counts{$item} == 1)
		{
			$counts{$item} = 0;
		}
	}
	foreach $item (keys %counts)
	{
		if ($counts{$item} == 1)
		{
			push @result, $item;
		}
	}
	return @result;
}

sub intersect_arrays
{
	my ($class, $arr_ref1, $arr_ref2) = @_;
	my @array1 = @{$arr_ref1};
	my @array2 = @{$arr_ref2};
	my @result;
	my $item;
	my %counts;
	foreach $item (@array1)
	{
		$counts{$item} = 1;
	}
	foreach $item (@array2)
	{
		if ($counts{$item} < 1)
		{
			$counts{$item} = 0;
		}
		$counts{$item}++;
	}
	foreach $item (sort keys %counts)
	{
		if ($counts{$item} > 1)
		{
			push @result, $item;
		}
	}
	return @result;
}

sub escape_XML
{
	my ($class, $xml) = @_;
	$xml =~ s/&/&amp;/g;
	$xml =~ s/</&lt;/g;
	$xml =~ s/>/&gt;/g;
	$xml =~ s/\"/&quot;/g;
	$xml =~ s/\'/&apos;/g;
	return $xml;
}


sub all_tag_values
{
	my ($class, $tag, $s, $keep_tag) = @_;
	my @values;
    while ($s =~ /<$tag(>|\s[^>]*>)(.*?)<\/$tag>/sg)
	{
		if ($keep_tag)
		{
      		push @values, '<' . $tag . $1 . $2 . '</' . $tag . '>';
		}
		else
		{
			push @values, $2;
		}
	}
	return @values;
}

sub tag_value
{
	my ($class, $t, $s) = @_;
	if ($s =~ /<$t(>|\s[^>]*>)(.*?)<\/$t>/is)
	{
		return JUtility->trim_string($2);
	}
	else
	{
		return "";
	}
}

sub trim_string
{
	my ($class, $string) = @_;
   	$string =~ s/^\s+//;
    $string =~ s/\s+$//;
	return $string;
}

sub is_number
{
	my ($class, $string) = @_;
	if(looks_like_number($string)) 
	{
 		 return 1;
	}
	else
	{
		return 0;	
	}
}

1;
