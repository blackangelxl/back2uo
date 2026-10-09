/*
	Back2Uo v2.1 - Gametype hook dispatcher.

	The modified gametype scripts (maps\mp\gametypes\dm/tdm/sd/ctf/hq.gsc) call one function of
	this file at each game event (gametype start, connect, disconnect, damage, killed, spawn,
	spectator, map end). Each function starts the mod's systems for that event: HUD, weather,
	war FX, sprint, anti-camper/AFK, gore, sounds, weapon system.
	All hooks are no-ops when game["back2uo_enable"] is off.
	Notifies: level "back2uo_killthreads" (map end) and player "back2uo_killplayerthreads"
	(disconnect) end the mod's long-running threads.
*/

/*
=============
back2uo_start_gametype

Starts all level-wide mod systems once the gametype has started: map and player area
dimensions (used by weather and war FX), turret checks, map rotation, war FX and weather
loops, weapon limits, spectator switch, clan messages and test bots.
Called on: level (from the gametype's Callback_StartGameType)
=============
*/
back2uo_start_gametype()
{
	if(!game["back2uo_enable"]) return;

	// Bounding boxes of the map and of the player spawn area; must run before the FX below.
	back2uo\_back2uo_tools::back2uo_playerdimension();
	back2uo\_back2uo_tools::back2uo_mapdimension();

	thread back2uo\_back2uo_weaponsystem::back2uo_turret_inradius();

	back2uo\_back2uo_tools::back2uo_getmaprotation_control();

	// Random triggers for mortars, tracers and airplanes.
	back2uo\warfx\_back2uo_warfx::back2uo_warfx_random();

	// Roll whether this map gets weather, then start rain/snow.
	back2uo\weatherfx\_back2uo_weather::back2uo_weather_randomallow();

	back2uo\weatherfx\_back2uo_weather::back2uo_weathercontrol();

	// Weapon limits per team.
	thread back2uo\_back2uo_weaponsystem::back2uo_weapon_limitiert();

	thread back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();

	thread back2uo\weatherfx\_back2uo_thunder::back2uo_thunder_draw();

	// War FX control loops (react to the flags set by back2uo_warfx_random).
	thread back2uo\warfx\_back2uo_mortar::back2uo_mortarfx_control();

	thread back2uo\warfx\_back2uo_ambtracer::back2uo_ambtracerfx_control();

	thread back2uo\warfx\_back2uo_airplane::back2uo_airplanefx_control();

	thread back2uo\antiplay\_back2uo_afk::back2uo_switchspec();

	thread back2uo\_back2uo_messages::back2uo_clan_messages_draw();

	// Limit the number of snipers and shotguns per team.
	thread back2uo\_back2uo_weaponsystem::back2uo_snipershotgun_limiter();

	// Test bots (back2uo_testbots_aktiv), see _teams.gsc.
	thread maps\mp\gametypes\_teams::addTestClients();
}

/*
=============
back2uo_player_connect

Per-player setup on connect: client cvar settings, favorite server menu, AFK and camper
checks, binocular distance display and the auto-download check.
Called on: self = player
=============
*/
back2uo_player_connect()
{
	if(!game["back2uo_enable"]) return;

	// CoD2 client cvar settings pushed to the player.
	back2uo\_back2uo_cod2set::back2uo_clientset_init();

	back2uo\_back2uo_cvars::back2uo_favorite_menu();

	thread back2uo\antiplay\_back2uo_afk::back2uo_antiplay_afk();

	thread back2uo\antiplay\_back2uo_camper::back2uo_antiplay_camper();

	thread back2uo\hud\_back2uo_binocular::back2uo_binocular_control();

	thread back2uo\antiplay\_back2uo_autodownload::back2uo_client_autodownload_init();
}

/*
=============
back2uo_player_disconnect

Ends all of the player's mod threads (they use endon "back2uo_killplayerthreads").
Called on: self = player
=============
*/
back2uo_player_disconnect()
{
	if(!game["back2uo_enable"]) return;

	self notify("back2uo_killplayerthreads");
}

