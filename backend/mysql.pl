#
# The backend/ directory includes files that follows an interface that allows
# other database backends to be implemented without the need to alter the core.
#
# The file is named as $name$.pl where $name$ is the case-sensitive name for
# the database backend, this can be anything you like, but the name of the file
# you choose is very important to the name of the subroutines you have in this
# file.
#
# If you want to implement your own backend duplicate this file and make the
# changes where appropriate - but all subroutines whether they are used or not
# must stay in the file.
#


# mbz_connect()
# Make database connection. It will set the global $dbh and it will return it.
# $g_db_name, $g_db_host, $g_db_port, $g_db_user and $g_db_pass are supplied by settings.pl.
# @return $dbh
sub backend_mysql_connect {
	$dbh = DBI->connect("dbi:mysql:dbname=$g_db_name;host=$g_db_host;port=$g_db_port",
						$g_db_user, $g_db_pass);
	return $dbh;
}


# backend_mysql_update_schema()
# Attempt to update the scheme from the current version to a new version by creating a table with a
# dummy field, altering the tables by adding one field at a time them removing the dummy field. The
# idea is that given any schema and SQL file the new table fields will be added, the same fields
# will result in an error and the table will be left unchanged and fields and tables that have been
# removed from the new schema will not be removed from the current schema.
# This is a crude way of doing it. The field order in each table after it's altered will not be
# retained from the new schema however the field order should not have a big bearing on the usage
# of the database because name based and column ID in scripts that use the database will remain the
# same.
# It would be nice if this subroutine had a makeover so that it would check items before attempting
# to create (and replace) them. This is just so all the error messages and so nasty.
# @return Always 1.
sub backend_mysql_update_schema {
	# TODO: this does not check for columns that have changed their type, as a column that already
	#       exists will be ignored. I'm not sure how important this is but its worth noting.
	
	# this is where it has to translate PostgreSQL to MySQL as well as making any modifications
	# needed.
	open(SQL, "temp/CreateTables.sql");
	chomp(my @lines = <SQL>);
	my $table = "";
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || $line eq "(" || substr($line, 0, 1) eq "\\");
		
		my $stmt = "";
		if(substr($line, 0, 6) eq "CREATE") {
			$table = mbz_remove_quotes(substr($line, 13, length($line)));
			if(substr($table, length($table) - 1, 1) eq '(') {
				$table = substr($table, 0, length($table) - 1);
			}
			$table = mbz_trim($table);
			print $L{'table'} . " $table\n";
			
			# do not create the table if it already exists
			if(!mbz_table_exists($table)) {
				$stmt = "CREATE TABLE `$table` (dummycolumn int)";
				$stmt .= " tablespace $g_tablespace" if($g_tablespace ne '');
			}
		} elsif(substr($line, 0, 1) eq " " || substr($line, 0, 1) eq "\t") {
			my @parts = split(" ", $line);
			for($i = 0; $i < @parts; ++$i) {
				if(substr($parts[$i], 0, 2) eq "--") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}
				
				if(substr($parts[$i], length($parts[$i]) - 2, 2) eq "[]") {
					$parts[$i] = "VARCHAR(255)";
				}
				$parts[$i] = "INT NOT NULL" if(substr($parts[$i], 0, 6) eq "SERIAL");
				$parts[$i] = "CHAR(32)" if(substr($parts[$i], 0, 4) eq "UUID");
				$parts[$i] = "TEXT" if(substr($parts[$i], 0, 4) eq "CUBE");
				$parts[$i] = "CHAR(1)" if(substr($parts[$i], 0, 4) eq "BOOL");
				$parts[$i] = "VARCHAR(256)" if($parts[$i] eq "NAME");
				$parts[$i] = "0" if(substr($parts[$i], 0, 3) eq "NOW");
				$parts[$i] = "0" if(substr($parts[$i], 1, 1) eq "{");
				$parts[$i] = $parts[$i + 1] = $parts[$i + 2] = "" if($parts[$i] eq "WITH");
				if($parts[$i] eq "VARCHAR" && substr($parts[$i + 1], 0, 1) ne "(") {
					$parts[$i] = "TEXT";
				}
			}
			if(substr(reverse($parts[@parts - 1]), 0, 1) eq ",") {
				$parts[@parts - 1] = substr($parts[@parts - 1], 0, length($parts[@parts - 1]) - 1);
			}
			
			next if($parts[0] eq "CHECK" || $parts[0] eq "CONSTRAINT" || $parts[0] eq "");
			$parts[0] = mbz_remove_quotes($parts[0]);
			$stmt = "ALTER TABLE `$table` ADD `$parts[0]` " .
				join(" ", @parts[1 .. @parts - 1]);
				
			# no need to create the column if it already exists in the table
			$stmt = "" if(mbz_table_column_exists($table, $parts[0]));
		} elsif(substr($line, 0, 2) eq ");") {
			if(mbz_table_column_exists($table, "dummycolumn")) {
				$stmt = "ALTER TABLE `$table` DROP dummycolumn";
			}
		}
		
		if(mbz_trim($stmt) ne "") {
			$dbh->do($stmt) or print "";
		}
	}
	
	close(SQL);
	return 1;
}


