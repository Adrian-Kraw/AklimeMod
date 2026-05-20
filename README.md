# AklimeMod

Persönliches WoW Addon für Midnight (12.0.7).

---

## Kategorien

### Dashboard
Übersichtsseite mit allen verfügbaren Slash-Befehlen und Kontaktinformationen.

---

### Interface
Visuelle Anpassungen am Spielclient.

- **Elite Frame**: Ersetzt den Eliterahmen mit einem von vier Drachen-Stilen (silber/gold, mit oder ohne Flügel)
- **Seltene Gegner**: Ergänzt den Stern bei seltenen Gegnern durch einen silbernen Drachen
- **Dungeon Eye**: Verschiebt das LFG-Auge an den Minimap-Rand, frei per Drag positionierbar
- **Raid Frame Zentrierung**: Zentriert die Raid-Frames automatisch, passt sich an die Gruppengröße an
- **Makro-Namen ausblenden**: Versteckt die Beschriftung unter Makro-Buttons in der Aktionsleiste
- **Schadensanzeige nach unten klappen**: Klappt kompatible Schadensanzeigen nach unten statt nach oben
- **Minimap Button Sammler**: Bündelt Addon-Buttons an der Minimap in einem aufklappbaren Menü
- **Minimap-Elemente ausblenden**: Blendet einzelne Minimap-Elemente aus (Uhr, Koordinaten, Zone usw.)
- **Mausring und Mausspur**: Farbiger Ring und Trail-Effekt am Mauszeiger, anpassbar in Farbe, Größe und Stil
- **Ausrüstungs-Prüfung**: Zeigt Sockel-Icons, Itemlevel und Verzauberungsstatus an jedem Equipment-Slot
- **Tooltip im Kampf ausblenden**: Blendet den Tooltip während des Kampfes aus
- **Farbliche Anpassungen**: Einfärben von Unit Frames, HUD, Micro Menu, Action Bars und zahlreichen Fenstern

**Interface Ausblendung**
- **Chillmodus in Ruhezonen**: Blendet HUD-Elemente in Ruhezonen automatisch aus
- **Offene Welt**: Blendet HUD-Elemente in der offenen Welt automatisch aus
- **Housing**: Blendet HUD-Elemente in Housing-Bereichen automatisch aus

---

### Quality of Life
Komfort-Features für den Spielalltag.

**Chat und Social**
- **Chat Interaktion**: C-Button zum Kopieren des Chatverlaufs, klickbare URLs, Itemlevel in Chat-Links
- **Chat verblassen**: Ältere Chat-Nachrichten werden automatisch ausgeblendet
- **Chatverlauf speichern**: Speichert den Chatverlauf sitzungsübergreifend
- **Erweiterte Ignore-Liste**: Blockiert Chat-Nachrichten ignorierter Spieler über das Blizzard-Limit hinaus
- **Dienste-Channel verlassen**: Verlässt Dienste-Channels automatisch beim Login
- **Duellanfragen blockieren**: Lehnt Duellanfragen automatisch ab
- **Haustierkampf-Duelle blockieren**: Lehnt Haustierkampf-Anfragen automatisch ab
- **Gruppeneinladungen blockieren**: Lehnt alle Einladungen ab, mit Ausnahmen für Gilde und Freunde
- **Gruppeneinladungen automatisch annehmen**: Nimmt Einladungen von Gildenmitgliedern und/oder Freunden automatisch an
- **Beschwörungen automatisch annehmen**: Nimmt Beschwörungsanfragen automatisch an
- **Verbesserte Freundesliste**: Erweiterte Darstellung mit Realm, Level und Klasse

**Allgemein**
- **Wöchentliche Schatzkammer**: Öffnet das Blizzard-Schatzkammer-Fenster per Knopfdruck
- **Auto Repair**: Repariert Ausrüstung automatisch beim Händler (Gildenbank oder Gold)
- **Interface Neuladen**: `/rl` und `/nl` als Kurzbefehl für ReloadUI
- **Einfaches Bestätigen und Löschen**: Überspringt die Texteingabe beim Löschen und Bestätigen von Items
- **Graue Items automatisch verkaufen**: Verkauft graue Items automatisch beim Öffnen eines Händlers
- **Jagd % Anzeige**: Zeigt den Jagdfortschritt als Prozentwert statt als Kristall-Icon
- **24-Stunden-Uhr**: Stellt die Ingame-Uhr auf 24-Stunden-Format um
- **Karten-Koordinaten**: Zeigt die eigenen Koordinaten auf der Weltkarte an
- **Lernen-/Vergessen-Meldungen ausblenden**: Blendet Systemmeldungen beim Lernen von Fähigkeiten aus
- **Item- und Währungssymbole im Chat**: Zeigt Icons bei Item- und Währungslinks im Chat
- **Itemlevel in Chat-Links**: Zeigt das Itemlevel von Spielern neben dem Chatnamen
- **Adressbuch für Post**: Speichert Empfänger-Namen für das Postfach mit Autovervollständigung
- **Händlerfenster - 20 Gegenstände pro Seite**: Zeigt 20 statt 10 Gegenstände pro Händler-Seite

**Gameplay**
- **Mana Warnung**: Warnt per Sound und Meldung wenn Mana unter einen einstellbaren Schwellenwert fällt
- **HT-Anzeige**: Zeigt an wenn Heldentum / Trommeln aktiv ist
- **Todessound**: Spielt einen Sound beim Tod des eigenen Charakters
- **Talent-Erinnerung**: Hinweis wenn man einen Dungeon ohne gewählte Talente betritt

**Quest**
- **Quest automatisch annehmen / abgeben**: Nimmt Quests und Belohnungen automatisch an, überspringt Gossipdialoge
- **Wowhead-URL im Quest-Menü**: Fügt einen Wowhead-Link im Quest-Menü ein
- **Quest-Tracker Erweiterungen**: Eigener Quest-Tracker mit einstellbarer Breite und Ein-/Ausblenden per Klick

**Gesundheit**
- **Trinkerinnerung**: Erinnert regelmäßig daran zu trinken und sich zu strecken

**Spielzeit**
- **Gespielte Zeit**: Erfasst die Spielzeit aller Chars beim Login, abrufbar per `/akm played`

---

### Collecting
Charakter- und Fortschrittsübersicht über alle eigenen Charaktere.

- **Charakter-Tracker**: Zeigt gespeicherte Instanzen (Raids), Große Schatzkammer, Währungen und Gold für alle Charaktere
- **Währungen**: Filter welche Währungen pro Erweiterung im Tracker angezeigt werden

---

### PvP
- **Namensplaketten einfärben**: Färbt Namensplaketten in Arenen und Schlachtfeldern (Grün = eigenes Team, Rot = Gegner)
- **Chat im PvP blockieren**: Verhindert das Öffnen der Chat-Eingabe in Arenen und Schlachtfeldern

---

## Befehle

| Befehl | Funktion |
|--------|----------|
| `/akm` | Einstellungsfenster öffnen / schließen |
| `/akm help` | Alle Befehle im Chat anzeigen |
| `/akm todo` | ToDo-Liste öffnen / schließen |
| `/akm ignore` | Erweiterte Ignore-Liste öffnen / schließen |
| `/akm played` | Gespielte Zeit aller Chars anzeigen |
| `/rl` `/nl` | Interface neu laden |
| `/akmana` | Mana-Warnung Status anzeigen |
| `/akmana test` | Mana-Warnung Testnachricht senden |
