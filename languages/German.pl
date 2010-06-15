#############################################
## Language: German
#############################################

# Lanuage
$L{'language'} = "German";

##-------------------------------------------
## Generic status updates
##-------------------------------------------

$L{'done'} = "Fertig";
$L{'error'} = "Fehler";
$L{'table'} = "Tabelle";
$L{'alldone'} = "Alles erledigt";
$L{'downloadschema'} = "Lade Schema herunter... ";
$L{'restart_init'} = "Bitte init.pl erneut aufrufen";
$L{'invalid'} = "UngÅltige Eingabe";

##-------------------------------------------
## init.pl
##-------------------------------------------

# Language changed
$L{'langchanged'} = "Sprache geÑndert. Bitte init.pl erneut aufrufen\n";

# Welcome message
$L{'init_welcome'} =
"Willkommen bei MB_MySQL v3".
"HINWEIS: Version 3 lÑuft mit einem anderen Replikations-System als\n".
"die Ñlteren Varianten. Wir empfehlen deshalb eine neue Datenbank fÅr\n".
"diese v3 zu erstellen.".
"Bitte fuer Details im Handbuch nachsehen.\n\n";

$L{'init_firstboot'} =
"*** Bevor es losgehen kann UNBEDINGT zuerst die gewÅnschte MySQL-Datenbank\n".
"    MANUELL erstellen! *** \n\n".
"Werte in eckigen Klammern sind Standard-Vorgaben. Wenn man nicht sicher ist\n".
"ob diese Werte stimmen, einfach mal ENTER drÅcken um fortzusetzen.\n".
"Man kann jederzeit abbrechen und die Optionen werden gespeichert.\n".
"Ein einzelner Leerschlag als Antwort setzt den Wert auf 'leer'.\n\n";

# mysql options
$L{'init_mysqluser'} = "MySQL Benutzer";
$L{'init_mysqlpass'} = "MySQL Passwort";
$L{'init_mysqlname'} = "MySQL Datenbank";
$L{'init_mysqlhost'} = "MySQL Host";
$L{'init_mysqlport'} = "MySQL Port";

# init action
$L{'init_action'} =
"Die einzelnen Optionen zeigen vor der AusfÅhrung zusÑtzliche Informationen,\n".
"sobald ausgewÑhlt\n".
"[1] Komplett-Installation (macht alles automatisch, benîtigt grossen Download)\n".
"[2] Installiert/aktualisiert Datenbank-Schema\n".
"[3] LÑdt Tabellen (benîtigt grossen Download ~1GB)\n".
"[4] LÑdt Tabellen (kein Download, lÑdt von Verzeichnis 'mbdump/')\n".
"[5] Erstellt Tabellen-Indexe (dauert sehr lange!)\n".
"[6] Initialisiert Plug-Ins\n\n".
"Option: ";

# action descriptions
$L{'init_actionfull'} =
"Die Komplett-Installation erstellt das Datenbank-Schema, lÑdt die rohen Daten\n".
"herunter (~1GB), importiert diese in die DB, erstellt alle Tabellen-Indexe und\n".
"initialisiert anschliessend die Plug-Ins.\n\n".
"Bitte Datei 'settings.pl' zuerst mit den gewÅnschten Plug-Ins konfigurieren.\n\n".
"ACHTUNG: Es kann bis zu 24 Stunden dauern bis all diese Schritte vollstÑndig\n".
"ausgefÅhrt sind!\n\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionschema'} =
"Benîtigt Internet-Verbindung. LÑdt neuestes Datenbank-Schema herunter und\n".
"installiert oder aktualisert alle VerÑnderungen...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw1'} =
"Benîtigt Internet-Verbindung. LÑdt neueste Musicbrainz-Daten herunter (~1GB)...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw2'} =
"Wenn die neuesten Datenbank-Archiv-Dumps schon (manuell) heruntergeladen\n".
"wurden, diese bitte dekomprimieren und die rohen Daten in das Verzeichnis\n".
"'mbdump/' kopieren...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionindex'} =
"Hier wird am meisten Zeit benîtigt. Es werden nun die Indexe zur bereits\n".
"abgefÅllten Datenbank erstellt. Es ist wichtig, die Indexe NACH dem\n".
"importieren der Daten zu erstellen, weil das schneller ist...\n".
"Dieser Schritt kann nach einem Abbruch jederzeit wieder aufgerufen werden.\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionplugininit'} =
"Dieser Schritt sollte am Schluss aber vor der Replikation ausgefÅhrt werden.\n".
"Bitte die Einstellungen vorher fÅr die gewÅnschten Plug-Ins in der Datei\n".
"'settings.pl' bei der Variable 'g_active_plugins=' vornehmen.\n\n".
"Zu initialisierende Plug-Ins sind: " . join(', ', @g_active_plugins) . "\n\n".
"Bereit fortzusetzen? (y/n): ";

return 1;
