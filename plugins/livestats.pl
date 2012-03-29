#
# LiveStats keeps a live count of the table sizes. This is important for any transactional database
# like InnoDB, PostgreSQL etc because count(*) requires an expensive full table scan.
#
# SEE example.pl FOR DOCUMENTATION
#

sub livestats_description {
	return "LiveStats keeps a live count of the table sizes. This is\n".
	       "important because InnoDB is transactional and count(*)\n".
	       "requires an expensive full table scan."
}

sub livestats_init {
	# live stats has many elements that are RDBMS specific, so if the user is using a RDBMS we don't
	# understand its better to warn and exit
	if($g_db_rdbms ne 'mysql' and $g_db_rdbms ne 'postgresql') {
		warn("'$g_db_rdbms' is not supported for livestats.\n\n");
		return 0;
	}

	# for PostgreSQL we need to CREATE LANGUAGE
	backend_postgresql_create_plpgsql() if($g_db_rdbms eq 'postgresql');

	# create tables
	print "Creating livestats tables and views...";
	if(mbz_table_exists("livestats")) {
		if($g_db_rdbms eq 'postgresql') {
			# PostgreSQL requires a cascaded DROP
			mbz_do_sql("DROP TABLE livestats cascade");
		} else {
			# some other generic-SQL like mysql
			mbz_do_sql("DROP TABLE livestats");
		}
	}
	mbz_do_sql("DROP VIEW livestats_count") if(mbz_table_exists("livestats_count"));
	mbz_do_sql("DROP VIEW livestats_sql") if(mbz_table_exists("livestats_sql"));
	
	# the actual livestats table
	mbz_do_sql(qq|
		CREATE TABLE livestats (
			name varchar(255) not null primary key,
			val bigint
		)
	|);
	           
	# a couple of extra views
	mbz_do_sql(qq|
		CREATE VIEW livestats_count AS
		SELECT sum(val) as total FROM livestats WHERE name like 'count.%'
	|);
	mbz_do_sql(qq|
		CREATE VIEW livestats_sql AS
		SELECT name, val FROM livestats WHERE name like 'sql.%'
		UNION SELECT 'sql.all', sum(val) FROM livestats WHERE name like 'sql.%'
	|);
	           
	print " Done\n";
	
	# count tables
	if($g_db_rdbms eq 'postgresql') {
		$sth = $dbh->prepare("select table_name from information_schema.tables ".
		                     "where table_schema='public'");
	}
	if($g_db_rdbms eq 'mysql') {
		$sth = $dbh->prepare("show tables");
	}
	$sth->execute();
	$start = time();
	
	# default data
	mbz_do_sql(qq|
		insert into livestats values
		('sql.insert', 0),
		('sql.update', 0),
		('sql.delete', 0),
		('count.pendinglog', 0)
	|);
	
	while(@result = $sth->fetchrow_array()) {
		if($result[0] ne "livestats" && substr($result[0],0,17) ne "over_art_presence") {
			print "  Counting records for table $result[0]... ";
			$table = mbz_escape_entity($result[0]);
			
			# create the key if it doesn't exist
			my $sth2 = $dbh->prepare("select count(1) from livestats where name='count.$result[0]'");
			$sth2->execute();
			my @key_exists = $sth2->fetchrow_array();
			if($key_exists[0] == 0) {
				mbz_do_sql("insert into livestats (name, val) values ('count.$result[0]', 0)");
			}
			
			mbz_do_sql("update livestats set val=(select count(1) from $table) ".
			           "where name='count.$result[0]'");
			           
			print "Done\n";
		}
	}
	           
	# TODO: The name of the pending tables depends on if this is NGS or not, there should be extra
	#       options in settings.pl or builtins.pl to configure these table names.
	mbz_do_sql("update livestats set val=0 where name='$g_pending' or name='$g_pendingdata'");
	
	return 1;
}

sub livestats_beforereplication {
	my ($repID) = @_;
	return 1;
}

sub livestats_beforestatement {
	my ($table, $seqID, $action, $data) = @_;
	return 1;
}

sub livestats_afterstatement {
	my ($table, $seqID, $action, $data) = @_;
	if($action eq 'i') {
		mbz_do_sql("UPDATE livestats SET val=val+1 WHERE name='count.$table' or name='sql.insert'");
	} elsif($action eq 'd') {
		mbz_do_sql("UPDATE livestats SET val=val-1 WHERE name='count.$table'");
		mbz_do_sql("UPDATE livestats SET val=val+1 WHERE name='sql.delete'");
	} elsif($action eq 'u') {
		mbz_do_sql("UPDATE livestats SET val=val+1 WHERE name='sql.update'");
	}
	return 1;
}

sub livestats_afterreplication {
	my ($repID) = @_;
	return 1;
}

return 1;
