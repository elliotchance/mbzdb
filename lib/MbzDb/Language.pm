#!/usr/bin/perl -w

package MbzDb::Language;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

# new()
# Create a new language translator.
sub new {
    my $class = shift;
    my $self = {
        'language' => 'English'
    };
    return bless $self, $class;
}

# get()
# Get the translated text for a key.
sub get {
    my ($self, $key) = @_;
    return $key;
}

1;
