#!/usr/bin/perl

use LWP::UserAgent;
use Net::FTP;


# Based on the PHP function trim() to chop whitespace off the left and right.
sub mbz_trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


# Based on the PHP function in_array(). Simply returns true if an array value exists.
sub mbz_in_array {
	my ($arr, $search_for) = @_;
	my %items = map {$_ => 1} @$arr; # create a hash out of the array values
	return (exists($items{$search_for})) ? 1 : 0;
}


# This is just a simple function for padding a string to the right.
sub mbz_pad_right {
	my ($str, $len, $ch) = @_;
	$r = "";
	for(my $i = 0; $i < $len - length($str); ++$i) {
		$r .= $ch;
	}
	return "$r$str";
}


# Round to nearest integer.
sub mbz_round {
    my ($number) = shift;
    return int($number + 0.5);
}


# Generic function to download a file.
sub mbz_download_file {
	my $ua = LWP::UserAgent->new();
	my $request = HTTP::Request->new('GET', $_[0]);
	my $resp = $ua->request($request, $_[1]);
}


# This function will download the original MusicBrainz PostgreSQL create table SQL. It will later
# be converted for the RDBMS we are using.
sub mbz_download_schema {
	unlink("temp/CreateTables.sql");
	mbz_download_file($g_schema_url, "temp/CreateTables.sql");
	unlink("temp/CreateIndexes.sql");
	mbz_download_file($g_index_url, "temp/CreateIndexes.sql");
	unlink("temp/CreatePrimaryKeys.sql");
	mbz_download_file($g_pk_url, "temp/CreatePrimaryKeys.sql");
	unlink("temp/CreateFunctions.sql");
	mbz_download_file($g_func_url, "temp/CreateFunctions.sql");
}


# Almost all SQL statements should be executed through mbz_do_sql(), this is because if the SQL
# fails this function is called. The action this function takes is dictate by what the user has
# specified in settings.pl.
sub mbz_sql_error {
	($err, $stmt) = @_;

	# is it a duplicate ID?
	return if((substr($err, 0, 15) eq "Duplicate entry") && ($g_die_on_dupid == 0));

	if($g_die_on_error == 1) {
		die "SQL: '$stmt'\n\n";
	} else {
		print "SQL: '$stmt'\n\n";
	}
}


# See the description for mbz_sql_error(). This function should also be used with plugins.
sub mbz_do_sql {
	return $dbh->do($_[0]) or mbz_sql_error($dbh->errstr, $_[0]);
}


# Some plugins may require settings to be saved for next execution. You may use mbz_set_key() and
# mbz_get_key() for this. There is an example in plugins/example.pl.
sub mbz_set_key {
	mbz_do_sql("insert into kv set name=" . $dbh->quote($_[0]) . ", value=" . $dbh->quote($_[1]));
}


# Some plugins may require settings to be saved for next execution. You may use mbz_set_key() and
# mbz_get_key() for this. There is an example in plugins/example.pl.
sub mbz_get_key {
	my $sth = $dbh->prepare("select * from kv where name=" . $dbh->quote($_[0]));
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'value'};
}


# Download all the mbdump files.
sub mbz_raw_download {
	print "Logging into MusicBrainz FTP...\n";
	
	# find out the latest NGS
	my $latest = "";
	my $host = 'ftp.musicbrainz.org';
	my $ftp = Net::FTP->new($host, Timeout => 60)
				or die "Cannot contact $host: $!";
	$ftp->login('anonymous') or die "Can't login ($host): " . $ftp->message;
	$ftp->cwd('/pub/musicbrainz/data/ngs/')
		or die "Can't change directory ($host): " . $ftp->message;
	my @ls = $ftp->ls('-lr');
	my @parts = split(' ', $ls[0]);
	$latest = pop(@parts);
	print "The latest is '$latest'\n";
	$ftp->cwd("/pub/musicbrainz/data/ngs/$latest")
			or die "Can't change directory (ftp.musicbrainz.org): " . $ftp->message;
	
	# these are the files we need to download, there is more but their not required.
	my @files = (
		#'mbdump-derived.tar.bz2',
		'mbdump-stats.tar.bz2'
		#'mbdump.tar.bz2'
	);
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
}


# find out there language
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


