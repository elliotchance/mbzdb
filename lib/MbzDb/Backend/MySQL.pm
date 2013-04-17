#!/usr/bin/perl -w

package MbzDb::Backend::MySQL;

use strict;
use warnings;
use DBI;
use MbzDb::Backend;
use Cwd;

require Exporter;
our @ISA = qw(MbzDb::Backend);
our @EXPORT = qw();

sub new {
    my ($class, $instance) = @_;
    my $self = {
        'dbh' => undef,
        'instance' => $instance
    };
    return bless $self, $class;
}

sub connect {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    
    if(!$self->{'dbh'}) {
        my ($driver, $db, $user, $pass) = $self->{'instance'}->getInstanceOption('driver', 'db', 'user', 'pass');
        
        # set the default driver is the user didn't give us a specific one
        $driver = 'mysql' if(!$driver);
        
        # make connection
        $self->{'dbh'} = DBI->connect("dbi:$driver:database=;host=localhost", $user, $pass,
            { RaiseError => 1, PrintError => 0 })
            or $logger->logFatal("Could not connect to database: $DBI::errstr");
            
        # try to create the database
        eval {
            $self->do("CREATE DATABASE $db");
        };
        $self->do("USE $db");
    }
}

sub DESTROY {
    my $self = shift;
    $self->{'dbh'}->disconnect() if($self->{'dbh'});
}

sub do {
    my ($self, $sql) = @_;
    my $logger = MbzDb::Logger::Get();
    
    $logger->logInfo("SQL: $sql");
    return $self->{'dbh'}->do($sql);
}

# install()
# This is called when --install is used from the command line. It is responsible for anything that
# is required to setup the environment before the schema is allied and data is loaded in.
sub install {
    my $self = shift;
    
    # connect
    $self->connect();
}

