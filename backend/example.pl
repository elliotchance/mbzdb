#
# The backend/ directory includes files that follows an interface that allows other database
# backends to be implemented without the need to alter the core.
#
# The file is named as $name$.pl where $name$ is the case-sensitive name for the database backend,
# this can be anything you like, but the name of the file you choose is very important to the name
# of the subroutines you have in this file.
#
# === Implementing Your Own Backend ===
# Duplicate this file and make the changes where appropriate - but all subroutines whether they are
# used or not must stay in the file.
#
# * mbz_do_sql($sql) should be used for any SQL that needs to execute a statement that does not need
#   to return a handle, such as INSERT/DELETE/UPDATE etc.
# * $dbh is the active database handle that you can use with your own error handling.
#


# mbz_connect()
# Make database connection. It will set the global $dbh and it will return it. When implmenting your
# own backend you should only really need to change the $driver to the correct perl DBI driver.
# $g_db_name, $g_db_host, $g_db_port, $g_db_user and $g_db_pass are supplied by settings.pl.
# @return $dbh
sub backend_NAME_connect {
	$driver = 'mysql';
	$dbh = DBI->connect("dbi:$driver:dbname=$g_db_name;host=$g_db_host;port=$g_db_port",
						$g_db_user, $g_db_pass);
	return $dbh;
}


# mbz_update_schema()
# @return 1 on success, otherwise 0.
sub backend_NAME_update_schema {
	return 1;
}


# mbz_update_index()
# @return 1 on success, otherwise 0.
sub backend_NAME_update_index {
	return 1;
}


# mbz_table_exists($table_name)
# Check if a table already exists.
# @param $table_name The name of the table to look for.
# @return 1 if the table exists, otherwise 0.
sub backend_NAME_table_exists {
	my $table_name = $_[0];
	
	# your code here
	
	return 0;
}


# mbz_table_column_exists($table_name, $col_name)
# Check if a table already has a column.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub backend_NAME_table_column_exists {
	my ($table_name, $col_name) = @_;
	
	# your code here
	
	return 0;
}


# mbz_index_exists($index_name)
# Check if an index already exists.
# @param $index_name The name of the index to look for.
# @return 1 if the index exists, otherwise 0.
sub backend_NAME_index_exists {
	my $index_name = $_[0];
	
	# your code here
	
	return 0;
}


# mbz_load_data()
# Load the data from the mbdump files into the tables.
sub backend_NAME_load_data {
}


# mbz_create_extra_tables()
# The mbzdb plugins use a basic key-value table to hold information such as settings.
# @see mbz_set_key(), mbz_get_key().
# @return Passthru from $dbh::do().
sub backend_NAME_create_extra_tables {
	# no need to if the table already exists
	return 1 if(mbz_table_exists("kv"));

	$sql = "CREATE TABLE kv (" .
	       "name varchar(255) not null primary key," .
	       "value text" .
	       ")";
	$sql .= " tablespace $g_tablespace" if($g_tablespace ne "");
	return mbz_do_sql($sql);
}


# be nice
return 1;
