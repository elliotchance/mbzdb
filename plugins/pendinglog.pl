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
	mbz_do_sql(qq|
		INSERT INTO pendinglog
		SELECT Pending.SeqId, '$repID',
			substring(TableName from 11 for length(TableName) - 11) as TableName, Op, XID, P1.Data,
			P2.Data as keyclause
		FROM Pending
		LEFT JOIN PendingData as P1 on Pending.SeqId=P1.SeqId and P1.IsKey='f'
		LEFT JOIN PendingData as P2 on Pending.SeqId=P2.SeqId and P2.IsKey='t'
	|);
	mbz_do_sql(qq|
		UPDATE livestats set val=val+(select count(1) from Pending)
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
