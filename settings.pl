require "src/builtins.pl";
require "src/firstboot.pl";


#############################
# Basic options
#############################

# Must be 'mysql' or 'postgresql'
$g_db_rdbms = 'postgresql';

# Database user name.
$g_db_user = 'ngsdb';

# Database user password.
$g_db_pass = 'ngsdb';

# The name of the database to use.
$g_db_name = 'ngsdb';


#############################
# Advanced database options
#############################

# The table 'tracklist_index' uses a data type called 'CUBE' which is only available for postgresql
# with contrib/cube installed. So if you are unsure leave this as 0.
$g_contrib_cube = 0;

# The engine to use when creating tables with MySQL. Set this to "" if you want to use the MySQL
# default storage engine.
$g_mysql_engine = 'InnoDB';

# Server host, use 'localhost' if the database is on the same server as this script.
$g_db_host = 'localhost';

# Port number, set to 'default' to use the default port
$g_db_port = 'default';

# Tablespace to create all tables and indexes in. Leave blank to use the default tablespace.
$g_tablespace = '';

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
$g_index_url = "$schema_base;f=admin/sql/CreateIndexes.sql;hb=master";
$g_pk_url = "$schema_base;f=admin/sql/CreatePrimaryKeys.sql;hb=master";
$g_func_url = "$schema_base;f=admin/sql/CreateFunctions.sql;hb=master";
$g_pending_url = "$schema_base;f=admin/sql/ReplicationSetup.sql;hb=master";

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

$g_db_port = mbz_get_default_port($g_db_rdbms) if($g_db_port eq 'default');

$g_pending = 'dbmirror_Pending';
$g_pendingdata = 'dbmirror_PendingData';
$g_pendingfile = 'dbmirror_pending';
$g_pendingdatafile = 'dbmirror_pendingdata';

return 1;
