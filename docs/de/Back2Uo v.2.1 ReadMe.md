# Back2Uo Mod v.2.1 ReadMe - Deutsch

## Einleitung

Vielen Dank für dein Interesse und deine Unterstützung für die Back2UO Mod für Call of Duty 2.

Back2UO ist eine Call of Duty 2 Modifikation, die Kernelemente des ursprünglichen
Gameplays aus CoD United Offensive übernimmt und in CoD 2 einbaut.
Zum Beispiel das Heads-up-Display, Funktionen, Atmosphäre und viele Effekte.

Dieses ReadMe beschreibt den **v.2.1 Rebuild**. Der Quellcode ist auf GitHub verfügbar:
<https://github.com/blackangelxl/back2uo>

## Inhalt

1. Installation
2. Einstellungen
3. Bekannte Mod-Bugs
4. Nutzungsbedingungen
5. Herstellerangaben
6. Kontakt

## 1.) Installation

- Erstelle im Call of Duty 2 Hauptverzeichnis einen Ordner mit dem Namen `back2uo`.
- Kopiere die folgenden Back2Uo Mod Dateien in diesen Ordner:

**Back2Uo v.2.1 Dateien:**

| Datei | Inhalt |
|-------|--------|
| `z_back2uo_2.1_client.iwd` | Menüs, Bilder, Effekte, Waffen, Sounds (Client) |
| `z_svr_back2uo_2.1.iwd` | Server-Skripte |
| `z_svr_back2uo_2.1_libcod.iwd` | zk_libcod Funktionen (nur für Server mit zk_libcod, siehe unten) |
| `localized_english_iw15.iwd` | Englische Texte und Sounds |
| `localized_german_iw15.iwd` | Deutsche Texte und Sounds |
| `mp_dawnville_cl.iwd` | Map Dawnville Classic |
| `back2uomod.cfg` | Alle Mod-Einstellungen |
| `cod2server.cfg` | Beispiel-Serverconfig |
| `maprotation.cfg` | Beispiel-Maprotation |
| `zk_libcod.cfg` | Einstellungen für zk_libcod (nur für Server mit zk_libcod) |

Um den Server mit der Back2Uo Mod zu starten, wird dieser Parameter benötigt:

**Server-Parameter:**

```
+set fs_game back2uo +exec cod2server.cfg
```

> **Hinweis:**
>
> - Um eigene Einstellungen in der `back2uomod.cfg` zu nutzen, muss sie aus der eigenen
>   `cod2server.cfg` geladen werden (`exec back2uomod.cfg`).
> - Wird die Back2Uo Config nicht geladen, startet die Back2UO Mod immer mit den
>   Standardeinstellungen.
> - Wichtig ist, dass `localized_english_iw15.iwd` und `localized_german_iw15.iwd`
>   im Ordner liegen. So kann jeder Spieler unabhängig von seiner Spielversion spielen,
>   mit den passenden Sounds, Grafiken und Texten in seiner Sprache.
> - Clients laden die Mod über den Auto-Download herunter (`sv_allowDownload "1"`).

### zk_libcod

