#!/usr/bin/perl

use LWP::UserAgent;
use Net::FTP;


# connect to the specific RDBMS.
mbz_connect();


# TODO:
# ALTER TABLE  `artist_name` CHANGE  `name`  `name` TEXT CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL


# mbz_check_new_schema($id)
# Check if the SCHEMA_SEQUENCE matches $id, if it doesnt this means the schema has changed and we
# need to go download the latest schema and alter the database accordingly.
# @param $id The current schema number.
sub mbz_check_new_schema {
	my $id = $_[0];
	open(SCHEMAFILE, "replication/$id/SCHEMA_SEQUENCE") ||
		warn("Could not open 'replication/$id/SCHEMA_SEQUENCE'\n");
	my @data = <SCHEMAFILE>;
	chomp($data[0]);
	close(SCHEMAFILE);
	return ($data[0] == $schema);
}


# mbz_choose_language()
# Find out there language. This is for firstboot, once the language is set it can be changed
# manually in src/firstboot.pl.
# @return This function does not return. It will always issue a safe exit(0) so the script can be
#         restarted with the the new language file.
sub mbz_choose_language {
	choose:
	opendir(LANGDIR, "languages");
	my @languages = readdir(LANGDIR);
	closedir(LANGDIR);
	my @langoptions = ();
	foreach my $language (@languages) {
		if(substr($language, 0, 1) ne ".") {
			push(@langoptions, substr($language, 0, length($language) - 3));
		}
	}
	@langoptions = sort(@langoptions);
	for($i = 0; $i < @langoptions; ++$i) {
		print "[$i] $langoptions[$i]\n";
	}
	print "> ";
	chomp(my $input = <STDIN>);
	if($input !~ /^-?\d/ or $input < 0 or $input > @langoptions - 1) {
		print $L{'invalid'} . "\n\n";
		goto choose;
	}
	
	$g_chosenlanguage = 1;
	$g_language = $langoptions[$input];
	mbz_rewrite_settings();
	require "languages/$g_language.pl";
	print $L{'langchanged'};
	print "\n";
	exit(0);
}


# mbz_connect()
# This subroutine is just a controller that redirects to the connect for the RDBMS we are using.
# @return Passthru from backend_DB_connect().
sub mbz_connect {
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_connect();");
}


# mbz_create_extra_tables()
# This subroutine is just a controller that redirects to the create extra tables for the RDBMS we
# are using.
# @return Passthru from backend_DB_update_schema().
sub mbz_create_extra_tables {
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_create_extra_tables();");
}


# mbz_do_sql($sql)
# Execute a SQL statement that does not require a statement handle result. This is a safer and
# easier that using other methods because this subroutine will handles errors properly based on the
# values in settings.pl. This function should also be used with plugins that need to interface the
# MusicBrainz tables so that the plugin can follow the same rules as the replication itself.
# @param $sql The SQL statement to be executed.
# @return Passthru from $dbh::do().
sub mbz_do_sql {
	return $dbh->do($_[0]) or mbz_sql_error($dbh->errstr, $_[0]);
}


# mbz_download_file($url, $location)
# Generic function to download a file.
# @param $url The URL to fetch from.
# @param $location File path to save downloaded file to.
# @return Response result.
sub mbz_download_file {
	my $ua = LWP::UserAgent->new();
	my $request = HTTP::Request->new('GET', $_[0]);
	my $resp = $ua->request($request, $_[1]);

    if( $resp->is_success ) {
        return $resp;
    } else {
        die 'Error downloading ' . $_[0] . ': ' . $resp->status_line;
	}
}


# mbz_download_replication($id)
# Download a single replication.
# @param $id The replication ID to download, this will be the NEXT replication ID not the current
#            replication.
sub mbz_download_replication {
	my $id = $_[0];
	print "===== $id =====\n";
	
	# its possible the script was exited by the user or a crash during downloading or decompression,
	# for this reason we always download the latest copy.
	print localtime() . ": Downloading... ";
	$localfile = "replication/replication-$id.tar.bz2";
	$url = "$g_rep_url/replication-$id.tar.bz2";
	my $resp = mbz_download_file($url, $localfile);
	$found = 0;
	
	use HTTP::Status qw( RC_OK RC_NOT_FOUND RC_NOT_MODIFIED );
	if($resp->code == RC_NOT_FOUND) {
		# file not found
	} elsif($resp->code == RC_OK || $resp->code == RC_NOT_MODIFIED) {
		$found = 1;
	}
	
	print "Done\n";
	return $found;
}


