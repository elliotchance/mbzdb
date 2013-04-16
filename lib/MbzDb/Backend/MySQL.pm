#!/usr/bin/perl -w

package MbzDb::Backend::MySQL;

use strict;
use warnings;
use DBI;

require Exporter;
our @ISA = qw(Exporter);
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

sub init {
    my $self = shift;
    
    # connect
    $self->connect();
    
    # create the database
    my ($db) = $self->{'instance'}->getInstanceOption('db');
}

1;
