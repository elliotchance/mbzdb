#!/usr/bin/perl -w

package MbzDb::Backend;

use strict;
use warnings;
use Net::FTP;
use LWP::UserAgent;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(GetClassByName);

sub GetClassByName {
    my $backendName = lc(shift);
    
    if($backendName eq 'mysql') {
        return 'MbzDb::Backend::MySQL';
    }
    
    return undef;
}

# init()
# This is called when --init is used from the command line. It is responsible for anything that is
# required to setup the environment before the schema is allied and data is loaded in.
sub init {
    return 1;
}

# updateSchema()
# Attempt to update the schema from the current version to a new version by creating a table with a
# dummy field, altering the tables by adding one field at a time them removing the dummy field. The
# idea is that given any schema and SQL file the new table fields will be added, the same fields
# will result in an error and the table will be left unchanged and fields and tables that have been
# removed from the new schema will not be removed from the current schema.
# This is a crude way of doing it. The field order in each table after it's altered will not be
# retained from the new schema however the field order should not have a big bearing on the usage
# of the database because name based and column ID in scripts that use the database will remain the
# same.
# It would be nice if this subroutine had a makeover so that it would check items before attempting
# to create (and replace) them. This is just so all the error messages and so nasty.
sub updateSchema {
    my $self = shift;
    
	$self->updateSchemaFromFile("replication/CreateTables.sql");
	$self->updateSchemaFromFile("replication/ReplicationSetup.sql");
	$self->updateSchemaFromFile("replication/StatisticsSetup.sql");
	$self->updateSchemaFromFile("replication/CoverArtSetup.sql");
	
	return 1;
}

# updateSchemaFromFile($path)
# Override this with your backend specific implementation.
sub updateSchemaFromFile {
    return 1;
}

# removeQuotes($str)
# Take the double-quotes out of a string. This is used by updateSchema() because PostgreSQL
# wraps entity names in double quotes which does not work in most other RDBMSs.
# @return A new string that does not include double-quotes.
sub removeQuotes {
	my ($self, $str) = @_;
	my $r = "";
	for(my $i = 0; $i < length($str); ++$i) {
		$r .= substr($str, $i, 1) if(substr($str, $i, 1) ne '"');
	}
	return $r;
}

# rawDownload()
# Download all the mbdump files.
# @return 1 on success. This subroutine has the potential to issue a die() if there as serious ftp
#         problems.
sub rawDownload {
    my $self = shift;
	my $host = 'ftp.musicbrainz.org';
    my $logger = MbzDb::Logger::Get();
	
	# find out the latest NGS
	my $latest = "";
	$logger->logInfo("Logging into MusicBrainz FTP ($host)...");
	
	# login
	my $ftp = Net::FTP->new($host, Timeout => 60) or $logger->logFatal("Cannot contact $host: $!");
	$ftp->login('anonymous') or $logger->logFatal("Can't login ($host): " . $ftp->message);
	
	# change directory
	$ftp->cwd('/pub/musicbrainz/data/fullexport/')
	    or $logger->logFatal("Can't change directory ($host): " . $ftp->message);
	
	# get directory listing
	my @ls = $ftp->ls('-l latest*');
	$latest = substr($ls[0], length($ls[0]) - 15, 15);
	$logger->logInfo("The latest is mbdump is '$latest'");
	$ftp->cwd("/pub/musicbrainz/data/fullexport/$latest")
	    or $logger->logFatal("Can't change directory (ftp.musicbrainz.org): " . $ftp->message);
			
	my @files = (
		'mbdump-stats.tar.bz2',
		#'mbdump-derived.tar.bz2',
		#'mbdump.tar.bz2'
	);
	
	# probably need this
	$ftp->binary();
	
	foreach my $file (@files) {
		$logger->logInfo("Downloading $file...");
		
		# if the file exists, don't download it again
		if(-e "replication/$file") {
			$logger->logInfo("File already downloaded");
		} else {
			$ftp->get($file, "replication/$file")
			    or $logger->logFatal("Unable to download file $file: " . $ftp->message);
			$logger->logInfo("Done");
		}
	}
	
	return 1;
}

sub getSchemaFiles {
    my $self = shift;
    
    my $schema_base = 'http://git.musicbrainz.org/gitweb/?p=musicbrainz-server.git;a=blob_plain';
    my %files = (
        "$schema_base;f=admin/sql/CreateTables.sql;hb=master" => "replication/CreateTables.sql",
        "$schema_base;f=admin/sql/CreateFKConstraints.sql;hb=master" => "replication/CreateFKConstraints.sql",
        "$schema_base;f=admin/sql/CreateIndexes.sql;hb=master" => "replication/CreateIndexes.sql",
        "$schema_base;f=admin/sql/CreatePrimaryKeys.sql;hb=master" => "replication/CreatePrimaryKeys.sql",
        "$schema_base;f=admin/sql/CreateFunctions.sql;hb=master" => "replication/CreateFunctions.sql",
        "$schema_base;f=admin/sql/ReplicationSetup.sql;hb=master" => "replication/ReplicationSetup.sql",
        "$schema_base;f=admin/sql/statistics/CreateTables.sql;hb=master" => "replication/StatisticsSetup.sql",
        "$schema_base;f=admin/sql/caa/CreateTables.sql;hb=master" => "replication/CoverArtSetup.sql"
    );
    
    return %files;
}

# downloadSchema()
# This function will download the original MusicBrainz PostgreSQL SQL commands to create tables,
# indexes and PL/pgSQL. It will later be converted for the RDBMS we are using.
# @return Always 1.
sub downloadSchema {
    my $self = shift;
    my %files = $self->getSchemaFiles();
    
    while(my ($url, $location) = each %files) {
	    unlink($location);
	    $self->downloadFile($url, $location);
    }
    
	return 1;
}

# downloadFile($url, $location)
# Generic function to download a file.
# @param $url The URL to fetch from.
# @param $location File path to save downloaded file to.
# @return Response result.
sub downloadFile {
    my ($self, $url, $location) = shift;
	my $ua = LWP::UserAgent->new();
	my $request = HTTP::Request->new('GET', $_[0]);
	my $resp = $ua->request($request, $_[1]);
    my $logger = MbzDb::Logger::Get();

	if($resp->is_success) {
		$logger->logInfo("Downloaded " . $_[1]);
		return $resp;
	}
	else {
		$logger->logFatal('Error downloading ' . $_[0] . ': ' . $resp->status_line);
	}
}

1;
