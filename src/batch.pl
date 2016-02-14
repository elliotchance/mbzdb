
use Getopt::Mixed;

# Set defaults for batch commands
$g_chosenlanguage = 1;
$g_language = "English";

$g_action = 0;
$g_ask    = 1;
$g_pipe_bzip = 0;
$g_compress_prog = null;
$g_parallel = 0;

Getopt::Mixed::init('bzip:s action:i ask:i pipe-bzip:i parallel:i');
while( my( $option, $value, $pretty ) = Getopt::Mixed::nextOption() )
{
    OPTION: {
      $option eq 'bzip' and do {
        $g_compress_prog = $value;
        last OPTION;
      };
      $option eq 'action' and do {
        $g_action = $value if $value;
        last OPTION;
      };
      $option eq 'ask' and do {
        $g_ask = $value;
        last OPTION;
      };
      $option eq 'pipe-bzip' and do {
        $g_pipe_bzip = $value if $value;
        last OPTION;
      };
      $option eq 'parallel' and do {
        $g_parallel = $value if $value;
        last OPTION;
      };
    }
}

Getopt::Mixed::cleanup();

if( $g_compress_prog )
{
    print "Using compress program " . $g_compress_prog . "\n";
    system($g_compress_prog . " --version");
}

return 1;
