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
$L{'invalid'} = "Ungltige Eingabe";

##-------------------------------------------
## init.pl
##-------------------------------------------

# Language changed
$L{'langchanged'} = "Sprache ge„ndert. Bitte init.pl erneut aufrufen\n";

# Welcome message
$L{'init_welcome'} =
"Willkommen bei mbzdb v1.0".
"HINWEIS: Version 3 l„uft mit einem anderen Replikations-System als\n".
"die „lteren Varianten. Wir empfehlen deshalb eine neue Datenbank fr\n".
"diese v3 zu erstellen.".
"Bitte fuer Details im Handbuch nachsehen.\n\n";

$L{'init_firstboot'} =
"*** Bevor es losgehen kann UNBEDINGT zuerst die gewnschte MySQL-Datenbank\n".
"    MANUELL erstellen! *** \n\n".
"Werte in eckigen Klammern sind Standard-Vorgaben. Wenn man nicht sicher ist\n".
"ob diese Werte stimmen, einfach mal ENTER drcken um fortzusetzen.\n".
"Man kann jederzeit abbrechen und die Optionen werden gespeichert.\n".
"Ein einzelner Leerschlag als Antwort setzt den Wert auf 'leer'.\n\n";

# init action
$L{'init_action'} =
"Die einzelnen Optionen zeigen vor der Ausfhrung zus„tzliche Informationen,\n".
"sobald ausgew„hlt\n".
"[1] Komplett-Installation (macht alles automatisch, ben”tigt grossen Download)\n".
"[2] Installiert/aktualisiert Datenbank-Schema\n".
"[3] L„dt Tabellen (ben”tigt grossen Download ~1GB)\n".
"[4] L„dt Tabellen (kein Download, l„dt von Verzeichnis 'mbdump/')\n".
"[5] Erstellt Tabellen-Indexe (dauert sehr lange!)\n".
"[6] Initialisiert Plug-Ins\n\n".
"Option: ";

# action descriptions
$L{'init_actionfull'} =
"Die Komplett-Installation erstellt das Datenbank-Schema, l„dt die rohen Daten\n".
"herunter (~1GB), importiert diese in die DB, erstellt alle Tabellen-Indexe und\n".
"initialisiert anschliessend die Plug-Ins.\n\n".
"Bitte Datei 'settings.pl' zuerst mit den gewnschten Plug-Ins konfigurieren.\n\n".
"ACHTUNG: Es kann bis zu 24 Stunden dauern bis all diese Schritte vollst„ndig\n".
"ausgefhrt sind!\n\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionschema'} =
"Ben”tigt Internet-Verbindung. L„dt neuestes Datenbank-Schema herunter und\n".
"installiert oder aktualisert alle Ver„nderungen...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw1'} =
"Ben”tigt Internet-Verbindung. L„dt neueste Musicbrainz-Daten herunter (~1GB)...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionraw2'} =
"Wenn die neuesten Datenbank-Archiv-Dumps schon (manuell) heruntergeladen\n".
"wurden, diese bitte dekomprimieren und die rohen Daten in das Verzeichnis\n".
"'mbdump/' kopieren...\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionindex'} =
"Hier wird am meisten Zeit ben”tigt. Es werden nun die Indexe zur bereits\n".
"abgefllten Datenbank erstellt. Es ist wichtig, die Indexe NACH dem\n".
"importieren der Daten zu erstellen, weil das schneller ist...\n".
"Dieser Schritt kann nach einem Abbruch jederzeit wieder aufgerufen werden.\n".
"Bereit fortzusetzen? (y/n): ";

$L{'init_actionplugininit'} =
"Dieser Schritt sollte am Schluss aber vor der Replikation ausgefhrt werden.\n".
"Bitte die Einstellungen vorher fr die gewnschten Plug-Ins in der Datei\n".
"'settings.pl' bei der Variable 'g_active_plugins=' vornehmen.\n\n".
"Zu initialisierende Plug-Ins sind: " . join(', ', @g_active_plugins) . "\n\n".
"Bereit fortzusetzen? (y/n): ";

return 1;
