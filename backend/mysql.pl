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
	print $L{'downloadschema'};
	mbz_download_schema();
	print $L{'done'} . "\n";
	
	# this is where it has to translate PostgreSQL to MySQL
	# as well as making any modifications needed.
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
			$stmt = "CREATE TABLE \"$table\" (dummycolumn int) tablespace $g_tablespace";
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


# backend_mysql_table_exists($tablename)
# Check if a table already exists.
# @return 1 if the table exists, otherwise 0.
sub backend_mysql_table_exists {
	# TODO: Incomplete
	return 0;
}


# mbz_load_data()
# Load the data from the mbdump files into the tables.
sub backend_mysql_load_data {
	# TODO: Incomplete.
}


# be nice
return 1;
