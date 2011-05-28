#############################
# Basic options
#############################

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

# Server host, use 'localhost' if the database is on the same server as this script.
$g_db_host = 'localhost';

# Port number, default is 5432
$g_db_port = 5432;

# Tablespace to create all tables and indexes in. Leave blank to use the default tablespace.
$g_tablespace = '';


return 1;
