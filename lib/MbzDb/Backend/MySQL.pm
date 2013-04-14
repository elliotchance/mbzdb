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
        my ($db, $user, $pass) = $self->{'instance'}->getInstanceOption('db', 'user', 'pass');
        $self->{'dbh'} = DBI->connect("DBI:mysql:$db", $user, $pass, { RaiseError => 1 })
            or $logger->logFatal("Could not connect to database: $DBI::errstr");
    }
}

sub DESTROY {
    my $self = shift;
    $self->{'dbh'}->disconnect() if($self->{'dbh'});
}

sub do {
    my ($self, $sql) = @_;
    return $self->{'dbh'}->do($sql);
}

sub init {
    my $self = shift;
    
    # connect
    $self->connect();
    
    # create the database
    my $db = $self->{'instance'}->getInstanceOption('db');
    $self->do("CREATE DATABASE $db");
}

1;
