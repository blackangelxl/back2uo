# Back2UO – Code Review / Findings

## Critical – Script Errors, Mod Toggle & Security

### 1. `back2uo_status 0` does not persist
**File:** `_back2uo_cvars.gsc:316-321`

**DE:**  
Wenn `game["back2uo_enable"]` auf `0` steht, setzt `back2uo_setconfig` die Cvar auf ihren Default-Wert zurück. Für `back2uo_status` ist dieser Default in `main` die `1`.

**Folge:**  
Der Mod lässt sich praktisch nicht abschalten. Zusätzlich werden alle Admin-Cvars und `scr_killcam` überschrieben.

Da der Mod nie wirklich deaktiviert ist, behalten die Feature-Flags ihre Defaults. Hooks, die nur diese Flags prüfen, verändern dadurch weiterhin das Stock-Gameplay:

- Score-HUD fehlt
- Regeneration funktioniert nicht
- Waypoints fehlen

**EN:**  
When `game["back2uo_enable"]` is set to `0`, `back2uo_setconfig` resets the Cvar to its default value. For `back2uo_status`, that default is `1` in `main`.

**Impact:**  
The mod effectively cannot be disabled. In addition, all admin Cvars and `scr_killcam` are overwritten.

Because the mod is never truly disabled, the feature flags retain their default values. Hooks that only check these flags therefore continue to modify stock gameplay:

- Score HUD is missing
- Regeneration does not work
- Waypoints are missing

---

### 2. `self.pers["sprinting"] == true` without `isdefined`
**File:** `_weapons.gsc:913`

**DE:**  
Mit `back2uo_sprint_aktiv 0` gibt es bei jedem Tod einen Script-Error in `Callback_PlayerKilled`. Respawn und Score fallen dabei aus.

**EN:**  
With `back2uo_sprint_aktiv 0`, every death causes a script error in `Callback_PlayerKilled`. Respawning and score handling then fail.

---

### 3. `level.back2uo_voices` exists only when taunts are enabled
**File:** `_back2uo_main.gsc:271`

**DE:**  
Mit `back2uo_tauntsounds_aktiv 0` gibt es bei jedem Treffer bzw. Tod einen Script-Error in `_back2uo_sounds.gsc:147`.

**EN:**  
With `back2uo_tauntsounds_aktiv 0`, every hit or death causes a script error in `_back2uo_sounds.gsc:147`.

---

### 4. Melee damage reads `level.back2uo_melee_strength` before initialization
**Files:** `dm.gsc:361`, similarly in `tdm`/`sd`

**DE:**  
Der Wert wird erst gesetzt, nachdem `back2uo_mapdimension()` gelaufen ist. Diese Funktion wartet pro Entity `0.05 s` und benötigt dadurch mehrere Sekunden.

In dieser Zeit erzeugt jeder Bash einen Script-Error. In SD passiert das zu Beginn jeder Runde.

**EN:**  
The value is initialized only after `back2uo_mapdimension()` has run. This function waits `0.05 s` per entity and therefore takes several seconds.

During this time, every melee bash causes a script error. In SD, this happens at the beginning of every round.

---

### 5. Gore hook reads `attacker.pers["team"]` without `isPlayer`
**Files:** `dm.gsc:554`, similarly in `tdm`/`sd`

**DE:**  
Bei Fall- oder Trigger-Toden gibt es einen Script-Error im Kill-Callback.

**EN:**  
Fall deaths or trigger deaths cause a script error in the kill callback.

---

### 6. Unprotected `endround` menu response
**File:** `_menus.gsc:194`

**DE:**  
Die `endround`-Menu-Response besitzt keinerlei Prüfung. Jeder Client kann mit `mr … endround` die Map beenden.

Der Code stammt vermutlich aus dem Stock-Spiel, ist in dieser Form aber ausnutzbar.

**EN:**  
The `endround` menu response has no permission check. Any client can use `mr … endround` to end the current map.

The code probably originates from the stock game, but in its current form it is exploitable.

---

### 7. `cod2server.cfg` contains insecure defaults
**File:** `cod2server.cfg`

**DE:**  
Folgende Werte werden unverändert in die Distribution übernommen:

- `sv_cheats "1"` – Zeile 104
- `rcon_password "rcon"` – Zeile 35

**EN:**  
The following insecure values are shipped unchanged in the distribution:

- `sv_cheats "1"` – line 104
- `rcon_password "rcon"` – line 35

---

### 8. Sprint swaps to a non-existent weapon
**File:** `_back2uo_sprint.gsc:144-155`