# mbz_download_schema()
# This function will download the original MusicBrainz PostgreSQL SQL commands to create tables,
# indexes and PL/pgSQL. It will later be converted for the RDBMS we are using.
# @return Always 1.
sub mbz_download_schema {
	unlink("replication/CreateTables.sql");
	mbz_download_file($g_schema_url, "replication/CreateTables.sql");
	unlink("replication/CreateIndexes.sql");
	mbz_download_file($g_index_url, "replication/CreateIndexes.sql");
	unlink("replication/CreatePrimaryKeys.sql");
	mbz_download_file($g_pk_url, "replication/CreatePrimaryKeys.sql");
	unlink("replication/CreateFunctions.sql");
	mbz_download_file($g_func_url, "replication/CreateFunctions.sql");
	unlink("replication/ReplicationSetup.sql");
	mbz_download_file($g_pending_url, "replication/ReplicationSetup.sql");
	return 1;
}


# mbz_escape_entity()
# This subroutine is just a controller that redirects to the escape entity for the RDBMS we are
# using.
# @return Passthru from backend_DB_escape_entity().
sub mbz_escape_entity {
	# use the subroutine appropriate for the RDBMS
	my $entity = $_[0];
	return eval("backend_$g_db_rdbms" . "_escape_entity(\"$entity\");");
}


# mbz_first_boot()
# We currently don't need this but may in the future. It is called by init.pl the first time init.pl
# is run.
# @return Always 1.
sub mbz_first_boot {
	return 1;
}


# mbz_format_time()
# Translate seconds into "hours h minutes m seconds s"
# @return Formatted interval.
sub mbz_format_time {
	my $left = $_[0];
	my $hours = int($left / 3600);
	$left -= $hours * 3600;
	my $mins = int($left / 60);
	$left -= $mins * 60;
	my $secs = int($left);
	
	my $r = "";
	$r .= $hours . "h " if($hours > 0);
	$r .= " " if($mins < 10);
	$r .= $mins . "m ";
	$r .= " " if($secs < 10);
	$r .= $secs . "s";
	return $r;
}


# mbz_get_count($table_name, $extra)
# @param $table_name The name of the table to count from.
# @param $extra Extra string to put at the end.
# @return SQL count() result.
sub mbz_get_count {
	my ($table_name, $extra) = @_;
	$table_name = mbz_escape_entity($table_name);
	my $q = $dbh->prepare("select count(1) as count from $table_name $extra");
	$q->execute();
	return $q->fetchrow_hashref()->{'count'};
}


# mbz_get_current_replication()
# Get the current replication number.
# @return The current replication number or undef if there was a problem.
sub mbz_get_current_replication {
	my $sth = $dbh->prepare("select * from replication_control");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'current_replication_sequence'};
}


# mbz_get_key($name)
# Some plugins may require settings to be saved for next execution. You may use mbz_set_key() and
# mbz_get_key() for this. There is an example in plugins/example.pl.
# @note When using $name prepend it will somethign unique to your plugin as all plugins share the
#       same key-value space.
# @param $name The unique name.
# @return The value is returned on success or undef if it cannot be found.
sub mbz_get_key {
	my $sth = $dbh->prepare("select * from kv where name=" . $dbh->quote($_[0]));
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'value'};
}


# mbz_in_array($haystack, $needle)
# Based on the PHP function in_array(). Simply returns true if an array value exists.
# @param $haystack Array to search.
# @param $needle Scalar to search for.
# @return 1 if $needle is found, otherwise 0.
sub mbz_in_array {
	my ($arr, $search_for) = @_;
	my %items = map {$_ => 1} @$arr; # create a hash out of the array values
	return (exists($items{$search_for})) ? 1 : 0;
}


