#
# The backend/ directory includes files that follows an interface that allows other database
# backends to be implemented without the need to alter the core.
#
# The file is named as $name$.pl where $name$ is the case-sensitive name for the database backend,
# this can be anything you like, but the name of the file you choose is very important to the name
# of the subroutines you have in this file.
#
# If you want to implement your own backend duplicate this file and make the changes where
# appropriate - but all subroutines whether they are used or not must stay in the file.
#


# mbz_update_index()
sub backend_NAME_update_index {
}


# mbz_update_schema()
sub backend_NAME_update_schema {
}


# mbz_table_exists($tablename)
# Check if a table already exists.
# @return 1 if the table exists, otherwise 0.
sub backend_NAME_table_exists {
}


# mbz_load_data()
# Load the data from the mbdump files into the tables.
sub backend_NAME_load_data {
}


# be nice
return 1;
