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
#$schema_base    = 'https://raw.github.com/metabrainz/musicbrainz-server/master';
$schema_base    = 'https://raw.githubusercontent.com/metabrainz/musicbrainz-server/master';
$g_schema_url   = "$schema_base/admin/sql/CreateTables.sql";
$g_indexfk_url  = "$schema_base/admin/sql/CreateFKConstraints.sql";
$g_index_url    = "$schema_base/admin/sql/CreateIndexes.sql";
$g_pk_url       = "$schema_base/admin/sql/CreatePrimaryKeys.sql";
$g_func_url     = "$schema_base/admin/sql/CreateFunctions.sql";
$g_pending_url  = "$schema_base/admin/sql/ReplicationSetup.sql";
$g_stats_url    = "$schema_base/admin/sql/statistics/CreateTables.sql";
$g_coverart_url = "$schema_base/admin/sql/caa/CreateTables.sql";
$g_slaveidx_url = "$schema_base/admin/sql/CreateSlaveIndexes.sql";
$g_caapk_url    = "$schema_base/admin/sql/caa/CreatePrimaryKeys.sql";
$g_caaidx_url   = "$schema_base/admin/sql/caa/CreateIndexes.sql";
$g_statpk_url   = "$schema_base/admin/sql/statistics/CreatePrimaryKeys.sql";
$g_statidx_url  = "$schema_base/admin/sql/statistics/CreateIndexes.sql";

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
