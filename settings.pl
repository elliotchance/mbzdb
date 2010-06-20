require "src/builtins.pl";
require "src/firstboot.pl";


#############################
# Basic options
#############################

# Must be 'mysql' or 'postgresql'
$g_db_rdbms = 'mysql';

# Database user name.
$g_db_user = 'root';

# Database user password.
$g_db_pass = 'abcd1234';

# The name of the database to use.
$g_db_name = 'mbzdb_old';

# Use NGS (Next Generation Schema)?
$g_use_ngs = 0;


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

# there are some SQL inconsistencies when using non-NGS
if(!$g_use_ngs) {
	push(@g_ignore_tables, 'release_group');
	push(@g_ignore_tables, 'release_group_meta');
	push(@g_ignore_tables, 'release_groupwords');
	push(@g_ignore_tables, 'isrc');
	
	push(@g_ignore_fields, 'release_group');
	push(@g_ignore_fields, 'release_groupusecount');
}

# Schema. This is where the SQL scripts to create the schema come from, only edit this if you know
# what you're doing.
$schema_base = 'http://git.musicbrainz.org/gitweb/?p=musicbrainz-server/core.git;a=blob_plain';
$hb = ($g_use_ngs ? 'master' : '6b70f50c57401fc07140dcbb242550b7e5ebfa31');
$g_schema_url = "$schema_base;f=admin/sql/CreateTables.sql;hb=$hb";
$g_index_url = "$schema_base;f=admin/sql/CreateIndexes.sql;hb=$hb";
$g_pk_url = "$schema_base;f=admin/sql/CreatePrimaryKeys.sql;hb=$hb";
$g_func_url = "$schema_base;f=admin/sql/CreateFunctions.sql;hb=$hb";

# Replications URLs
# TODO: add the URLs for NGS when they are available.
if($g_use_ngs) {
} else {
	$g_rep_url = "ftp://ftp.musicbrainz.org/pub/musicbrainz/data/replication";
}

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

if($g_use_ngs) {
	$g_pending = 'dbmirror_Pending';
	$g_pendingdata = 'dbmirror_PendingData';
} else {
	$g_pending = 'Pending';
	$g_pendingdata = 'PendingData';
}

return 1;
