#!/usr/bin/perl -w

package MbzDb::Instance;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use MbzDb;
use MbzDb::Backend;
use MbzDb::Ini::Config;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(startFromCommandLine PrintCommandLineUsage);

use constant DEFAULT_INSTANCE => 'default';

sub new {
    my $class = shift;
    my $self = {
        'commandLineOptions' => {},
        'ini' => new MbzDb::Ini::Config($ENV{"HOME"} . '/mbzdb.ini')
    };
    return bless $self, $class;
}

sub startFromCommandLine {
    my $self = shift;
    $self->{'commandLineOptions'} = $self->_getCommandLineOptions();
    
    # choose action
    if($self->{'commandLineOptions'}{'action'} eq 'help') {
        $self->help();
    }
    elsif($self->{'commandLineOptions'}{'action'} eq 'info') {
        $self->info();
    }
    elsif($self->{'commandLineOptions'}{'action'} eq 'init') {
        $self->init();
    }
}

# init()
# Setup a new MbzDb instance.
sub init {
    my $self = shift;
    
    # create the empty folders needed
    MbzDb::CreateFolders();
    
    # make sure the backend is valid
    my $db = $self->{'commandLineOptions'}{'db'};
    my $class = MbzDb::Backend::GetClassByName($db);
    if(!$class) {
        die("Bad --db option or not specified.\n");
    }
    
    # make sure the instance doesn't already exist
    my $name = $self->{'commandLineOptions'}{'instance'};
    if($self->{'ini'}->instanceExists($name)) {
        die("An instance with that name '$name' already exists.");
    }
    
    $self->{'ini'}->set("$name.db", $self->{'commandLineOptions'}{'db'});
    while(my ($key, $value) = each %{$self->{'commandLineOptions'}{'options'}}) {
        $self->{'ini'}->set("$name.$key", $value);
    }
    
    print "Done.\n";
}

# help()
# Print the command line usage and exit will a failure status.
sub help {
    my $self = shift;
    print "\nUsage: ./mbzdb [options]\n\n";
    print "    --help   Show this help message.\n";
    print "    --info   Show information about the instances.\n";
    print "    --init   Create a new instance.\n";
    print "      --db       The database (mysql, postgresql, etc).\n";
    print "      --options  Database options, like 'user=bob'.\n";
    print "\n";
    exit(1);
}

# info()
# Print basic information then exit.
sub info {
    my $self = shift;
    print "MbzDb v" . MbzDb::Version() . "\n";
    exit(0);
}

sub _getCommandLineOptions {
    # the default values
    my %options = (
        'action' => '',
        'instance' => DEFAULT_INSTANCE,
        'language' => 'English',
        'db' => '',
        'options' => ''
    );
    my %actions = (
        'help' => '',
        'info' => '',
        'init' => ''
    );

    # read the command line options
    GetOptions(
        "help" => \$actions{'help'},
        "instance=s" => \$options{'instance'},
        "language=s" => \$options{'language'},
        "info" => \$actions{'info'},
        "init" => \$actions{'init'},
        "db=s" => \$options{'db'},
        "options=s" => \$options{'options'},
    );
    
    # post process
    foreach my $action (keys %actions) {
        if($actions{$action}) {
            $options{'action'} = $action;
        }
    }
    
    $options{'options'} = MbzDb::MakeHashFromKeyValues($options{'options'});
    
    return (\%options);
}

1;
