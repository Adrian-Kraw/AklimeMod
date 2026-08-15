## 1.3.1

**EN**

Quest Tracker

* Fixed: The quest count in the tracker header was too low. It counted the entries currently shown in the quest log, so every quest below a collapsed header was missing. It now uses the game's own quest count, the same number the quest log shows.

Character Tracker

* Fixed: A typo in the German raid tooltip, "Bezwunden" instead of "Bezwungen".

Auto Accept Summons

* New: A delay slider from 0 to 10 seconds. At "Instant" the summon is accepted right away as before, that stays the default. With a delay you keep the chance to answer the dialog yourself during the wait, and nothing is accepted if you already did.

Auto Accept Non-Refundable Warning

* New: A third option next to the purchase and refund confirmations. It confirms the warning that an item can no longer be refunded, so the popup no longer appears. Covers all four cases that show it: equipping, using, socketing and mailing. Off by default, because that warning is the last chance to stop.

Mana Warning

* Fixed: In instances where the game hides mana values, the "out of mana" warning never reached the group. The game blocked it because it went out from inside one of its own routines. It is sent correctly again.
* Changed: The warnings now use the game's current chat function. The old one is only kept as a fallback, Blizzard is phasing it out.

**DE**

Quest-Tracker

* Behoben: Die Questzahl in der Kopfzeile war zu niedrig. Gezählt wurden die im Questlog gerade sichtbaren Einträge, alle Quests unter einer zugeklappten Überschrift fehlten dadurch. Jetzt wird die Questzahl des Spiels verwendet, also dieselbe, die auch im Questlog steht.

Charakter-Tracker

* Behoben: Tippfehler im Raid-Tooltip, dort stand "Bezwunden" statt "Bezwungen".

Beschwörungen automatisch annehmen

* Neu: Ein Regler für die Verzögerung von 0 bis 10 Sekunden. Bei "Sofort" wird wie bisher direkt angenommen, das bleibt der Standard. Mit Verzögerung hast du während der Wartezeit noch die Möglichkeit, selbst auf den Dialog zu reagieren, und es wird nichts mehr angenommen, wenn du das getan hast.

Warnung zum Verfall der Rückerstattung annehmen

* Neu: Eine dritte Option neben der Kauf- und der Rückerstattungsbestätigung. Sie bestätigt die Warnung, dass ein Gegenstand nicht mehr zurückerstattet werden kann, das Fenster erscheint damit nicht mehr. Deckt alle vier Fälle ab, in denen es auftaucht: Anlegen, Benutzen, Sockeln und Verschicken per Post. Standardmäßig aus, weil diese Warnung die letzte Möglichkeit zum Abbrechen ist.

Mana-Warnung

* Behoben: In Instanzen, in denen das Spiel die Manawerte verbirgt, kam die "kein Mana mehr"-Warnung nie in der Gruppe an. Das Spiel hat sie blockiert, weil sie aus einer seiner eigenen Routinen heraus verschickt wurde. Sie geht jetzt wieder korrekt raus.
* Geändert: Die Warnungen nutzen jetzt die aktuelle Chat-Funktion des Spiels. Die alte bleibt nur noch als Rückfallebene, Blizzard schafft sie ab.
