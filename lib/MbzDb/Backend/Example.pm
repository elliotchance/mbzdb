#!/usr/bin/perl -w

package MbzDb::Backend::Example;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(connect);

# connect()
# Make database connection. It will set the global $dbh and it will return it. When implmenting your
# own backend you should only really need to change the $driver to the correct perl DBI driver.
# $g_db_name, $g_db_host, $g_db_port, $g_db_user and $g_db_pass are supplied by settings.pl.
# @return $dbh
sub connect {
	$driver = 'mysql';
	$dbh = DBI->connect("dbi:$driver:dbname=$g_db_name;host=$g_db_host;port=$g_db_port",
						$g_db_user, $g_db_pass);
	return $dbh;
}

1;
