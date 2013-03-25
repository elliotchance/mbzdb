# We need this for all scripts.
use DBI;

# Version. When changing this also look in languages/ for $L{'init_welcome'}
$g_version = "5.0";
$g_build_date = "2011-05-28";

# System commands
$g_mv = (($^O eq "MSWin32") ? "move" : "mv");
$g_rm = (($^O eq "MSWin32") ? "del" : "rm");
