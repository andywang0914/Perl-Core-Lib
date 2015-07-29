
package JDBEntryExtension;

# for a database table that has extended xml field to represent variable attributes
# 
# its subclass must implement following methods:
# SubClass::extension_field
# SubClass::extension_keys
#

use strict;
use JUtility;
use JDBEntry;

our @ISA = qw(JDBEntry);   

sub new
{
	my ($class, $table_desc) = @_;
	my $self = $class->SUPER::new($table_desc);
	$self->{_ext} = undef;
	bless $self, $class;
	return $self;
}

sub get_extension # always return a meaningful hash reference
{
	my $self = shift;
	return $self->{_ext} ? $self->{_ext} : $self->parse_extension();
}

sub parse_extension
{
	my $self = shift;
	my %info =  JUtility->parse_description($self->xml_extension());
	$self->{_ext} = \%info;
	return $self->{_ext};
}

sub compact_extension
{
	my ($self, $ext_ref) = @_;
	if (!$ext_ref) 
	{
		$ext_ref = $self->get_extension();
	}
	my $xml = '';
	foreach my $k ($self->extension_keys()) 
	{
		if ($ext_ref->{$k} ne '') 
		{
			$xml .= qq{<$k>$ext_ref->{$k}</$k> };
		}
	}
	return $xml;
}

sub update_extension
{
	my ($self, $ext_ref) = @_;
	$self->xml_extension($self->compact_extension($ext_ref));
}

sub update_extension_DB
{
	my ($self, $ext_ref) = @_;
	my @fields = ($self->extension_field());
	$self->update_extension();
	$self->SUPER::update_DB(@fields);
}

sub empty_extension
{
	my $self = shift;
	$self->xml_extension('');
	my %empty = ();
	$self->{_ext} = \%empty;
}

sub extension_field # abstract method.  This abstract method is a better design then xml_extension
{
	my $self = shift;
	return undef;
}

sub xml_extension # method - get/set extension field 
{
	my ($self, $v) = @_;
	my $ext_field = $self->extension_field();
	if (defined($ext_field)) 
	{
		return $self->name_value($ext_field, $v);
	}
	else
	{
		return undef;
	}
}

sub extension_keys # abstract method
{
	my $self = shift;
	return ();
}

sub set_extension
{
	my ($self, $ext) = @_;
	$self->{_ext} = $ext;
}

sub get_ext_field
{
	my ($self, $f) = @_;
	my $ext = $self->get_extension();
	return $ext->{$f};
}

sub get_desc # old method
{
	my ($self, $f) = @_;
	my $ext = $self->get_extension();
	return $ext->{$f};
}

sub set_ext_field
{
	my ($self, $f, $v) = @_;
	my $ext = $self->get_extension();
	return $ext->{$f} = $v;
}

sub set_desc # old method
{
	my ($self, $f, $v) = @_;
	my $ext = $self->get_extension();
	return $ext->{$f} = $v;
}

sub update_info
{
	my ($self, %info) = @_;
	$self->SUPER::update_info(%info);
	foreach my $k ($self->extension_keys()) 
	{
		if (defined($info{$k})) 
		{
			$self->set_ext_field($k, $info{$k});
		}
	}
}

sub set_info
{
	my ($self, %info) = @_;
	$self->SUPER::set_info(%info);
	foreach my $k ($self->extension_keys()) 
	{
		$self->set_ext_field($k, $info{$k});
	}
}

sub get_info
{
	my $self = shift;
	my %info = $self->SUPER::get_info();
	foreach my $k ($self->extension_keys()) 
	{
		$info{$k} = $self->get_ext_field($k);
	}
	return %info;
}

sub update_DB
{
	my ($self, @attrs) = @_;
	$self->update_extension();
	return $self->SUPER::update_DB(@attrs);
}

sub add_to_DB
{
	my $self = shift;
	$self->update_extension();
	return $self->SUPER::add_to_DB();
}

sub init
{
	my $self = shift;
	$self->{_ext} = undef;
	$self->SUPER::init();
}

sub copy
{
	my ($self, $src) = @_;
	if (!$src)
	{
		return;	
	}
	if ($self != $src) 
	{
		$self->SUPER::copy($src);
		foreach my $k ($self->extension_keys())
		{
			$self->set_ext_field($k, $src->get_ext_field($k));
		}
	}
}

sub copy_entry
{
	my ($self, $src) = @_;
	if ($self != $src) 
	{
		$self->SUPER::copy_entry($src);
		foreach my $k ($self->extension_keys())
		{
			$self->set_ext_field($k, $src->get_ext_field($k));
		}
	}
}

sub params # parameters for this instance used for sub-classing mechanism.  Unlike $class->all_params()
{
	my $self = shift;
	my @all_fields = ($self->SUPER::params(), $self->extension_keys());
	my @ext_fields = ($self->extension_field());
	return JUtility->subtract_arrays(\@all_fields, \@ext_fields);
}

sub get_selected_xml # protected method
{
	my ($self, @attrs) = @_;
	my @entry_fields = $self->SUPER::params();
	my @ext_fields = ($self->extension_field());
	my @parent_attrs = JUtility->subtract_arrays(\@entry_fields, \@ext_fields);
	if (@attrs) 
	{
		@parent_attrs = JUtility->intersect_arrays(\@parent_attrs, \@attrs);
		my @ext_keys = $self->extension_keys();
		@attrs = JUtility->intersect_arrays(\@ext_keys, \@attrs);
	}
	my $xml = $self->SUPER::get_selected_xml(@parent_attrs) . $self->get_extension_xml(@attrs);
	return $xml;
}

sub get_extension_xml
{
	my ($self, @attrs) = @_;
	if (@attrs == ()) 
	{
		@attrs = $self->extension_keys();
	}
	my $xml;
	foreach my $k (@attrs)
	{
		my $v = $self->get_ext_field($k);
		if ($v ne '')
		{
			$xml .= "  <$k>" . JUtility->escape_XML($v) . "</$k>\n";
		}	
	}
	return $xml;
}

1;