**DE:**  
Nur `panzerschreck_mp` ist ausgenommen. Sprint mit Fernglas in der Hand erzeugt `binoculars_mp_sprint`, das nicht precached ist. Ergebnis: Script-Error.

**EN:**  
Only `panzerschreck_mp` is excluded. Sprinting while holding binoculars produces `binoculars_mp_sprint`, which is not precached. Result: script error.

---

### 9. Weapon selection trusts client input
**File:** `_weapons.gsc:1535ff`

**DE:**  
Im Klassen-Limit-Modus akzeptiert der Server per `mr` eine nicht precachte Waffe. Ergebnis: Script-Error.

Auch „nur Auto-Team“ wird lediglich in der UI erzwungen (`_menus.gsc:246`).

**EN:**  
In class-limit mode, the server accepts a non-precached weapon through `mr`, resulting in a script error.

“Auto Team Only” is also enforced only in the UI (`_menus.gsc:246`).

---

### 10. `openMenu(game["menu_serverinfos"])` when the mod is disabled
**File:** `_menus.gsc:206`

**DE:**  
Bei ausgeschaltetem Mod ist der Wert `undefined`. Dadurch stirbt die Menü-Schleife des Spielers. Danach kann er weder Team noch Waffe wechseln.

**EN:**  
When the mod is disabled, the value is `undefined`. The player's menu loop then terminates, preventing the player from changing teams or weapons.

---

### 11. Regeneration mode compares string with integer
**File:** `_healthoverlay.gsc:281`

**DE:**  
`extra = ""` wird mit `1` verglichen. Dadurch gibt es bei jedem verletzten Spieler einen Script-Error.

**EN:**  
`extra = ""` is compared with `1`, causing a script error whenever a player is injured.

---

## Gameplay Bugs – Medium

### 12. Binocular state can become permanently stuck
**File:** `_back2uo_hudfx.gsc:1884`

**DE:**  
Wird das Fernglas innerhalb von `0.3 s` wieder gesenkt, geht das `binocular_exit`-Event verloren.

`back2uo_playerdo` bleibt anschließend auf `"binocularuse"` hängen.

Bis zum Tod sind dadurch folgende Aktionen gesperrt:

- Bombe legen
- Bombe entschärfen
- Sprint
- Pickups

**EN:**  
If the binoculars are lowered again within `0.3 s`, the `binocular_exit` event is lost.

`back2uo_playerdo` then remains stuck at `"binocularuse"`.

Until the player dies, the following actions are blocked:

- Planting the bomb
- Defusing the bomb
- Sprinting
- Pickups

---

### 13. Turret trigger overwrites plant/defuse state
**File:** `_back2uo_weaponsystem.gsc:1129`

**DE:**  
Der Turret-Trigger setzt `back2uo_playerdo = "turret_use"` und überschreibt dabei `plant` bzw. `defuse`.

**EN:**  
The turret trigger sets `back2uo_playerdo = "turret_use"`, overwriting the `plant` or `defuse` state.

---

### 14. Pickup lock can persist for the rest of the map

**DE:**  
`medi_origin` bzw. `weapon_origin` bleiben am Spieler hängen. Er kann dadurch für den Rest der Map keine Medipacks oder Waffen mehr aufheben.

Pickup-Trigger bedienen außerdem nur einen Spieler pro Tick.

**EN:**  
`medi_origin` / `weapon_origin` remain attached to the player. As a result, the player cannot pick up medkits or weapons for the remainder of the map.

Pickup triggers also process only one player per tick.

---

### 15. Incorrect weapon names in damage table

**DE:**  
`pps42_mp` und `svt40_mp` passen nicht zu den tatsächlichen Namen `PPS42_mp` und `SVT40_mp`.

Ich gehe davon aus, dass Array-Keys case-sensitive sind, wie beim bekannten TT30-Fall.

Außerdem gehört `frag_grenade_*_cookable` zu keiner existierenden Waffe. Die echten Varianten heißen `_special1` und `_special2`.

**EN:**  
`pps42_mp` and `svt40_mp` do not match the actual weapon names `PPS42_mp` and `SVT40_mp`.

I assume array keys are case-sensitive, as in the known TT30 case.

Also, `frag_grenade_*_cookable` does not correspond to an existing weapon. The actual variants are `_special1` and `_special2`.

---

### 16. Taunt aliases are incorrectly numbered

**DE:**  
Die CSV nummeriert die Stimmen `0..3`, der Code baut jedoch `1..4`. Der Fix aus den bekannten Notes reicht daher nicht aus.

Zusätzlich wird die Taunt-Stimme vom Opfer statt vom Angreifer gelesen.

