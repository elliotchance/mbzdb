#############################################
## Language: German
#############################################

# Lanuage
use utf8;
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
$L{'invalid'} = "Ungültige Eingabe";

##-------------------------------------------
## init.pl
##-------------------------------------------

# Language changed
$L{'langchanged'} = "Sprache geändert. Bitte init.pl erneut aufrufen\n";

# Welcome message
$L{'init_welcome'} =
"Willkommen bei mbzdb v1.0".
"HINWEIS: Version 3 läuft mit einem anderen Replikations-System als\n".
"die älteren Varianten. Wir empfehlen deshalb eine neue Datenbank für\n".
"diese v3 zu erstellen.".
"Bitte fuer Details im Handbuch nachsehen.\n\n";

$L{'init_firstboot'} =
"*** Bevor es losgehen kann UNBEDINGT zuerst die gewünschte MySQL-Datenbank\n".
"    MANUELL erstellen! *** \n\n".
"Werte in eckigen Klammern sind Standard-Vorgaben. Wenn man nicht sicher ist\n".
"ob diese Werte stimmen, einfach mal ENTER drücken um fortzusetzen.\n".
"Man kann jederzeit abbrechen und die Optionen werden gespeichert.\n".
"Ein einzelner Leerschlag als Antwort setzt den Wert auf 'leer'.\n\n";

# init action
$L{'init_action'} =
"Die einzelnen Optionen zeigen vor der Ausführung zusätzliche Informationen,\n".
"sobald ausgewählt\n".
"[1] Komplett-Installation (macht alles automatisch, benötigt grossen Download)\n".
"[2] Installiert/aktualisiert Datenbank-Schema\n".
"[3] Lädt Tabellen (benötigt grossen Download ~1GB)\n".
"[4] Lädt Tabellen (kein Download, lädt von Verzeichnis 'mbdump/')\n".
"[5] Erstellt Tabellen-Indexe (dauert sehr lange!)\n".
"[6] Initialisiert Plug-Ins\n\n".
"Option: ";

# action descriptions
$L{'init_actionfull'} =
"Die Komplett-Installation erstellt das Datenbank-Schema, lädt die rohen Daten\n".
"herunter (~1GB), importiert diese in die DB, erstellt alle Tabellen-Indexe und\n".
"initialisiert anschliessend die Plug-Ins.\n\n".
"Bitte Datei 'settings.pl' zuerst mit den gewünschten Plug-Ins konfigurieren.\n\n".
"ACHTUNG: Es kann bis zu 24 Stunden dauern bis all diese Schritte vollständig\n".
"ausgeführt sind!\n\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionschema'} =
"Benötigt Internet-Verbindung. Lädt neuestes Datenbank-Schema herunter und\n".
"installiert oder aktualisert alle Veränderungen...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw1'} =
"Benötigt Internet-Verbindung. Lädt neueste Musicbrainz-Daten herunter (~1GB)...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw2'} =
"Wenn die neuesten Datenbank-Archiv-Dumps schon (manuell) heruntergeladen\n".
"wurden, diese bitte dekomprimieren und die rohen Daten in das Verzeichnis\n".
"'mbdump/' kopieren. Mit MySQL-Datenbank den Import nach dem Anlegen der\n".
"Indexe durchführen, weil das schneller ist!\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionindex'} =
"Hier wird am meisten Zeit benötigt. Es werden nun die Indexe zur bereits\n".
"abgefüllten Datenbank erstellt. Mit PostgreSQL-Datenbank die Indexe nach\n".
" dem Importieren der Daten erstellen, weil das schneller ist.\n".
"Dieser Schritt kann nach einem Abbruch jederzeit wieder aufgerufen werden.\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionplugininit'} =
"Dieser Schritt sollte am Schluss aber vor der Replikation ausgeführt werden.\n".
"Bitte die Einstellungen vorher für die gewünschten Plug-Ins in der Datei\n".
"'settings.pl' bei der Variable 'g_active_plugins=' vornehmen.\n\n".
"Zu initialisierende Plug-Ins sind: " . join(', ', @g_active_plugins) . "\n\n".
"Bereit fortzusetzen? (y/n): ";

return 1;
