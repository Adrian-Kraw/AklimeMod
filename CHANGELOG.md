## 1.1.2

Fix for the Enhanced Friends List after Blizzard's API hotfix. / Fix für die verbesserte Freundesliste nach Blizzards API-Hotfix.

**EN**

Enhanced Friends List

* Fixed: Favorite stars flickered on and off after Blizzard's patch restored the favorites API

**DE**

Verbesserte Freundesliste

* Behoben: Favoriten-Sterne blinkten nach Blizzards Patch, der die Favoriten-API wiederhergestellt hat


## 1.1.1

Translation fixes. / Übersetzungskorrekturen.

**EN**

Chat Interaction

* Fixed: "Select All" and "Close" buttons in the chat copy window were hardcoded in German

**DE**

Chat Interaktion

* Behoben: "Alles auswählen" und "Schließen" Buttons im Chat-Kopierfenster waren auf Deutsch hardcodiert


## 1.1.0

Bug fixes for the Enhanced Friends List and Dungeon Eye, plus a new sub-toggle to hide talent point alert popups. / Bugfixes für die verbesserte Freundesliste und das Dungeon Eye, plus neuer Unter-Schalter zum Ausblenden der Talentpunkt-Popups.

**EN**

Hide Learn/Unlearn Messages

* New: Sub-toggle to hide the "You have unspent talent points" and "PvP talent slot available" alert popups

Enhanced Friends List

* Fix attempt: BNet contacts could still show an outdated zone location after the contact changed zones
* Fixed: WoW friends could remain shown as online after going offline

Dungeon Eye

* Fixed: The eye's looking animation was frozen while the Dungeon Eye feature was active

**DE**

Lernen-/Vergessen-Meldungen ausblenden

* Neu: Unter-Schalter zum Ausblenden der Popups "Ihr habt noch unverteilte Talentpunkte" und "Ihr habt einen verfügbaren PvP-Talentplatz"

Verbesserte Freundesliste

* Behebungsversuch: BNet-Kontakte konnten noch den alten Ort anzeigen, nachdem der Kontakt die Zone gewechselt hatte
* Behoben: Ingame-Freunde konnten nach dem Ausloggen noch als online angezeigt werden

Dungeon Eye

* Behoben: Die Augen-Animation (Schauen) war eingefroren solange das Dungeon-Eye-Feature aktiv war


## 1.0.0

First stable release / Erste stabile Release-Version.

**EN**

Heroism Tracker

* Fixed: BL text disappeared as soon as combat started in instances. Blizzard hides the buff data from addons in instanced combat (12.0), the tracker now derives the buff from the readable exhaustion debuff instead. Works no matter who casts BL and also covers drums

Mana Warning

* New: The warning now works. Sends one group message when your mana drops below 10%

Settings Window

* New: Complete redesign in a flat black and gold look with rounded category buttons, stone background, round addon portrait and centered window title
* New: Action buttons are now real centered buttons instead of plain clickable text
* New: Delete actions ask for confirmation with a Yes / No dialog
* New: The character delete list shows Name - Realm - Class in class colors, arranged in columns of 20
* Changed: The window turns slightly transparent while being dragged
* Fixed: Some checkboxes closed their section when clicked, sections now stay open
* Fixed: Exclusive options (for example chat fade times) could show two checkmarks at once, now exactly one is shown and it updates instantly
* Fixed: Clicking an already active option no longer removes its checkmark

Colorizer

* New: The addon window skin got more color slots: boxes, lines, selection and portrait ring, plus a "Color everything" picker and a restore default button
* New: Elite Frame can now be colored (Addons group)
* New: Game menu buttons can now be colored
* Fixed: The active chat tab and the focused chat edit box were not colored along

Character Tracker

* New: Currency amounts now update live after transferring a currency between your characters. The receiving character and the offline source character both show the new balance immediately, no relog needed

Purchase Confirmation

* Fixed: Not all high cost purchase dialogs ("buy for the following amount") were not auto-confirmed, now they are
* New: Separate toggle to auto-confirm refund dialogs when selling refundable items back to a vendor

**DE**

Heldentum-Tracker

