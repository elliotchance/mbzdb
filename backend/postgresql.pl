# mbz_connect()
# Make database connection. It will set the global $dbh and it will return it.
# $g_db_name, $g_db_host, $g_db_port, $g_db_user and $g_db_pass are supplied by settings.pl.
# @return $dbh
sub backend_postgresql_connect {
	$dbh = DBI->connect("dbi:Pg:dbname=$g_db_name;host=$g_db_host;port=$g_db_port",
						$g_db_user, $g_db_pass);
	return $dbh;
}


# mbz_update_index()
# @return Always 1.
sub backend_postgresql_update_index {
	print $L{'downloadschema'};
	mbz_download_schema();
	print $L{'done'} . "\n";
	
	# we attempt to create language, load all the native functions and indexes. If the create
	# language or functions fail they will ultimatly be skipped.
	
	# for PostgreSQL we need to try CREATE LANGUAGE
	backend_postgresql_create_plpgsql() if($g_db_rdbms eq 'postgresql');
	
	open(SQL, "replication/CreateFunctions.sql");
	chomp(my @lines = <SQL>);
	my $full = "";
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        $line eq "BEGIN;" || $line eq "COMMIT;");
		
		$full .= "$line\n";
		if(index($line, 'plpgsql') > 0) {
			#print "$full\n";
			mbz_do_sql("begin");
			mbz_do_sql($full, 'nodie');
			mbz_do_sql("commit");
			$full = "";
		}
	}
	close(SQL);
	
	open(SQL, "replication/CreateIndexes.sql");
	chomp(my @lines = <SQL>);
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN");
		
		# no need to create the index if it already exists
		my $pos_index = index($line, 'INDEX ');
		my $index_name = mbz_trim(substr($line, $pos_index + 6, index($line, ' ', $pos_index + 7) -
				                  $pos_index - 6));
		next if(backend_postgresql_index_exists($index_name));
		
		print "$line\n";
		mbz_do_sql($line, 'nodie');
	}
	close(SQL);
	
	open(SQL, "replication/CreatePrimaryKeys.sql");
	chomp(my @lines = <SQL>);
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN");
		
		# no need to create the index if it already exists
		my $pos_index = index($line, 'CONSTRAINT ');
		my $index_name = mbz_trim(substr($line, $pos_index + 11, index($line, ' ', $pos_index + 12) -
				                  $pos_index - 11));
		next if(backend_postgresql_index_exists($index_name));
		
		print "$line\n";
		mbz_do_sql($line, 'nodie');
	}
	close(SQL);
}


# backend_postgresql_update_schema()
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
sub backend_postgresql_update_schema_file {
	open(SQL, $_[0]);
	chomp(my @lines = <SQL>);
	my $table = "";
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || $line eq "(" || substr($line, 0, 1) eq "\\");
		
		my $stmt = "";
		if(substr($line, 0, 12) eq "CREATE TABLE") {
			$table = mbz_remove_quotes(substr($line, 13, length($line)));
			if(substr($table, length($table) - 1, 1) eq '(') {
				$table = substr($table, 0, length($table) - 1);
			}
			$table = mbz_trim($table);
			print $L{'table'} . " $table\n";
			$stmt = "CREATE TABLE \"$table\" (dummycolumn int)";
			$stmt .= " tablespace $g_tablespace" if($g_tablespace ne '');
		} elsif(substr($line, 0, 1) eq " " || substr($line, 0, 1) eq "\t") {
			my @parts = split(" ", $line);
			for($i = 0; $i < @parts; ++$i) {
				if(substr($parts[$i], 0, 2) eq "--") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}
				
				# because the original MusicBrainz database is PostgreSQL we only need to make
				# minimal changes to the SQL.
				
				if(uc(substr($parts[$i], 0, 4)) eq "CUBE" && !$g_contrib_cube) {
					$parts[$i] = "TEXT";
				}
			}
			if(substr(reverse($parts[@parts - 1]), 0, 1) eq ",") {
				$parts[@parts - 1] = substr($parts[@parts - 1], 0, length($parts[@parts - 1]) - 1);
			}
			next if($parts[0] eq "CHECK" || $parts[0] eq "CONSTRAINT" || $parts[0] eq "");
			$parts[0] = mbz_remove_quotes($parts[0]);
			$stmt = "ALTER TABLE \"$table\" ADD \"$parts[0]\" " .
				join(" ", @parts[1 .. @parts - 1]);
		} elsif(substr($line, 0, 2) eq ");") {
			$stmt = "ALTER TABLE \"$table\" DROP dummycolumn";
		}
		if($stmt ne "") {
			# if this statement fails its hopefully because the field exists
			$dbh->do($stmt) or print "";
		}
	}
	
	close(SQL);
	return 1;
}


sub backend_postgresql_update_schema {
	backend_postgresql_update_schema_file("replication/CreateTables.sql");
	backend_postgresql_update_schema_file("replication/ReplicationSetup.sql");
}


# backend_postgresql_table_exists($tablename)
# Check if a table already exists.
# @note This must support searching for VIEWs as well. mbz_table_exists() is used for testing if
#       tables and views exist.
# @param $table_name The name of the table to look for.
# @return 1 if the table exists, otherwise 0.
sub backend_postgresql_table_exists {
	# TODO: I don't know if this is checking for views.
	my $sth = $dbh->prepare("select count(1) as count from information_schema.tables ".
	                        "where table_name='$_[0]'");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'count'};
}


# mbz_table_column_exists($table_name, $col_name)
# Check if a table already has a column.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub backend_postgresql_table_column_exists {
	my ($table_name, $col_name) = @_;
	
	# TODO: incomplete
	
	return 0;
}


