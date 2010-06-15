#
# InnoDB doesn't support fulltext indexing, but with this plugin it will keep a managed
# copy of the artist, album and track tables as MyISAM so you can use the fulltext index.
#
# SEE example.pl FOR DOCUMENTATION
#

sub fulltext_description {
	return "InnoDB doesn't support fulltext indexing, but with this\n"
		 . "plugin it will keep a managed copy of the artist, album and\n"
		 . "track tables as MyISAM so you can use the fulltext index.";
}

sub fulltext_init {
	# drop existing tables
	print "Dropping fulltext tables...";
	mbz_do_sql("DROP TABLE IF EXISTS album_fulltext");
	mbz_do_sql("DROP TABLE IF EXISTS artist_fulltext");
	mbz_do_sql("DROP TABLE IF EXISTS artistalias_fulltext");
	mbz_do_sql("DROP TABLE IF EXISTS track_fulltext");
	mbz_do_sql("DROP TABLE IF EXISTS label_fulltext");
	mbz_do_sql("DROP TABLE IF EXISTS labelalias_fulltext");
	print " Done\n";
	
	# create tables.
	print "Creating fulltext tables...";
	mbz_do_sql("CREATE TABLE album_fulltext       (albumid  int not null, name varchar(255)) engine=MyISAM");
	mbz_do_sql("CREATE TABLE artist_fulltext      (artistid int not null, name varchar(255), sortname varchar(255), resolution varchar(255)) engine=MyISAM");
	mbz_do_sql("CREATE TABLE artistalias_fulltext (id int not null, artistid int not null, name varchar(255)) engine=MyISAM");
	mbz_do_sql("CREATE TABLE track_fulltext       (trackid  int not null, name varchar(255)) engine=MyISAM");
	mbz_do_sql("CREATE TABLE label_fulltext       (labelid  int not null, name varchar(255), sortname varchar(255), resolution varchar(255)) engine=MyISAM");
	mbz_do_sql("CREATE TABLE labelalias_fulltext  (id int not null, labelid  int not null, name varchar(255)) engine=MyISAM");
	print " Done\n";
	
	# load raw data in from original tables
	print "Insering raw album data...";
	mbz_do_sql("insert into album_fulltext  select id, name from album");
	print " Done\n";
	print "Insering raw artist data...";
	mbz_do_sql("insert into artist_fulltext select id, name, sortname, resolution from artist");
	print " Done\n";
	print "Insering raw track data...";
	mbz_do_sql("insert into track_fulltext  select id, name from track");
	print " Done\n";
	print "Insering raw label data...";
	mbz_do_sql("insert into label_fulltext  select id, name, sortname, resolution from label");
	print " Done\n";
	print "Insering raw artistalias data...";
	mbz_do_sql("insert into artistalias_fulltext  select id, ref, name from artistalias");
	print " Done\n";
	print "Insering raw labelalias data...";
	mbz_do_sql("insert into labelalias_fulltext  select id, ref, name from labelalias");
	print " Done\n";
	
	# apply index
	print "Indexing album fulltext...";
	mbz_do_sql("alter table album_fulltext add primary key(albumid), add fulltext(name)");
	print " Done\n";
	print "Indexing artist fulltext...";
	mbz_do_sql("alter table artist_fulltext add primary key(artistid), add fulltext(name), add fulltext(sortname), add fulltext(resolution)");
	print " Done\n";
	print "Indexing track fulltext...";
	mbz_do_sql("alter table track_fulltext add primary key(trackid), add fulltext(name)");
	print " Done\n";
	print "Indexing label fulltext...";
	mbz_do_sql("alter table label_fulltext add primary key(labelid), add fulltext(name), add fulltext(sortname), add fulltext(resolution)");
	print " Done\n";
	print "Indexing artistalias fulltext...";
	mbz_do_sql("alter table artistalias_fulltext add primary key(id), add index(artistid), add fulltext(name)");
	print " Done\n";
	print "Indexing labelalias fulltext...";
	mbz_do_sql("alter table labelalias_fulltext add primary key(id), add index(labelid), add fulltext(name)");
	print " Done\n";
	
	return 1;
}

sub fulltext_beforereplication {
	my ($repID) = @_;
	return 1;
}

sub fulltext_beforestatement {
	my ($table, $seqID, $action, $data) = @_;
	return 1;
}

sub fulltext_afterstatement {
	my ($table, $seqID, $action, $data) = @_;
	if($action eq 'd') {
		if($table eq "artist" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM artist_fulltext WHERE artistid='" . $data->{'id'} . "'");
		} elsif($table eq "album" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM album_fulltext WHERE albumid='" . $data->{'id'} . "'");
		} elsif($table eq "track" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM track_fulltext WHERE trackid='" . $data->{'id'} . "'");
		} elsif($table eq "label" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM label_fulltext WHERE labelid='" . $data->{'id'} . "'");
		} elsif($table eq "artistalias" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM artistalias_fulltext WHERE id='" . $data->{'ref'} . "'");
		} elsif($table eq "labelalias" && $data->{'id'} != 0) {
			mbz_do_sql("DELETE FROM labelalias_fulltext WHERE id='" . $data->{'ref'} . "'");
		}
	} else {
		if($table eq "artist" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO artist_fulltext SET artistid='" . $data->{'id'} . "', name=" . $dbh->quote($data->{'name'}) . ", sortname=" . $dbh->quote($data->{'sortname'}) . ", resolution=" . $dbh->quote($data->{'resolution'}) . " ON DUPLICATE KEY UPDATE name=" . $dbh->quote($data->{'name'}) . ", sortname=" . $dbh->quote($data->{'sortname'})) . ", resolution=" . $dbh->quote($data->{'resolution'});
		} elsif($table eq "album" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO album_fulltext SET albumid='" . $data->{'id'} . "', name=" . $dbh->quote($data->{'name'}) . " ON DUPLICATE KEY UPDATE name=" . $dbh->quote($data->{'name'}));
		} elsif($table eq "track" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO track_fulltext SET trackid='" . $data->{'id'} . "', name=" . $dbh->quote($data->{'name'}) . " ON DUPLICATE KEY UPDATE name=" . $dbh->quote($data->{'name'}));
		} elsif($table eq "label" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO label_fulltext SET labelid='" . $data->{'id'} . "', name=" . $dbh->quote($data->{'name'}) . ", sortname=" . $dbh->quote($data->{'sortname'}) . ", resolution=" . $dbh->quote($data->{'resolution'}) . " ON DUPLICATE KEY UPDATE name=" . $dbh->quote($data->{'name'}) . ", sortname=" . $dbh->quote($data->{'sortname'})) . ", resolution=" . $dbh->quote($data->{'resolution'});
		} elsif($table eq "artistalias" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO artistalias_fulltext SET id='" . $data->{'id'} . "', artistid='" . $data->{'ref'} . "', name=" . $dbh->quote($data->{'name'}) . " ON DUPLICATE KEY UPDATE artistid='" . $data->{'ref'} . "', name=" . $dbh->quote($data->{'name'}));
		} elsif($table eq "labelalias" && $data->{'id'} != 0) {
			mbz_do_sql("INSERT INTO labelalias_fulltext SET id='" . $data->{'id'} . "', labelid='" . $data->{'ref'} . "', name=" . $dbh->quote($data->{'name'}) . " ON DUPLICATE KEY UPDATE labelid='" . $data->{'ref'} . "', name=" . $dbh->quote($data->{'name'}));
		}
	}
	return 1;
}

sub fulltext_afterreplication {
	my ($repID) = @_;
	return 1;
}

return 1;