/*
=============
back2uo_player_damage

Damage effects for the hit player: pain sound, blood on screen, blood effects at the
hit location, health bar glow and helmet popping on head shots.
Called on: self = player who was damaged
Params: same as the gametype Callback_PlayerDamage (eInflictor, eAttacker, iDamage, iDFlags,
		sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
=============
*/
back2uo_player_damage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(!game["back2uo_enable"]) return;

	thread back2uo\_back2uo_sounds::back2uo_painsound_play(sHitLoc, eAttacker);

	// Blood sprites on the player's screen.
	thread back2uo\hud\_back2uo_bloodfx::back2uo_view_bloodfx();

	thread back2uo\_back2uo_gore::back2uo_playerdamage_blood(sHitLoc, iDamage, eAttacker);

	thread back2uo\hud\_back2uo_healthbar::back2uo_healthbar_glow();

	thread back2uo\_back2uo_objects::back2uo_helmpopping(vDir, iDamage, sHitLoc, eAttacker);
}

/*
=============
back2uo_player_killed

Death handling for the killed player: removes camper marker and HUD elements, plays the
death sound, drops health packs, updates the health bar, pops the helmet and plays the
attacker's hit taunt.
Called on: self = player who was killed
Params: same as the gametype Callback_PlayerKilled (eInflictor, attacker, iDamage, sMeansOfDeath,
		sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
=============
*/
back2uo_player_killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(!game["back2uo_enable"]) return;

	back2uo\antiplay\_back2uo_camper::back2uo_antiplay_camper_remove2();

	back2uo\hud\_back2uo_binocular::back2uo_binocular_distance_clear2();

	back2uo\hud\_back2uo_playerposition::back2uo_playerposition_clear();

	thread back2uo\_back2uo_sounds::back2uo_deathsound_play(sHitLoc);

	// Medic packs dropped by the dead player.
	thread back2uo\_back2uo_objects::back2uo_dropHealthPacks(iDamage);

	thread back2uo\hud\_back2uo_healthbar::back2uo_healthbar_update();

	thread back2uo\_back2uo_objects::back2uo_helmpopping(vDir, iDamage, sHitLoc, attacker);

	thread back2uo\_back2uo_sounds::back2uo_hit_taunts(attacker, sHitLoc);
}

/*
=============
back2uo_player_spawn

Per-spawn setup: picks a taunt voice, clears leftovers from the last life, then starts
all HUD elements (health bar, position, ranking, scores, weapon pickup), unlimited pistol
ammo, grenade/smoke checks, the sprint system, startup weather, welcome message, spawn
protection, cold breath, grenade throw sounds and the development test hook.
Called on: self = player
=============
*/
back2uo_player_spawn()
{
	if(!game["back2uo_enable"]) return;

	// Voice set (0-2) used for this player's taunts.
	self.pers["taunt_person"] = randomint(3);

	// Clean up from the previous life.
	back2uo\_back2uo_cvars::back2uo_clear_triggerhud_elements();

	back2uo\_back2uo_objects::back2uo_helmpopping_off();

	back2uo\hud\_back2uo_bloodfx::back2uo_clear_bloodfx();

	// HUD element creation.
	thread back2uo\hud\_back2uo_healthbar::back2uo_healthbar_draw();

	thread back2uo\hud\_back2uo_playerposition::back2uo_playerposition_draw();

	thread back2uo\hud\_back2uo_ranking::back2uo_ranking_draw();

	thread back2uo\hud\_back2uo_hudfx::back2uo_hudfx_draw();

	thread back2uo\hud\_back2uo_playerscore::back2uo_playerscore_draw();

	thread back2uo\hud\_back2uo_teamscore::back2uo_teamscore_draw();

	thread back2uo\hud\_back2uo_weaponpickup::back2uo_weaponpickup_hud_draw();

	thread back2uo\hud\_back2uo_binocular::back2uo_binocular_distance_clear2();

	thread back2uo\_back2uo_weaponsystem::back2uo_pistel_unlimtedammo();

	// Hint which key is used for sprinting.
	thread back2uo\hud\_back2uo_sprinttast::back2uo_sprinttast_msg();

	thread back2uo\_back2uo_cvars::back2uo_grana_smoke_checker();

	thread back2uo\_back2uo_sprint::back2uo_sprintsystem_main();

	// SD only: weather above the player until the main weather loop takes over.
	thread back2uo\weatherfx\_back2uo_weather::back2uo_weather_startup();

	thread back2uo\_back2uo_messages::back2uo_wellc_messages_draw();

	thread back2uo\antiplay\_back2uo_spawnprotection::back2uo_antiplay_spawn_start();

	thread back2uo\weatherfx\_back2uo_coldbreath::back2uo_coldbreath_draw();

	thread back2uo\_back2uo_sounds::back2uo_grenade_isthrowing();

	// HUD update loops.
	thread back2uo\hud\_back2uo_hudfx::back2uo_hudfx_update();

	thread back2uo\hud\_back2uo_healthbar::back2uo_healthbar_update();

	thread back2uo\hud\_back2uo_playerposition::back2uo_playerposition_update();

	thread back2uo\hud\_back2uo_ranking::back2uo_ranking_update();

	thread back2uo\hud\_back2uo_playerscore::back2uo_playerscore_update();

	thread back2uo\hud\_back2uo_teamscore::back2uo_teamscore_update();

	// Development test hook (melee double tap), only with game["back2uo_development_enable"].
	thread back2uo\_back2uo_cvars::back2uo_fx_run();

	back2uo\_back2uo_cvars::back2uo_clear_triggerhud_elements();

	back2uo\_back2uo_cvars::back2uo_hud_elements_draw();
}

