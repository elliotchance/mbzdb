#!/usr/bin/perl -w

package MbzDb::Backend;

use strict;
use warnings;
use Net::FTP;

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
	my @files;
	
	# find out the latest NGS
	my $latest = "";
	print "Logging into MusicBrainz FTP ($host)...\n";
	my $ftp = Net::FTP->new($host, Timeout => 60) or die "Cannot contact $host: $!";
	$ftp->login('anonymous') or die "Can't login ($host): " . $ftp->message;
	$ftp->cwd('/pub/musicbrainz/data/fullexport/') or die "Can't change directory ($host): " . $ftp->message;
	my @ls = $ftp->ls('-l latest*');
	$latest = substr($ls[0], length($ls[0]) - 15, 15);
	print "The latest is mbdump is '$latest'\n";
	$ftp->cwd("/pub/musicbrainz/data/fullexport/$latest") or die "Can't change directory (ftp.musicbrainz.org): " . $ftp->message;
			
	@files = (
		'mbdump-stats.tar.bz2',
		'mbdump-derived.tar.bz2',
		'mbdump.tar.bz2'
	);
	
	# probably need this
	$ftp->binary();
	
	foreach my $file (@files) {
		print localtime() . ": Downloading $file... ";
		
		# if the file exists, don't download it again
		if(-e "replication/$file") {
			print "File already downloaded\n";
		} else {
			#$ftp->get($file, "replication/$file") or die("Unable to download file $file: " . $ftp->message);
			print "Done\n";
		}
	}
	
	return 1;
}

1;