# mbz_load_data()
# Load the data from the mbdump files into the tables.
# @return Always 1, but if something bad goes wrong like a file cannot be opened it will issue a
#         die().
sub backend_postgresql_load_data {
	my $temp_time = time();
	opendir(DIR, "mbdump") || die "Can't open ./mbdump: $!";
	@files = sort(grep { $_ ne '.' and $_ ne '..' } readdir(DIR));
	$count = @files;
	$i = 1;
	
	foreach my $file (@files) {
		my $t1 = time();
		$table = $file;
		next if($table eq "blank.file" || substr($table, 0, 1) eq '.');
		print "\n" . localtime() . ": Loading data into '$file' ($i of $count)...\n";
		
		# make sure the table exists
		next if(!mbz_table_exists($table));
  		
  		open(TABLEDUMP, "mbdump/$file") or warn("Error: cannot open file 'mbdump/$file'\n");
  		my $sth2 = $dbh->prepare("select count(1) from information_schema.columns ".
  		                         "where table_name='$table'");
		$sth2->execute();
		my $result2 = $sth2->fetchrow_hashref();
		
		$dbh->do("COPY $table FROM STDIN");
		while($readline = <TABLEDUMP>) {
			chomp($readline);
			
			# crop to make postgres happy
			my @cols = split('	', $readline);
			$dbh->pg_putcopydata(join('	', @cols[0 .. ($result2->{'count'} - 1)]) . "\n");
		}
		close(TABLEDUMP);
  		
  		$dbh->pg_putcopyend();
		my $t2 = time();
		print "Done (" . mbz_format_time($t2 - $t1) . ")\n";
		++$i;
	}
	
	closedir(DIR);
	my $t2 = time();
	print "\nComplete (" . mbz_format_time($t2 - $temp_time) . ")\n";
	return 1;
}


# backend_postgresql_create_extra_tables()
# The mbzdb plugins use a basic key-value table to hold information such as settings.
# @see mbz_set_key(), mbz_get_key().
# @return Passthru from $dbh::do().
sub backend_postgresql_create_extra_tables {
	# no need to if the table already exists
	return 1 if(mbz_table_exists("kv"));

	$sql = "CREATE TABLE kv (" .
	       "name varchar(255) not null primary key," .
	       "value text" .
	       ")";
	$sql .= " tablespace $g_tablespace" if($g_tablespace ne "");
	return mbz_do_sql($sql);
}


# mbz_index_exists($index_name)
# Check if an index already exists.
# @param $index_name The name of the index to look for.
# @return 1 if the index exists, otherwise 0.
sub backend_postgresql_index_exists {
	my $sth = $dbh->prepare("select count(*) from (".
	                        "select constraint_name from information_schema.key_column_usage ".
	                        "where constraint_name='$_[0]' union all select indexname from pg_indexes ".
	                        "where indexname='$_[0]') as t");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'count'};
}


# mbz_load_pending($id)
# Load Pending and PendingData from the downaloded replication into the respective tables. This
# function is different to mbz_load_data that loads the raw mbdump/ whole tables.
# @param $id The current replication number. See mbz_get_current_replication().
# @return Always 1.
sub backend_postgresql_load_pending {
	$id = $_[0];
	my $pending = mbz_escape_entity($g_pending);
	my $pendingdata = mbz_escape_entity($g_pendingdata);

	# make sure there are no pending transactions before cleanup
	$temp = $dbh->prepare("SELECT count(1) FROM $pending");
	$temp->execute;
	@row = $temp->fetchrow_array();
	$temp->finish;
	return -1 if($row[0] ne '0');

	# perform cleanup (makes sure there no left over records in the PendingData table)
	$dbh->do("DELETE FROM $pending");

	# load Pending and PendingData
	print localtime() . ": Loading pending tables... ";
	
	open(TABLEDUMP, "replication/$id/mbdump/$g_pendingfile")
		or warn("Error: cannot open file 'replication/$id/mbdump/$g_pendingfile'\n");
	$dbh->do("COPY $pending FROM STDIN");
	while($readline = <TABLEDUMP>) {
		$dbh->pg_putcopydata($readline);
	}
	close(TABLEDUMP);
  	$dbh->pg_putcopyend();
  	
  	open(TABLEDUMP, "replication/$id/mbdump/$g_pendingdatafile")
  		or warn("Error: cannot open file 'replication/$id/mbdump/$g_pendingdatafile'\n");
	$dbh->do("COPY $pendingdata FROM STDIN");
	while($readline = <TABLEDUMP>) {
		$dbh->pg_putcopydata($readline);
	}
	close(TABLEDUMP);
  	$dbh->pg_putcopyend();
  	
	print "Done\n";
	
	# PLUGIN_beforereplication()
	foreach my $plugin (@g_active_plugins) {
		eval($plugin . "_beforereplication($id)") or warn($!);
	}
	
	return 1;
}


# mbz_escape_entity($entity)
# Wnen dealing with table and column names that contain upper and lowercase letters some databases
# require the table name to be encapsulated.  PostgreSQL uses double-quotes.
# @return A new encapsulated entity.
sub backend_postgresql_escape_entity {
	my $entity = $_[0];
	return "\"$entity\"";
}


sub backend_postgresql_create_plpgsql {
	my $sth = $dbh->prepare("SELECT count(*) FROM pg_catalog.pg_language WHERE lanname='plpgsql'");
	$sth->execute();
	my @row = $sth->fetchrow_array();
	mbz_do_sql("CREATE LANGUAGE plpgsql") if($row[0] == 0)
}


# be nice
return 1;