**EN:**  
The CSV numbers the voices `0..3`, while the code generates `1..4`. Therefore, the fix from the existing notes is insufficient.

Additionally, the taunt voice is read from the victim instead of the attacker.

---

## Artillery

### 17. Artillery ignores Friendly-Fire modes 2/3

**DE:**  
Die Artillerie ignoriert Friendly-Fire-Modus `2/3`.

Das Team wird erst beim Einschlag gelesen. Nach einem Teamwechsel des Callers kann die Artillerie daher die alten Teamkameraden treffen.

Sie trifft außerdem Spectators und tote Spieler.

**EN:**  
Artillery ignores Friendly-Fire modes `2/3`.

The team is only checked when the shell impacts. If the caller changes teams before impact, the artillery can therefore hit their former teammates.

It can also hit spectators and dead players.

---

### 18. `fall_time` has no lower bound

**DE:**  
`fall_time` hat keine Untergrenze. Ist der Wert `0`, schlägt `moveto(…, 0)` fehl.

**EN:**  
`fall_time` has no lower bound. If the value is `0`, `moveto(…, 0)` fails.

---

### 19. Aircraft crash does not delete the aircraft

**DE:**  
`notify("end_airplanefly")` beendet den eigenen Thread, bevor `delete()` ausgeführt wird.

Das Flugzeug fliegt dadurch einfach weiter.

**EN:**  
`notify("end_airplanefly")` terminates its own thread before `delete()` is executed.

As a result, the aircraft simply continues flying.

---

## Other Gameplay Bugs

### 20. Rank downgrade does not reset ranking value

**DE:**  
`pers["back2uo_ranking"]` wird beim Rang-Abstieg nicht auf `1` gesetzt. Nach dem Wiederaufstieg gibt es deshalb keine Rang-Belohnung.

**EN:**  
`pers["back2uo_ranking"]` is not reset to `1` when a player is demoted. After ranking up again, the player therefore receives no rank reward.

---

### 21. Grenade rewards duplicate grenades

**DE:**  
Granaten-Belohnungen duplizieren Granaten.

**EN:**  
Grenade rewards duplicate grenades.

---

### 22. Spawn-protection thread lacks `endon("killed_player")`

**DE:**  
Der Spawn-Protection-Thread besitzt kein `endon("killed_player")`. Der alte Thread kann dadurch den Schutz des neuen Lebens abbrechen.

**EN:**  
The spawn-protection thread has no `endon("killed_player")`. The old thread can therefore terminate the protection of the player's new life.

---

### 23. Damage and helmet save run before FF/spawn-protection checks

**DE:**  
Schaden und Helm-Save laufen vor dem FF-/Spawnschutz-Return.

Ein Teamkamerad kann dadurch den Helm des Spielers abschlagen und dessen einmaligen Helm-Save verbrauchen, obwohl der Schaden eigentlich ignoriert werden müsste.

**EN:**  
Damage and helmet-save handling occur before the Friendly Fire / spawn-protection return.

A teammate can therefore knock off the player's helmet and consume their one-time helmet save even though the damage itself should have been ignored.

---

### 24. Suicide penalty also applies during team switching

**DE:**  
`switching_teams` wird bei der Suicide-Strafe nicht geprüft.

**EN:**  
`switching_teams` is not checked when applying the suicide penalty.

---

### 25. Sniper/shotgun limit has an off-by-one error

**DE:**  
Gesperrt wird bei `>`. Korrekt wäre `>=`.

Der Limiter erzwingt außerdem `scr_allow_* = 1` und überschreibt damit Admin-Werte.

**EN:**  
The weapon is blocked using `>`. The correct comparison should be `>=`.

The limiter also forces `scr_allow_* = 1`, overriding administrator settings.

---

### 26. Map rotation is reshuffled on every start

**DE:**  
Die Map-Rotation wird bei jedem Start neu gemischt, in SD sogar in jeder Runde.

Dadurch läuft die Rotation nie normal weiter.

**EN:**  
The map rotation is reshuffled on every startup, and in SD even every round.

As a result, the rotation never progresses normally.

---

### 27. Vote Cvars only modify `ui_allowvote*`

**DE:**  
Die Vote-Cvars setzen nur `ui_allowvote*`. `g_allowvote*` bleibt `1`.

Dadurch funktioniert beispielsweise `/callvote kick` weiterhin.

**EN:**  
The vote Cvars only modify `ui_allowvote*`. `g_allowvote*` remains `1`.

As a result, commands such as `/callvote kick` continue to work.

---

### 28. `back2uo_artillery_onrang 0` does not disable artillery

**DE:**  
Laut CFG soll `back2uo_artillery_onrang 0` „Keine“ bedeuten.

