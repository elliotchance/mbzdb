#
# Soundex provides 4 extra tables for searching based on the soundex algorithm for what words sound
# like, rather than the physical letters they contain.
#
# SEE example.pl FOR DOCUMENTATION
#

sub soundex_description {
	return "Soundex provides 4 extra tables for searching based on the\n".
           "soundex algorithm for what words sound like, rather than the\n".
           "physical letters they contain.";
}

sub soundex_init {
	# this plugin is only available to MySQL
	if($g_db_rdbms ne 'mysql') {
		warn("soundex plugin is only supported by MySQL.\n\n");
		return 0;
	}

	# drop existing tables
	print "Dropping soundex tables...";
	mbz_do_sql("DROP TABLE album_soundex") if(mbz_table_exists("album_soundex"));
	mbz_do_sql("DROP TABLE artist_soundex") if(mbz_table_exists("artist_soundex"));
	mbz_do_sql("DROP TABLE track_soundex") if(mbz_table_exists("track_soundex"));
	print " Done\n";
	
	# create tables.
	print "Creating soundex tables...";
	mbz_do_sql(qq|
		CREATE TABLE album_soundex (
			albumid  int not null,
			soundindex varchar(255)
		) engine=$g_mysql_engine
	|);
	mbz_do_sql(qq|
		CREATE TABLE artist_soundex (
			artistid int not null,
			soundindex varchar(255)
		) engine=$g_mysql_engine
	|);
	mbz_do_sql(qq|
		CREATE TABLE track_soundex (
			trackid  int not null,
			soundindex varchar(255)
		) engine=$g_mysql_engine
	|);
	print " Done\n";
	
	# load raw data in from original tables
	print "Insering raw album data...";
	mbz_do_sql("insert into album_soundex  select id, soundex(name) from album");
	print " Done\n";
	print "Insering raw artist data...";
	mbz_do_sql("insert into artist_soundex select id, soundex(name) from artist");
	print " Done\n";
	print "Insering raw track data...";
	mbz_do_sql("insert into track_soundex  select id, soundex(name) from track");
	print " Done\n";
	
	# apply index
	print "Indexing album soundex...";
	mbz_do_sql(qq|
		alter table album_soundex
		add primary key(albumid),
		add index(soundindex)
	|);
	print " Done\n";
	print "Indexing artist soundex...";
	mbz_do_sql(qq|
		alter table artist_soundex
		add primary key(artistid),
		add index(soundindex)
	|);
	print " Done\n";
	print "Indexing track soundex...";
	mbz_do_sql(qq|
		alter table track_soundex
		add primary key(trackid),
		add index(soundindex)
	|);
	print " Done\n";
	
	return 1;
}

sub soundex_beforereplication {
	my ($repID) = @_;
	return 1;
}

sub soundex_beforestatement {
	my ($table, $seqID, $action, $data) = @_;
	return 1;
}

sub soundex_afterstatement {
	my ($table, $seqID, $action, $data) = @_;
	if($action eq 'd') {
		if($table eq "artist" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM artist_soundex WHERE artistid='" . $data->{'id'} . "'");
		} elsif($table eq "album" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM album_soundex WHERE albumid='" . $data->{'id'} . "'");
		} elsif($table eq "track" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM track_soundex WHERE trackid='" . $data->{'id'} . "'");
		}
	} else {
		if($table eq "artist" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO artist_soundex SET ".
			           "artistid='" . $data->{'id'} . "', ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ") ".
			           "ON DUPLICATE KEY UPDATE ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ")");
		} elsif($table eq "album" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO album_soundex SET ".
			           "albumid='" . $data->{'id'} . "', ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ") ".
			           "ON DUPLICATE KEY UPDATE ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ")");
		} elsif($table eq "track" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO track_soundex SET ".
			           "trackid='" . $data->{'id'} . "', ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ") ".
			           "ON DUPLICATE KEY UPDATE ".
			           "soundindex=soundex(" . $dbh->quote($data->{'name'}) . ")");
		}
	}
	return 1;
}

sub soundex_afterreplication {
	my ($repID) = @_;
	return 1;
}

return 1;