* Behoben: HT-Text verschwand in Instanzen, sobald der Kampf begann. Blizzard versteckt die Buff-Daten im Instanz-Kampf vor Addons (12.0), der Tracker leitet den Buff jetzt stattdessen aus dem lesbaren Erschöpfungs-Debuff ab. Funktioniert egal wer HT wirkt und deckt auch Trommeln ab

Mana-Warnung

* Neu: Die Warnung arbeitet jetzt. Sendet eine Gruppennachricht, wenn das Mana unter 10% fällt. 

Einstellungsfenster

* Neu: Komplett neues Design in flachem Schwarz-Gold-Look mit abgerundeten Kategorie-Buttons, Stein-Hintergrund, rundem Addon-Portrait und mittigem Fenstertitel
* Neu: Aktions-Schaltflächen sind jetzt echte zentrierte Buttons statt klickbarer Textflächen
* Neu: Lösch-Aktionen fragen vorher mit einem Ja / Nein-Dialog nach
* Neu: Die Char-Löschen-Liste zeigt Name - Server - Klasse in Klassenfarben, aufgeteilt in Spalten zu je 20
* Geändert: Das Fenster wird beim Verschieben leicht transparent
* Behoben: Manche Haken haben beim Anklicken ihre Sektion zugeklappt, Sektionen bleiben jetzt offen
* Behoben: Bei exklusiven Optionen (z.B. Chat-Verblassen-Zeiten) konnten zwei Haken gleichzeitig zu sehen sein, jetzt ist immer genau einer gesetzt und er aktualisiert sich sofort
* Behoben: Klick auf eine bereits aktive Option entfernt deren Haken nicht mehr

Colorizer

* Neu: Der Skin für das Addon-Fenster hat mehr Farbfelder: Boxen, Linien, Auswahl und Portrait-Ring, dazu "Alles färben" und einen Standard-Button
* Neu: Elite Frame ist jetzt färbbar (Gruppe Addons)
* Neu: Die Spielmenü-Buttons sind jetzt färbbar
* Behoben: Der aktive Chat-Reiter und die fokussierte Eingabezeile wurden nicht mitgefärbt

Charakter-Tracker

* Neu: Währungsstände aktualisieren sich jetzt live nach einem Währungstransfer zwischen deinen Charakteren. Empfangender und abgebender Charakter (auch offline) zeigen sofort den neuen Stand, kein Relog nötig

Kaufbestätigung

* Behoben: Nicht alle teure Kaufdialoge ("für den folgenden Betrag kaufen") wurden nicht automatisch bestätigt, jetzt schon
* Neu: Eigener Schalter, der Rückerstattungsdialoge beim Rückverkauf umtauschbarer Items automatisch bestätigt


## 0.9.6

**EN**

Friends List

* Fixed: Visiting a friend's house from the contacts frame could cause an ADDON_ACTION_FORBIDDEN error due to the enhanced friends list hook running in Blizzard's call chain
* Fixed: "Last Online" text for offline friends was being hidden

Chat

* Fixed: Clicking an item link in chat could cause an ADDON_ACTION_FORBIDDEN taint error

Summons

* Fixed: Auto-accept summons was broken and should work now

Ready Check

* Changed: Ready Check window now closes automatically after auto-accepting

Heroism Tracker

* Fixed: BL text was not reliably shown during combat and in instances
* Fixed: BL Tracker frame was intercepting mouse clicks during combat, frame is now click-through by default when locked (locked is the new default)
* Fixed: BL text did not appear when the buff came from an Evoker or a Marksmanship Hunter. Both are now detected

General

* Fixed: /rl and /nl slash commands worked even when the option was disabled
* Fixed: Mouse ring could appear as a very large circle on the minimap after visiting a housing area

**DE**

Verbesserte Freundesliste

* Behoben: Das Besuchen eines Hauses über die Kontakteliste konnte einen ADDON_ACTION_FORBIDDEN-Fehler verursachen, weil der Hook der erweiterten Freundesliste in Blizzards sicherem Aufruf lief
* Behoben: "Zuletzt online"-Text bei Offline-Freunden wurde ausgeblendet

Chat

* Behoben: Klick auf einen Item-Link im Chat konnte einen ADDON_ACTION_FORBIDDEN-Taint-Fehler verursachen