Der Code klemmt den Wert jedoch auf `1`. Artillerie gibt es dadurch bereits ab dem niedrigsten Rang.

**EN:**  
According to the CFG, `back2uo_artillery_onrang 0` should mean “None”.

However, the code clamps the value to `1`, making artillery available from the lowest rank.

---

## Leaks / Thread Accumulation – Low to Medium

### 29. Dropped weapon triggers, artillery shells and sound entities are never deleted

**DE:**  
Gedroppte Waffen-Trigger, Artillerie-Shells und Sound-Entities bei Disconnect werden nie gelöscht.

Auch der Container in `back2uo_getmaprotation` wird nicht gelöscht.

Langfristig kann dies zum Entity-Limit von `1024` führen.

**EN:**  
Dropped weapon triggers, artillery shells and sound entities created during disconnects are never deleted.

The container in `back2uo_getmaprotation` is also never deleted.

Over time, this can lead to the `1024` entity limit being reached.

---

### 30. Spectator switching creates accumulating threads

**DE:**  
Bei jedem Wechsel zum Spectator wird ein neuer `teamscore_update`-Thread gestartet.

Dadurch können sich Healthbar-Glow- und Blood-Splatter-Threads überlagern.

**EN:**  
Every switch to spectator starts a new `teamscore_update` thread.

This can cause Healthbar Glow and Blood Splatter threads to accumulate and overlap.

---

### 31. Camper objective slots are recycled without occupancy checks

**DE:**  
Camper-Objective-Slots werden ohne Belegt-Prüfung recycelt.

Nach einem Disconnect kann das Camper-Icon stehen bleiben.

**EN:**  
Camper objective slots are recycled without checking whether they are occupied.

After a disconnect, the camper icon can remain visible.

---

## Config / Documentation

### 32. `cod2set` fade values do not match the documented range

**DE:**  
`cod2set`-Fade-Werte haben im Code ein Maximum von `1`, während die CFG `0.1–30 s` angibt.

**EN:**  
`cod2set` fade values have a maximum of `1` in the code, while the CFG specifies `0.1–30 s`.

---

### 33. Typo in `cg_hudObjectiveMinHeigth`

**DE:**  
`cg_hudObjectiveMinHeigth` enthält vermutlich einen Tippfehler.

**EN:**  
`cg_hudObjectiveMinHeigth` appears to contain a typo.

---

### 34. Range mismatches between CFG and code

**DE:**  
Es gibt mehrere Abweichungen zwischen CFG und Code:

- `mpoints`: Code-Maximum `5` statt `10`
- Munition: Code-Maximum `99` statt `999`

**EN:**  
There are several range mismatches between the CFG and the code:

- `mpoints`: code maximum `5` instead of `10`
- Ammunition: code maximum `99` instead of `999`

---

### 35. Several Cvars are missing from the CFGs

**DE:**  
Mehrere Cvars fehlen in den CFG-Dateien, unter anderem:

- `back2uo_mapvote_*`
- `back2uo_airplanes_crash`

**EN:**  
Several Cvars are missing from the CFG files, including:

- `back2uo_mapvote_*`
- `back2uo_airplanes_crash`

---

### 36. Map-vote feature is dead code

**DE:**  
Das Map-Vote-Feature ist toter Code.

**EN:**  
The map-vote feature is dead code.

---

### 37. `scr_allow_shotgun` is not read

**DE:**  
`scr_allow_shotgun` wird nicht gelesen.

Außerdem steht `pb_sv_disable` ohne Wert in der CFG.

**EN:**  
`scr_allow_shotgun` is never read.

Additionally, `pb_sv_disable` is present in the CFG without a value.

---

## Strings / Localization

### 38. Missing strings

**DE:**  
Folgende Strings fehlen:

- `WEAPON_UNKNOWNWEAPON`
- `MP_AMERICAN`
- `MP_BRITISH`
- `MP_RUSSIAN`
- `BACK2UOMOD_BINOCULAR_NONE`

**EN:**  
The following strings are missing:

- `WEAPON_UNKNOWNWEAPON`
- `MP_AMERICAN`
- `MP_BRITISH`
- `MP_RUSSIAN`
- `BACK2UOMOD_BINOCULAR_NONE`

---

### 39. Missing German localization

**DE:**  
`pc_patch_1_1.str` fehlt für Deutsch.

**EN:**  
`pc_patch_1_1.str` is missing for the German localization.

---

### 40. Duplicate strings

**DE:**  
`KILLCAM` und `SCOPEDG43` stehen doppelt.

**EN:**  
`KILLCAM` and `SCOPEDG43` are duplicated.