sub updateSchemaFromFile {
	# TODO: this does not check for columns that have changed their type, as a column that already
	#       exists will be ignored. I'm not sure how important this is but its worth noting.
	my ($self, $path) = @_;
	my %enums;
    my $logger = MbzDb::Logger::Get();
	
    # read whole file into memory
    open my $fh,"< $path" or $logger->logFatal("Cannot open file: $path");
    chomp(my @lines = <$fh>);
    close $fh;
	
	my $table = "";
	my $enums = ();
	my $ignore = 0;
	my $inCreateTable = 0;
	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		my $tline = MbzDb::Trim($line);
		next if($tline eq "" || $tline eq "(" || substr($tline, 0, 1) eq "\\" || substr($tline, 0, 2) eq '--');
		
		# if in ignore mode
		if($ignore) {
			if((index($line, ",") > 0) || (index($line, ";") > 0)) {
				$ignore = 0;
			}
			next;
		}

		my $stmt = '';

		if($tline =~ /^CREATE\s+TABLE/) {
            $table = $self->removeQuotes(substr($line, 13, length($line)));
            if(substr($table, length($table) - 1, 1) eq '(') {
                $table = substr($table, 0, length($table) - 1);
            }
            $table = MbzDb::Trim($table);
            $inCreateTable = 1;
        
            # do not create the table if it already exists
            if(!$self->tableExists($table)) {
                $stmt = "CREATE TABLE `$table` (dummycolumn int) COMMENT 'mbzdb'";
            
                my ($engine, $tablespace) = $self->{'instance'}->getInstanceOption('engine', 'tablespace');
                $stmt .= " ENGINE=$engine" if($engine);
                $stmt .= " TABLESPACE $tablespace" if($tablespace);
            }
		}
		elsif($tline =~ /^CREATE\s+TYPE/) {
			my @p = split(" ", $line);
            $table = MbzDb::Trim($p[2]);
			my $content = substr($line, index($line, "AS") + 2, length($line));
			$content = substr($content, 0, index($content,";"));

			$enums{$table} = $content;
		}
		elsif(substr(MbzDb::Trim($line), 0, 5) eq "CHECK" || substr(MbzDb::Trim($line), 0, 5) eq 'ALTER') {
			# ignore the line rest of lines
			$ignore = 1;
		}
		elsif($line =~ /^\s*\w+\s+\w+/ && $inCreateTable) {
			my @parts = split(" ", $line);
			for(my $i = 0; $i < @parts; ++$i) {
				if(substr($parts[$i], 0, 2) eq "--") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}
				if(substr($parts[$i], 0, 5) eq "CHECK") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}
				
				if(substr($parts[$i], length($parts[$i]) - 2, 2) eq "[]") {
					$parts[$i] = "VARCHAR(255)";
				}
				if(uc(substr($parts[$i], 0, 7)) eq "VARCHAR" && index($line, '(') < 0) {
					$parts[$i] = "TEXT";
				}
				$parts[$i] = $enums{$parts[$i]} if($i != 0 && exists($enums{$parts[$i]}));
				$parts[$i] = "VARCHAR(15)" if(uc(substr($parts[$i], 0, 13)) eq "CHARACTER(15)");
				$parts[$i] = "INT NOT NULL" if(uc(substr($parts[$i], 0, 6)) eq "SERIAL");
				$parts[$i] = "CHAR(36)" if(uc(substr($parts[$i], 0, 4)) eq "UUID");
				$parts[$i] = "TEXT" if(uc(substr($parts[$i], 0, 4)) eq "CUBE");
				$parts[$i] = "CHAR(1)" if(uc(substr($parts[$i], 0, 4)) eq "BOOL");
				$parts[$i] = "VARCHAR(256)" if(uc($parts[$i]) eq "INTERVAL");
				$parts[$i] = "0" if(substr($parts[$i], 0, 3) && uc(substr($parts[$i], 0, 3)) eq "NOW");
				$parts[$i] = "0" if(length($parts[$i]) > 1 && substr($parts[$i], 1, 1) && uc(substr($parts[$i], 1, 1)) eq "{");
				$parts[$i] = $parts[$i + 1] = $parts[$i + 2] = "" if(uc($parts[$i]) eq "WITH");
				if(uc($parts[$i]) eq "VARCHAR" && substr($parts[$i + 1], 0, 1) ne "(") {
					$parts[$i] = "TEXT";
				}
			}
			if(substr(reverse($parts[@parts - 1]), 0, 1) eq ",") {
				$parts[@parts - 1] = substr($parts[@parts - 1], 0, length($parts[@parts - 1]) - 1);
			}
			
			next if(uc($parts[0]) eq "CHECK" || uc($parts[0]) eq "CONSTRAINT" || $parts[0] eq "");
			$parts[0] = $self->removeQuotes($parts[0]);
			
			my $new_col;
			if(uc($parts[0]) ne "PRIMARY" && uc($parts[0]) ne "FOREIGN") {
				$new_col = "`$parts[0]`";
			} else {
				$new_col = $parts[0];
			}
			$stmt = "ALTER TABLE `$table` ADD $new_col " . join(" ", @parts[1 .. @parts - 1]);
			
			# no need to create the column if it already exists in the table
			$stmt = "" if($table eq "" || $self->tableColumnExists($table, $parts[0]));
		}
		elsif(substr($line, 0, 2) eq ");") {
			if($table && $self->tableColumnExists($table, "dummycolumn")) {
				$stmt = "ALTER TABLE `$table` DROP dummycolumn";
			}
			$inCreateTable = 0;
		}
		
		$self->do($stmt) if(MbzDb::Trim($stmt) ne "");
	}
	
	close(SQL);
	return 1;
}

# tableColumnExists($table_name, $col_name)
# Check if a table already has a column.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub tableColumnExists {
	my ($self, $table_name, $col_name) = @_;
	return 0 if($table_name eq "");
	
	my $sth = $self->{'dbh'}->prepare("describe `$table_name`");
	$sth->execute();
	while(my @result = $sth->fetchrow_array()) {
		if($col_name eq "PRIMARY") {
			return 1 if($result[3] eq 'PRI');
		} else {
			return 1 if($result[0] eq $col_name);
		}
	}
	
	# table column was not found
	return 0;
}

# tableExists($table_name)
# Check if a table already exists.
# @note This must support searching for VIEWs as well. tableExists() is used for testing if
#       tables and views exist.
# @param $table_name The name of the table to look for.
# @return 1 if the table exists, otherwise 0.
sub tableExists {
	my ($self, $table_name) = @_;
	
	my $sth = $self->{'dbh'}->prepare('show tables');
	$sth->execute();
	while(my @result = $sth->fetchrow_array()) {
		return 1 if($result[0] eq $table_name);
	}
	
	# table was not found
	return 0;
}

