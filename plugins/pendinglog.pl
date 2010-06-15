#
# Pending Log keeps a copy of all replicated data.
#
# SEE example.pl FOR DOCUMENTATION
#

sub pendinglog_description {
	return "Pending Log keeps a copy of all replicated data.";
}

sub pendinglog_init {
	# create table
	print "Creating pendinglog table...";
	mbz_do_sql("CREATE TABLE pendinglog (seqid int not null primary key, repid int not null, tablename varchar(255), op char(1), xid int, data text, keyclause text)");
	mbz_do_sql("create index pendinglog_repid on pendinglog (repid)");
	mbz_do_sql("create index pendinglog_xid on pendinglog (xid)");
	print " Done\n";
	
	return 1;
}

sub pendinglog_beforereplication {
	my ($repID) = @_;
	mbz_do_sql("insert into pendinglog " .
	           "select \"Pending\".\"SeqId\", '$repID', substring(\"TableName\" from 11 for length(\"TableName\") - 11) as \"TableName\", " .
	           "\"Op\", \"XID\", \"P1\".\"Data\", \"P2\".\"Data\" as keyclause " .
	           "from \"Pending\" " .
	           "left join \"PendingData\" as \"P1\" on \"Pending\".\"SeqId\"=\"P1\".\"SeqId\" and \"P1\".\"IsKey\"='f' " .
	           "left join \"PendingData\" as \"P2\" on \"Pending\".\"SeqId\"=\"P2\".\"SeqId\" and \"P2\".\"IsKey\"='t' ");
	mbz_do_sql("update livestats set val=val+(select count(1) from \"Pending\") where name='count.pendinglog'");
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