Die Mod nutzt [zk_libcod](https://github.com/ibuddieat/zk_libcod), wenn es auf dem Server installiert ist.

- **Server mit zk_libcod:** `z_svr_back2uo_2.1_libcod.iwd` behalten und `zk_libcod.cfg`
  aus der Serverconfig laden (`exec zk_libcod.cfg`).
- **Server ohne zk_libcod:** `z_svr_back2uo_2.1_libcod.iwd` löschen, sonst lassen sich
  die Skripte nicht kompilieren. Die Mod nutzt dann ihre Ersatzfunktionen:
  - Beim Sprinten wird auf eine Sprint-Waffe gewechselt, statt die Spielergeschwindigkeit zu erhöhen.
  - Test-Bots stehen still.
  - zk_libcod Funktionen wie Bullet Drop (`g_bulletDrop`) sind nicht verfügbar.

### Cod2server.cfg

- Gerne kann unsere vordefinierte CoD 2 Serverconfig genutzt werden. Sie lädt bereits
  `zk_libcod.cfg`, `back2uomod.cfg` und `maprotation.cfg`.
- Wer eine eigene Config nutzt, MUSS darin diese Parameter setzen:

**Anweisungen:**

```
set com_hunkMegs "512"
set g_logsync "2"    // 0 = kein Log, 1 = gepuffert, 2 = fortlaufend, 3 = anhängen
set logfile "1"
set g_log "games_mp.log"

exec zk_libcod.cfg   // nur mit zk_libcod
exec back2uomod.cfg
exec maprotation.cfg
```

> **Hinweis:**
>
> - Ohne diese Befehle kann es zu Performance-Problemen kommen.
> - Bei Fehlern im Zusammenhang mit der Config – die Logdateien prüfen.

## 2.) Einstellungen

Hier folgen Details zu den Funktionen der Mod. Jede Einstellung in der `back2uomod.cfg`
hat einen Kommentar mit den erlaubten Werten und dem Standardwert.

### Back2Uo Mod Einstellungen

**Back2Uo Mod Setup:**

- Hier lässt sich die Mod mit allen Funktionen und Einstellungen ein- oder ausschalten
  (`back2uo_status`).

**Debug:**

- `back2uo_development` aktiviert Entwicklungs- und Testfunktionen.
- `back2uo_logprint` schreibt Mod-Ereignisse (`B2U;...`) in das Serverlog,
  optional mit Funktions-Trace.
- Beides sollte auf einem öffentlichen Server ausgeschaltet sein.

**Admin-Befehle:**

- Mit `back2uo_admin_password` wird ein Admin-Passwort gesetzt. Ein leeres Passwort
  schaltet die Befehle aus.
- Die Befehle werden in der Spielerkonsole eingegeben:

```
/openscriptmenu -1 b2u_artillery:<passwort>           Gibt dir selbst einen Artillerieschlag
/openscriptmenu -1 b2u_airplanes:<anzahl>:<passwort>  Startet einen Flugzeug-Überflug (0 = Anzahl aus back2uo_airplanes_max_count | 1 -> 6)
/openscriptmenu -1 b2u_mortar:<passwort>              Startet einen Mörserbeschuss
/openscriptmenu -1 b2u_ambtracer:<passwort>           Startet eine Welle Ambience-Flakfeuer
/openscriptmenu -1 b2u_thunderfx:<passwort>           Spielt einen Blitz mit Donner ab
/openscriptmenu -1 b2u_rainfx:<passwort>              Regen an / aus für die aktuelle Runde (ersetzt Schnee)
/openscriptmenu -1 b2u_snowfx:<passwort>              Schnee an / aus für die aktuelle Runde (ersetzt Regen)
```

- Nach 3 falschen Passwörtern ist der Spieler für die aktuelle Map von den Befehlen gesperrt.

**Test-Bots:**

- Test-Bots zum Testen der Mod, z. B. im LAN oder auf einem Testserver (`back2uo_testbots_aktiv`,
  `back2uo_testbots`).
- Die Bots laufen auf den Standard-Maps und Dawnville Classic entlang von Waypoints, klettern,
  springen und kämpfen wie Spieler, inklusive Nahkampf.
- Der Bot-Skill (Reaktion, Zielen und Drehgeschwindigkeit) lässt sich von 1 = Leicht bis
  3 = Schwer einstellen (`back2uo_testbots_skill`).
- Bots bekommen Namen, die zu ihrem Team passen.
- Die Test-Bots benötigen zk_libcod. Ohne zk_libcod stehen sie still.

**Back2Uo Auto-Download Info:**

- Hier lassen sich Spieler fernhalten, die den Auto-Download in COD 2 nicht aktiviert haben.
  Diese Spieler erhalten eine Warnmeldung und werden automatisch vom Server gekickt.

**Client-Einstellungen:**

- Diese enthalten Standardeinstellungen für Clients, die sich mit dem Server verbinden.

Einstellungen:

```
cg_errordecay           -> "100"
cg_fov                  -> "80"
cg_hudDamageIconHeight  -> "64"
cg_hudDamageIconInScope -> "0"
cg_hudDamageIconOffset  -> "128"
cg_hudDamageIconTime    -> "2000"
cg_hudDamageIconWidth   -> "128"
cg_hudObjectiveMaxRange -> "2048"
cg_hudObjectiveMinAlpha -> "1"
cg_hudObjectiveMinHeigth -> "-70"
cg_thirdperson          -> "0"
fx_sort                 -> "1"
```

**Zufällige Maprotation:**

- Wenn aktiviert, werden die Maps der Rotation in zufälliger Reihenfolge gespielt.

### COD 2 Elemente

**Fadenkreuz-Anzeigen:**

- Fadenkreuz, Geschütz-Fadenkreuz, Namen über dem Fadenkreuz, Mini-Fadenkreuz und
  rotes Fadenkreuz ein- oder ausschalten.

**Spieler-Kopf-Icons:**

- Alle Icons, die über dem Kopf eines Spielers erscheinen, ein- oder ausschalten.

**Elemente:**

- Anzeigen konfigurieren, die im Spieler-HUD oder an Wänden sichtbar sind.

**HUD-Elemente:**

- Alle Standard-HUD-Elemente von COD 2 konfigurieren.

**Map-Ambience-Effekte:**

- Alle Ambience-Effekte der Maps konfigurieren.

**Map Kill Trigger:**

- Seit Patch v.1.2 enthält COD 2 einen Kill Trigger. Er verhindert, dass ein Spieler auf
  einer unerlaubten Position steht oder sich dorthin bewegt, z. B. auf ein Dach, einen Baum,
  ins Feuer usw.
- Statt die Spieler zu töten, kann ihnen auf diesen Bereichen Energie abgezogen werden.

**Spielmodi:**

- Legt die Respawn-Zeit für Headquarters und Capture the Flag fest.

### COD 2 Menü

**Automatische Teamwahl:**

- Die Teamwahl der Spieler erfolgt automatisch.

**Back2Uo Server-Informationen:**

- Zeigt nach dem Verbinden eines Spielers das Server-Informationsmenü an.

**Back2Uo Favoriten-Menü:**

- Ein zusätzlicher Menüpunkt, über den Spieler den Server zu ihrer Favoritenliste
  hinzufügen können.

**Abstimmungssystem:**

- Das Abstimmungssystem konfigurieren (Map-Neustart, nächste Map, Map, Spielmodus, Spieler kicken).

### Nachrichtensystem

**Clan- & Willkommensnachrichten:**

- Mit diesen Einstellungen lassen sich eigene Nachrichten festlegen.

z. B.:

```
set back2uo_clanm_0                "Nachricht 1"
set back2uo_clanm_1                "Nachricht 2"
```

- Für weitere Nachrichten einfach Zeilen hinzufügen und nur die Endnummer erhöhen
  (z. B. `set back2uo_clanm_2`, `_3`, `_4` usw.).

**Server-Nachrichten:**

- Zeigt den Servernamen, einen Slogan oder ein Banner an.

**Spieler-Status-Nachrichten:**

- Zeigt allen Spielern eine Nachricht an, wenn ein Spieler den Server betritt oder verlässt.

**Nächste-Map-Nachricht:**

- Steuert die Anzeige der nächsten Map / des nächsten Spielmodus im Spiel.

### Wetter-Ambience-System

**Wettereffekt-System:**

- Stärke und Wahrscheinlichkeit / Häufigkeit der Wettereffekte einstellen.
- Hohe Werte können zu Performance- und Stabilitätsproblemen für den Server oder die
  Spieler führen.

**Gewitter- & Wintereffekt:**

- Steuert die Ambience-Effekte abhängig von der Map – z. B. Schnee -> Winter-Maps.

### Kriegs-Ambience-System

**Kriegseffekte:**

- Die Kriegsatmosphäre-Effekte einstellen.
- Hohe Werte können zu Performance- und Stabilitätsproblemen für den Server oder die
  Spieler führen.

**Mörsereffekte:**

- Setzt Mörser auf einer Map und konfiguriert sie (Anzahl, Warnsound, Erdbeben,
  Schaden, Radius und Stärke).

**Flugzeugeffekte:**

- Setzt Flugzeugeffekte und konfiguriert sie (Anzahl, Flak).
- Von der Flak getroffene Flugzeuge können abstürzen (`back2uo_airplanes_crash`).
- Auf kleinen Maps fliegen keine Flugzeuge.

**Ambience-Flakfeuer:**

- Setzt Flakfeuer und die Anzahl der Flakgeschütze.

> **Hinweis:** Bei den Anzahlen (`*_max_count`) bedeutet der Wert `0` eine zufällige Anzahl.

### Erkennungs- | Schutzsystem

**AFK-Erkennung:**

- Verschiebt einen Spieler in den Zuschauermodus, wenn er AFK (away from keyboard) ist.

**Camper-Schutz:**

- Zeigt Camper auf dem Kompass an.
- Diese Option wird nur für Deathmatch & Team Deathmatch empfohlen.

**Spawn-Schutz:**

- Schützt neu gespawnte Spieler für eine bestimmte Zeit vor Schaden durch Artillerie
  oder andere Spieler.
- Optional endet der Schutz, sobald sich der Spieler bewegt oder eine Aktion ausführt.

### Blutsystem

**Bluteffekte:**

- Einstellung der Bluteffekte und Blutlachen nach dem Tod eines Spielers.

### Spieler-Sounds

**Sprüche & Sounds:**

- Einstellung der Sounds bei Treffern oder Tod eines Spielers, der Sprüche und der
  Granatenwarnungen. Diese Sounds können gemeinsam abgespielt werden.

### Punktesystem

**Ranking Plus- oder Minuspunkte:**

- Einstellung der Plus- oder Minuspunkte für bestimmte Aktionen oder Situationen im Spiel
  (Selbstmord, Teamkill, Bombe legen / entschärfen, Runde überleben,
  Flagge erobern / verteidigen).

### HUD-Anzeigen

**HUD-Anzeige:**

- HUD-Fx-Icon
  - Zeigt im HUD an, ob Ambience-Effekte wie Regen oder Mörser aktiv sind.
- Spielerposition
  - Erweitert die Standard-Positionsanzeige um die aktuelle Haltung des Spielers.
    Zusätzlich wird beim Sprinten die Ausdauer angezeigt.

**HUD-Punkteanzeige:**

- Wahl einer Punkteanzeige für Deathmatch oder für Team Deathmatch (zeigt mehr Details
  als DM, z. B. wie viele Spieler noch leben).

**HUD-Objektanzeige:**

- Fernglas-Entfernung
  - Hilft beim Zielen mit der Artillerie über das Fernglas – zeigt die Entfernung zum
    Ziel in Metern.
- Treffer-Entfernung
  - Zeigt die Entfernung zum Opfer und das Körperteil, an dem der Kill erfolgte.

### Spieler-Energiesystem

**Energieanzeige:**

- Legt fest, ob eine Lebensanzeige angezeigt wird.

**Energieverhalten:**

- Legt fest, ob die Lebensenergie eines Spielers reduziert bleibt (realistisch) oder sich
  wieder regenerieren darf.

**Fallschaden:**

- Legt fest, wie viel Lebensenergie abgezogen wird, wenn ein Spieler aus einer minimalen
  oder maximalen Höhe auf den Boden fällt.

**Medipacks:**

- Einstellung der Medipacks bei Verletzung / Tod – jeder Spieler füllt seine Energie über
  diese Packs auf. Verletzung / Tod hängen davon ab, wodurch der Spieler verletzt wird:
  durch andere Spieler, Artillerie oder Sturz.
- Medipacks werden automatisch oder durch Drücken der 'Benutzen'-Taste aufgenommen
  (`back2uo_medipacks_pickup`).

**Helm-Popping:**

- Legt fest, ob Spielerhelme bei einem Kopftreffer davonfliegen.
- Außerdem lässt sich einstellen, ob Spieler indirekte Kopftreffer überleben können.

### Sprintsystem

**Spieler-Sprint (Rennen):**

- Legt fest, ob Spieler sprinten können.
- Der Sprint funktioniert wie in COD United Offensive.

**Sprint-Modus:**

- `back2uo_sprint_mode "1"`: Der Sprint erhöht die Spielergeschwindigkeit
  (`back2uo_sprint_speedscale` x `g_speed`). Das benötigt zk_libcod; ohne zk_libcod wird
  der Waffenwechsel als Ersatz genutzt.
- `back2uo_sprint_mode "0"`: Der Spieler wechselt beim Sprinten auf eine Sprint-Waffe.

**Zusätzliche Infos:**

- Gesprintet wird durch Halten der 'Benutzen'-Taste, standardmäßig 'F'.
- Sprinten ist nur in Bewegung möglich. Nicht, wenn ein Spieler das Fernglas oder ein
  Geschütz benutzt, sitzt, auf einer Leiter ist, liegt oder hockt oder eine Bombe legt /
  entschärft.
- Wie in COD UO wird der Spieler nach dem vollen Sprintlimit müde und kann erst wieder
  sprinten, wenn sich die Sprintanzeige aufgefüllt hat. Nach einem vollen Sprint keucht der
  Spieler und ist außer Atem. Dieses Geräusch können andere Spieler hören.

### Ranking-System

**Ranking-Status:**

- Legt fest, ob das Ranking-System aktiv ist. Ränge bringen Belohnungen und werden im
  Spiel angezeigt.

**Ranking-Anzeigen & Sounds:**

- Legt fest, ob Rang-Ansagen angezeigt und abgespielt werden und ob Rang-Icons auf dem
  Scoreboard und über Teammitgliedern angezeigt werden.

**Ranking-Stufen:**

- Legt die Punktzahl fest, die für einen Rangaufstieg nötig ist.
- Wie in COD UO gibt es 5 Ränge, die ein Spieler erreichen kann.

**Ranking über Höchststufe (maximaler Rang erreicht):**

- Ermöglicht, dass einem Spieler nach Erreichen des höchsten Rangs Artillerie zur
  Verfügung steht.

**Belohnungen Rang 1 -> 4:**

- Legt fest, welche Belohnung ein Spieler beim Erreichen eines bestimmten Rangs erhält.
- Die Belohnung wird nach jeder Runde vergeben.
- Ein Rangabstieg wird entsprechend berücksichtigt.

**Rangzuweisung:**

- Legt fest, ab welchem Rang ein Spieler das Fernglas und die Möglichkeit erhält,
  Artillerieunterstützung anzufordern.

**Artillerie-Befehl:**

- Konfiguriert die Artillerie (Anzahl der Einschläge, Befehls- und Warnmeldungen,
  Warnradius vor Selbstbeschuss).

Info:

- Die Artillerie wird aktiviert, indem man mit dem Fernglas auf das Ziel zielt (schaut)
  und die 'Benutzen'-Taste drückt.
- Die Artillerie kann nur abgefeuert werden, wenn eine Entfernung / ein Wert angezeigt wird.
  - Die Artillerie kommt immer aus der Gegenrichtung des zielenden Spielers,
    d. h. zielt der Spieler nach Norden, kommt die Artillerie aus dem Süden.
  - Spieler unter Spawn-Schutz können von der Artillerie nicht verletzt werden.
  - Die Artillerie gilt nicht als Friendly Fire: Bei "0" wirkt sie, bei "1 -> 3" sind
    eigene Teammitglieder geschützt.
  - Wechselt ein Spieler zu den Zuschauern, verfällt ein nicht genutzter Artillerieschlag.

### Waffensystem

**Waffensystem:**

- Legt fest, ob die Waffenoptimierung im Spiel aktiv ist.

**Waffentyp-Auswahl:**

- Hier wird festgelegt, welcher Waffentyp zur freien Auswahl steht
  (alle, nur MGs, nur Gewehre, nur Scharfschützengewehre, nur Pistolen).
  - Das ändert das Waffenauswahlmenü.

**Waffensystem Extra:**

- Eine Zusatzoption zum erlaubten Waffentyp. Im Pistolen-Modus gibt es unendlich
  Munition für Pistolen.

**Waffen erlauben:**

- Hier lassen sich bestimmte Spielerwaffen oder Map-Waffen im Spiel erlauben oder
  deaktivieren.
- Außerdem lassen sich 2 neue Waffen erlauben: das G43 Sniper und der Panzerschreck.
  Diese erscheinen dann auch im Waffenmenü.

**Waffenlimits:**

- Hier lassen sich bestimmte Waffen pro Team begrenzen,
  z. B. 1 Sniper & 1 Schrotflinte pro Team.

**Granatensystem:**

- Hier lässt sich die maximale Anzahl an Granaten und Rauchgranaten für Spieler
  einstellen.

**Spezialausrüstung:**

- Ändert die Granaten und Rauchgranaten, z. B. kürzere Wurfweite oder Granaten,
  die man "kochen" kann.

**Waffenstärke:**

- Ändert die Stärke von Waffen oder einer Aktion, z. B. einem Schlag mit der Waffe.
  - 100 % entsprechen dem normalen Schaden der Waffe oder Aktion.
    Je kleiner der Prozentwert, desto kleiner der Schaden.

**Bullet Drop:**

- Mit zk_libcod können Kugeln von der Schwerkraft beeinflusst werden (`g_bulletDrop` und
  `g_bulletDropMaxTime` in der `zk_libcod.cfg`).

## 3.) Bekannte Mod-Bugs

**Rote Kompasspunkte (bei Feindfeuer):**

- Die roten Punkte auf dem Kompass, die Feindfeuer anzeigen, werden absichtlich durch die
  Datei `compassping_enemyfiring` im Ordner `materials/` der `z_back2uo_2.1_client.iwd`
  ausgeblendet.
- Diese Grafikdatei überschreibt den Originaleffekt.
- Um die roten Punkte auf dem Kompass wieder zu aktivieren, diese Datei im Ordner
  `materials/` der `z_back2uo_2.1_client.iwd` entfernen oder umbenennen.
- Die `*.iwd` Datei lässt sich einfach mit WinRar, WinZip oder 7-Zip öffnen und bearbeiten.

**Custom Maps:**

- Da Back2Uo eigene Skripte, Modelle, Sounds usw. verwendet, können wir keine Gewähr
  oder Garantie geben, dass Custom Maps mit dieser MOD kompatibel sind.
- Viele Custom Multiplayer Maps haben eigene Skripte für Map-Effekte usw., die zu
  Problemen mit der Back2Uo Programmierung führen können.
- Außerdem kann es sein, dass manche Maps so viele Modelle enthalten, dass sie zusammen
  mit der Back2Uo Mod das maximale Modell-Limit der COD 2 Engine überschreiten und den
  Fehler `G_ModelIndex: overflow` erzeugen.

**Waffenstärke-Einstellung (Geschütze):**

- Wegen eines Problems in der CoD 2 Engine wirkt die Waffenstärke manchmal nicht auf
  Geschütze.

## 4.) Nutzungsbedingungen

Die Back2Uo Mod darf auf jedem COD Server genutzt und eingesetzt werden.
Das Entfernen, Verändern oder Verunstalten der MOD sowie Urheberrechtsverletzungen sind
verboten. Der Copyright-Hinweis muss sichtbar, vollständig und in der Originalform ohne
jegliche Änderungen erhalten bleiben.
Änderungen an Skripten und Funktionen sowie die Anpassung und Erweiterung gewünschter
Funktionen liegen im Ermessen des Nutzers und erfolgen auf eigenes Risiko. Auch diese
Änderungen unterliegen weiterhin dem Urheberrecht.

Änderungen, Add-ons, Bugfixes usw. dürfen ohne ausdrückliche Erlaubnis der unten
genannten Entwickler nicht weiterverbreitet, weitergegeben oder verteilt werden.

Es gibt keine Gewähr oder Garantie für die Kompatibilität mit anderen Mods.
Die Nutzung der Back2Uo Mod zusammen mit anderen Mods kann zu Datenverlust,
Fehlern, Performance-Problemen oder Systemabstürzen führen.

Das Back2Uo Team übernimmt keine Haftung oder Verantwortung für Schäden, die durch die
Installation der Back2Uo Mod entstehen. Die Nutzung der Back2Uo Mod erfolgt auf EIGENES
Risiko des Betreibers / Nutzers.

## 5.) Entwickler- und Herstellerangaben

**Der Ersteller:**

- [GCF]Wulf

**Die Assistenten:**

- [LE|Style]Lejack
- -]GCF[-Tool

**Danke:**

- Mein größter Dank geht an meine Kollegen vom -]GCF[-Team, die mir immer beim Testen,
  Übersetzen und bei der Entwicklung der MOD geholfen haben.
- Danke an die Jungs von der GFM Mod für den guten Infoaustausch.
- Danke auch an die super Website iwnation.com.
- Vielen Dank an COD Infobase (cod.esgnserver2.de) für die fortlaufende
  'gute Mod'-Werbung & Unterstützung.
- Vielen Dank an den CODW Clan (codw.net), der uns einen Testserver für die Entwicklung
  und das Testen von Back2Uo gesponsert hat.
- Und natürlich auch Danke an alle Back2Uo Fans, die gutes Feedback gegeben und die
  Entwicklung der MOD unterstützt haben.
- Großer Dank an Tabbycat alias Paul Gallagher für die super Übersetzung.

**Grüße:**

- Ein besonderer Gruß geht an den Ex-Back2Uo Mitarbeiter 'RaZor'. Leider ist dieser „In Erinnerung an einen ‚guten Mitarbeiter & Freund'“.

## 6.) Kontakt

Bei Problemen mit der Installation, der Einrichtung oder beim Spielen der Back2Uo Mod
bitte ein Issue auf GitHub eröffnen:

**GitHub:** <https://github.com/blackangelxl/back2uo>

Wer sich für die Back2Uo Mod interessiert, die Entwickler kennenlernen oder einfach eine
Runde mit uns spielen möchte… besucht uns einfach auf unserer Gamers Club Formation
Homepage.

**Homepage:** <http://www.gcf-team.de>
