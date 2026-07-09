## 1.1.3

**EN**

Fixes for the Enhanced Friends List, unlearn confirmation, Easy Delete input handling, and a translation fix for the chat copy window, plus a smarter Great Vault status for characters that have not logged in yet, a Heroism Tracker click-through fix, a Minimap Button Collector fix for TomTom waypoints, and a Lua error fix for the Leave Trade Channel feature.

Enhanced Friends List

* Fixed: BNet contacts on the Battle.net mobile app were shown as offline with no status indicator. They now appear as online and show "Mobile" in the info line.

Chat Interaction

* Fixed: "Select All" and "Close" buttons in the chat copy window were not translated for German clients.

Easy Confirm and Delete

* Fixed: When unlearning, the confirmation field was auto-filled with the wrong word, leaving the Unlearn button disabled. The correct confirmation word is now detected and filled in.
* Fixed: Confirming the destroy prompt for a whole item stack left the confirmation field empty because that dialog type was not recognized. Delete/destroy confirmations are now matched more broadly.

Character Tracker

* New: The Great Vault "Reward" row now shows "Open" for characters that have not logged in since the weekly reset, if their last known progress guarantees a reward is waiting

Heroism Tracker

* Fixed: The tracker was unlocked by default, blocking clicks on frames behind it. It is now locked by default, so it is click-through unless you unlock it to move it.

Minimap Button Collector

* Fixed: TomTom's minimap waypoint arrows could get swept into the collector and show up there as invisible icons. They are now excluded.

Leave Trade Channel

* Fixed: Rejoining the channel could throw a Lua error, because the addon tried to auto-show it in the chat window using a Blizzard API function that no longer exists. The channel is now shown correctly and without errors.

**DE**

Fixes für die verbesserte Freundesliste, die Verlernen-Bestätigung, Einfaches Löschen Eingabeanpassungen und einen Übersetzungsfix für das Chat-Kopierfenster, außerdem eine schlauere Schatzkammer-Anzeige für noch nicht eingeloggte Charaktere, ein Klick-durch-Fix für den Heldentum-Tracker, ein Fix im Minimap Button Sammler für TomTom-Wegpunkte und ein Lua-Fehler-Fix beim Dienste-Channel verlassen.

Verbesserte Freundesliste

* Behoben: BNet-Kontakte über die Battle.net Mobile-App wurden als offline angezeigt und hatten keinen Status-Indikator. Sie erscheinen jetzt als online und zeigen "Mobilgerät" in der Info-Zeile.

Chat Interaktion

* Behoben: "Alles auswählen" und "Schließen" Buttons im Chat-Kopierfenster waren für deutschsprachige Nutzer auf Englisch.

Einfaches Bestätigen und Löschen

* Behoben: Beim Verlernen wurde im Bestätigungsfeld das falsche Wort eingetragen ("LÖSCHEN" statt "VERLERNEN"), wodurch der Verlernen-Knopf deaktiviert blieb. Das richtige Wort wird jetzt erkannt und eingetragen.
* Behoben: Einfaches Löschen Eingabeanpassungen, der Zerstören-Dialog für einen ganzen Item-Stapel wurde nicht erkannt, das Bestätigungsfeld blieb leer. Lösch-/Zerstören-Dialoge werden jetzt zuverlässiger erkannt.

Charakter-Tracker

* Neu: Die "Belohnung"-Zeile der Großen Schatzkammer zeigt jetzt "Offen" für Charaktere, die seit dem wöchentlichen Reset nicht eingeloggt waren, sofern der zuletzt bekannte Fortschritt eine Belohnung garantiert

Heldentum-Tracker

* Behoben: Der Tracker war standardmäßig entsperrt und blockierte dadurch Klicks auf Frames dahinter. Er ist jetzt standardmäßig gesperrt und damit click-through, außer man entsperrt ihn zum Verschieben.

Minimap Button Sammler

* Behoben: TomTom-Wegpunkt-Pfeile auf der Minimap konnten in den Sammler aufgenommen werden und erschienen dort als unsichtbare Icons. Sie werden jetzt ausgeschlossen.

Dienste-Channel verlassen

* Behoben: Beim erneuten Beitreten zum Channel konnte ein Lua-Fehler auftreten, weil das Addon versuchte, ihn per einer nicht mehr existierenden Blizzard-API-Funktion automatisch im Chatfenster anzuzeigen. Der Channel wird jetzt korrekt und ohne Fehler angezeigt.