# mbz_update_index()
# This subroutine is just a controller that redirects to the index exists for the RDBMS we are
# using.
# @param $index_name The name of the index to look for.
# @return Passthru from backend_DB_index_exists().
sub mbz_index_exists {
	# use the subroutine appropriate for the RDBMS
	my $index_name = $_[0];
	return eval("backend_$g_db_rdbms" . "_index_exists(\"$index_name\");");
}


# mbz_init_plugins()
# Execute the PLUGIN_init() for each currently active plugin. Active plugins are set in
# src/settings.pl.
# @return Always 1.
sub mbz_init_plugins {
	# PLUGIN_init() for each active plugin
	foreach my $plugin (@g_active_plugins) {
		require "plugins/$plugin.pl";
		eval($plugin . "_init()") or warn($!);
	}
	
	return 1;
}


# mbz_load_data()
# This subroutine is just a controller that redirects to the loda data for the RDBMS we are using.
# @return Passthru from backend_DB_load_data().
sub mbz_load_data {
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_load_data();");
}


# mbz_load_pending()
# This subroutine is just a controller that redirects to the load pending for the RDBMS we are
# using.
# @return Passthru from backend_DB_load_pending().
sub mbz_load_pending {
	# use the subroutine appropriate for the RDBMS
	my $id = $_[0];
	return eval("backend_$g_db_rdbms" . "_load_pending(\"$id\");");
}


# mbz_map_kv($data, $join)
# This function takes the raw replication data in the format:
# "id"='255756' "link0"='210318' "link1"='672498' "link_type"='3' "begindate"= "enddate"=
# and generates the SQL key=value, non-existant values like begindate are set as NULL.
# @param $data The hash of the key-value pairs.
# @param $join The scalar to join each item with. For SQL this will be ",".
# @return A string built from the key-value pairs.
sub mbz_map_kv {
	my ($data, $join) = @_;
	my $r = "";
	my $first = 1;
	
	foreach my $k (keys(%$data)) {
		$r .= $join if(!$first);
		$first = 0 if($first);
		$r .= mbz_escape_entity($k) . "=" . $dbh->quote($data->{$k});
	}
	
	return $r;
}


# mbz_map_values($data, $join)
# This function takes the raw replication data in the format:
# "id"='255756' "link0"='210318' "link1"='672498' "link_type"='3' "begindate"= "enddate"=
# and generates the SQL in the form of:
# (a, b, c) VALUES (1, 2, 3)
# Non-existant values like begindate are set as NULL.
# @param $data The hash of the key-value pairs.
# @param $join The scalar to join each item with. For SQL this will be ",".
# @return A string built from the key-value pairs.
sub mbz_map_values {
	my ($data, $join) = @_;
	my $r = "(";
	
	my $first = 1;
	foreach my $k (keys(%$data)) {
		$r .= ',' if(!$first);
		$first = 0 if($first);
		$r .= mbz_escape_entity($k);
	}
	
	$r .= ") values (";
	
	my $first = 1;
	foreach my $k (keys(%$data)) {
		$r .= ',' if(!$first);
		$first = 0 if($first);
		$r .= $dbh->quote($data->{$k});
	}
	
	$r .= ")";
	return $r;
}


# mbz_pad_right($str, $len, $ch)
# This is just a simple function for padding a string to the right.
# @param $str The initial string to pad.
# @param $len The total number of characters to pad the string out to.
# @param $ch Pad character.
# @return Padded string.
sub mbz_pad_right {
	my ($str, $len, $ch) = @_;
	$r = "";
	for(my $i = 0; $i < $len - length($str); ++$i) {
		$r .= $ch;
	}
	return "$r$str";
}


