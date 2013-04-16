require "src/builtins.pl";
require "src/firstboot.pl";


#############################
# Basic options
#############################

# Must be 'mysql' or 'postgresql'
$g_db_rdbms = 'mysql';


#############################
# Advanced database options
#############################

# You may want to ignore certain tables or fields during the replications.
@g_ignore_tables = (
	# eg. 'trm', 'trmjoin'
);
@g_ignore_fields = (
	# eg. 'trmids'
);

# Replications URL
$g_rep_host = "ftp.musicbrainz.org";
$g_rep_url = "/pub/musicbrainz/data/replication";

# Kill the update script if a duplicate error (i.e. a duplicate unique key) occurs. It is
# recommended you leave this at 0.
$g_die_on_dupid = 0;

# Kill the update script if a real database error occurs, like an invalid SQL statement.
$g_die_on_error = 1;

# Kill the update script if some part of a plugin fails.
$g_die_on_plugin = 0;


#############################
# Plugin options
#############################

# Currently active plugins.
@g_active_plugins = ('livestats','pendinglog');


#############################
# Don't edit beyond this point
#############################

$g_pending = 'dbmirror_Pending';
$g_pendingdata = 'dbmirror_PendingData';
$g_pendingfile = 'dbmirror_pending';
$g_pendingdatafile = 'dbmirror_pendingdata';

return 1;
