#!/usr/bin/perl -w

package MbzDb;

use strict;
use warnings;
use Text::ParseWords;

sub Version {
    return "6.0";
}

# http://stackoverflow.com/a/3470808/1470961
sub LoadModule {
    for (@_) {
        (my $file = "$_.pm") =~ s{::}{/}g;
        require $file;
    }
}

# Trim($string)
# Based on the PHP function trim() to chop whitespace off the left and right.
# @param $string The string to trim.
# @return A new copy of the trimmed string.
sub Trim {
    my @r;
    foreach my $string (@_) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        push(@r, $string);
    }
    
    return $r[0] if(@r == 1);
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

# FormatTime()
# Translate seconds into "hours h minutes m seconds s"
# @return Formatted interval.
sub FormatTime {
	my $left = $_[0];
	my $hours = int($left / 3600);
	$left -= $hours * 3600;
	my $mins = int($left / 60);
	$left -= $mins * 60;
	my $secs = int($left);
	
	my $r = "";
	$r .= $hours . "h " if($hours > 0);
	$r .= " " if($mins < 10);
	$r .= $mins . "m ";
	$r .= " " if($secs < 10);
	$r .= $secs . "s";
	return $r;
}

1;
