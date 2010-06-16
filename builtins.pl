# We need this for all scripts.
use DBI;

# Version. When changing this also look in languages/ for $L{'init_welcome'}
$g_version = "1.0";

# System commands
$g_mv = (($^O eq "MSWin32") ? "move" : "mv");
$g_rm = (($^O eq "MSWin32") ? "del" : "rm");

# You shouldn't need to change these.
$g_pending     = '"dbmirror_Pending"';
$g_pendingdata = '"dbmirror_PendingData"';

# Return the default port number for a database engine.
sub mbz_get_default_port {
	return 3306 if($_[0] eq 'mysql');
	return 5432 if($_[0] eq 'postgresql');
}
