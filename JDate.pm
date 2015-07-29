
package JDate;

use strict;
use Date::Simple (':all');
use overload '-' => 'subtract';
use overload '+' => 'add';
use Date::Manip;
use Date::Parse;

sub new
{
	my ($class, $inst_date) = @_;
	my $self = {};
	bless $self, $class;
	$self->{_date_obj} = JDate->get_date_simple_obj($inst_date);
	return $self;
}

sub year
{
	my $self = shift;
	return $self->{_date_obj} ? $self->{_date_obj}->year : '';
}

sub month
{
	my $self = shift;
	return $self->{_date_obj} ? $self->{_date_obj}->month : '';
}

sub day
{
	my $self = shift;
	return $self->{_date_obj} ? $self->{_date_obj}->day : '';
}

sub to_string
{
	my ($self, $format) = @_;
	if (!$format)
	{
		$format = "%Y-%m-%d";
	}
	$self->date_obj()->format($format);
}

sub to_us_format
{
	my $self = shift;
	return $self->to_string() . " " . $self->short_day_of_week();	
}

sub date_obj
{
	my ($self, $date_obj) = @_;
	if (defined($date_obj))
	{
		$self->{_date_obj} = $date_obj;
	}
	else
	{
		if (!$self->{_date_obj})
		{
			$self->{_date_obj} = Date::Simple->new();
		}
		return $self->{_date_obj};
	}
}

sub add
{
	my ($self, $days) = @_;
	my $sd = $self->date_obj() + $days;
	my $d = new JDate();
	$d->date_obj($sd);
	return $d;
}

sub subtract # $d1 - d2 or $d1 - 5
{
	my ($self, $second_operand) = @_;
	return ref($second_operand) ? $self->date_obj() - $second_operand->date_obj() : $self->add(-$second_operand);
}

sub today_string
{
	my $class = shift;
	return $class->get_todays_date();
}

sub get_week_day
{
	my $class = shift;
	my $today = JDate->get_todays_date();
	return JDate->to_weekday($today);	
}

