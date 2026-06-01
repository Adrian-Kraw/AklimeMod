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