/*
=============
back2uo_player_spectator

Switches the HUD to spectator mode: keeps the team score display and removes all
player-only HUD elements.
Called on: self = player
=============
*/
back2uo_player_spectator()
{
	if(!game["back2uo_enable"]) return;

	thread back2uo\hud\_back2uo_teamscore::back2uo_teamscore_draw();

	thread back2uo\hud\_back2uo_teamscore::back2uo_teamscore_update();

	// Remove player-only HUD elements.
	back2uo\hud\_back2uo_bloodfx::back2uo_clear_bloodfx();

	back2uo\hud\_back2uo_healthbar::back2uo_healthbar_clear();

	back2uo\hud\_back2uo_playerposition::back2uo_playerposition_clear();

	back2uo\hud\_back2uo_hudfx::back2uo_hudfx_clear();

	back2uo\hud\_back2uo_ranking::back2uo_ranking_clear();

	back2uo\hud\_back2uo_playerscore::back2uo_playerscore_clear();

	back2uo\hud\_back2uo_binocular::back2uo_binocular_distance_clear2();

	back2uo\_back2uo_cvars::back2uo_clear_triggerhud_elements();
}

/*
=============
back2uo_map_end

Ends all level-wide mod threads (they use endon "back2uo_killthreads").
Called on: level (from the gametype's endMap)
=============
*/
back2uo_map_end()
{
	if(!game["back2uo_enable"]) return;

	level notify("back2uo_killthreads");
}

/*
=============
back2uo_clear_elements

Removes the player's HUD elements while waiting to respawn (blood, health bar, ranking,
HUD FX, trigger hints). Called by the gametypes right after a death with wert = 1.
Called on: self = player
Params: wert - 1 keeps the player position display, any other value clears it too
=============
*/
back2uo_clear_elements(wert)
{
	if(!game["back2uo_enable"]) return;

	if(wert != 1)
	{
		back2uo\hud\_back2uo_playerposition::back2uo_playerposition_clear();
	}

	back2uo\hud\_back2uo_bloodfx::back2uo_clear_bloodfx();

	back2uo\hud\_back2uo_healthbar::back2uo_healthbar_clear();

	back2uo\hud\_back2uo_ranking::back2uo_ranking_clear();

	back2uo\hud\_back2uo_hudfx::back2uo_hudfx_clear();

	back2uo\_back2uo_cvars::back2uo_clear_triggerhud_elements();
}