# mbz_raw_download()
# Download all the mbdump files.
# @return 1 on success. This subroutine has the potential to issue a die() if there as serious ftp
#         problems.
sub mbz_raw_download {
	print "Logging into MusicBrainz FTP...\n";
	my @files;
	my $ftp;
	
	if($g_use_ngs) {
		# find out the latest NGS
		my $latest = "";
		my $host = 'ftp.musicbrainz.org';
		$ftp = Net::FTP->new($host, Timeout => 60)
					or die "Cannot contact $host: $!";
		$ftp->login('anonymous') or die "Can't login ($host): " . $ftp->message;
		$ftp->cwd('/pub/musicbrainz/data/ngs/')
			or die "Can't change directory ($host): " . $ftp->message;
		my @ls = $ftp->ls('-lr');
		my @parts = split(' ', $ls[0]);
		$latest = pop(@parts);
		print "The latest is mbdump is '$latest'\n";
		$ftp->cwd("/pub/musicbrainz/data/ngs/$latest")
				or die "Can't change directory (ftp.musicbrainz.org): " . $ftp->message;
				
		@files = (
			'mbdump-derived.tar.bz2',
			'mbdump-stats.tar.bz2',
			'mbdump.tar.bz2'
		);
	} else {
		# find out the latest fullexport
		my $latest = "";
		$ftp = Net::FTP->new('ftp.musicbrainz.org', Timeout => 60)
			or die "Cannot contact ftp.musicbrainz.org: $!";
		$ftp->login('anonymous') or die("Can't login (ftp.musicbrainz.org): " . $ftp->message);
		$ftp->cwd('/pub/musicbrainz/data/fullexport/')
			or die("Can't change directory (ftp.musicbrainz.org): " . $ftp->message);
		my @ls = $ftp->ls('-lR');
		foreach my $l (@ls) {
			if(index($l, 'latest-is-') >= 0) {
				$ftp->cwd('/pub/musicbrainz/data/fullexport/' .
				          substr($l, index($l, 'latest-is-') + 10))
					or die "Can't change directory (ftp.musicbrainz.org): " . $ftp->message;
				last;
			}
		}
		
		@files = (
			'mbdump-artistrelation.tar.bz2',
			'mbdump-derived.tar.bz2',
			'mbdump-stats.tar.bz2',
			'mbdump.tar.bz2'
		);
	}
	
	# probably need this
	$ftp->binary();
	
	foreach my $file (@files) {
		print localtime() . ": Downloading $file... ";
		
		# if the file exists, don't download it again
		if(-e "replication/$file") {
			print "File already downloaded\n";
		} else {
			$ftp->get($file, "replication/$file")
				or die("Unable to download file $file: " . $ftp->message);
			print "Done\n";
		}
	}
	
	return 1;
}


# mbz_remove_quotes($str)
# Take the double-quotes out of a string. This is used by mbz_update_schema because PostgreSQL
# wraps entity names in double quotes which does not work in most other RDBMSs.
# @return A new string that does not include double-quotes.
sub mbz_remove_quotes {
	my $str = $_[0];
	my $r = "";
	for(my $i = 0; $i < length($str); ++$i) {
		$r .= substr($str, $i, 1) if(substr($str, $i, 1) ne '"');
	}
	return $r;
}


# mbz_rewrite_settings()
# After choosing the language rewrite the firstboot.pl file.
# @return 1 on success, otherwise 0.
sub mbz_rewrite_settings {
	open(SETTINGS, "> src/firstboot.pl") or return 0;
	
	print SETTINGS "# First boot\n";
	print SETTINGS "\$g_chosenlanguage = $g_chosenlanguage;\n";
	print SETTINGS "\$g_firstboot      = $g_firstboot;\n\n";

	print SETTINGS "# Language\n";
	print SETTINGS "\$g_language = '$g_language';\n\n";

	print SETTINGS "return 1;\n";
	
	close(SETTINGS);
	return 1;
}


# mbz_round($number)
# Round to nearest integer.
# @param $number The number to round.
# @return Whole integer.
sub mbz_round {
    my ($number) = shift;
    return int($number + 0.5);
}