sub get_todays_date
{
	my $class = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
	return $class->get_that_date_string($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
}

sub tomorrow_string
{
	my $class = shift;
	return $class->get_tomorrows_date();
}

sub get_tomorrows_date
{
	my $class = shift;
	return $class->get_date_string_after_hours(24);
}

sub get_yestoday_date
{
	my $class = shift;
	return $class->get_date_string_after_hours(-24);
}
sub yestoday_string
{
	my $class = shift;
	return $class->get_yestoday_date();
}

sub get_date_string_after_hours
{
	my ($class, $hours) = @_;
	return $class->get_that_date_string(localtime(time + $hours * 3600));
}

sub get_that_date_string
{
	my ($class, $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @_;
	my @months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
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
	return "$year-$mon_text-$day_text";
}

sub get_that_date_string_us_format
{
	my ($class, $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @_;
	my $date = JDate->get_that_date_string($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	my $d = new JDate($date);
	return $d->to_us_format();
}


sub get_char_month
{
	my ($class, $month) = @_;
	my %month_list = (
		'1'	=> "Jan",
		'2'	=> "Feb",
		'3'	=> "Mar",
		'4'	=> "Apr",
		'5'	=> "May",
		'6'	=> "Jun",
		'7'	=> "Jul",
		'8'	=> "Aug",
		'9'	=> "Sep",
		'10' => "Oct",
		'11' => "Nov",
		'12' => "Dec",
	);
	return $month_list{$month};
}

sub get_char_en_month
{
	my ($class, $month) = @_;
	my %month_list = (
		'1'	=> "Jan",
		'2'	=> "Feb",
		'3'	=> "Mar",
		'4'	=> "Apr",
		'5'	=> "May",
		'6'	=> "Jun",
		'7'	=> "Jul",
		'8'	=> "Aug",
		'9'	=> "Sep",
		'10' => "Oct",
		'11' => "Nov",
		'12' => "Dec",
	);
	return $month_list{$month};
}

sub get_date_simple_obj
{
	my ($class, $date) = @_;
	my $d;
	if ($date)
	{
		my $year = substr($date, 0 , 4);	
		my $month = substr($date, 5 , 2);	
		my $day = substr($date, 8 , 2);
		if ($year >= 1901 && $year <= 2038 && $month >=1 && $month <=12)
		{	
		my $last_day = days_in_month($year,$month);
		if ($day > $last_day)
		{
			$date = qq{$year-$month-$last_day};	
		}
		}
		$d = Date::Simple->new($date);
	}
	else
	{
		$d = Date::Simple->new();
	}
	return $d;
}

sub _day_of_week
{
	my $date = shift;
	my $dt  = JDate->get_date_simple_obj($date);
	if ($dt)
	{
		return $dt->day_of_week();
	}
}

sub day_of_week
{
	my $self = shift;
	if ($self->date_obj())
	{
		return $self->date_obj()->day_of_week();
	}
}

sub short_day_of_week
{
	my $self = shift;
	my @weeks = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
	return $weeks[$self->day_of_week()]
}

sub week_day
{
	my ($class, $date) = @_;
	my $dt  = JDate->get_date_simple_obj($date);
	return $dt->day_of_week();
}

sub to_weekday
{
	my ($class, $date) = @_;
	my @weeks = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
	return $weeks[_day_of_week($date)];
}

sub extract_date
{
	my ($class, $string) = @_;
	if ($string =~ m/([0-9]{4}-[0-9]{2}-[0-9]{2})/)
	{
		return $1;
	}
	return '';
}

sub get_last_week_ends
{
	my $class = shift;
	my $today = new JDate();
	my $day_of_week =  $today->day_of_week();
	my $today_string = JDate->get_todays_date();
	my $s_date = JDate->get_offset_date($today_string, -$day_of_week - 7);
	my $e_date = JDate->get_offset_date($today_string, -$day_of_week);
	return ($s_date, $e_date);
}

sub get_current_month_ends
{
	my $class = shift;
	my $end_date = new JDate();
	my $start_date = $end_date - ($end_date->day() - 1);
	return ($start_date->to_string(), $end_date->to_string());
}

sub get_last_month_ends
{
	my $class = shift;
	my $d = new JDate();
	my $end_date = $d - $d->day();
	my $start_date = $end_date - ($end_date->day() - 1);
	return ($start_date->to_string(), $end_date->to_string());
}


sub get_previous_month_ends
{
	my $class = shift;
	my $today_string = JDate->today_string();
	my ($year, $month, $date) = split '-', $today_string;
	my $endDate = JDate->get_offset_date($today_string, -$date);
	($year, $month, $date) = split '-', $endDate;
	my $startDate = "$year-$month-01";
	return ($startDate, $endDate);
}


sub offset_date_object
{
	my ($class, $date, $offset, $unit) = @_;
	my $d = new JDate($date);
	my $year;
	my $month;
	my $day;
	my $returndate;
	if ($unit eq "year")
	{
		$year = $d->year() + $offset;
		$month = $d->month();
		$day = $d->day();
		$month = ($month < 10) ? "0$month" : $month;
		$day = ($day < 10) ? "0$day" : $day;
		$returndate = $year . "-" . $month . "-" . $day;
		$d = new JDate($returndate);
		#$d->date_obj(Date::Simple->new($returndate));
	}
	elsif ($unit eq "month")
	{
		my $y_offset = 0;
		my $m = $offset + $d->month();
		while ($m > 12)
		{
			$y_offset++;
			$m = $m - 12;
		}
		while ($m < 1)
		{
			$y_offset--;
			$m = $m + 12;
		}
		if ($y_offset) 
		{
			$year = $d->year() + $y_offset;
		}
		else
		{
			$year = $d->year();	
		}
		$month = ($m < 10) ? "0$m" : $m;
		$day = $d->day();
		$day = ($day < 10) ? "0$day" : $day;
		$returndate = $year . "-" . $month . "-" . $day;
		$d = new JDate($returndate);
		#$d->date_obj(Date::Simple->new($returndate));
	}
	elsif ($unit eq "hour")
	{
		$returndate =  JDate->get_that_date_string(localtime(time + $offset * 3600));
		$d = new JDate($returndate);
		#$d->date_obj(Date::Simple->new($returndate));
	}
	else
	{
		$d = $d + $offset;
	}
	return $d;
}


sub round_up
{
	my ($class, $number) = @_;
	return eval sprintf("%d", $number + 0.99999);
}


sub get_past_date
{
	my ($class, $adjust_hour) = @_;
	return JDate->get_offset_date(JDate->today_string(), $adjust_hour, 'hour');	
}

sub get_offset_date_us_format
{
	my ($class, $date, $offset, $unit) = @_;
	my $d = $class->offset_date_object($date, $offset, $unit);
	if (!defined($d))
	{
		return '';
	}
	return $d->to_us_format();
}


sub get_offset_date
{
	my ($class, $date, $offset, $unit) = @_;
	my $d = $class->offset_date_object($date, $offset, $unit);
	if (!defined($d)) 
	{
		return '';
	}
	return $d->to_string();
}

sub get_month_days
{
	my ($class, $date) = @_;
	my $date_start = new JDate($date);
	my $year_start = $date_start->year();
	my $month_start = $date_start->month();
	my $year_end = $year_start;
	my $month_end = $month_start +1;
	if ($month_start == 12)
	{
		$year_end = $year_end + 1;
		$month_end = 1;
	}
	$month_end = ($month_end < 10) ? "0$month_end" : $month_end;
	$month_start = ($month_start < 10) ? "0$month_start" : $month_start;
	my $date_end = new JDate($year_end . "-" . $month_end . "-01");
	my $date_start_string = $year_start . "-" . $month_start . "-01";
	my $d = new JDate($date_start_string);
	my $days = $date_end - $d;
	return $days;
}
sub get_next_month_days
{
	my ($class, $date) = @_;
	my $date_start = new JDate($date);
	my $year_start = $date_start->year();
	my $month_start = $date_start->month();
	my $year_end = $year_start;
	my $month_end = $month_start +1;
	if ($month_start == 12)
	{
		$year_end = $year_end + 1;
		$month_end = 1;
	}
	$month_end = ($month_end < 10) ? "0$month_end" : $month_end;
	my $date_end = $year_end . "-" . $month_end . "-01";
	return JDate->get_month_days($date_end);
}
sub get_next_month_string
{
	my ($class, $date_start) = @_;
	my $year_start = $date_start->year();
	my $month_start = $date_start->month();
	my $year_end = $year_start;
	my $month_end = $month_start +1;
	if ($month_start == 12)
	{
		$year_end = $year_end + 1;
		$month_end = 1;
	}
	$month_end = ($month_end < 10) ? "0$month_end" : $month_end;
	my $date_end = $year_end . "-" . $month_end . "-01";
	return $date_end;
}

sub compare
{
	my ($class, $date1, $date2) = @_;
	return &Date_Cmp($date1,$date2);
	# < 0: date1 is earlier than date2
	# = 0: date1 is eq date2
	# > 0: date1 is later than date2
}

sub get_month_day_string
{
	my ($class, $date) = @_;
	my $date_start = new JDate($date);
	my $month = $date_start->month();
	my $day = $date_start->day();
	return $month . "/" . $day;	
}

sub is_date_string
{
	my ($class, $date_string) = @_;
	if (ParseDateString($date_string))
	{
		return 1;
	}
	return 0;
}

sub dates_between_two_days
{
	my ($class, $from_string, $to_string) = @_;
	my @dates;
	if ($from_string && $to_string)
	{
		my $date_string = $from_string;
		while($class->compare($date_string, $to_string) <= 0)
		{
			push @dates, $date_string;
			$date_string = $class->get_offset_date($date_string, 1);
		}
	}
	return @dates;
}


sub get_year 
{
	my $class = shift;
	my $date_string = JDate->get_todays_date();
	return substr($date_string, 0 , 4);
}
	
sub get_day
{
	my $class = shift;
	my $today = JDate->get_todays_date();
	my $d = new JDate($today);
	return $d->day();	
}


sub get_month_ends
{
	my $class = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
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
	return ($year . '-' . $mon_text . "-01", $year . '-' . $mon_text . '-' . $day_text);
}
	
	
sub parse_date
{
	my ($class, $string) = @_;
	if ($string =~ m/([0-9]{4}-[0-9]{2}-[0-9]{2})/)
	{
		return $1;
	}
	else
	{
		return '';
	}
}

sub us_date_to_string
{
	my ($class, $m, $d, $y) = @_;
	if (!$m || !$d || !$y)
	{
		return '';
	}
	my %months = ('Jan' => "01", 'Feb' => "02", 'Mar' => "03", 'Apr' => "04", 'May' => "05",
				  'Jun' => "06", 'Jul' => "07", 'Aug' => "08", 'Sep' => "09", 'Oct' => "10",
				  'Nov' => "11", 'Dec' => "12");
	my $date = ($d < 10) ? "0$d"  : $d;
	return	"$y-$months{$m}-$date";
}

sub months_string_between_two_days
{
	my ($class, $from_string, $to_string) = @_;
	my $time_from = str2time($from_string);
	my $time_to = str2time($to_string);
	my $days = ($time_to - $time_from) / 86400;
	my @months;
	for(my $i = 1; $i<= $days; $i++)
	{
		my $date_string = $class->get_offset_date($from_string,$i);
		my $month = $date_string;
		$month =~ s/-//g;
		$month = substr($month, 0, 6);		
		push @months, $month;
	}
	my %hash;
  	my @result =grep(!$hash{$_}++, @months);
  	return @result;
}

sub min_date
{
	my ($class, $date1, $date2) = @_;
	my $compare = &Date_Cmp($date1,$date2);
	if($compare < 0)
	{
		return $date1;
	}
	return $date2;
}

sub max_date
{
	my ($class, $date1, $date2) = @_;
	my $compare = &Date_Cmp($date1,$date2);
	if($compare < 0)
	{
		return $date2;
	}
	return $date1;
}	

sub between_date_range
{
	my ($class, $date_from, $date_to, $date) = @_;
	if(JDate->compare($date, $date_from) >= 0 && JDate->compare($date, $date_to) <= 0)
	{
		return 1;
	}
	return 0;	
}

sub between_date_ranges
{
	my ($class, $date, $date_ranges) = @_;
	my @date_ranges = split(';', $date_ranges);
	foreach my $date_range (@date_ranges)
	{
		my $date_start;
		my $date_end;	
		if($date_range =~ /~/)
		{
			($date_start, $date_end) = split('~', $date_range);
		}
		else
		{
			$date_start = $date_range;
			$date_end = $date_range;
		}
		if(JDate->between_date_range($date_start, $date_end, $date))
		{
			return 1;
		}
	}
	return 0;
}

sub string_to_date_option
{
	my ($class, $str, $tag, $out_tag) = @_;
	my @date_ranges = split(';', $str);
	my $xml;
	my $today_string = JDate->today_string();
	foreach my $date_range (@date_ranges)
	{
		my $date_start;
		my $date_end;
		if($date_range =~ /~/)
		{
			($date_start, $date_end) = split('~', $date_range);
		}
		else
		{
			$date_start = $date_range;
			$date_end = $date_range;
		}
		if($date_start && $date_end)
		{
			if(JDate->compare($date_start, $today_string) < 0)
			{
				$date_start = $today_string;
			}
			my $flag = 0;
			while(JDate->compare($date_start, $date_end) <= 0 && $flag < 1000)
			{
				$xml .= qq{<$tag>$date_start</$tag>\n};
				my $date_start_obj = new JDate($date_start);				
				my $new_date_start_obj = $date_start_obj->add(1);
				$date_start = $new_date_start_obj->to_string();
				$flag++;
			}
		}
	}
	if($out_tag)
	{
		$xml = qq{<$out_tag>\n$xml</$out_tag>\n};
	}
	return $xml;
}

1;