Beschwörungen

* Behoben: Auto-Beschwörung hat nicht mehr funktioniert und sollte jetzt funktionieren

Ready Check

* Geändert: Das Ready-Check-Fenster schließt sich jetzt automatisch nach dem Auto-Accept

Heldentum-Tracker

* Behoben: HT-Text wurde im Kampf nicht zuverlässig angezeigt, vor allem in Instanzen 
* Behoben: Der HT-Tracker-Frame hat Maus-Klicks im Kampf blockiert, Frame ist jetzt standardmäßig click-through wenn gesperrt (gesperrt ist jetzt der Standard)
* Behoben: HT-Text erschien nicht, wenn der Buff von einem Rufer oder Treffsicherheits-Jäger kam. Beide werden jetzt erkannt

Allgemein

* Behoben: /rl und /nl funktionierten auch wenn die Option deaktiviert war
* Behoben: Der Mausring konnte nach dem Besuchen eines Housing-Bereichs als sehr großer Kreis auf der Minimap erscheinen


## 0.9.5

**EN**

Quest

* Fixed: Auto Quest could trigger a protected VisitHouse() call when opening gossip at a housing contact, causing an ADDON_ACTION_FORBIDDEN error

**DE**

Quest

* Behoben: Auto Quest konnte beim Öffnen von Gossip an einem Housing-Kontakt einen geschützten VisitHouse()-Aufruf auslösen und einen ADDON_ACTION_FORBIDDEN-Fehler verursachen


## 0.9.4

**EN**

General
* Addon name unified to "Aklime Mod Tools" everywhere

Translation
* Addon fully bilingual (EN/DE)

Character Tracker
* Raid name translation table corrected and expanded
* Currency sorting in the Settings panel

Easy Confirm and Delete
* Two new separate checkboxes added:
* No longer type UNLEARN 
* No longer type UNDERSTOOD 
* UNLEARN was previously bundled internally under "CONFIRM", now standalone

Gear Check
* Enchant indicator for weapon slots correctly positioned (was mirrored)
* Main hand: text now appears on the left (outward), off hand: right (outward)

Prey Progress (formerly Hunt % Display)
* Module renamed: "Prey Progress in Phases" / "Jagd Fortschritt in Phasen"
* Display changed: instead of 25 / 50 / 75 / 100 % now Phase 1 / Phase 2 / Phase 3 / Phase 4

Rare Enemies
* Toggle text clarified: "Add Silver Dragon additionally to the Star" 

Miscellaneous
* Possible bug fixed: saved value for UI fade could reset itself
* Drink reminder now also active in the Housing instance
* Auto-purchase confirmation: skip option added

**DE**

Allgemein
* Addon-Name überall vereinheitlicht zu „Aklime Mod Tools"

Übersetzung
* Addon vollständig bilingual (EN/DE)

Charakter-Tracker
* Raid-Namensübersetzungstabelle korrigiert und erweitert
* Währungssortierung im Settings-Panel

Easy Confirm and Delete
* Zwei neue separate Haken ergänzt:
* Nicht mehr VERLERNEN schreiben
* Nicht mehr VERSTANDEN schreiben
* VERLERNEN war bisher intern unter „BESTÄTIGEN" versteckt, ist jetzt eigenständig

Gear Check
* Verzauberungs-Anzeige bei Waffen-Slots korrekt positioniert (war gespiegelt)
* Hauptwaffe: Text erscheint jetzt links (auswärts), Nebenwaffe: rechts (auswärts)

Prey Progress (ehemals Hunt % Display)
* Modul umbenannt: „Prey Progress in Phases" / „Jagd Fortschritt in Phasen"
* Anzeige geändert: statt 25 / 50 / 75 / 100 % jetzt Phase 1 / Phase 2 / Phase 3 / Phase 4

Seltene Gegner
* Toggle-Text präzisiert: „Add Silver Dragon additionally to the Star" / „Silbernen Drachen zusätzlich zum Stern hinzufügen"

Sonstiges
* Möglicher Bug behoben: gespeicherter Wert beim UI-Ausblenden konnte sich zurücksetzen
* Trink-Erinnerung jetzt auch in der Housing-Instanz aktiv
* Auto-Kauf Bestätigung: Skip-Option ergänzt