# We can't always use the CreateIndexes.sql script provided by MusicBrainz because it has
# PostgreSQL specific functions. Instead we use a cardinality calculation to determine the need for
# an index.
sub backend_mysql_update_index {
	# go through each table
	$sth = $dbh->prepare('show tables');
	$sth->execute();
	$start = time();
	while(@result = $sth->fetchrow_array()) {
		next if($result[0] eq $g_pending || $result[0] eq $g_pendingdata);
		
		print "Indexing $result[0]\n";
		$sth2 = $dbh->prepare("\\d \"" . $result[0] . "\"");
		$sth2->execute();
		while(@result2 = $sth2->fetchrow_array()) {
			$start2 = time();
			if($result2[3] eq "" && $result2[1] ne "text") {
				print "  Calculating cardinality of $result2[0]... ";
				$sth_card = $dbh->prepare("select count(1)/(select count(1) from \"$result[0]\") ".
					"from (select distinct \"$result2[0]\" from \"$result[0]\") as t");
				$sth_card->execute();
				my @card = $sth_card->fetchrow_array();
				if($card[0] >= 0.01) {
					print "$card[0] (Yes)\n";
					print "    Adding index $result[0].$result2[0]...";
					mbz_do_sql("create index $result[0]_" . $result2[0] .
					           " on \"$result[0]\"(\"$result2[0]\")");
					print " Done (", mbz_format_time(time() - $start2), ", ",
						mbz_format_time(time() - $start), " total)\n";
				} else {
					print "$card[0] (No)\n";
				}
			}
		}
	}
}


# backend_mysql_table_exists($table_name)
# Check if a table already exists.
# @param $table_name The name of the table to look for.
# @return 1 if the table exists, otherwise 0.
sub backend_mysql_table_exists {
	my $table_name = $_[0];
	
	my $sth = $dbh->prepare('show tables');
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		return 1 if($result[0] eq $table_name);
	}
	
	# table was not found
	return 0;
}


# mbz_table_column_exists($table_name, $col_name)
# Check if a table already has a column.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub backend_mysql_table_column_exists {
	my ($table_name, $col_name) = @_;
	
	my $sth = $dbh->prepare("describe `$table_name`");
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		return 1 if($result[0] eq $col_name);
	}
	
	# table column was not found
	return 0;
}


# mbz_load_data()
# Load the data from the mbdump files into the tables.
sub backend_mysql_load_data {
	# TODO: Incomplete.
}


# backend_mysql_create_extra_tables()
# The mbzdb plugins use a basic key-value table to hold information such as settings.
# @see mbz_set_key(), mbz_get_key().
# @return Passthru from $dbh::do().
sub backend_mysql_create_extra_tables {
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
