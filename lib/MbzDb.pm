#!/usr/bin/perl -w

package MbzDb;

use strict;
use warnings;
use Text::ParseWords;

sub Version {
    return "6.0";
}

sub Trim {
    my @r;
    foreach my $string (@_) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        push(@r, $string);
    }
	return @r;
}

sub GetSystemMoveCommand {
    return (($^O eq "MSWin32") ? "move" : "mv");
}

sub GetSystemRemoveCommand {
    return (($^O eq "MSWin32") ? "del" : "rm");
}

# http://stackoverflow.com/a/15947886/1470961
sub MakeHashFromKeyValues {
    my $str  = shift;
    my @foo  = quotewords(',', 0, $str);   # split into pairs
    my %hash = quotewords('=', 0, @foo);   # split into key + value
    return \%hash;
}

# CreateFolders()
# Create the required mbdump/ and replication/ folders if they do not exist.
# @return Always 1.
sub CreateFolders {
	mkdir("mbdump");
	mkdir("replication");
	return 1;
}

1;
