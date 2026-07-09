## 1.1.3

**EN**

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

Auto Accept Summons

* Fixed: Accepting a summon no longer worked, it only closed the popup without teleporting. 

Gear Check

* New: The Inspect window now shows the average item level ("GS") on the model when viewing another player.
* New: Item level is now also shown on gear in bags, bank, Warband Bank and guild bank, not just on equipped slots.
* Fixed: Legacy items like the Heart of Azeroth and Legion artifact weapons showed a wrong, outdated item level. 

**DE**

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

Beschwörungen automatisch annehmen

* Behoben: Das Annehmen einer Beschwörung funktionierte nicht mehr, es schloss nur das Fenster ohne zu teleportieren.

Ausrüstungs-Prüfung

* Neu: Im Betrachten-Fenster wird jetzt oben am Modell das durchschnittliche Itemlevel des angesehenen Spielers angezeigt.
* Neu: Itemlevel wird jetzt auch bei Ausrüstung in Taschen, Bank, Warband-Bank und Gildenbank angezeigt, nicht mehr nur an angelegten Slots.
* Behoben: Legacy-Items wie das Herz von Azeroth und Legion-Artefaktwaffen zeigten ein falsches, veraltetes Itemlevel. 