# mbz_run_transactions()
#
# The replications work by first loading a Pending and PendingData table. Each Pending record is
# a single replication action that joins to one or two records in the PendingData table. The
# PendingData table for any given replication record will have a raw data record and key record
# which is indicated by IsKey. The raw data record is used for INSERT and UPDATE as the new data to
# be inserted whereas the key record is use to specify the columns for the WHERE clause to be used
# in UPDATE and DELETE statements.
#
# Multiple replications are grouped into a single transaction with the XID column. For example a
# transaction would include the INSERT of a release and all the tracks for that album. The
# transaction support isn't implemented yet as the data given from MusicBrainz is assumed to be
# correct because it has already been passed the constraint checks. There may be some benefit to
# speed if the whole hours replication is wrapped into a single transaction but this can be left
# for some time in the future. It is however important that the Pending data run in the correct
# order specified by SeqId.
#
# Those wishing to keep the replication data can use the pendinglog plugin which will put all the
# incoming replications into a separate table that will grow over time. The pendinglog plugin uses
# a single table that uses one record per one replication item regardless of the replication action
# taken.
#
# This subroutine could possibly be moved to backend specific so that each RDBMS can impose its own
# optimsed rules however the SQL will always be the same, so for now i'll keep it generic SQL for
# all backend databases.
#
# @note Each XID is a transaction, however for this function we run the replication statements
#       inderpendantly in case the user is not using the InnoDB storage engine with MySQL.
# @return Always 1.
sub mbz_run_transactions {
	my $pending = mbz_escape_entity($g_pending);
	my $pendingdata = mbz_escape_entity($g_pendingdata);

	my $rep_handle = $dbh->prepare(qq|
		SELECT * from $pending
		LEFT JOIN $pendingdata ON $pending.SeqId=$pendingdata.SeqId
		ORDER BY $pending.SeqId, IsKey desc
	|);
	$rep_handle->execute();
	my $totalreps = mbz_get_count($g_pending);
	$starttime = time() - 1;
	$currep = mbz_get_current_replication();
	
	my ($key, $data);
	for(my $rows = 1; @rep_row = $rep_handle->fetchrow_array(); ) {
		# next if we are ignoring this table
		my $tableName = "";
		if($g_use_ngs) {
			$tableName = substr($rep_row[1], 15, length($rep_row[1]) - 16);
		} else {
			$tableName = substr($rep_row[1], 10, length($rep_row[1]) - 11);
		}
		if(mbz_in_array(\@g_ignore_tables, $tableName)) {
			++$rows if(($rep_row[5] eq '0' || $rep_row[5] eq 'f') || $rep_row[2] eq 'd');
			mbz_do_sql("DELETE FROM $pending WHERE SeqId='$rep_row[0]'");
			mbz_do_sql("DELETE FROM $pendingdata WHERE SeqId='$rep_row[0]'");
			next;
		}
		
		# also ignore any table that starts with "nz"
		next if(substr($tableName, 0, 2) eq "nz");
		
		# rename sanitised tables
		$tableName = "release_meta" if($tableName eq "release_meta_sanitised");
	
		# we use '1' and 't' for MySQL and PostgreSQL
		$key = mbz_unpack_data($rep_row[6]) if($rep_row[5] eq '1' or $rep_row[5] eq 't');
		
		# we use '0' and 'f' for MySQL and PostgreSQL
		if(($rep_row[5] eq '0' || $rep_row[5] eq 'f') || $rep_row[2] eq 'd') {
			$data = mbz_unpack_data($rep_row[6]);
			
			# build replicated SQL
			my $sql = "INSERT INTO ";
			$sql = "UPDATE " if($rep_row[2] eq 'u');
			$sql = "DELETE FROM " if($rep_row[2] eq 'd');
			$sql .= mbz_escape_entity($tableName) . " ";
			if($rep_row[2] eq 'i') {
				$sql .= mbz_map_values($data, ',');
			} elsif($rep_row[2] eq 'u') {
				$sql .= "SET " . mbz_map_kv($data, ',');
			}
			$sql .= " WHERE " . mbz_map_kv($key, " AND ") if(defined($key));
				
			# PLUGIN_beforestatement()
			foreach my $plugin (@g_active_plugins) {
				eval($plugin .
					"_beforestatement('$tableName', '$rep_row[0]', '$rep_row[2]', \$data)")
					or warn($!);
			}
			
			# execute SQL
			mbz_do_sql($sql);
			print mbz_pad_right($rows, length($totalreps), ' '), "/$totalreps (", 
			      mbz_pad_right(mbz_round($rows / $totalreps * 100), 3, ' '), '%)   ',
			      "Run: " . mbz_format_time(time() - $starttime) . "   ",
			      "ETA: " . mbz_format_time(((time() - $starttime) * ($totalreps / $rows)) *
			      	(($totalreps - $rows) / $totalreps)),
			      "\n";
				
			# PLUGIN_afterstatement()
			foreach my $plugin (@g_active_plugins) {
				eval($plugin .
					"_afterstatement('$tableName', '$rep_row[0]', '$rep_row[2]', \$data)")
					or warn($!);
			}
			
			# clear for next round
			mbz_do_sql("DELETE FROM $pending WHERE SeqId='$rep_row[0]'");
			mbz_do_sql("DELETE FROM $pendingdata WHERE SeqId='$rep_row[0]'");
			undef($key);
			undef($data);
			++$rows;
		}
	}
	
	# PLUGIN_afterreplication()
	foreach my $plugin (@g_active_plugins) {
		eval($plugin . "_afterreplication($currep)") or warn($!);
	}
	
	# Clean up. Remove old replication
	if($^O eq "MSWin32") {
		system("del \"replication/replication-$currep.tar.bz2\"");
		system("del \"replication/replication-$currep.tar\"");
		system("rmdir /s /y \"replication/$currep\"");
	} else {
		system("$g_rm -f \"replication/replication-$currep.tar.bz2\"");
		system("$g_rm -f \"replication/replication-$currep.tar\"");
		system("$g_rm -f -r \"replication/$currep\"");
	}
	
	return 1;
}


