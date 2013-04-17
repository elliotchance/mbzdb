#!/usr/bin/perl

use LWP::UserAgent;
use DBI;

# FLAGS
$f_quiet = 0;
$f_info = 0;
$f_onlypending = 0;
$f_skiptorep = 0;
$f_truncatetables = 0;

# PROCESS FLAGS
foreach $ARG (@ARGV) {
	@parts = split("=", $ARG);
	if($parts[0] eq "-q" || $parts[0] eq "--quiet") {
		$f_quiet = 1;
	} elsif($parts[0] eq "-i" || $parts[0] eq "--info") {
		$f_info = 1;
	} elsif($parts[0] eq "-t" || $parts[0] eq "--truncate") {
		$f_truncatetables = 1;
	} elsif($parts[0] eq "-p" || $parts[0] eq "--onlypending") {
		$f_onlypending = 1;
	} elsif($parts[0] eq "-g" || $parts[0] eq "--skiptorep") {
		$f_skiptorep = int($parts[1]);
	} elsif($parts[0] eq "-h" || $parts[0] eq "--help") {
		mbz_show_update_help();
		exit(0);
	} else {
		die "Unknown option '$parts[0]'\n";
	}
}

# TRUNCATE TABLES
if($f_truncatetables == 1) {
	mbz_do_sql("TRUNCATE $g_pending");
	mbz_do_sql("TRUNCATE $g_pendingdata");
	print "Table truncate successful.\n";
	exit(0);
}

BEGIN:

# FIND IF THERE ARE PENDING TRANSACTIONS
$sth = $dbh->prepare("SELECT count(1) from " . mbz_escape_entity($g_pending));
$sth->execute();
@row = $sth->fetchrow_array();
if($f_info) {
	print "\nCurrent replication       : " . ($rep + 1);
	$sql = "SELECT * from replication_control";
	my $sth2 = $dbh->prepare($sql);
	$sth2->execute;
	my @row2 = $sth2->fetchrow_array();
	print "\nLast replication finished : " . $row2[3];
	print "\nPending transactions      : $row[0]\n\n";
	exit(0);
}

print "\nCurrent replication is $rep\n\n";
$id = int($rep) + 1;
print "Looking for previous pending changes... $row[0] pending\n\n";

if($row[0] == 0 && !$f_info) {
	exit(0) if($f_onlypending);
	if(!mbz_download_replication($id)) {
		print "\nReplication $id could not be found on the server\n\n";
		exit(0);
	}
	mbz_unzip_replication($id);
	mbz_load_pending($id);
}

# run the pending edits
print localtime() . ": Processing Transactions...\n";
mbz_run_transactions();
print "Finished\n";

goto BEGIN if(!$f_info);

1;
