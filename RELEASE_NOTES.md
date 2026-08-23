## 1.3.1

**EN**

Colorizer

* Fixed: The colored border around buff icons caused a flood of Lua errors, on the buff bar as well as on target and focus auras. The border was a backdrop frame anchored to the icon, and since the game hides aura sizes as secret values, Blizzard's backdrop code failed on every resize. The border is now drawn with four plain textures, which need no size calculation. It looks a little crisper than before.

Center Raid Frames

* New: Recentering now also happens during combat, so a group turning into a raid or a new group appearing mid fight no longer leaves the frames off center until the fight ends. The raid container is a protected frame that an addon may not move in combat, so this runs through a secure snippet inside the game's own restricted environment.
* Fixed: When a party turned into a raid, the frames stayed off center. The single attempt after the roster change ran while the raid container was still hidden or its groups were not laid out yet, and nothing tried again afterwards. Centering now also reacts to the container appearing and to it changing size.
* Fixed: The frames could end up off center, especially with a raid frame size other than the default. The width was estimated from the number of groups times one group's width, which ignored that size setting and fell back to a fixed guess when the group frames were not found. The container's own width is used now.

Quest Tracker

* Fixed: On characters whose quests are all campaign quests, the count was invisible. Campaign quests have their own section in the tracker, and the count was pinned to the header of the normal quest section, which is hidden on such a character. It now attaches to whichever quest header is actually on screen.
* Fixed: On some characters no quest count appeared at all. It was only calculated half a second after login, and the quest log arrives from the server later than that, so the result was zero and the display stayed hidden. The count now recalculates whenever the quest log changes.
* Fixed: The quest count in the tracker header did not match the quest log. World quests and bonus objectives are entries in the quest log too, but they are not quests and do not count against the limit of 35. The count now uses the same rule the quest log itself uses to decide what is a quest.

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

Einfärber

* Behoben: Der farbige Rahmen um Buff-Icons löste eine Flut von Lua-Fehlern aus, sowohl an der Buffleiste als auch bei Ziel- und Fokus-Auren. Der Rahmen war ein Backdrop-Frame, der an das Icon geheftet war, und da das Spiel Aurengrößen als geheime Werte behandelt, scheiterte Blizzards Backdrop-Code bei jeder Größenänderung. Der Rahmen besteht jetzt aus vier einfachen Texturen, die keine Größenberechnung brauchen. Er wirkt dadurch etwas klarer als vorher.

Gruppenrahmen zentrieren

* Neu: Die Zentrierung greift jetzt auch im Kampf. Wird mitten im Kampf aus einer Gruppe ein Schlachtzug oder kommt eine Gruppe dazu, stehen die Rahmen nicht mehr bis Kampfende schief. Der Schlachtzugsrahmen ist ein geschütztes Frame, das ein Addon im Kampf nicht bewegen darf, das läuft deshalb über ein Secure Snippet in der geschützten Umgebung des Spiels.
* Behoben: Wurde aus einer Gruppe ein Schlachtzug, blieben die Rahmen unzentriert. Der einzelne Versuch nach der Gruppenänderung lief zu früh, da war der Schlachtzugsrahmen noch ausgeblendet oder seine Gruppen noch nicht angeordnet, und danach passierte nichts mehr. Die Zentrierung reagiert jetzt auch darauf, dass der Rahmen erscheint und dass er seine Größe ändert.
* Behoben: Die Rahmen konnten daneben landen, vor allem bei einer anderen Rahmengröße als der Voreinstellung. Die Breite wurde aus Gruppenanzahl mal Breite einer Gruppe geschätzt, das ignorierte die eingestellte Größe und fiel auf einen festen Schätzwert zurück, wenn die Gruppenrahmen nicht gefunden wurden. Jetzt wird die tatsächliche Breite des Rahmens verwendet.

Quest-Tracker

* Behoben: Bei Charakteren, deren Quests alle Kampagnenquests sind, war die Zahl unsichtbar. Kampagnenquests haben im Tracker einen eigenen Abschnitt, die Zahl hing aber an der Kopfzeile des normalen Quest-Abschnitts, und die ist bei so einem Charakter ausgeblendet. Sie hängt sich jetzt an die Quest-Kopfzeile, die tatsächlich zu sehen ist.
* Behoben: Bei manchen Charakteren stand gar keine Questzahl da. Sie wurde nur eine halbe Sekunde nach dem Login berechnet, das Questlog kommt aber später vom Server. Das Ergebnis war dann null und die Anzeige blieb ausgeblendet. Jetzt wird bei jeder Änderung am Questlog neu gezählt.
* Behoben: Die Questzahl in der Kopfzeile passte nicht zum Questlog. Weltquests und Bonusziele sind dort ebenfalls Einträge, zählen aber nicht als Quest und nicht gegen das Limit von 35. Gezählt wird jetzt nach derselben Regel, mit der auch das Questlog entscheidet, was eine Quest ist.

Charakter-Tracker

* Behoben: Tippfehler im Raid-Tooltip, dort stand "Bezwunden" statt "Bezwungen".

Beschwörungen automatisch annehmen

* Neu: Ein Regler für die Verzögerung von 0 bis 10 Sekunden. Bei "Sofort" wird wie bisher direkt angenommen, das bleibt der Standard. Mit Verzögerung hast du während der Wartezeit noch die Möglichkeit, selbst auf den Dialog zu reagieren, und es wird nichts mehr angenommen, wenn du das getan hast.

Warnung zum Verfall der Rückerstattung annehmen

* Neu: Eine dritte Option neben der Kauf- und der Rückerstattungsbestätigung. Sie bestätigt die Warnung, dass ein Gegenstand nicht mehr zurückerstattet werden kann, das Fenster erscheint damit nicht mehr. Deckt alle vier Fälle ab, in denen es auftaucht: Anlegen, Benutzen, Sockeln und Verschicken per Post. Standardmäßig aus, weil diese Warnung die letzte Möglichkeit zum Abbrechen ist.

Mana-Warnung

* Behoben: In Instanzen, in denen das Spiel die Manawerte verbirgt, kam die "kein Mana mehr"-Warnung nie in der Gruppe an. Das Spiel hat sie blockiert, weil sie aus einer seiner eigenen Routinen heraus verschickt wurde. Sie geht jetzt wieder korrekt raus.
* Geändert: Die Warnungen nutzen jetzt die aktuelle Chat-Funktion des Spiels. Die alte bleibt nur noch als Rückfallebene, Blizzard schafft sie ab.