# mbz_set_key($name, $value)
# Some plugins may require settings to be saved for next execution. You may use mbz_set_key() and
# mbz_get_key() for this. There is an example in plugins/example.pl.
# @note When using $name prepend it will somethign unique to your plugin as all plugins share the
#       same key-value space.
# @param $name The unique name.
# @param $value Partner value of any type. The value is passed raw to mbz_set_key() as this
#               subroutine will handle the appropriate database escaping.
# @return Passthru from $dbh::do().
sub mbz_set_key {
	# TODO: handle value replacing if the key already exists.
	mbz_do_sql("insert into kv set name=" . $dbh->quote($_[0]) . ", value=" . $dbh->quote($_[1]));
}


# mbz_show_update_help()
# Show the console help message.
# @return Always 1.
sub mbz_show_update_help {
	print "mbzdb version: $g_version\n\n";
	print "-g=x or --skiptorep=x  Change replication number to 'x'\n";
	print "-h or --help           Show this help.\n";
	print "-i or --info           ";
	print "Only shows the information about the current replication and pending\n";
	print "                       transactions.\n";
	print "-p or --onlypending    Only process pending transactions then quit.\n";
	print "-q or --quiet          Non-verbose. The status of each statement is not printed.\n";
	print "-t or --truncate       Force TRUNCATE on $g_pending and $g_pendingdata tables.\n";
	
	return 1;
}


# mbz_sql_error($err, $stmt)
# Almost all SQL statements should be executed through mbz_do_sql(), this is because if the SQL
# fails this function is called. The action this function takes is dictated by what the user has
# specified in settings.pl.
# @param $err The error message directly from the RDBMS.
# @param $stmt The SQL statement that caused the problem.
# @return Always 0. However this subroutine has the potential to issue a die() if that is set as the
#         action in settings.pl.
sub mbz_sql_error {
	($err, $stmt) = @_;

	# is it a duplicate ID?
	# TODO: "Duplicate entry" is only suited to MySQL error messages.
	return 0 if((substr($err, 0, 15) eq "Duplicate entry") && ($g_die_on_dupid == 0));

	if($g_die_on_error == 1) {
		die("SQL: '$stmt'\n\n");
	} else {
		warn("SQL: '$stmt'\n\n");
	}
	
	return 0;
}


# mbz_table_column_exists($table_name, $col_name)
# This subroutine is just a controller that redirects to the table column exists for the RDBMS we
# are using.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub mbz_table_column_exists {
	# use the subroutine appropriate for the RDBMS
	my ($table_name, $col_name) = @_;
	return eval("backend_$g_db_rdbms" . "_table_column_exists(\"$table_name\", \"$col_name\");");
}


# mbz_table_exists($tablename)
# This subroutine is just a controller that redirects to the table exists for the RDBMS we are
# using.
# @return Passthru from backend_DB_table_exists().
sub mbz_table_exists {
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_table_exists(\"$_[0]\");");
}


# mbz_trim($string)
# Based on the PHP function trim() to chop whitespace off the left and right.
# @param $string The string to trim.
# @return A new copy of the trimmed string.
sub mbz_trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


