## 0.9.6

**EN**

Quest

* Fixed: Auto Quest no longer auto-clicks gossip options — previously this could trigger a protected VisitHouse() call and cause an ADDON_ACTION_FORBIDDEN error

Friends List

* Fixed: Visiting a friend's house from the contacts frame could cause an ADDON_ACTION_FORBIDDEN error due to the enhanced friends list hook running in Blizzard's call chain
* Fixed: "Last Online" text for offline friends was being hidden

Chat

* Fixed: Clicking an item link in chat could cause an ADDON_ACTION_FORBIDDEN taint error (ItemRefTooltip.SetHyperlink was replaced directly instead of hooked safely)

General

* Fixed: /rl and /nl slash commands worked even when the option was disabled
* Fixed: Mouse ring could appear as a very large circle on the minimap after visiting a housing area

**DE**

Quest

* Behoben: Auto Quest klickt keine Gossip-Optionen mehr automatisch an — bisher konnte das einen geschützten VisitHouse()-Aufruf auslösen und einen ADDON_ACTION_FORBIDDEN-Fehler verursachen

Verbesserte Freundesliste

* Behoben: Das Besuchen eines Hauses über die Kontakteliste konnte einen ADDON_ACTION_FORBIDDEN-Fehler verursachen, weil der Hook der erweiterten Freundesliste in Blizzards sicherem Aufruf lief
* Behoben: "Zuletzt online"-Text bei Offline-Freunden wurde ausgeblendet

Chat

* Behoben: Klick auf einen Item-Link im Chat konnte einen ADDON_ACTION_FORBIDDEN-Taint-Fehler verursachen (ItemRefTooltip.SetHyperlink wurde direkt ersetzt statt sicher gehookt)

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
