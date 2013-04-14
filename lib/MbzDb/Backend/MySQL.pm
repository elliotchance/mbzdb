#!/usr/bin/perl -w

package MbzDb::Backend::MySQL;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

sub new {
    my $class = shift;
    my $self = {
        'dbh' => 0
    };
    return bless $self, $class;
}

sub init {
    my $self = shift;
    
    # create the database
    
}

1;
