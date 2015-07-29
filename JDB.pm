
package JDB;

use strict;
use DBI;

my %local_dbs;
my $local_default_db = 'db_key';
my $local_db_name = 'db_name';
my $local_db_host = 'localhost';
my $local_db_username = 'username';
my $local_db_password = 'password';
my $local_current_key = $local_default_db;

sub new 
{
	my ($class, $db_key) = @_;
	if (!$db_key)
	{
		$db_key = $local_default_db;
	}
	my $self = {
		_dbh => undef,
		_drh => undef,
		_db_key => $db_key,
		_db_name => $local_db_name,
		_db_host => $local_db_host,
		_db_username => $local_db_username,
		_db_password => $local_db_password,
		_jdb => "JDB$db_key",
	};
	bless $self, $class;
	return $self;
}

sub db
{
	my ($class, $db_key) = @_;
	if (!$db_key)
	{
		$db_key = $local_default_db;
	}
	if (!$local_dbs{$db_key})
	{
		$local_dbs{$db_key} = new JDB($db_key);
	}
	return $local_dbs{$db_key};
}

sub db_key
{
	my ($class, $new_key) = @_;
	if ($new_key)
	{
		$local_current_key = $new_key;
	}
	else
	{
		return $local_current_key;
	}
}

sub connect_DB
{
	my $self = shift;
    my $dsn = "DBI:mysql:database=" . $self->{_db_name} . ";host=" . $self->{_db_host};
	$self->{_dbh} = DBI->connect($dsn, $self->{_db_username}, $self->{_db_password});
	if (!$self->{_dbh})
	{
		die "database server is down." . $DBI::errstr;
	}
	$self->{_drh} = DBI->install_driver('mysql');
	if (!$self->{_drh})
	{
		die "Could not install: $DBI::errstr";
	}
}

sub disconnect_DB
{
	my $self = shift;
	if ($self->{_dbh})
	{
		$self->{_dbh}->disconnect();
		$self->{_dbh} = undef;
	}
}

sub get_dbh
{
	my $self = shift;
	if (! $self->{_dbh}) 
	{
		$self->connect_DB();
	}
	return $self->{_dbh};
}

sub sql
{   
	my ($self, $sql) = @_;
	my $jdb = $self->{_jdb};
	my $sth = $self->prepare($sql) || die "$jdb::SQL: " . $self->get_dbh()->errstr;
	$sth->execute || return $self->process_die_error("$jdb::sql", $self->{_db_name} . $sql, $self->get_dbh()->errstr, $sql, $sth);
	return $sth;
}


sub process_die_error
{
	my ($self, $title, $error_message, $db_error, $sql, $sth) = @_;
	if ($db_error =~ /Lost connection to MySQL server during query/)
	{
		$self->connect_DB();
		my $jdb = $self->{_jdb};
		$sth = $self->prepare($sql) || die "$jdb::SQL: " . $self->get_dbh()->errstr;
		$sth->execute || die $self->get_dbh()->errstr;
	}
	return $sth;
}


sub do
{
	my ($self, $query) = @_;
	my $result = $self->get_dbh()->do($query);
	return $result;
}

sub select_count
{
    my ($self, $table, $condition) = @_;
    my $dbh = $self->get_dbh();
    my $sth;
    if ($condition eq "")
    {
        $sth = $self->prepare("select count(*) from $table") || die "select_count(): " . $dbh->errstr;
    }
    else
    {
        $sth = $self->prepare("select count(*) from $table where $condition") || die "select_count(): " . $dbh->errstr;
    }
    $sth->execute;
    return $sth->fetchrow;
}

#
# target is '*'
#
sub table_select
{
	my ($self, $table, $condition, $order_name) = @_;
	return $self->generic_select('*', $table, $condition, $order_name);
}	

#
# you can create your own target (generic table select)
#
sub generic_select
{
	my ($self, $target, $table, $condition, $order_name, $group_by) = @_;
	my $order = $order_name ? "order by $order_name" : "";
	my $group = $group_by ? "group by $group_by" : "";
	my $sql = $condition ? qq{select $target from $table where $condition $group $order} : qq{select $target from $table $group $order};
	my $sth = $self->prepare($sql);
	my $jdb = $self->{_jdb};
	$sth->execute || return $self->process_die_error("$jdb::sql generic_select",  $sql, $self->get_dbh()->errstr, $sql, $sth);
	return $sth;
}

sub prepare
{
	my ($self, $sql) = @_;
	my $sth = $self->get_dbh()->prepare($sql);
	return $sth;
}

sub get_DB_row
{
	my ($self, $table, $condition) = @_;
	my $sth = $self->table_select($table, $condition);
	return $sth ? $sth->fetchrow : ();
}

sub get_sum 
{
	my ($self, $columns, $table, $condition, $order_name) = @_;
	my $sth = $self->generic_select("sum($columns)", $table, $condition, $order_name);
	return $sth ? $sth->fetchrow : ();
}

sub quote
{
	my ($self, $s) = @_;
	return $self->get_dbh()->quote($s);
}

sub get_inserted_id
{
	my $self = shift;
	return $self->get_dbh()->{mysql_insertid};
}

sub check_existence
{
	my ($self, $table, $condition) = @_;
	my @vs = $self->get_DB_row($table, $condition);
	return (@vs == ()) ? 0 : 1;
}

sub sql_single_result
{
	my ($self, $sql) = @_;
	my $sth = $self->sql($sql);
	my @row = $sth->fetchrow;
	return (@row == ()) ? undef : $row[0];
}

sub conditional_move_table
{
	my ($self, $source, $dest, $condition) = @_;
	my $msg = $self->do("insert into $dest select * from $source where $condition");
    if (!$msg)
    {
        return "insert into $dest select * from $source where $condition: $msg";
    }
	else
	{
		$self->do("delete from $source where $condition");
		return "";
	}
}

sub copy_table
{
    my ($self, $source, $dest, $condition) = @_;
    my $msg = $condition ? $self->do("insert into $dest select * from $source where $condition")
						 : $self->do("insert into $dest select * from $source");
    if (!$msg)
    {
		return "Error copy $dest from $source $condition: $DBI::errstr";
	}
	return "";
}

sub create_copy_table
{
    my ($self, $source, $dest) = @_;
	my $msg = $self->do("create table $dest as select * from $source");
    if (!$msg)
    {
		return "Error create copy $dest from $source: $DBI::errstr";
	}
	return "";
}

1;
