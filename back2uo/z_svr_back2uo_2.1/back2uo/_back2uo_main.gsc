/*
	Back2Uo v2.1 - mod entry point: reads all mod cvars and precaches mod assets

	back2uo_main() is threaded from the main() of every gametype (dm, tdm, sd, hq, ctf). It reads
	the mod cvars from back2uomod.cfg via _back2uo_cvars (back2uo_setconfig -> game[] on/off
	switches, back2uo_getcvardef -> level. settings), loads the effects and publishes some
	settings as serverinfo cvars for the client menus.
	back2uo_precached() is threaded right after it (only if game["back2uo_enable"]) and
	precaches strings, shaders, models and items once per map (guarded by game[]).
	Master switch: cvar back2uo_status -> game["back2uo_enable"].
*/

/*
=============
back2uo_main

Reads every mod cvar into game[] (feature on/off) and level. (feature settings) variables,
loads the effects (loadfx) and sets the UI serverinfo cvars. Runs without waits, so all
settings are available in the same frame for the gametype init code.
Called on: level (threaded from the gametype main())
=============
*/
back2uo_main()
{
	// Mod master switch, development mode and debug log output
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 1, 0, 1);
	game["back2uo_development_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_development", 0, 0, 1);
	game["back2uo_logprint_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_logprint", 0, 0, 1);

	// --- Binocular HUD (distance to the aimed point) ---

	game["back2uo_binocularhud_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_binocular_distance", 1, 0, 1);

	level.back2uo_binocularm1 = &"BACK2UOMOD_BINOCULAR_DISTANCE";
	level.back2uo_binocularm2 = &"BACK2UOMOD_BINOCULAR_METERS";
	level.back2uo_binocularm3 = &"BACK2UOMOD_BINOCULAR_UNKNOWN";
	level.back2uo_binocularm4 = &"BACK2UOMOD_BINOCULAR_NONE";

	// Artillery hint text (set again in the artillery section below)
	level.back2uo_artilm = &"BACK2UOMOD_ARTILLERY_USE";

	// --- Weapon pickup ---

	level.back2uo_weaponpickup = &"BACK2UOMOD_SWAPWEAPONS";

	// --- Blood splatter ---

	game["back2uo_bloodsplater_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_blood", 1, 0, 1);

	level.back2uo_blood_pools = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_blood_pools", 1, 0, 1, "float");
	level.back2uo_blood_spatter = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_bloodsplatter", 1, 0, 1, "float");

	level.back2uo_effect["body_bloodpool"] = loadfx("fx/effects/gore/back2uo_bloodpool_system.efx");

	level.back2uo_effect["body_bloodsplatter"] = loadfx("fx/effects/gore/back2uo_bloodsplatter.efx");

	// --- Health bar ---

	game["back2uo_healthbar_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_healthbar", 1, 0, 1);

	// --- HUD effect icons (weather / air / impact status) ---

	game["back2uo_hudfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudfx_aktiv", 1, 0, 1);

	// --- Player stance icon ---

	game["back2uo_playerposition_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_playerposition", 1, 0, 1);

	// --- Player score HUD ---

	game["back2uo_playerscore_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_playerscore", 1, 0, 1);

	level.back2uo_hudscore_alpha = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hudscore_alpha", 0.7, 0, 1, "float");

	// --- Player ranking ---

	game["back2uo_ranking_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_playerranking", 1, 0, 1);

	// Rank display options: HUD icon, team head icons, scoreboard status icon, sound, message
	level.back2uo_hudrankingdraw = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hudrankingdraw", 1, 0, 1, "int");
	level.back2uo_teamrankheadicons = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_teamrankheadicons", 1, 0, 1, "int");
	level.back2uo_rankingscorelist = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rankingscorelist", 1, 0, 1, "int");
	level.back2uo_rankingsound = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rankingsound", 1, 0, 1, "int");
	level.back2uo_rankingmsg = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rankingmsg", 1, 0, 1, "int");

	// Points needed per rank. Note the offset: cvar ..._level1 holds the threshold for internal level 2, etc.
	level.back2uo_ranking_level2 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ranking_level1", 10, 1, 100, "int");
	level.back2uo_ranking_level3 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ranking_level2", 20, 1, 100, "int");
	level.back2uo_ranking_level4 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ranking_level3", 30, 1, 100, "int");
	level.back2uo_ranking_level5 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ranking_level4", 40, 1, 100, "int");

	// Extra bounty after the highest rank, every back2uo_rang_lv_points points
	level.back2uo_rankextra_aktiv = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang_overlv_aktiv", 1, 0, 1, "int");
	level.back2uo_ranking_lvextra = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang_lv_points", 10, 1, 100, "int");

	// Rank at which binoculars / artillery are unlocked; +1 converts the cvar rank to the internal level
	level.back2uo_binocular_onrank = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_binocular_onrang", 1, 1, 4, "int");
	level.back2uo_artillery_onrank = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_artillery_onrang", 3, 1, 4, "int");
	level.back2uo_artillery_onrank++;

	// No rank icons in the CTF scoreboard
	if(getcvar("g_gametype") == "ctf") level.back2uo_rankingscorelist = 0;

	// Rank rewards on spawn (grenades, smokes, primary/secondary ammo); same cvar/level offset as above
	level.back2uo_rang2_getgranade = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang1_getgranade", 1, 0, 10, "int");
	level.back2uo_rang2_getsmoke = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang1_getsmoke", 0, 0, 10, "int");
	level.back2uo_rang2_getpriammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang1_getpriammo", 0, 0, 99, "int");
	level.back2uo_rang2_getsekammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang1_getsekammo", 10, 0, 99, "int");

	level.back2uo_rang3_getgranade = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang2_getgranade", 1, 0, 10, "int");
	level.back2uo_rang3_getsmoke = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang2_getsmoke", 0, 0, 10, "int");
	level.back2uo_rang3_getpriammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang2_getpriammo", 10, 0, 99, "int");
	level.back2uo_rang3_getsekammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang2_getsekammo", 10, 0, 99, "int");

	level.back2uo_rang4_getgranade = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang3_getgranade", 2, 0, 10, "int");
	level.back2uo_rang4_getsmoke = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang3_getsmoke", 1, 0, 10, "int");
	level.back2uo_rang4_getpriammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang3_getpriammo", 20, 0, 99, "int");
	level.back2uo_rang4_getsekammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang3_getsekammo", 20, 0, 99, "int");

	level.back2uo_rang5_getgranade = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang4_getgranade", 2, 0, 10, "int");
	level.back2uo_rang5_getsmoke = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang4_getsmoke", 1, 0, 10, "int");
	level.back2uo_rang5_getpriammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang4_getpriammo", 30, 0, 99, "int");
	level.back2uo_rang5_getsekammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rang4_getsekammo", 30, 0, 99, "int");

	// --- Player points (rank points) ---

	game["back2uo_playerpoints_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_points_system", 1, 0, 1);

	// Point penalties for suicide and team kill
	level.back2uo_selfkill_mpoints = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mpoints_suicide", 1, 0, 5, "int");
	level.back2uo_teamkill_mpoints = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mpoints_teamkill", 3, 0, 5, "int");

	// S&D: points for plant, defuse and surviving the round
	level.back2uo_sd_plant_points = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_points_plant", 5, 0, 10, "int");
	level.back2uo_sd_defuse_points = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_points_defuse", 5, 0, 10, "int");
	level.back2uo_playeralive = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_points_alive", 3, 0, 10, "int");

	// CTF: points for capturing and defending the flag
	level.back2uo_captureflag = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_points_captureflag", 2, 0, 10, "int");
	level.back2uo_defendsflag = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_points_defendsflag", 2, 0, 10, "int");

	// --- Team score HUD ---

	game["back2uo_teamscore_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_teamscore", 1, 0, 1);

	// Same cvar as in the player score section
	level.back2uo_hudscore_alpha = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hudscore_alpha", 0.7, 0, 1, "float");

	// Separator between the team scores
	level.cuticon = &"|";

	// --- Talking head icons ---

	game["back2uo_talkingicon"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_talkingicon", 0, 0, 1);

	// --- Call vote menu options (published as ui_allowvote* below) ---

	game["back2uo_playerkickvote_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_vote_playerkick", 0, 0, 1);

	// Vote gametype + map
	game["back2uo_vote_gametype_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_vote_gametype", 0, 0, 1);

	game["back2uo_vote_map_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_vote_map", 1, 0, 1);

	// Vote next map in rotation
	game["back2uo_vote_nextmap_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_vote_nextmap", 1, 0, 1);

	game["back2uo_vote_map_restart_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_vote_maprestart", 0 ,0, 1);

	// --- "Add server to favorites" menu (see _back2uo_cvars::back2uo_favorite_menu) ---

	game["back2uo_add_favorite_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_add_favorite", 1 ,0, 1);

	if(game["back2uo_add_favorite_enable"])
	{
		level.favorite_menu = 1;
	}
	else
	{
		level.favorite_menu = 0;
	}

	// --- Map vote at map end ---

	game["back2uo_endmapvote_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_mapvote_aktiv", 0, 0, 1);

	level.back2uo_mapvotetime	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_map_vote_time", 30, 10, 180, "int");
	level.back2uo_mapvotereplay	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_map_vote_replay", 0, 0, 1,"int");

	// Vote HUD texts (German, hardcoded Latin-1 strings, not from the localized string file)
	level.back2uo_votetxt_button = &"Drücken Sie [^2FIRE^7] um zu Voten.";
	level.back2uo_votetxt_time = &"Zeit: ";
	level.back2uo_votetxt_title = &"Vote - Nächste Map";

	// --- Client autodownload notice ---

	game["back2uo_autodownload_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_autodownload", 1, 0, 1);

	// --- Allow only auto-assign on team change ---

	game["back2uo_autoteam_changeallow_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_autoteam_change", 0, 0, 1);

	// --- Server information on join ---

	game["back2uo_serverinfo_join"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_serverinfo_aktiv", 1, 0, 1);

	// --- Special equipment (special frag / smoke grenade variants) ---

	// Max 2: more than one special grenade mode
	game["back2uo_specialgrenade_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_spezial_grenade", 1, 0, 2);

	game["back2uo_specialsmoke_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_spezial_smoke", 1, 0, 1);

	// --- Fall damage ---

	game["back2uo_falldamage_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_falldamage_aktiv", 1, 0, 1);

	// Fall heights in units for minimum and lethal fall damage
	level.back2uo_falldamage_min = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_falldamage_min", 225, 1, 1000, "int");
	level.back2uo_falldamage_max = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_falldamage_max", 355, 1, 1000, "int");

	// Overrides the engine fall damage cvars
	if(game["back2uo_falldamage_enable"])
	{
		setcvar("bg_fallDamageMinHeight", level.back2uo_falldamage_min);
		setcvar("bg_fallDamageMaxHeight", level.back2uo_falldamage_max);
	}

	// --- Next map message ---

	game["back2uo_mapmsg_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_mapmsg_aktiv", 1, 0, 1);

	level.back2uo_mapmsg_maptype	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mapmsg_maptype", 2, 1, 2, "int");
	level.back2uo_mapmsg_delay	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mapmsg_delay", 60, 1, 1440, "int");
	level.back2uo_mapmsg_loop	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mapmsg_loop", 1, 0, 1, "int");

	// --- Player status messages ---

	game["back2uo_playerstatus_msg_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_playerstatus_msg", 0, 0, 1);

	// --- Server text ---

	game["back2uo_servertext_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_servertext_aktiv", 0, 0, 1);

	// --- Clan messages (cvar list back2uo_clanm_0, _1, ...) ---

	game["back2uo_clanm_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_clanm_aktiv", 1, 0, 1);

	level.back2uo_clanmrepeatwait = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_clanm_repeatwait", 30, 1, 120, "float");
	game["back2uo_clanmsg"] = back2uo\_back2uo_cvars::back2uo_getarray("back2uo_clanm");

	// --- Welcome messages (cvar list back2uo_wellm_0, _1, ...) ---

	game["back2uo_wellm_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_wellm_aktiv", 1, 0, 1);

	game["back2uo_wellmsg"] = back2uo\_back2uo_cvars::back2uo_getarray("back2uo_wellm");

	// --- Health behaviour ---

	game["back2uo_health_is_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_health_is", 1, 0, 1);

	// --- Pain / death / taunt / grenade sounds (see _back2uo_sounds.gsc) ---

	// Chance values 0..100, 0 = off
	level.back2uo_painsound_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_painsound_aktiv", 30 ,0, 100, "int");
	level.back2uo_deathsound_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_deathsound_aktiv", 60 ,0, 100, "int");
	level.back2uo_tauntsounds_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_tauntsounds_aktiv", 40, 0, 100, "int");
	level.back2uo_nadesounds_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_nadesounds_aktiv", 25, 0, 100, "int");

	// Number of recorded voices per nationality (pain/death sound variants)
	if(level.back2uo_tauntsounds_random != 0)
	{
		level.back2uo_voices["german"] = 3;
		level.back2uo_voices["american"] = 7;
		level.back2uo_voices["russian"] = 6;
		level.back2uo_voices["british"] = 6;
	}

	// --- Hit location and distance messages ---

	game["back2uo_hit_distance_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hit_distance_aktiv", 1, 0, 1);

	// --- Health packs (see objects\_back2uo_healthpacks.gsc) ---

	game["back2uo_medipacks_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_drophealth", 1, 0, 1);

	// Health per pack size, lifetime in seconds (0 = forever), pickup mode (0 auto, 1 use key)
	level.back2uo_medipacks_health1 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_medipacks_health1", 25, 1, 100, "int");
	level.back2uo_medipacks_health2 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_medipacks_health2", 50, 1, 100, "int");
	level.back2uo_medipacks_health3 = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_medipacks_health3", 75, 1, 100, "int");
	level.back2uo_medipacks_hide = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_medipacks_hide", 35, 0, 999, "int");
	level.back2uo_medipacks_pickup = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_medipacks_pickup", 0, 0, 1, "int");

	// --- Helmet popping ---

	game["back2uo_helmpoppping_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_helmpopping", 1, 0, 1);

	// Helmet luck: the first head hit only knocks the helmet off (gametype damage callbacks)
	level.back2uo_helmpopping_luck = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_helmluck", 1, 0, 1, "int");

	// Object queue for helmet models (not referenced elsewhere in the mod)
	level.back2uo_objectQ["helm"] = [];
	level.back2uo_objectQcurrent["helm"] = 0;
	level.back2uo_objectQsize["helm"] = 8;

	// --- Anti AFK (see antiplay\_back2uo_afk.gsc) ---

	game["back2uo_antiplay_afk_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_antiplay_afk_aktiv", 1, 0, 1);

	// Seconds without activity before the warning
	level.back2uo_antiplay_afk_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_afk_lmd", 100, 0, 230, "int");

	// --- Anti camper ---

	game["back2uo_antiplay_cmp_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_antiplay_cmp_aktiv", 0, 0, 1);

	// Allowed camping time (s), compass marking time (s), radius (units) that counts as camping
	level.back2uo_antiplay_cmp_timer = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_cmp_lmd", 60, 0, 120, "int");
	level.back2uo_antiplay_cmp_objtime = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_cmp_go", 40, 0, 120, "int");
	level.back2uo_antiplay_cmp_radius = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_cmp_rad", 160, 0, 999, "int");

	// --- Spawn protection ---

	game["back2uo_antiplay_sp_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_antiplay_sp_aktiv", 1, 0, 1);

	// Protection time (s), message to the attacker, end protection on movement/action
	level.back2uo_antiplay_sp_time = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_sp_lmd", 5, 1, 60, "int");
	level.back2uo_antiplay_sp_msg = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_sp_msg", 1, 0, 1, "int");
	level.back2uo_antiplay_sp_move = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_antiplay_sp_move", 1, 0, 1, "int");

	// Stock friend head icon setting
	level.back2uo_drawfriend = back2uo\_back2uo_cvars::back2uo_getcvardef("scr_drawfriend", 1, 0, 1, "int");

	// Head icon of spawn-protected players
	game["headicon_sp_icon"] = "gfx/hud/hud@health_cross.tga";

	// --- War effects (see the warfx\ scripts) ---

	game["back2uo_warfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_warfx_aktiv", 1, 0, 1);

	level.back2uo_warfx_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_warfx_random", 40 ,1, 100, "int");

	// --- Airplanes ---

	game["back2uo_airplanesfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_airplanes_aktiv", 1, 0, 1);

	level.back2uo_airplanes_count = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_airplanes_count", 0, 0, 6, "int");
	level.back2uo_airplanes_crash = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_airplanes_crash", 0, 0, 1, "int");

	level.back2uo_effect["plane_smoke"] = loadfx("fx/fire/fire_airplane_trail.efx");
	level.back2uo_effect["plane_explosion"] = loadfx("fx/explosions/matmata_plane_explosion.efx");

	// Airplane FX allowed; set to 0 by _back2uo_tools::back2uo_mapdimension() on maps too small
	level.back2uo_airplanedimo_allow = 1;

	// --- Flak effects ---

	game["back2uo_flakfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_flaksfx_aktiv", 1, 0, 1);

	level.back2uo_effect["flak_smoke"] = loadfx("fx/explosions/flak_puff.efx");
	level.back2uo_effect["flak_flash"] = loadfx("fx/explosions/default_explosion.efx");
	level.back2uo_effect["flak_dust"]	= loadfx("fx/dust/flak_dust_blowback.efx");

	// --- Ambient anti-air tracers ---

	game["back2uo_ambtracerfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_ambtracer_aktiv", 1, 0, 1);

	level.back2uo_ambtracer_count = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambtracer_count", 0, 0, 8, "int");

	level.back2uo_effect["ambiente_tracer"] = loadfx("fx/misc/antiair_tracers.efx");

	// --- Mortar effects ---

	game["back2uo_mortarfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_mortar_aktiv", 1, 0, 1);

	level.back2uo_mortar_count = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_count", 0, 0, 16, "int");
	level.back2uo_mortar_alert = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_alert", 0, 0, 1, "int");
	level.back2uo_mortar_quake = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_quake", 1, 0, 1, "int");
	level.back2uo_mortar_damage = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_damage", 1, 0, 1, "int");
	level.back2uo_mortar_radius = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_radius", 150, 1, 999, "int");
	level.back2uo_mortar_strength = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_mortar_stre", 50, 1, 999, "int");

	// Impact effect per surface type
	level.back2uo_effect["mortar_beach"] = loadfx("fx/explosions/mortarExp_beach.efx");
	level.back2uo_effect["mortar_concrete"] = loadfx("fx/explosions/mortarExp_concrete.efx");
	level.back2uo_effect["mortar_dirt"] = loadfx("fx/explosions/mortarExp_mud.efx");
	level.back2uo_effect["mortar_snow"] = loadfx("fx/explosions/grenadeExp_snow.efx");
	level.back2uo_effect["mortar_wood"] = loadfx("fx/explosions/mortarExp_mud.efx");
	level.back2uo_effect["mortar_water"] = loadfx("fx/explosions/mortarExp_water.efx");

	// --- Artillery effects ---

	game["back2uo_artilleryfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_artillery_aktiv", 1, 0, 1);

	// danger = danger-close warning when the target is nearer than this (units), 0 = off
	level.back2uo_artillery_count = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_artillery_count", 0, 0, 10, "int");
	level.back2uo_artillery_alert = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_artillery_alert", 0, 0, 1, "int");
	level.back2uo_artillery_order = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_artillery_order", 1, 0, 1, "int");
	level.back2uo_artillery_danger = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_artillery_danger", 400, 0, 999, "int");

	// Impact effect per surface type
	level.back2uo_effect["artillery_beach"] = loadfx("fx/explosions/artilleryExp_desert_yellow.efx");
	level.back2uo_effect["artillery_concrete"] = loadfx("fx/explosions/artilleryExp_desert_building.efx");
	level.back2uo_effect["artillery_dirt"] = loadfx("fx/explosions/artilleryExp_grass.efx");
	level.back2uo_effect["artillery_snow"] = loadfx("fx/explosions/grenadeExp_snow.efx");
	level.back2uo_effect["artillery_wood"] = loadfx("fx/explosions/artilleryExp_grass.efx");
	level.back2uo_effect["artillery_water"] = loadfx("fx/explosions/mortarExp_water.efx");

	// Artillery hint text (duplicate of the assignment in the binocular section)
	level.back2uo_artilm = &"BACK2UOMOD_ARTILLERY_USE";

	// --- Weather effects (see the weatherfx\ scripts) ---

	game["back2uo_weatherfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_weatherfx_aktiv", 1, 0, 1);

	level.back2uo_weatherfx_random = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weatherfx_random", 20 ,1, 100, "int");
	level.back2uo_weatherfx_strength = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weatherfx_str", 30 ,1, 100, "int");

	// --- Cold breath ---

	game["back2uo_coldbreath_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_coldbreath_aktiv", 1, 0, 1);

	level.back2uo_breathfx = loadfx("fx/misc/cold_breath.efx");

	// --- Rain ---

	game["back2uo_rainfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_rainfx_aktiv", 1, 0, 1);

	level.back2uo_effect["rain"]	= loadfx ("fx/back2uo/rain.efx");

	// --- Snow ---

	game["back2uo_snowfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_snowfx_aktiv", 1, 0, 1);

	level.back2uo_effect["snow"]	= loadfx ("fx/back2uo/snow.efx");

	// --- Thunder ---

	game["back2uo_thunderfx_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_thunderfx_aktiv", 1, 0, 1);

	level.back2uo_effect["lightning"] = loadfx ("fx/misc/lightning.efx");
	level.back2uo_effect["thunder_flash"] = loadfx("fx/back2uo/thunder_flash.efx");

	// --- Random map rotation ---

	game["back2uo_mapsystem_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_randommaprotation", 0, 0, 1);

	// --- Test bots ---

	game["back2uo_testbots_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_testbots_aktiv", 0, 0, 1);

	// --- Sniper and shotgun limits (players per team) ---

	game["back2uo_weaponlimit_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_weapons_lmd_aktiv", 1, 0, 1);

	// Sniper rifles
	level.back2uo_kar98sniper_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_kar98sniper_lmd", 1, 1, 10, "int");
	level.back2uo_nagantsniper_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_nagantsniper_lmd", 1, 1, 10, "int");
	level.back2uo_springfield_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_springfield_lmd", 1, 1, 10, "int");
	level.back2uo_enfieldsniper_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_enfieldsniper_lmd", 1, 1, 10, "int");

	// Shotguns
	level.back2uo_shotgun_axis_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_shotgun_axis_lmd", 1, 1, 10, "int");
	level.back2uo_shotgun_allies_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_shotgun_allies_lmd", 1, 1, 10, "int");

	// --- Sprint ---

	game["back2uo_sprint_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_sprint_aktiv", 1, 0, 1);

	// Sprint length and recovery time in seconds; read as "int", so a cvar value like 2.5 is truncated
	level.back2uo_sprint_onhud = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_sprint_onhud", 1, 0, 1, "int");
	level.back2uo_sprint_length = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_sprint_length", 2.5, 1, 15, "int");
	level.back2uo_sprint_rehatime = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_sprint_rehatime", 4, 1, 15, "int");
	level.back2uo_sprint_infomsg = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_sprint_infomsg", 1, 0, 1, "int");

	level.back2uo_nosprint_msg = &"BACK2UOMOD_NOSPRINT_TAST";

	// --- Weapon system ---

	game["back2uo_weaponsystem_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_weaponsetup_aktiv", 1, 0, 1);

	// Allowed weapon class (0 = all), pistol/turret/binocular/shotgun availability
	level.back2uo_weapon_limit = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weapons_allow", 0, 0, 4, "float");
	level.back2uo_pistel_unammo = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_pistolonly_unammo", 1, 0, 1, "int");
	level.back2uo_pistel_allow	= back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_pistel_allow", 1, 0, 1, "float");
	level.back2uo_turret_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_turret_allow", 1, 0, 1, "float");
	level.back2uo_binocular_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_binocular_allow", 1, 0, 1, "float");
	level.back2uo_shotgunteam_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_shotgun_allow", 1, 0, 1, "float");

	// Extra weapons: rocket launcher, G43 sniper
	level.back2uo_rocketl_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_rocketlancher_on", 0, 0, 1, "float");
	level.back2uo_g43sniper_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_g43sniper_on", 0, 0, 1, "float");

	// Grenade setup: limits checked by _back2uo_cvars::back2uo_grana_smoke_checker, counts given on spawn
	level.back2uo_smoke_grana_aktiv = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_smoke_grana_aktiv", 1, 0, 1, "int");
	level.back2uo_granaten_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_frag_allow", 3 ,1, 5, "int");
	level.back2uo_granaten_use = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_frag_use", 1, 0, 5, "int");
	level.back2uo_smoke_allow = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_smoke_allow", 1, 1, 5, "int");
	level.back2uo_smoke_use = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_smoke_use", 0, 0, 5, "int");

	// --- CoD2 game settings ---

	game["back2uo_deathicon_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_deathicon", 0, 0, 1);

	game["back2uo_friendicon_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_friendicon", 1, 0, 1);

	// Grenade indicator
	game["back2uo_granatenindecator_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_granatenindecator", 0, 0, 1);

	// Mini crosshair
	game["back2uo_minicrosshair_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_minicrosshair", 0, 0, 1);

	// Objective indicator
	game["back2uo_objindekator_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_objindekator", 0, 0, 1);

	game["back2uo_objindekator_ctf_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_objindekator_ctf", 0, 0, 1);

	game["back2uo_playerhitsound_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_playerhitsound", 0, 0, 1);

	game["back2uo_killcam"] = back2uo\_back2uo_cvars::back2uo_setconfig("scr_killcam", 0, 0, 1);

	// --- Serverinfo cvars for the client server info / call vote menus ---

	// CoD2 / extra settings
	// game["back2uo_drawmantlehint"] is only set in _back2uo_cod2set on player connect; if it is
	// still undefined here, back2uo_setui_var() returns without setting ui_hudbombpoints.
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_killcam", game["back2uo_killcam"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_hudbombpoints", game["back2uo_drawmantlehint"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_skullicons", game["back2uo_deathicon_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_friendicons", game["back2uo_friendicon_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_grenadesinde", game["back2uo_granatenindecator_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allow_onlyautoteam", game["back2uo_autoteam_changeallow_enable"]);

	// Call vote options
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allowvotekick", game["back2uo_playerkickvote_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allowvotetypemap", game["back2uo_vote_gametype_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allowvotemap", game["back2uo_vote_map_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allowvotemaprotate", game["back2uo_vote_nextmap_enable"]);
	back2uo\_back2uo_cvars::back2uo_setui_var("ui_allowvotemaprestart", game["back2uo_vote_map_restart_enable"]);
}

/*
=============
back2uo_precached

Precaches all strings, shaders, status/head icons, models and items the mod uses.
CoD2 only allows precaching during the first frame of a level, so this must run during
gametype init. game["back2uo_precached_complett"] prevents a second run across rounds
of the same map (game[] survives map_restart).
Called on: level (threaded from the gametype main() after back2uo_main)
=============
*/
back2uo_precached()
{
	// Already precached
	if(isdefined(game["back2uo_precached_complett"])) return;

	// --- Binocular HUD ---

	precacheString(level.back2uo_binocularm1);
	precacheString(level.back2uo_binocularm2);
	precacheString(level.back2uo_binocularm3);
	precacheString(level.back2uo_binocularm4);

	// Artillery hint
	precacheString(level.back2uo_artilm);

	precacheShader("artillery");

	// --- Player points messages ---

	precacheString(&"BACK2UOMOD_RANKINGPOINTS_ADD");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_SUB");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_PLANT");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_DEFUSE");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_CAPTURE");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_DEFENDING");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_SURVIVE");
	precacheString(&"BACK2UOMOD_RANKINGPOINTS_FOR_SUICIDE");

	// --- Sprint key message ---

	precacheString(level.back2uo_nosprint_msg);

	// --- Blood splatter screen overlays ---

	precacheShader("gfx/gore/back2uo_hud_blood_hit1.tga");
	precacheShader("gfx/gore/back2uo_hud_blood_hit2.tga");

	// --- Health bar ---

	precacheShader("gfx/hud/hud@health_back.tga");
	precacheShader("gfx/hud/hud@health_bar.tga");
	precacheShader("gfx/hud/hud@health_cross.tga");

	// --- HUD effect icons ---

	// Weather
	precacheShader("gfx/custom/back2uo_hud_snowfx.tga");
	precacheShader("gfx/custom/back2uo_hud_rainfx.tga");
	precacheShader("gfx/custom/back2uo_hud_thunderfx.tga");
	precacheShader("gfx/custom/back2uo_hud_noweatherfx.tga");

	// Air
	precacheShader("gfx/custom/back2uo_hud_airplanefx.tga");
	precacheShader("gfx/custom/back2uo_hud_flakfx.tga");
	precacheShader("gfx/custom/back2uo_hud_noplanefx.tga");

	// Impact
	precacheShader("gfx/custom/back2uo_hud_mortarfx.tga");
	precacheShader("gfx/custom/back2uo_hud_artilleryfx.tga");
	precacheShader("gfx/custom/back2uo_hud_nomortarfx.tga");

	// --- Player stance icons ---

	precacheShader("gfx/custom/back2uo_hud_stance_prone.tga");
	precacheShader("gfx/custom/back2uo_hud_stance_crouch.tga");
	precacheShader("gfx/custom/back2uo_hud_stance_stand.tga");
	precacheShader("gfx/custom/back2uo_hud_stance_sprint.tga");
	precacheShader("white");

	// --- Player score: nation flags ---

	precacheShader("gfx/custom/back2uo_flag_ammis.tga");
	precacheShader("gfx/custom/back2uo_flag_british.tga");
	precacheShader("gfx/custom/back2uo_flag_russian.tga");
	precacheShader("gfx/custom/back2uo_flag_german.tga");

	// --- Player ranking icons ---

	// HUD rank icon
	if(level.back2uo_hudrankingdraw == 1)
	{
		precacheShader("gfx/custom/back2uo_ranking_lv1.tga");
		precacheShader("gfx/custom/back2uo_ranking_lv2.tga");
		precacheShader("gfx/custom/back2uo_ranking_lv3.tga");
		precacheShader("gfx/custom/back2uo_ranking_lv4.tga");
		precacheShader("gfx/custom/back2uo_ranking_lv5.tga");
	}

	// Scoreboard status icons
	if(level.back2uo_rankingscorelist == 1)
	{
		precacheStatusIcon("gfx/custom/back2uo_ranking_lv1.tga");
		precacheStatusIcon("gfx/custom/back2uo_ranking_lv2.tga");
		precacheStatusIcon("gfx/custom/back2uo_ranking_lv3.tga");
		precacheStatusIcon("gfx/custom/back2uo_ranking_lv4.tga");
		precacheStatusIcon("gfx/custom/back2uo_ranking_lv5.tga");
	}

	// Rank head icons above teammates (team gametypes only)
	if(level.back2uo_teamrankheadicons == 1 && getCvar("g_gametype") != "dm")
	{
		precacheHeadIcon("gfx/hud/hud@back2uo_ranking_head_lv1.tga");
		precacheHeadIcon("gfx/hud/hud@back2uo_ranking_head_lv2.tga");
		precacheHeadIcon("gfx/hud/hud@back2uo_ranking_head_lv3.tga");
		precacheHeadIcon("gfx/hud/hud@back2uo_ranking_head_lv4.tga");
		precacheHeadIcon("gfx/hud/hud@back2uo_ranking_head_lv5.tga");
	}

	// --- Team score ---

	precacheString(level.cuticon);

	// Nation flags (already precached above; repeated precache is harmless)
	precacheShader("gfx/custom/back2uo_flag_ammis.tga");
	precacheShader("gfx/custom/back2uo_flag_british.tga");
	precacheShader("gfx/custom/back2uo_flag_russian.tga");
	precacheShader("gfx/custom/back2uo_flag_german.tga");

	// Alive / dead player count icons
	precacheShader("gfx/custom/back2uo_liveicon.tga");
	precacheShader("gfx/custom/back2uo_deadicon.tga");

	// --- Health packs ---

	precacheModel("xmodel/health_small");
	precacheModel("xmodel/health_medium");
	precacheModel("xmodel/health_large");

	precacheShader("gfx/hud/hud@back2uo_medicicon.tga");

	// --- Explosive charge ---

	// Disabled: model for the unused explosive charge / mine feature
	//precacheModel("xmodel/back2uo_s_mine");

	// --- Map vote at map end ---

	precacheString(level.back2uo_votetxt_button);
	precacheString(level.back2uo_votetxt_time);
	precacheString(level.back2uo_votetxt_title);

	precacheShader("white");

	// --- Anti camper compass icons ---

	precacheShader("gfx/custom/back2uo_camper_german.tga");
	precacheShader("gfx/custom/back2uo_camper_russian.tga");
	precacheShader("gfx/custom/back2uo_camper_british.tga");
	precacheShader("gfx/custom/back2uo_camper_american.tga");
	precacheShader("objpoint_radio");

	// --- Spawn protection head icon ---

	PrecacheHeadIcon("gfx/custom/back2uo_liveicon.tga");

	// --- Airplanes ---

	PrecacheModel("xmodel/vehicle_stuka_flying");
	PrecacheModel("xmodel/vehicle_spitfire_flying");

	// Model spawned by _back2uo_tools::back2uo_mapdimension() (map dimension check)
	PrecacheModel("xmodel/tree_destroyed_snow_fallen_log_a");

	// --- Mortar shell model ---

	PrecacheModel("xmodel/prop_mortar_ammunition");

	// --- Artillery ---

	// Shell model
	PrecacheModel("xmodel/vehicle_halftrack_rockets_shell_d");

	// Weapon name used as damage source for artillery hits (warfx\_back2uo_artillery)
	precacheItem("artillery_mp");

	// --- Weapon pickup hint ---

	precacheString(level.back2uo_weaponpickup);

	game["back2uo_precached_complett"] = true;
}