## 0.9.3

**EN**
- New: Lazy Ready Check, automatically confirms ready checks after a configurable delay
- New: Auto Skip Cutscene, skips in-game cutscenes and cinematics automatically
- New: Auto Quest Turn-In, automatically turns in quests with options to include dailies and exclude weeklies
- New: Colorizer global color, enable all skins at once and set a single shared color for all of them
- New: Minimap now has 6 buttons (previously 4), added Playtime and Todo List buttons
- New: Character tracker icon updated
- Overhaul: Character tracker currencies reorganized by expansion with sorting and per-currency totals across all characters (including Oath-Bound Service Medal)
- WiP: Mana warning
- WiP: Mouse effects, checkbox options removed, slider not yet implemented
- Fix: Playtime total percentage no longer fails to reach 100%
- Fix: Raid frame centering bug resolved
- Fix: Friends list favorite star now appears to the right of the name instead of being clipped by the scroll region
- Fix: Friends list separator between BattleTag and character name removed
- Fix: Chat copy window now shows the active tab name in the title
- Fix: Chat copy detects the active tab via FCFDock instead of always reading from the first visible frame
- Fix: Chat copy line click mapping corrected by setting EditBox width before inserting text
- Fix: Chat copy window now scrolls to the most recent messages on open
- Fix: Raid frame debuff type indicators (magic/poison/curse/disease) no longer overridden by Colorizer border tinting

**DE**
- Neu: Lazy Ready Check, bestätigt Ready Checks automatisch nach einer einstellbaren Verzögerung
- Neu: Auto Cutscene Skip, überspringt Ingame-Cutscenes und Cinematics automatisch
- Neu: Auto Quest Abgeben, gibt Quests automatisch ab mit Optionen für Dailies und Weekly-Ausschluss
- Neu: Colorizer Globalfarbe, alle Skins auf einmal aktivieren und eine gemeinsame Farbe für alle setzen
- Neu: Minimap hat jetzt 6 Knöpfe (vorher 4), Playtime und Todo-Liste hinzugefügt
- Neu: Icon für den Charakter-Tracker geändert
- Überarbeitung: Charakter-Tracker Währungen nach Expansion sortiert mit Gesamtsummen pro Währung über alle Charaktere (inkl. Dienstmedaille der Eidgebundenen)
- WiP: Mana-Warnung
- WiP: Mauseffekte, Haken-Optionen entfernt, Slider noch nicht umgesetzt
- Fix: Playtime Gesamt-Prozent erreicht jetzt korrekt 100%
- Fix: Bug beim Zentralisieren von Raid Frames behoben
- Fix: Favoriten-Stern in der Freundesliste erscheint jetzt rechts neben dem Namen statt vom Scroll-Bereich abgeschnitten zu werden
- Fix: Trennzeichen zwischen BattleTag und Charaktername in der Freundesliste entfernt
- Fix: Chat-Kopier-Fenster zeigt den aktiven Tab-Namen im Titel an
- Fix: Chat-Kopieren erkennt den aktiven Tab über FCFDock statt immer vom ersten sichtbaren Frame zu lesen
- Fix: Zeilen-Klick-Zuordnung im Chat-Kopier-Fenster korrigiert durch Setzen der EditBox-Breite vor dem Einfügen
- Fix: Chat-Kopier-Fenster scrollt beim Öffnen automatisch zu den neuesten Nachrichten
- Fix: Raidframe Debuff-Typ-Indikatoren (Magie/Gift/Fluch/Krankheit) werden vom Colorizer nicht mehr überschrieben

## 0.9.2

**EN**
- Fix: Addon initializes correctly after rename to AklimeModTools
- Fix: Mouse trail particles now disappear correctly after playing

**DE**
- Fix: Addon initialisiert nach Umbenennung zu AklimeModTools korrekt
- Fix: Mausspur-Partikel verschwinden nun korrekt nach dem Abspielen

## 0.9.1

**EN**
- Fix: CurseForge upload via GitHub Actions set up

**DE**
- Fix: CurseForge Upload über GitHub Actions eingerichtet

## 0.9.0

**EN**
- Initial release

**DE**
- Erste Veröffentlichung
