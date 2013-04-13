#!/usr/bin/perl -w

package MbzDb::Ini::File;

use strict;
use warnings;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get set);

sub new {
    my ($class, $location) = @_;
    my $self = {
        'location' => $location,
        'file' => []
    };
    return bless $self, $class;
}

sub _load {
    my $self = shift;
    
    # if the file does not exist then create it
    if(!(-e $self->{'location'})) {
        open(FH, '>' . $self->{'location'}) or die "Can't create " . $self->{'location'} . ": $!";
        close(FH);
        print "Created '" . $self->{'location'} . "'.\n";
    }
    
    # read whole file into memory
    open my $fh, '<' . $self->{'location'} or die "Cannot load file: " . $self->{'location'} . "\n";
    @{$self->{'file'}} = <$fh>;
    close $fh;
}

sub _save {
    my $self = shift;
    
    open(FH, '>' . $self->{'location'}) or die "Can't create " . $self->{'location'} . ": $!";
    foreach my $line (@{$self->{'file'}}) {
        print FH $line;
    }
    close(FH);
}

sub get {
    my ($self, $name) = @_;
    $self->_load();
    return 0;
}

sub set {
    my ($self, $name, $value) = @_;
    $self->_load();
    #print Dumper($self->{'file'});
    push @{$self->{'file'}}, "$name = $value\n";
    $self->_save();
}

1;
