#!/usr/bin/perl -w

package MbzDb::Ini::Config;

use strict;
use warnings;
use Data::Dumper;
use MbzDb::Ini::File;

require Exporter;
our @ISA = qw(MbzDb::Ini::File);
our @EXPORT = qw();

sub instanceExists {
    my ($self, $instanceName) = @_;
    if($self->get($instanceName . "._db")) {
        return 1;
    }
    return 0;
}

sub removeInstance {
    my ($self, $instanceName) = @_;
    my %data = $self->getAll();
    while(my ($key, $value) = each %data) {
        if(substr($key, 0, length($instanceName) + 1) eq "$instanceName.") {
            $self->remove($key);
        }
    }
}

1;
