#
# LiveStats keeps a live count of the table sizes. This is important because InnoDB
# is transactional and count(*) requires an expensive full table scan.
#
# SEE example.pl FOR DOCUMENTATION
#

sub livestats_description {
	return "LiveStats keeps a live count of the table sizes. This is\n"
	     . "important because InnoDB is transactional and count(*)\n"
	     . "requires an expensive full table scan."
}

sub livestats_init {
	# create tables
	print "Creating livestats table...";
	mbz_do_sql("CREATE OR REPLACE FUNCTION update_livestats(newname character varying(255), newval bigint)\n".
	           "RETURNS VOID AS \$\$\n".
	           "BEGIN\n".
	           "    UPDATE livestats SET val = newval WHERE name = newname;\n".
	           "    IF found THEN\n".
	           "        RETURN;\n".
	           "    END IF;\n".
	           "    INSERT INTO livestats(name, val) VALUES (newname, newval);\n".
	           "END;".
	           "\$\$\n".
	           "LANGUAGE plpgsql;");
	mbz_do_sql("DROP TABLE livestats cascade");
	mbz_do_sql("DROP VIEW livestats_count");
	mbz_do_sql("DROP VIEW livestats_sql");
	mbz_do_sql("CREATE TABLE livestats (name varchar(255) not null primary key, val bigint)");
	mbz_do_sql("CREATE VIEW livestats_count as SELECT sum(val) as total FROM livestats WHERE name like 'count.%'");
	mbz_do_sql("CREATE VIEW livestats_sql as SELECT name, val FROM livestats WHERE name like 'sql.%' ".
	           "UNION SELECT 'sql.all', sum(val) FROM livestats WHERE name like 'sql.%'");
	print " Done\n";
	
	# count tables
	$sth = $dbh->prepare("select table_name from information_schema.tables where table_schema='public'");
	$sth->execute();
	$start = time();
	while(@result = $sth->fetchrow_array()) {
		if($result[0] ne "livestats") {
			print "  Counting records for table $result[0]... ";
			mbz_do_sql("insert into livestats (name, val) values ('count.$result[0]', (select count(1) from \"$result[0]\"))");
			print "Done\n";
		}
	}
	
	# default data
	mbz_do_sql("insert into livestats values ('sql.insert', 0), ('sql.update', 0), ('sql.delete', 0), ('count.pendinglog', 0)");
	mbz_do_sql("update livestats set val=0 where name='Pending' or name='PendingData'");
	
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
