#
# Pending Log keeps a copy of all replicated data.
#
# SEE example.pl FOR DOCUMENTATION
#

sub pendinglog_description {
	return "Pending Log keeps a copy of all replicated data.";
}

sub pendinglog_init {
	if(!mbz_table_exists("pendinglog")) {
		# create table, we will not drop the table if it already exists so there no risk of losing data.
		print "Creating pendinglog table...";
		mbz_do_sql(qq|
			CREATE TABLE pendinglog (
				seqid int not null primary key,
				repid int not null,
				tablename varchar(255),
				op char(1),
				xid int,
				data text,
				keyclause text
			)
		|);
		
		# create some indexes
		mbz_do_sql("create index pendinglog_repid on pendinglog (repid)");
		mbz_do_sql("create index pendinglog_xid on pendinglog (xid)");
		
		print " Done\n";
	} else {
		print "pendinglog table already exists - skipping\n";
	}
	
	return 1;
}

sub pendinglog_beforereplication {
	my ($repID) = @_;
	my $pending = mbz_escape_entity($g_pending);
	my $pendingdata = mbz_escape_entity($g_pendingdata);
	my $seqid = mbz_escape_entity("SeqId");
	my $iskey = mbz_escape_entity("IsKey");
	my $tablename = mbz_escape_entity("TableName");
	my $op = mbz_escape_entity("Op");
	my $xid = mbz_escape_entity("XID");
	my $data = mbz_escape_entity("Data");
	
	mbz_do_sql(qq|
		INSERT INTO pendinglog
		SELECT $pending.$seqid, '$repID',
			substring($tablename from 11 for length($tablename) - 11) as $tablename, $op, $xid, P1.$data,
			P2.$data as keyclause
		FROM $pending
		LEFT JOIN $pendingdata as P1 on $pending.$seqid=P1.$seqid and P1.$iskey='f'
		LEFT JOIN $pendingdata as P2 on $pending.$seqid=P2.$seqid and P2.$iskey='t'
	|);
	mbz_do_sql(qq|
		UPDATE livestats set val=val+(select count(1) from $pending)
		where name='count.pendinglog'
	|);
	return 1;
}

sub pendinglog_beforestatement {
	my ($table, $seqID, $action, $data) = @_;
	return 1;
}

sub pendinglog_afterstatement {
	my ($table, $seqID, $action, $data) = @_;
	return 1;
}

sub pendinglog_afterreplication {
	my ($repID) = @_;
	return 1;
}

return 1;
