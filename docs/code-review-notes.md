# Code review notes (v2.1)

Suspected bugs found while documenting the scripts. **None of them are fixed** in this
release. The code is byte-for-byte the original v2.1 logic. Some places carry a `Note:` comment in the source.
Line numbers are approximate. Paths are relative to `back2uo/z_svr_back2uo_2.1/`.

## Likely to affect gameplay

| Where | Problem |
|-------|---------|
| `maps/mp/mp_*_fx.gsc`, `maps/mp/_killtriggers.gsc` | `back2uo_setconfig("back2uo_status", 0, 0, 1)` defaults the mod switch to **0**, while `_back2uo_main.gsc` defaults it to 1. The map FX script runs first. If `back2uo_status` is not set in the config, the mod starts disabled. |
| `back2uo/_back2uo_weaponsystem.gsc` ~178 | Cvar typo `back2uo_weaponstrh_kar98k_sniper` (cfg uses `back2uo_weaponstr_...`). The Kar98k sniper damage setting is ignored. |
| `back2uo/_back2uo_weaponsystem.gsc` ~164 | Strength key `"rocketlancher_mp"` is not a real weapon (`panzerschreck_mp`). The rocket launcher damage setting never applies. |
| `back2uo/_back2uo_weaponsystem.gsc` ~394 | `back2uo_snipershotgun_limiter` resets its counters inside the per-player loop. The sniper/shotgun team limits do not work. |
| `back2uo/_back2uo_weaponsystem.gsc` ~535 | The branch that should re-enable the allied shotgun sets it to `"0"` (copy/paste). |
| `back2uo/_back2uo_warfx.gsc` ~1547 | `back2uo_artillery_damage` uses `return` instead of `continue` on a teammate. With friendly fire off, players after the first teammate in range take no damage. |
| `back2uo/_back2uo_warfx.gsc` ~434, ~1650 | `pc >= 25 < 50` is always true. Voice variants 2/3 never play. |
| `back2uo/_back2uo_warfx.gsc` ~341, ~950, ~1508 | `randomint(1)` is always 0. One plane roll direction never happens, and the delay is always 0.5. |
| `back2uo/_back2uo_hudfx.gsc` ~1797 | `x = thread func()` returns nothing. The once-per-rank artillery guard does not work. |
| `back2uo/_back2uo_hudfx.gsc` ~1707 | Rank ammo reward: the counter always increments, clip ammo is added to the reserve, and the "binocular" reward calls `takeWeapon`. |
| `back2uo/_back2uo_tools.gsc` ~1070 | `back2uo_playerpoints_system("bomb_defense")` has no matching case. The bomb-defense bonus is always 0. |
| `back2uo/_back2uo_sounds.gsc` | `taunt_person` is `randomint(3)` (0..2), but the alias builder expects 1..4. Person 0 plays `""`, variant 4 never plays. |
| `back2uo/_back2uo_main.gsc` | `back2uo_sprint_length` is read as `"int"`, so 2.5 becomes 2. `ui_hudbombpoints` depends on a value that is set only later, on player connect. |
| `back2uo/_back2uo_antiplay.gsc` ~375-460 | `back2uo_switchspec` runs on `level`, so `self notify("joined_spectators")` and the spectator message target the level, not the player. |
| `back2uo/_back2uo_antiplay.gsc` | The auto-download notice repeats every 12 s forever (no condition, no `endon`). |
| `back2uo/_back2uo_weatherfx.gsc` ~321 | Cold breath: `self_org` is not refreshed in the inner loop. Once started, it runs until death. |
| `maps/mp/gametypes/_weapons.gsc` | `"tt30_mp"` vs real name `"TT30_mp"`: the TT30 is always restricted and named "unknown weapon". The `luger_mp` case never restricts, so `scr_allow_luger` has no effect. In class-limit mode only the German grenades are precached. |
| `maps/mp/gametypes/_friendicons.gsc` ~235 | Rank head icons read `self.pers` (the level) instead of `player.pers`. The inner loop reuses `i`/`players`. A cvar change never takes effect. |
| `maps/mp/gametypes/sd.gsc` ~2118 | Planting compares `other.back2uo_playerdo` without checking whether the mod is enabled. With `back2uo_status 0`, this probably throws a script error. |

## Same pattern in several gametypes

- `isdefined(sHitLoc) && sHitLoc == "head" || sHitLoc == "neck"`: missing parentheses (dm, tdm, sd, ctf, hq).
- `back2uo_hit_distance()` is called without checking `game["back2uo_enable"]` (dm, tdm, sd, ctf, hq).
- Tie text `"MP_THE_GAME_IS_A_TIE"` is a plain string instead of `&"..."` (tdm, ctf, hq).

## Stock Infinity Ward bugs (kept as is)

- `sd.gsc` ~1991: dual-bomb team check uses `||` instead of `&&`. `bomb_think` sets `self.defuse` but checks `self.defusing`.
- `hq.gsc` ~885: `defendingBeforeDeath` and `defendingAfterDeath` read the same value at the same moment.
- `_utility.gsc` ~402: `getPlant` falls back to the normal of the last trace, not the best one.
- `_teams.gsc` `TestClient`: the `team` parameter is overwritten by the weapon's nationality.

## Minor

- `_objpoints.gsc` ~120: a new endless `onPlayerKilled` thread starts on every spawn, so the threads pile up.
- `_back2uo_objects.gsc`: `!level.back2uo_medipacks_hide < 1` works only by accident. Pickup triggers outlive their packs.
- `_back2uo_weaponsystem.gsc`: secondary-slot ammo pickup reads primary clip ammo. The pickup checks `self.planting` instead of `other.planting`.
- `mp_rhine_fx.gsc`: `fogbank_small_duhoc` is used even when smoke FX is off. Its positions are copied from Carentan.
- Duplicate loopfx lines in `mp_railyard_fx.gsc` and `mp_trainstation_fx.gsc`.
