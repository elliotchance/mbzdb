#!/usr/bin/perl -w

package MbzDb::Ini::File;

use strict;
use warnings;
use Data::Dumper;
use MbzDb::Logger;

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
    my $logger = MbzDb::Logger::Get();
    
    # if the file does not exist then create it
    if(!(-e $self->{'location'})) {
        open(FH, '>' . $self->{'location'})
            or $logger->logFatal("Can't create " . $self->{'location'} . ": $!");
        close(FH);
        print "Created '" . $self->{'location'} . "'.\n";
    }
    
    # read whole file into memory
    open my $fh, '<' . $self->{'location'}
        or $logger->logFatal("Cannot load file: " . $self->{'location'});
    @{$self->{'file'}} = <$fh>;
    close $fh;
}

sub _save {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    
    open(FH, '>' . $self->{'location'})
        or $logger->logFatal("Can't create " . $self->{'location'} . ": $!");
    foreach my $line (@{$self->{'file'}}) {
        print FH $line;
    }
    close(FH);
}

sub get {
    my ($self, $name) = @_;
    $self->_load();
    
    # find the key
    foreach my $line (@{$self->{'file'}}) {
        my ($k, $v) = MbzDb::Trim(split("=", $line));
        return $v if($k eq $name);
    }
    
    return undef;
}

sub getAll {
    my $self = shift;
    $self->_load();
    
    # translate
    my %data = ();
    foreach my $line (@{$self->{'file'}}) {
        my ($k, $v) = MbzDb::Trim(split("=", $line));
        $data{$k} = $v;
    }
    
    return %data;
}

sub set {
    my ($self, $name, $value) = @_;
    $self->_load();
    push @{$self->{'file'}}, "$name = $value\n";
    $self->_save();
}

sub remove {
    my ($self, $name) = @_;
    $self->_load();
    
    # find the key
    my @newlines;
    foreach my $line (@{$self->{'file'}}) {
        my ($k, $v) = MbzDb::Trim(split("=", $line));
        next if($k eq $name);
        push @newlines, $line;
    }
    
    @{$self->{'file'}} = @newlines;
    $self->_save();
}

1;