# After choosing the language rewrite the firstboot.pl file.
sub mbz_rewrite_settings {
	open(SETTINGS, "> firstboot.pl");
	
	print SETTINGS "# First boot\n";
	print SETTINGS "\$g_chosenlanguage = $g_chosenlanguage;\n";
	print SETTINGS "\$g_firstboot      = $g_firstboot;\n\n";

	print SETTINGS "# Language\n";
	print SETTINGS "\$g_language = '$g_language';\n\n";

	print SETTINGS "return 1;\n";
	
	close(SETTINGS);
}


sub mbz_remove_quotes {
	my $str = $_[0];
	my $r = "";
	for(my $i = 0; $i < length($str); ++$i) {
		$r .= substr($str, $i, 1) if(substr($str, $i, 1) ne '"');
	}
	return $r;
}


sub mbz_init_plugins {
	# PLUGIN_init()
	foreach my $plugin (@g_active_plugins) {
		require "plugins/$plugin.pl";
		eval($plugin . "_init()") or die($!);
	}
}


# The mbzdb modules use a basic key-value table to hold information such as settings.
sub mbz_create_extra_tables {
	mbz_do_sql("CREATE TABLE kv ("
	          ."name varchar(255) not null primary key,"
	          ."value text) tablespace $g_tablespace");
	         
	return 1;
}


sub mbz_update_schema {
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
				
				if($g_db_rdbms eq 'postgresql') {
					# because the original MusicBrainz database is PostgreSQL we only need to make
					# minimal changes to the SQL.
					
					if(substr($parts[$i], 0, 4) eq "CUBE" && !$g_contrib_cube) {
						$parts[$i] = "TEXT";
					}
				}
				
				if($g_db_rdbms eq 'mysql') {
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
}


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


sub mbz_update_index_postgresql {
	print $L{'downloadschema'};
	mbz_download_schema();
	print $L{'done'} . "\n";
	
	# we attempt to create language, load all the native functions and indexes. If the create
	# language or functions fail they will ultimatly be skipped.
	
	# for PostgreSQL we need to try CREATE LANGUAGE
	if($g_db_rdbms eq 'postgresql') {
		mbz_do_sql("CREATE LANGUAGE plpgsql");
	}
	
	open(SQL, "temp/CreateFunctions.sql");
	chomp(my @lines = <SQL>);
	my $full = "";
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\");
		
		$full .= "$line\n";
		if(index($line, 'plpgsql') > 0) {
			#print "$full\n";
			mbz_do_sql($full);
			$full = "";
		}
	}
	close(SQL);
	
	open(SQL, "temp/CreateIndexes.sql");
	chomp(my @lines = <SQL>);
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN");
		
		print "$line\n";
		mbz_do_sql($line);
	}
	close(SQL);
	
	open(SQL, "temp/CreatePrimaryKeys.sql");
	chomp(my @lines = <SQL>);
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN");
		
		print "$line\n";
		mbz_do_sql($line);
	}
	close(SQL);
}


