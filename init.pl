#!/usr/bin/perl

require "settings.pl";
require "settings_$g_db_rdbms.pl";
require "languages/$g_language.pl";
require "backend/$g_db_rdbms.pl";
require "src/functions.pl";
require "src/batch.pl";

mbz_create_folders();

# first boot
mbz_choose_language() if(!$g_chosenlanguage);
mbz_first_boot() if($g_firstboot);

# version info
print "mbzdb v$g_version ($g_build_date)\n\n";

my $action = undef;

if($g_action > 0)
{
    print "Action selected using command line args: " . $g_action . "\n";
    $action = $g_action;
    goto actionpicked;
}

grabaction:

print $L{'init_action'};
chomp($action = <STDIN>);
if($action !~ /^-?\d/ or $action < 0 or $action > 11) {
	print "Invalid\n\n";
	goto grabaction;
}

actionpicked:
print "Running action: " . $action . "\n";

# don't go crazy just yet - first give more information about the action
if($action == 1) {
	print $L{'init_actionfull'};
} elsif($action == 2) {
	print $L{'init_actionschema'};
} elsif($action == 3) {
	print $L{'init_actionraw1'};
} elsif($action == 4) {
	print $L{'init_actionraw2'};
} elsif($action == 5) {
	print $L{'init_actionindex'};
} elsif($action == 6) {
	print $L{'init_actionfk'};
} elsif($action == 7) {
	print $L{'init_actionplugininit'};
} else {
        print "Continue? [y/n]"
}

my $input = undef;

if( $g_ask )
{
    chomp($input = <STDIN>);
    exit(0) if($input ne "y" and $input ne "yes");
}
else
{
    print "Assuming 'yes'";
}

# OK, now it can have its fun
if($action == 1) {
	mbz_create_extra_tables();
	mbz_update_schema();
	mbz_raw_download();
	mbz_unzip_mbdumps();
	mbz_load_data();
	mbz_update_index();
	mbz_init_plugins();
	print "\n\n===== ALL DONE =====\n\n";
} elsif($action == 2) {
	mbz_create_extra_tables();
	mbz_update_schema();
} elsif($action == 3) {
	mbz_raw_download();
	mbz_unzip_mbdumps();
	mbz_load_data();
} elsif($action == 4) {
	mbz_load_data();
} elsif($action == 5) {
	mbz_update_index();
} elsif($action == 6) {
	mbz_update_foreignkey();
} elsif($action == 7) {
	mbz_init_plugins();
}
#Advanced (batch) options
elsif($action == 10) {
    # Download (but don't unzip) last full replication
	mbz_raw_download();
} elsif($action == 11) {
    # Unzip .bz2 files from replication into mbdump
	mbz_unzip_mbdumps();
} elsif($action == 12) {
    # Load data from replication files into database tables
	mbz_load_data();
}
