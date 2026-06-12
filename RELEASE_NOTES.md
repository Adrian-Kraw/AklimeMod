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
