#!/usr/bin/perl -w

package MbzDb::Backend;

use strict;
use warnings;

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

sub init {
    return 1;
}

1;
