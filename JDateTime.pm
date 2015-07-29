##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1998-2002 IvyMedia  All Rights Reserved.                         #
#                                                                            #
# Selling the code for this program is expressly forbidden.                  #
##############################################################################
package JDateTime;

use strict;
use Date::Simple;
use Time::Local;

our @ISA = qw(JDate);

sub new # May get changed
{
	my $class = shift;
	my $self = $class->SUPER::new();
	bless $self, $class;
	return $self;
}

sub get_date_time_string_before_hours
{
	my ($class, $hours) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time + $hours * 3600);
	if ($year < 90) 
	{
		$year += 2000;
	}
	elsif ($year < 1000)
	{  
		$year += 1900;
	}
	$mon++;
	my $mon_text = ($mon < 10) ? "0$mon" : "$mon";
	my $day_text = ($mday < 10) ? "0$mday" : "$mday";
	my $hour_text = ($hour < 10) ? "0$hour" : "$hour";
	my $min_text = ($min < 10) ? "0$min" : "$min";
	my $sec_text = ($sec < 10) ? "0$sec" : "$sec";
	return "$year-$mon_text-$day_text $hour_text:$min_text:$sec_text";
}


sub get_date_time_string
{
	my $class = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
	if ($year < 90) 
	{
		$year += 2000;
	}
	elsif ($year < 1000)
	{  
		$year += 1900;
	}
	$mon++;
	my $mon_text = ($mon < 10) ? "0$mon" : "$mon";
	my $day_text = ($mday < 10) ? "0$mday" : "$mday";
	my $hour_text = ($hour < 10) ? "0$hour" : "$hour";
	my $min_text = ($min < 10) ? "0$min" : "$min";
	my $sec_text = ($sec < 10) ? "0$sec" : "$sec";
	return "$year-$mon_text-$day_text $hour_text:$min_text:$sec_text";
}

sub get_date_time_hour_diff
{
	my ($class, $time_one, $time_two) = @_;	
	my $time_first;
	my $time_second;
	if($time_one =~ /(\d{4})-(\d{2})-(\d{2})\s(\d{1,2}):(\d{2}):(\d{2})/)
	{
		$time_first = timelocal(int($6), int($5), int($4), int($3), int($2)-1, int($1)-1900);
	}
	if($time_two =~ /(\d{4})-(\d{2})-(\d{2})\s(\d{1,2}):(\d{2}):(\d{2})/)
	{
		$time_second = timelocal(int($6), int($5), int($4), int($3), int($2)-1, int($1)-1900);
	}
	my $hours = ( $time_first - $time_second ) / 3600;
	return $hours;
}


sub get_current_hour
{
	my $class = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	return $hour + $min * 0.01666;
}

sub get_time_string
{
	my $class = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
	my $hour_text = ($hour < 10) ? "0$hour" : "$hour";
	my $min_text = ($min < 10) ? "0$min" : "$min";
	my $sec_text = ($sec < 10) ? "0$sec" : "$sec";
	return "$hour_text:$min_text:$sec_text";
}

sub get_date_time_min_diff
{
	my ($class, $time_one, $time_two) = @_;	
	my $time_first;
	my $time_second;
	if($time_one =~ /(\d{4})-(\d{2})-(\d{2})\s(\d{1,2}):(\d{2}):(\d{2})/)
	{
		$time_first = timelocal(int($6), int($5), int($4), int($3), int($2)-1, int($1)-1900);
	}
	if($time_two =~ /(\d{4})-(\d{2})-(\d{2})\s(\d{1,2}):(\d{2}):(\d{2})/)
	{
		$time_second = timelocal(int($6), int($5), int($4), int($3), int($2)-1, int($1)-1900);
	}
	my $mins = ( $time_first - $time_second ) / 60;
	return $mins;
}

sub seconds_to_date_time
{
	my ($class, $seconds_string) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($seconds_string);
	if ($year < 90) 
	{
		$year += 2000;
	}
	elsif ($year < 1000)
	{  
		$year += 1900;
	}
	$mon++;
	my $mon_text = ($mon < 10) ? "0$mon" : "$mon";
	my $day_text = ($mday < 10) ? "0$mday" : "$mday";
	my $hour_text = ($hour < 10) ? "0$hour" : "$hour";
	my $min_text = ($min < 10) ? "0$min" : "$min";
	my $sec_text = ($sec < 10) ? "0$sec" : "$sec";
	return "$year-$mon_text-$day_text $hour_text:$min_text:$sec_text";
}

sub hour_to_time
{
	my ($class, $h) = @_;
	my $d_h = JUtility->round_down($h);
	my $m = $h - $d_h;
	my $d_m = ($m > 0.001) ? JUtility->round_off($m * 60) : "0";
	$d_h = ($d_h < 10) ? "0$d_h" : "$d_h";
	$d_m = ($d_m < 10) ? "0$d_m" : "$d_m";
	return qq{$d_h:$d_m:00};
}

1;