sub getSchemaFiles {
    my $self = shift;
    
    my $schema_base = 'http://git.musicbrainz.org/gitweb/?p=musicbrainz-server.git;a=blob_plain';
    my %files = (
        "$schema_base;f=admin/sql/CreateTables.sql;hb=master" => "replication/CreateTables.sql",
        "$schema_base;f=admin/sql/CreateIndexes.sql;hb=master" => "replication/CreateIndexes.sql",
        "$schema_base;f=admin/sql/CreatePrimaryKeys.sql;hb=master" => "replication/CreatePrimaryKeys.sql",
        "$schema_base;f=admin/sql/ReplicationSetup.sql;hb=master" => "replication/ReplicationSetup.sql",
        "$schema_base;f=admin/sql/statistics/CreateTables.sql;hb=master" => "replication/StatisticsSetup.sql",
        "$schema_base;f=admin/sql/caa/CreateTables.sql;hb=master" => "replication/CoverArtSetup.sql"
    );
    
    return %files;
}

# loadData()
# Load the data from the mbdump files into the tables.
sub loadData {
    my $self = shift;
	my $temp_time = time();
    my $logger = MbzDb::Logger::Get();

	opendir(DIR, "mbdump") or $logger->logFatal("Can't open ./mbdump: $!");
	my @files = sort(grep { $_ ne '.' and $_ ne '..' } readdir(DIR));
	my $count = @files;
	my $i = 1;

	foreach my $file (@files) {
		my $t1 = time();
		my $table = $file;
		next if($table eq "blank.file" || substr($table, 0, 1) eq '.');
		next if(-d "./mbdump/$table");
		
		if(substr($table, 0, 11) eq "statistics.") {
			$table = substr($table, 11, length($table) - 11);
		}

		if($self->tableColumnExists($table, "dummycolumn")) {
       		$self->do("ALTER TABLE `$table` DROP COLUMN dummycolumn");
		}
		
		# if the table has any data then it is skipped
        my $sth = $self->{'dbh'}->prepare("SELECT COUNT(*) FROM `$table`");
        $sth->execute();
        my @result = $sth->fetchrow_array();
        if($result[0] > 0) {
		    $logger->logInfo("Table '$table' already contains records, skipping.");
		    next;
        }
		
		$logger->logInfo("Loading data into '$table' ($i of $count)...");
		$file = getcwd() . "/mbdump/$file";
		$self->do("LOAD DATA INFILE '$file' INTO TABLE `$table` ".
		          "FIELDS TERMINATED BY '\\t' ".
		          "ENCLOSED BY '' ".
		          "ESCAPED BY '\\\\' ".
		          "LINES TERMINATED BY '\\n' ".
		          "STARTING BY ''");

		my $t2 = time();
		$logger->logInfo("Done (" . MbzDb::FormatTime($t2 - $t1) . ")");
		++$i;
	}

	# clean up
	closedir(DIR);
	my $t2 = time();
	print "\nComplete (" . MbzDb::FormatTime($t2 - $temp_time) . ")\n";
}

# uninstall()
# This is called when --uninstall is used from the command line. It is responsible remove everything
# that was previously installed.
sub uninstall {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    my ($db) = $self->{'instance'}->getInstanceOption('db');
    
    # connect
    $self->connect();
    
    # drop tables
    while($self->_dropTables() > 0) {}
}

# _dropTables()
# Drop tables with 'mbzdb' in the comment. Keep calling this function until it returns 0.
# @return The number of tables dropped in this iteration.
sub _dropTables {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    my ($db) = $self->{'instance'}->getInstanceOption('db');
    my $tablesDropped = 0;
    
    # we do not drop the database in case we are sharing the database with something else, instead
    # we look for a COMMENT marker on the tables that we did install.
	my $sth = $self->{'dbh'}->prepare("show table status where comment='mbzdb'");
	$sth->execute();
	while(my @result = $sth->fetchrow_array()) {
	    # attempt to drop the tables, it is wrapped in an eval because it might fail with the
	    # foreign keys, you keep calling this function until it returns 0
	    eval {
		    $self->do("DROP TABLE `$result[0]`");
		    ++$tablesDropped;
		};
	}
	
	return $tablesDropped;
}

1;