# We can't always use the CreateIndexes.sql script provided by MusicBrainz because it has
# PostgreSQL specific functions. Instead we use a cardinality calculation to determine the need for
# an index.
sub mbz_update_index_mysql {
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


sub mbz_update_index {
	# use the subroutine appropraite for the RDBMS
	if($g_db_rdbms eq 'postgresql') {
		mbz_update_index_postgresql();
		return 1;
	}
	if($g_db_rdbms eq 'mysql') {
		mbz_update_index_mysql();
		return 1;
	}
}


# Given a packed string from "PendingData"."Data", this sub unpacks it into a hash of
# columnname => value.  It returns the hashref, or undef on failure.
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

		if (defined $v) {
			my $t = '';
			while (length $v) {
				$t .= "\\", next if $v =~ s/\A\\\\//;
				$t .= "'", next if $v =~ s/\A\\'// or $v =~ s/\A''//;
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


sub mbz_table_exists {
	my $sth = $dbh->prepare("select count(1) as count from information_schema.tables ".
	                        "where table_name='$_[0]'");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'count'};
}


sub mbz_load_data {
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
}


# This function takes the raw replciation data in the format:
# "id"='255756' "link0"='210318' "link1"='672498' "link_type"='3' "begindate"= "enddate"=
# and generates the SQL key=value, non-existant values like begindate are set as NULL.
sub mbz_map_kv {
	my ($data, $join) = @_;
	my $r = "";
	my $first = 1;
	
	foreach my $k (keys(%$data)) {
		$r .= $join if(!$first);
		$first = 0 if($first);
		$r .= "\"$k\"=" . $dbh->quote($data->{$k});
	}
	
	return $r;
}


sub mbz_map_values {
	my ($data, $join) = @_;
	my $r = "(";
	
	my $first = 1;
	foreach my $k (keys(%$data)) {
		$r .= ',' if(!$first);
		$first = 0 if($first);
		$r .= "\"$k\"";
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


sub mbz_get_current_replication {
	my $sth = $dbh->prepare("select * from replication_control");
	$sth->execute();
	my $result = $sth->fetchrow_hashref();
	return $result->{'current_replication_sequence'};
}


# PLEASE NOTE: Each XID is a transaction, however for this function we run the replication
#              statements inderpendantly in case the user is not using the InnoDB engine.
sub mbz_run_transactions {
	my $rep_handle = $dbh->prepare("select * from $g_pending left join $g_pendingdata ".
		"on $g_pending.\"SeqId\"=$g_pendingdata.\"SeqId\" ".
		"order by $g_pending.\"SeqId\", \"IsKey\" desc");
	$rep_handle->execute();
	my $rep_total = $dbh->prepare("select count(1) as count from $g_pending");
	$rep_total->execute();
	$totalreps = $rep_total->fetchrow_hashref()->{'count'};
	$starttime = time() - 1;
	$currep = mbz_get_current_replication();
	
	my ($key, $data);
	for(my $rows = 1; @rep_row = $rep_handle->fetchrow_array(); ) {
		# next if we are ignoring this table
		my $tableName = substr($rep_row[1], 10, length($rep_row[1]) - 11);
		if(mbz_in_array(\@g_ignore_tables, $tableName)) {
			++$rows if($rep_row[5] eq '0' || $rep_row[2] eq 'd');
			mbz_do_sql("DELETE FROM $g_pending WHERE \"SeqId\"='$rep_row[0]'");
			mbz_do_sql("DELETE FROM $g_pendingdata WHERE \"SeqId\"='$rep_row[0]'");
			next;
		}
	
		$key = mbz_unpack_data($rep_row[6]) if($rep_row[5] eq '1');
		if($rep_row[5] eq '0' || $rep_row[2] eq 'd') {
			$data = mbz_unpack_data($rep_row[6]);
			
			# build replicated SQL
			my $sql = "insert into ";
			$sql = "update " if($rep_row[2] eq 'u');
			$sql = "delete from " if($rep_row[2] eq 'd');
			$sql .= "\"$tableName\" ";
			if($rep_row[2] eq 'i') {
				$sql .= mbz_map_values($data, ',');
			} elsif($rep_row[2] eq 'u') {
				$sql .= "SET " . mbz_map_kv($data, ',');
			}
			$sql .= " WHERE " . mbz_map_kv($key, " AND ") if(defined($key));
				
			# PLUGIN_beforestatement()
			foreach my $plugin (@g_active_plugins) {
				eval("$plugin" .
					"_beforestatement('$tableName', '$rep_row[0]', '$rep_row[2]', \$data)")
					or die($!);
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
				eval("$plugin" .
					"_afterstatement('$tableName', '$rep_row[0]', '$rep_row[2]', \$data)")
					or die($!);
			}
			
			# clear for next round
			mbz_do_sql("DELETE FROM $g_pending WHERE \"SeqId\"='$rep_row[0]'");
			mbz_do_sql("DELETE FROM $g_pendingdata WHERE \"SeqId\"='$rep_row[0]'");
			undef($key);
			undef($data);
			++$rows;
		}
	}
	
	# PLUGIN_afterreplication()
	foreach my $plugin (@g_active_plugins) {
		eval("$plugin" . "_afterreplication($currep)") or die($!);
	}
	
	# Clean up. Remove old replication
	system("$g_rm -f replication/replication-$currep.tar.bz2");
	system("$g_rm -f replication/replication-$currep.tar");
	system("$g_rm -f -r replication/$currep");
}


# Load Pending and PendingData from the downaloded replciation into the respective tables. This
# function is different to mbz_load_data that loads the raw mbdump/ whole tables.
sub mbz_load_pending {
	$id = $_[0];

	# make sure there are no pending transactions before cleanup
	$temp = $dbh->prepare("SELECT count(1) FROM $g_pending");
	$temp->execute;
	@row = $temp->fetchrow_array();
	$temp->finish;
	return -1 if($row[0] ne '0');

	# perform cleanup (makes sure there no left over records in the PendingData table)
	$dbh->do("DELETE FROM $g_pending");

	# load Pending and PendingData
	print localtime() . ": Loading pending tables... ";
	
	open(TABLEDUMP, "replication/$id/mbdump/Pending")
		or warn("Error: cannot open file 'replication/$id/mbdump/Pending'\n");
	$dbh->do("COPY $g_pending FROM STDIN");
	while($readline = <TABLEDUMP>) {
		$dbh->pg_putcopydata($readline);
	}
	close(TABLEDUMP);
  	$dbh->pg_putcopyend();
  	
  	open(TABLEDUMP, "replication/$id/mbdump/PendingData")
  		or warn("Error: cannot open file 'replication/$id/mbdump/PendingData'\n");
	$dbh->do("COPY $g_pendingdata FROM STDIN");
	while($readline = <TABLEDUMP>) {
		$dbh->pg_putcopydata($readline);
	}
	close(TABLEDUMP);
  	$dbh->pg_putcopyend();
  	
	print "Done\n";
	
	# PLUGIN_beforereplication()
	foreach my $plugin (@g_active_plugins) {
		eval("$plugin" . "_beforereplication($id)") or die($!);
	}
	
	return 1;
}


# Unzip downloaded replication.
sub mbz_unzip_replication {
	my $id = $_[0];
	print localtime() . ": Uncompressing... ";
	mkdir("replication/$id");
	system("bunzip2 -f replication/replication-$id.tar.bz2");
	system("tar -xf replication/replication-$id.tar -C replication/$id");
	print "Done\n";
	return 1;
}


# Unzip downloaded mbdump file and move the raw tables to mbdump/.
sub mbz_unzip_mbdump {
	my $file = $_[0];
	print localtime() . ": Uncompressing $file... ";
	mkdir("mbdump");
	system("bunzip2 -f replication/$file");
	system("tar -xf replication/" . substr($file, 0, length($file) - 4) . " -C replication");
	if($^O eq "MSWin32") {
		system("$g_mv replication\\mbdump\\* mbdump >nul");
	} else {
		system("$g_mv replication/mbdump/* mbdump");
	}
	print "Done\n";
	return 1;
}


# Unzip all downloaded mbdumps
sub mbz_unzip_mbdumps {
	opendir(MBDUMP, "replication");
	my @files = sort(readdir(MBDUMP));
	foreach my $file (@files) {
		if(substr($file, 0, 6) eq 'mbdump' && substr($file, length($file) - 8, 8) eq '.tar.bz2' &&
		   substr($file, 0, 1) ne '.') {
			mbz_unzip_mbdump($file);
		}
	}
}


# There is going to be a change soon to NGS (new generation schema) which is not a improved version
# of the current schema, but a complete rewrite. Until that day comes this function will remain
# inactive, but the principle will be useful for when NGS comes in.
sub mbz_check_new_schema {
	my $id = $_[0];
	open(SCHEMAFILE, "replication/$id/SCHEMA_SEQUENCE") ||
		die "Could not open 'replication/$id/SCHEMA_SEQUENCE'\n";
	my @data = <SCHEMAFILE>;
	chomp($data[0]);
	close(SCHEMAFILE);
	return 0 if($data[0] == $schema);
	return 1;
}


# Download a single replication
sub mbz_download_replication {
	my $id = $_[0];
	print "===== $id =====\n";
	
	# its possible the script was exited by the user or a crash during
	# downloading or decompression, for this reason we always download
	# the latest copy.
	print localtime() . ": Downloading... ";
	$localfile = "replication/replication-$id.tar.bz2";
	$url = "ftp://ftp.musicbrainz.org/pub/musicbrainz/data/replication/replication-$id.tar.bz2";
	$ua = LWP::UserAgent->new();
	$request = HTTP::Request->new('GET', $url);
	$resp = $ua->request($request, $localfile);
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


sub mbz_show_update_help {
	print "mbzdb version: $g_version\n\n";
	print "-g=x or --skiptorep=x  Change replication number to 'x'\n";
	print "-h or --help           Show this help.\n";
	print "-i or --info           ";
	print "Only shows the information about the current replication and pending\n";
	print "                       transactions.\n";
	print "-p or --onlypending    Only process pending transactions then quit.\n";
	print "-q or --quiet          Non-verbose. The status of each statement is not printed.\n";
	print "-t or --truncate       Force TRUNCATE on Pending and PendindData tables.\n";
}


# We currently don't need this but may in the future. It is called by init.pl the first time init.pl
# is run.
sub mbz_first_boot {
}


return 1;