# mbz_unpack_data($packed)
# Given a packed string from pending data this subroutine unpacks it into a hash of
# columnname => value.
# @return The hashref, or undef on failure.
sub mbz_unpack_data {
	my $packed = $_[0];
	my %answer;

	while (length($packed)) {
		my ($k, $v) = $packed =~ m/
			\A
			"(.*?)"		# column name
			=
			(?:
				'
				(
					(?:
						\\\\	# two backslashes == \
						| \\'	# backslash quote == '
						| ''	# quote quote also == '
						| [^']	# any other char == itself
					)*
				)
				'
			)?			# NULL if missing
			\x20		# always a space, even after the last column-value pair
		/sx or warn("Failed to parse: [$packed]"), return undef;

		$packed = substr($packed, $+[0]);

		if(defined($v)) {
			my $t = '';
			while(length($v)) {
				$t .= "\\", next if($v =~ s/\A\\\\//);
				$t .= "'", next if($v =~ s/\A\\'// or $v =~ s/\A''//);
				$t .= substr($v, 0, 1, '');
			}
			$v = $t;
		}

		$answer{$k} = $v;
	}
	
	# delete unwanted fields
	foreach my $dfield (@g_ignore_fields) {
		delete $answer{$dfield};
	}

	return \%answer;
}


# mbz_unzip_mbdump($file)
# Unzip downloaded mbdump file and move the raw tables to mbdump/.
# @param $file The file name to uncompress.
# @return Always 1.
sub mbz_unzip_mbdump {
	my $file = $_[0];
	print localtime() . ": Uncompressing $file... ";
	mkdir("mbdump");
	if($^O eq "MSWin32") {
		system("$g_mv replication\\mbdump\\* mbdump >nul");
		system("bin\\bunzip2 -f replication/$file");
		system("bin\\tar -xf replication/" . substr($file, 0, length($file) - 4) . " -C replication");
	} else {
		system("tar -xjf replication/$file -C replication");
		system("$g_mv replication/mbdump/* mbdump");
	}
	print "Done\n";
	return 1;
}

# mbz_unzip_mbdumps()
# Unzip all downloaded mbdumps.
# @return Always 1.
sub mbz_unzip_mbdumps {
	opendir(MBDUMP, "replication");
	my @files = sort(readdir(MBDUMP));
	
	foreach my $file (@files) {
		if(substr($file, 0, 6) eq 'mbdump' && substr($file, length($file) - 8, 8) eq '.tar.bz2' &&
		   substr($file, 0, 1) ne '.') {
			mbz_unzip_mbdump($file);
		}
	}
	
	closedir(MBDUMP);
	return 1;
}


# mbz_unzip_replication($id)
# Unzip downloaded replication.
# @param $id The current replication number. See mbz_get_current_replication().
# @return Always 1.
sub mbz_unzip_replication {
	my $id = $_[0];
	print localtime() . ": Uncompressing... ";
	mkdir("replication/$id");
	if($^O eq "MSWin32") {
		system("bin\\bunzip2 -f replication/replication-$id.tar.bz2");
		system("bin\\tar -xf replication/replication-$id.tar -C replication/$id");
	} else {
		system("tar -xjf replication/replication-$id.tar.bz2 -C replication/$id");
	}
	print "Done\n";
	return 1;
}


# mbz_update_index()
# This subroutine is just a controller that redirects to the update index for the RDBMS we are
# using.
# @return Passthru from backend_DB_update_index().
sub mbz_update_index {
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_update_index();");
}


# mbz_update_schema()
# This subroutine is just a controller that redirects to the update schema for the RDBMS we are
# using.
# @return Passthru from backend_DB_update_schema().
sub mbz_update_schema {
	print $L{'downloadschema'};
	mbz_download_schema();
	print $L{'done'} . "\n";
	
	# use the subroutine appropriate for the RDBMS
	return eval("backend_$g_db_rdbms" . "_update_schema();");
}


# mbz_create_folders()
# Create the required mbdump/ and replication/ folders if they do not exist
# @return Always 1.
sub mbz_create_folders {
	mkdir("mbdump");
	mkdir("replication");
	return 1;
}


# be nice
return 1;
