
package JDBSelected;
BEGIN {
   use Exporter   ();
   use vars       qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
   @ISA         = qw(Exporter);
 
   # List the global variables here
   @EXPORT_OK = qw($gJDBSel);
 
   %EXPORT_TAGS = (JDBSelectedVarTag=>[@EXPORT_OK] );
}
use vars      @EXPORT_OK;
use strict;
use DBI;

$gJDBSel = new JDBSelected();

sub new 
{
	my $class = shift;
	my $self = {
		_sth	=> undef,
		_fields => undef, 
	};
	bless $self, $class;
	return $self;
}

sub set_handler
{
	my ($self, $sth) = @_;
    $self->{_sth} = $sth;
    return $self->{_sth};
}

sub handler
{
	my ($self, $sth) = @_;
    $self->{_sth} = $sth if defined($sth);
    return $self->{_sth};
}

sub set_fieldsRef
{
	my ($self, $fieldsRef) = @_;
	$self->{_fields} = $fieldsRef;
}

sub get_singleton_row
{
	my $self = shift;
	my @row = $self->{_sth}->fetchrow;
	return (@row == ()) ? undef : $row[0];
}

sub get_row
{
	my $self = shift;
	return $self->handler()->fetchrow;
}

sub get_rows
{
	my $self = shift;
	my $ref = $self->handler()->fetchall_arrayref;
	return $ref ? @{$ref} : ();
}

sub get_ref_rows
{
	my $self = shift;
	my $ref = $self->handler()->fetchall_arrayref;
	return $ref ? @{$ref} : ();
}

sub get_named_row
{
	my $self = shift;
	if (! defined($self->{_fields})) 
	{
		return ();
	}
	my @vs = $self->get_row();
	my %named;
	my $i = 0; 
	foreach my $n (@{$self->{_fields}}) 
	{
		$named{$n} = $vs[$i];
		$i++;
	}
	return %named;
}

sub get_named_rows
{
	my $self = shift;
	my %row;
	my @rows;
	while ((%row = $self->get_named_row()) > 0)
	{
		push @rows, \%row;
	}
	return @rows;
}

sub init
{
	my $self = shift;
	$self->{_sth} = undef;
	$self->{_fields} = undef;
}

1;