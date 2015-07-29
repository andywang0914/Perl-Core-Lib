

package JDBEntry;

use strict;
use JVars;
use JDB;
use JUtility;

#constructor
sub new
{
	my ($class, $table_desc) = @_;
	my $self = {
		_table_desc	=> undef,
		_values		=> undef,
		_table		=> undef,
		_dirty		=> 1,
		_database	=> undef,
	};
	$self->{_table_desc} = $table_desc;
	bless $self, $class;
	$self->set_table();
	$self->set_db();
	return $self;
}

sub init
{
	my $self = shift;
	$self->{_values} = undef;
	$self->{_dirty} = 0;
}

sub set_table
{
	my ($self, $table) = @_;
	if (defined ($table))
	{
		$self->{_table} = $table;
	}
	else
	{
		$self->{_table} = JVars->table_prefix() . $self->{_table_desc}->{'table'};
	}	
}

sub set_db
{
	my ($self, $db) = @_;
	if (defined ($db))
	{
		$self->{_database} = $db;
	}
	else
	{
		$self->{_database} = $self->{_table_desc}->{'database'};
	}	
}

sub params # this is instance method for sub-classing, unlike $class->all_params
{
	my $self = shift;
	return $self->get_fields() ? @{$self->get_fields()} : ();
}

sub set_default_table
{
	my $self = shift;
	$self->{_table} = JVars->table_prefix() . $self->{_table_desc}->{'table'};
}

sub get_table
{
	my $self = shift;
	return $self->{_table};
}

sub get_db
{
	my $self = shift;
	return $self->{_database};
}

sub set_name_value
{
	my ($self, $name, $value) = @_;
	if ($self->{_values}->{$name} ne $value)  # needs to be changed for better comparison 
	{
		$self->{_dirty} = 1;
		$self->{_values}->{$name} = $value;
	}
}

sub get_name_value
{
	my ($self, $name) = @_;
	return $self->{_values}->{$name};
}

#
# If we use construct string value this method works fine
# Otherwise, use set_name_value and get_name_value
#
sub name_value
{
	my ($self, $name, $value) = @_;
	if (defined($value)) 
	{
		if ($self->{_values}->{$name} ne $value)  # needs to be changed for better comparison 
		{
			$self->{_dirty} = 1;
			$self->{_values}->{$name} = $value;
		}
	}
    return $self->{_values}->{$name};
}

sub set_info
{
	my ($self, %info) = @_;
	my @fields = @{$self->{_table_desc}->{'fields'}};
	my @values;
	foreach my $f (@fields) 
	{
		push @values, $info{$f};
	}
	return $self->all_values(@values);
}

sub get_info
{
	my $self = shift;
	my %info;
	foreach my $f (@{$self->{_table_desc}->{'fields'}}) 
	{
		$info{$f} = $self->name_value($f);
	}
	return %info;
}

sub update_info
{
	my ($self, %info) = @_;
	my $fieldsRef = $self->{_table_desc}->{'fields'};
	my $index = 0;
	foreach my $f (@{$fieldsRef}) 
	{
		if (defined($info{$f})) 
		{
			$self->set_name_value($fieldsRef->[$index], $info{$f});
		}
		$index++;
	}
}

sub load_by_xml
{
	my ($self, $xml) = @_;
	if ($xml)
	{
		my $fieldsRef = $self->{_table_desc}->{'fields'};
		my @values;
		foreach my $field (@{$fieldsRef}) 
		{
			my $value = JUtility->tag_value($field, $xml);
			$value = JUtility->unescape_XML($value);
			push @values, $value;
		}
		return $self->all_values(@values);
	}
	return $self->all_values();
}

