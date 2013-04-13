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
    if($self->get($instanceName . ".db")) {
        return 1;
    }
    return 0;
}

1;
