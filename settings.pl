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

# Schema. This is where the SQL scripts to create the schema come from, only edit this if you know
# what you're doing.
$schema_base = 'http://git.musicbrainz.org/gitweb/?p=musicbrainz-server.git;a=blob_plain';
$g_schema_url = "$schema_base;f=admin/sql/CreateTables.sql;hb=master";
$g_indexfk_url = "$schema_base;f=admin/sql/CreateFKConstraints.sql;hb=master";
$g_index_url = "$schema_base;f=admin/sql/CreateIndexes.sql;hb=master";
$g_pk_url = "$schema_base;f=admin/sql/CreatePrimaryKeys.sql;hb=master";
$g_func_url = "$schema_base;f=admin/sql/CreateFunctions.sql;hb=master";
$g_pending_url = "$schema_base;f=admin/sql/ReplicationSetup.sql;hb=master";
$g_stats_url = "$schema_base;f=admin/sql/statistics/CreateTables.sql;hb=master";
$g_coverart_url = "$schema_base;f=admin/sql/caa/CreateTables.sql;hb=master";

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
