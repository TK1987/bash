Erläuterung:
Wir beginnen im Hauptprogramm
Zeile 5-6: Als erstes wird der Googleserver angepingt, um zu prüfen ob eine Internetverbindung besteht. Desteht diese nicht, wird eine entsprechende Meldung in roter Schrift ausgegeben und das Script endet.
Zeilen 7-10: Besteht eine Internetverbindung, wird mit 'pgrep -a apt' und 'pgrep -a dpkg' geprüft, ob ein apt- oder dpkg-Prozess läuft. Läuft ein solcher, wird eine entsprechende Meldung in roter Schrift ausgegeben und das Script endet.
Zeile 11: Läuft kein solcher Prozess, wird die Funktion "aptUpgrade" aufgerufen. 

Funktion aptUpgrade:
Zeile 17-19: Paketliste aktualisieren und Pakete aktualiesieren.
Zeile 20: Wurde das Aktualisieren der Pakete nicht erfolgreich beendet, wird im folgenden versucht, das Paketsystem zu reparieren.
Zeile 23-26: Reparaturversuch
Zeile 27: Erneuter Versuch zu Aktualisieren
Zeile 28-35: Falls der erneute Aktualisierungsversuch erfolgreich war, wird eine entsprechende Meldung in grüner schrift ausgegeben und das Scrupt fortgesetzt || falls dieser scheitert, wird eine Meldung in roter Schrift ausgegeben, zusätzlich über die Funktion "zWarn" eine Grafische Warnung in der GUI ausgegeben und das Script beendet.
Zeile 39: Nicht mehr benötigte Pakete entfernen
Zeile 40-43: Prüfen ob ein Neustart erforderlich ist und eine Meldung ausgeben, das die Aktualisierung erfolgreich war und ob neugestartet werden soll oder nicht.

Funktion zWarn
Zeile 47: Über "zenity" wird eine grafische Warnung in der GUI erzeugt.

Zeile 51: Ausführen des Hauptprogramms