sub all_values
{
	my ($self, @values) = @_;
	if (@values != ()) 
	{
		my $fieldsRef = $self->{_table_desc}->{'fields'};
		for (my $i=0; $i<$#values+1; $i++)
		{
			$self->set_name_value($fieldsRef->[$i], $values[$i]);
		}
	}
	$self->bless_type();
	return $self->{_values};
}

sub bless_type
{
	my $self = shift;
	return '';
}

sub copy # copy table name too
{
	my ($self, $src) = @_;
	if (!$src)
	{
		return;	
	}
	if ($self != $src) 
	{
		$self->init();
		my $fieldsRef = $self->{_table_desc}->{'fields'};
		foreach my $n (@{$fieldsRef}) 
		{
			$self->set_name_value($n, $src->{_values}->{$n});
		}
		$self->set_table($src->get_table());
	}
	$self->bless_type();	
	return $self->{_values};
}

sub copy_entry # no table name is copied
{
	my ($self, $src) = @_;
	if ($self != $src) 
	{
		$self->init();
		my $fieldsRef = $self->{_table_desc}->{'fields'};
		foreach my $n (@{$fieldsRef}) 
		{
			$self->set_name_value($n, $src->{_values}->{$n});
		}
	}
	return $self->{_values};
}

sub get_fields
{
	my $self = shift;
	return $self->{_table_desc}->{'fields'};
}

sub get_types
{
	my $self = shift;
	return $self->{_table_desc}->{'types'};
}

sub get_field_type
{
	my ($self, $field) = @_;
	my $typesRef = $self->get_types();
	return $typesRef->{$field};
}

sub get_sizes
{
	my $self = shift;
	return $self->{_table_desc}->{'sizes'};
}

sub get_field_size
{
	my ($self, $field) = @_;
	my $sizesRef = $self->get_sizes();
	return $sizesRef->{$field};
}

sub get_descriptions
{
	my $self = shift;
	return $self->{_table_desc}->{'descriptions'};
}

sub get_field_description
{
	my ($self, $field) = @_;
	my $descriptionsRef = $self->get_descriptions();
	return $descriptionsRef->{$field};
}

sub construct_value_string
{
	my ($self, $name, $value) = @_;
	my $attrs = $self->get_fields();
	my $types = $self->get_types();
	$value = ($value eq "") ? $self->{_values}->{$name} : $value;
	my $db = $self->{_database};
	if ($types->{$name} =~ "int" || $types->{$name} =~ "decimal")
    {
    	$value = ($value eq "") ? 0 : $value;
    	if(!JUtility->is_number($value))
    	{
    		#JEmail->report_dev_error("JDBEntry Construct Value String Failed", qq{JDBEntry Construct Value String Failed for Non-numeric param($value)});
    		$value = 0;
    	}
		return $value;
	}
	elsif ($types->{$name} =~ "datetime") 
	{
		if ($value eq "")
		{
			$value = JDateTime->get_date_time_string();
		}
	}
	elsif ($types->{$name} =~ "date") 
	{
		if ($value eq "")
		{
			$value = JDate->get_todays_date();
		}
	}
	elsif ($types->{$name} =~ "time") 
	{
		if ($value eq "")
		{
			$value = JDateTime->get_time_string();
		}
	}	
	elsif ($types->{$name} =~ "char" || $types->{$name} eq "text")
	{
		if (!defined($value))
		{
			$value = '';
		}
		else
		{
			$value = JUtility->trim_string($value);
			$value =~ s/\r//sg; 
		}
	}
	$self->{_values}->{$name} = $value;
	return JDB->db($db)->quote($value);
}

sub construct_value_pair
{
	my ($self, $name, $value) = @_;
	return '`'.$name.'`' . "=" . $self->construct_value_string($name, $value);
}

sub retrieve_from_DB
{
	my $self  = shift;
	my $xml = $self->get_cached_xml();
	if($xml)
	{
		return $self->load_by_xml($xml);
	}
	else
	{
		return $self->retrieve_self();
	}
}

sub retrieve_self
{
	my $self  = shift;
	my $attrs = $self->get_fields();
	my $primary_key = $attrs->[0];
	my $jdb_entry = "JDBEntry" . $self->{_database};
	if (! defined($self->{_values}->{$primary_key}) ) 
	{
		return qq{$jdb_entry: retrieve_from_DB(): value not defined for $primary_key};	
	}
	my $condition = $self->construct_value_pair($primary_key);
	return $self->conditional_retrieve($condition);
}


sub conditional_retrieve
{
	my ($self, $condition) = @_;
    my $table = $self->get_table();
	my $db = $self->{_database};
	my @vs = JDB->db($db)->get_DB_row($table, $condition);
	$self->{_dirty} = 0;
	return $self->all_values(@vs);
}

sub add_self_to_DB
{
	my $self = shift;
	my $attrs = $self->get_fields();
	my $types = $self->get_types();
	my $table = $self->get_table();
	my $value_list;
	my $attr_list;
	my $comma = "";
	my $auto_increase = 0;
	foreach my $a (@{$attrs}) 
	{
		if ($types->{$a} !~ /auto_increment/ || $self->{_values}->{$a} > 0) 
		{
			my $formatted = $self->construct_value_string($a, $self->{_values}->{$a});
			if ($formatted eq "") 
			{
				return 0;
			}
			$attr_list .= $comma . '`'.$a.'`';
			$value_list .= $comma . $formatted;
			$comma = ",";
		}
		else
		{
			$auto_increase = 1;
		}
	}
	my $db = $self->{_database};
	if (! JDB->db($db)->sql("insert into $table ($attr_list) values ($value_list)"))
	{
		return 0;
	}
	my $result;
	if ($auto_increase) 
	{
		my $last_inserted = JDB->db($db)->get_inserted_id();
		if ($last_inserted) 
		{
			my $pk = $self->{_table_desc}->{'fields'}->[0];
			$self->{_values}->{$pk} = $last_inserted;
		}
		$self->cache_xml();		
		$result = $last_inserted;
	}
	else
	{
		my $pk = $self->{_table_desc}->{'fields'}->[0];
		$self->cache_xml();		
		$result = $self->{_values}->{$pk};
	}
	return $result;
}

sub add_to_DB
{
	my $self = shift;
	return $self->add_self_to_DB();
}

sub add_or_update_DB
{
	my $self = shift;
	my $table = $self->get_table();
	my $primary_key = $self->{_table_desc}->{'fields'}->[0];
	my $primary_key_value = $self->$primary_key();
	my $condition = qq{$primary_key = $primary_key_value};
	my $db = $self->{_database};
	if ($primary_key_value && JDB->db($db)->check_existence($table, $condition))
	{
		$self->update_self_DB();
	}
	else
	{
		$primary_key_value = $self->add_self_to_DB();	
	}
	return $primary_key_value;
	
}

sub update_self_DB
{
	my ($self, @fields) = @_;
	$self->cache_xml();
	my $primary_key = $self->{_table_desc}->{'fields'}->[0];
	my $condition = $self->construct_value_pair($primary_key);
	my $result =$self->conditional_update($condition, @fields);
	return $result;
}

sub update_DB
{
	my ($self, @fields) = @_;
	return $self->update_self_DB(@fields);
}

sub conditional_update
{
	my ($self, $condition, @fields) = @_;
	my $value_pairs;
	my $comma = '';
	if (@fields == ()) 
	{
		@fields = @{$self->get_fields()};
		foreach my $a (@fields) 
		{
			$value_pairs .= $comma . $self->construct_value_pair($a);
			$comma = ",";
		}
	}
	else
	{
		my $typesRef = $self->get_types();
		foreach my $a (@fields) 
		{
			if ($typesRef->{$a}) # validate
			{
				$value_pairs .= $comma . $self->construct_value_pair($a);
				$comma = ",";
			}
		}
	}
	my $table = $self->get_table();
	my $db = $self->{_database};
	my $jdb_entry = "JDBEntry" . $self->{_database};
	if (!JDB->db($db)->do("update $table set $value_pairs where $condition") )
	{
		return qq{$jdb_entry: update_DB(): $DBI::errstr -- ($value_pairs), $condition};
	}
	return "";
}

sub remove_from_DB
{
	my ($self, $no_backup) = @_;
	return $self->remove_self_from_DB($no_backup);
}

sub remove_self_from_DB
{
	my ($self, $no_backup) = @_;
	my $fields = $self->get_fields();
	my $result = $self->conditional_remove($self->construct_value_pair($fields->[0]), $no_backup);
	$self->synch_remove(1);
	return $result;
}

sub conditional_remove
{
	my ($self, $condition, $no_backup) = @_;
	my $db = $self->{_database};
	JDB->db($db)->conditional_delete($self->get_table(), $condition, $no_backup);
}

sub get_xml # public method
{
	my ($self, $tag) = @_;
	my $xml = $self->get_selected_xml();
	return $tag ? qq{<$tag>\n$xml</$tag>\n} : $xml;
}

sub get_selected_xml # protected method
{
	my ($self, @attrs) = @_;
	my @all_params = $self->params();
	if (@attrs == ()) 
	{
		@attrs = @all_params;
	}
	else
	{
		@attrs = JUtility->intersect_arrays(\@all_params, \@attrs);
	}
	my $xml;
	foreach my $name (@attrs) 
	{
		$xml .= "  <$name>" . JUtility->escape_XML($self->{_values}->{$name}) . "</$name>\n";
	}
	return $xml;
}

sub print_text # debug method
{
	my $self = shift;
	my $text = $self->{_table_desc}->{'table'} . "\n"; 
	my @fields = @{$self->{_table_desc}->{'fields'}};
	foreach my $f (@fields) 
	{
		$text .= "field: $f = " . $self->{_values}->{$f} . "\n";
	}
	return $text;
}

sub export_sql
{
	my $self = shift;
	my $attrs = $self->get_fields();
	my $types = $self->get_types();
	my $table = $self->get_table();
	my $value_list;
	my $attr_list;

	my $comma = "";
	foreach my $a (@{$attrs}) 
	{
		my $formatted = $self->construct_value_string($a, $self->{_values}->{$a});
		if ($formatted eq "") 
		{
			return 0;
		}
		$attr_list .= $comma . '`'.$a.'`';
		$value_list .= $comma . $formatted;
		$comma = ",";
	}
	return "repalce into $table ($attr_list) values ($value_list);";
}

sub primary_key
{
	my $self = shift;
	my $attrs = $self->get_fields();
	if($attrs)
	{
		my $primary_key = $attrs->[0];
		return $primary_key;
	}
	return '';
}

1;
