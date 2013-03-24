#
# This is a blank plugin to demonstate the required methods.
# It is very important that all the methods exist and follow
# a strict naming convention so the update.pl script can run
# them.
#
# For a file called 'aBc.pl' the plugin name is 'aBc' and so
# the method names are like: aBc_description(), aBc_init()
# etc.
#
# * You have access to all the subroutines in functions.pl.
# * Use mbz_do_sql("insert into ...") for stataments that do
#   not require a handle.
# * Use $dbh as your active database handle for SELECTs.
# * Do not include/require any MB_MySQL3 files as there
#   already included by the time this script runs.
#

# Basic description of the pluging.
# This function should not print anything, only the
# description is returned.
sub example_description {
	return "Example plugin for explaining the basic methods.";
}

# This method is only run manually by init.pl. This should be
# performed after all the data and indexes have been loading
# but before the replications start.
# Returns: 0 (fail)   1 (pass)
sub example_init {
	return 1;
}

# This method is called after the replication is downloaded,
# but before any of the transactions are applied to the
# database.
# Arguments: $repID  The replication ID about to be applied.
# Returns: 0 (fail)   1 (pass)
sub example_beforereplication {
	my ($repID) = @_;
	# mbz_do_sql("insert ... ");
	return 1;
}

# This method is called before each indervidual replication
# statement is called. Be very careful not to bloat this
# function as replications can contain several thousand
# statements.
# Arguments: $table  Raw table name like 'album'
#            $seqID  Sequence ID refers to the Pending and
#                    PendingData tables.
#            $action Either 'i', 'u' or 'd' for INSERT,
#                    UPDATE and DELETE respectivly.
#            $data   Unpacked field data. Access it like:
#                    $data->{'id'}
# Returns: 0 (fail)   1 (pass)
sub example_beforestatement {
	my ($table, $seqID, $action, $data) = @_;
	# mbz_do_sql("insert ... ");
	return 1;
}

# This method works exactly the same way as beforestatement(),
# only that it is executed after the replication statement is
# performed on the database. The arguments are the same as
# beforestatement().
# Returns: 0 (fail)   1 (pass)
sub example_afterstatement {
	my ($table, $seqID, $action, $data) = @_;
	# mbz_do_sql("insert ... ");
	return 1;
}

# This method is called after the replication has completely
# finsihed.
# Arguments: $repID  The replication ID that has just finsihed.
# Returns: 0 (fail)   1 (pass)
sub example_afterreplication {
	my ($repID) = @_;
	# mbz_do_sql("insert ... ");
	return 1;
}

# Finished. Remeber this line.
return 1;
