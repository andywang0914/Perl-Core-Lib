
package JDistance;


use strict;
use WWW::Google::DistanceMatrix;
use JSON;
use URI::Escape;
use LWP::Simple;
my $local_google_key = JVars->google_key();
my $local_google_geo_url = "http://maps.google.com/maps/geo?output=xml&key=$local_google_key&q=";
my $pi = atan2(1,1) * 4;

sub distance
{
	my ($class, $lat1, $lon1, $lat2, $lon2, $unit) = @_;
	#$unit  k => kilometers  M=>miles  n=>Nautical Miles
	my $theta = $lon1 - $lon2;
	my $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
  	$dist  = acos($dist);
  	$dist = rad2deg($dist);
  	$dist = $dist * 60 * 1.1515;
  	if ($unit eq "K")
  	{
  		$dist = $dist * 1.609344;
  	}
 	elsif ($unit eq "N")
  	{
  		$dist = $dist * 0.8684;
 	}
  	return ($dist);
}

sub acos
{
	my ($rad) = @_;
	my $ret = atan2(sqrt(1 - $rad**2), $rad);
	return $ret;
}

sub deg2rad
{
	my ($deg) = @_;
	return ($deg * $pi / 180);
}

sub rad2deg
{
	my ($rad) = @_;
	return ($rad * 180 / $pi);
}

# meters not km
sub get_meters_by_latitude_and_longitude
{
	my ($class, $f_lati, $f_longi, $t_lati, $t_longi, $with_distance_if_google_failed) = @_;
	my $from_latlng = $f_lati . "," . $f_longi;
	my $to_latlng = $t_lati . "," . $t_longi;
	my $google = WWW::Google::DistanceMatrix->new( 'api_key' => $local_google_key);
	my %param_hash;
	$param_hash{'o_latlng'} = ["$from_latlng"];
	$param_hash{'d_latlng'} = ["$to_latlng"];
	my $distance = 0;
	my $results;
	eval{
		$results = $google->getDistance(\%param_hash);
	};
	if (!$@ &&  $results) 
	{
		my @array = @$results;
		$distance = $array[0]->distance();
		if ($distance =~ /km/)
		{
			$distance =~ s/ km//isg;
			$distance =~ s/,//isg;	
			$distance =~ s/,//isg;
			$distance *= 1000;
		}
		else
		{
			$distance = 0;	
		}
	}
	if ($distance <= 1 && $with_distance_if_google_failed)
	{
		$distance = int(JDistance->distance($f_lati, $f_longi, $t_lati, $t_longi, "K") * 1000);
	}
	return $distance;
}


#return an array contains (latitude, longitude);
sub address_to_coordinate
{
	my ($self, $address) = @_;
	return () unless(length($address)>2);
	$address = URI::Escape::uri_escape($address);
	my $url = $local_google_geo_url.$address;
	my $content = LWP::Simple::get($url);
	if($content && $content =~ /<coordinates>(.+?)<\/coordinates>/m )
	{
		my $coordinates = $1;
		my ($longitude, $latitude, $zindex) = split(/,/, $coordinates);
		return ($latitude, $longitude);
	}
	return ();
}
