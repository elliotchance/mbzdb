#!/usr/bin/perl

require "settings.pl";
require "languages/$g_language.pl";
require "backend/$g_db_rdbms.pl";
require "src/functions.pl";

# TODO: There is an issue with some of the CREATE UNIQUE INDEXs on table columns that are not unique
#       name                               (select count(1) - count(distinct ?) from ?)
#       artistalias_nameindex              20 duplicates
#       url_idx_url                        75 duplicates
#       wordlist_wordindex                 30 duplicates
#
#       This has only been tested against non-NGS. The non-NGS schema comes from an old version from
#       the git repository which means this can't be fixed. However everyone that can should move to
#       using the NGS schema where any unique issues can be fixed by updating the git repository.

# first boot
mbz_choose_language() if(!$g_chosenlanguage);
mbz_first_boot() if($g_firstboot);

grabaction:
print $L{'init_action'};
chomp(my $action = <STDIN>);
if($action !~ /^-?\d/ or $action < 0 or $action > 6) {
	print "Invalid\n\n";
	goto grabaction;
}

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
	print $L{'init_actionplugininit'};
}
chomp(my $input = <STDIN>);
exit(0) if($input ne "y" and $input ne "yes");

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
	mbz_unzip_mbdumps();
	mbz_load_data();
} elsif($action == 5) {
	mbz_update_index();
} elsif($action == 6) {
	mbz_init_plugins();
}
