/*
	Back2Uo v2.1 - Capture the Flag gametype (g_gametype ctf)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() registers the engine callbacks (see _callbacksetup.gsc) and starts the mod
	(back2uo\_back2uo_main::back2uo_main). The Callback_* functions call into
	back2uo\_back2uo_player.gsc when game["back2uo_enable"] is set.
	Mod-specific: damage scaling (weapon strength, melee strength, helmet save), spawn protection,
	player points for flag capture/return and kills, respawn delay back2uo_ctf_waitrespawn,
	optional hiding of the 3D flag icons (back2uo_objindekator_ctf), moved clock and flag HUD icon.
	Stock cvars: scr_ctf_timelimit, scr_ctf_scorelimit, scr_forcerespawn, scr_killcam, scr_friendlyfire.
*/

/*
	Capture the Flag
	Objective: 	Score points for your team by capturing the enemy's flag and returning it to your base
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	Instant / At base

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_ctf_spawn_allied
			Allied players spawn from these.
			classname		mp_ctf_spawn_axis
			Axis players spawn from these.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

		If using minefields or exploders:
			maps\mp\_load::main();

	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "normandy";
			game["german_soldiertype"] = "normandy";
			This sets what character models are used for each nationality on a particular map.

			Valid settings:
				american_soldiertype	normandy
				british_soldiertype		normandy, africa
				russian_soldiertype		coats, padded
				german_soldiertype		normandy, africa, winterlight, winterdark
*/

/*QUAKED mp_ctf_spawn_allied (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.
*/

/*QUAKED mp_ctf_spawn_axis (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.
*/

/*
=============
main

Gametype entry point, run by the engine at level load. Sets the level.callback* and
menu function pointers and starts the Back2Uo mod thread.
Called on: level
=============
*/
main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = ::menuWeapon;
	level.endgameconfirmed = ::endMap;

	// Back2Uo: start the mod (_back2uo_main.gsc). It sets game["back2uo_enable"] before its first wait.
	thread back2uo\_back2uo_main::back2uo_main();
}

/*
=============
Callback_StartGameType

Sets up the gametype: team flags and HUD shader names, precaching, the stock
helper scripts, spawnpoints, time/score limit cvars and the flags.
Called by CodeCallback_StartGameType() once per map.
Called on: level
=============
*/
Callback_StartGameType()
{
	precacheStatusIcon("hud_status_connecting");
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if(!isDefined(game["allies"]))
		game["allies"] = "american";
	if(!isDefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];

	level.hudflagflash_allies = "hud_flagflash_" + game["allies"];
	level.hudflagflash_axis = "hud_flagflash_" + game["axis"];

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon(level.hudflag_allies);
	precacheStatusIcon(level.hudflag_axis);
	precacheRumble("damage_heavy");
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.hudflag_allies);
	precacheShader(level.hudflag_axis);
	precacheShader(level.hudflagflash_allies);
	precacheShader(level.hudflagflash_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.objpointflagmissing_allies);
	precacheShader(level.objpointflagmissing_axis);
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
	precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"MP_CTF_OBJ_TEXT");
	precacheString(&"MP_ENEMY_FLAG_TAKEN");
	precacheString(&"MP_ENEMY_FLAG_CAPTURED");
	precacheString(&"MP_YOUR_FLAG_WAS_TAKEN");
	precacheString(&"MP_YOUR_FLAG_WAS_CAPTURED");
	precacheString(&"MP_YOUR_FLAG_WAS_RETURNED");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	// Back2Uo: precache the mod's shaders, models and strings (only possible during StartGameType).
	if(game["back2uo_enable"]) thread back2uo\_back2uo_main::back2uo_precached();

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");

	spawnpointname = "mp_ctf_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	if(getCvar("scr_ctf_timelimit") == "")
		setCvar("scr_ctf_timelimit", "30");
	else if(getCvarFloat("scr_ctf_timelimit") > 1440)
		setCvar("scr_ctf_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_ctf_timelimit");
	setCvar("ui_ctf_timelimit", level.timelimit);
	makeCvarServerInfo("ui_ctf_timelimit", "30");

	// Score limit per map
	if(getCvar("scr_ctf_scorelimit") == "")
		setCvar("scr_ctf_scorelimit", "300");
	level.scorelimit = getCvarInt("scr_ctf_scorelimit");
	setCvar("ui_ctf_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_ctf_scorelimit", "5");

	// Force respawning
	if(getCvar("scr_forcerespawn") == "")
		setCvar("scr_forcerespawn", "0");

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	// Back2Uo: respawn delay in seconds (back2uo_ctf_waitrespawn, 0-60, default 10), used by respawn_timer().
	level.respawndelay = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ctf_waitrespawn", 10, 0, 60, "int");

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];

	thread initFlags();
	thread startGame();
	thread updateGametypeCvars();

	// Back2Uo: start the mod's gametype-level threads.
	if(game["back2uo_enable"]) thread back2uo\_back2uo_player::back2uo_start_gametype();
}

/*
=============
dummy

Sends level notify "connecting" for this player one frame later (after waittillframeend),
so listeners can see the player once Callback_PlayerConnect() has started.
Called on: player
=============
*/
dummy()
{
	waittillframeend;

	if(isdefined(self))
		level notify("connecting", self);
}

/*
=============
Callback_PlayerConnect

Handles a connecting client: waits for "begin", logs the join (J;), then spawns the player
or puts him into spectator and opens the right menu. Also called after every map change.
Called on: player
=============
*/
Callback_PlayerConnect()
{
	thread dummy();

	self.statusicon = "hud_status_connecting";
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);

	if(!level.splitscreen) iprintln(&"MP_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	if(level.splitscreen)
		scriptMainMenu = game["menu_ingame_spectator"];
	else
		scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		if(isDefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			spawnSpectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!level.xenon)
		{
			if(!isdefined(self.pers["skipserverinfo"]))
				self openMenu(game["menu_serverinfo"]);
		}
		else
			self openMenu(game["menu_team"]);

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		spawnSpectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);

	// Back2Uo: start the mod's per-player threads.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_connect();
}

/*
=============
Callback_PlayerDisconnect

Drops a carried flag, clears the xenon team rank and logs the quit (Q;).
Called on: player
=============
*/
Callback_PlayerDisconnect()
{
	self dropFlag();

	if(!level.splitscreen) iprintln(&"MP_DISCONNECTED", self);

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies")
			setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis")
			setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator")
			setplayerteamrank(self, 2, 0);
	}

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	// Back2Uo: clean up the mod's per-player data.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_disconnect();
}

/*
=============
Callback_PlayerDamage

Damage handler: applies Back2Uo damage modifiers and spawn protection, then the stock
friendly fire rules (scr_friendlyfire 0-3), shellshock, damage feedback and the D; log line.
Called on: player (victim)
Params: same as CodeCallback_PlayerDamage; psOffsetTime - time offset of the hit
=============
*/
Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	// Back2Uo: spawn protection, mod damage hook and damage modifiers.
	if(game["back2uo_enable"])
	{
		// Spawn protection: while self.back2uo_antiplay_sp_run is set (antiplay\_back2uo_spawnprotection.gsc),
		// damage from other players is ignored and the attacker gets a warning.
		if(isdefined(eAttacker) && isdefined(self.back2uo_antiplay_sp_run) && isPlayer(eAttacker) && eAttacker != self && self.back2uo_antiplay_sp_run)
		{
			eAttacker thread back2uo\messages\_back2uo_spawnattacking::back2uo_spawn_attacking();

			return;
		}

		back2uo_victimhit = true;

		// Friendly fire the victim does not take (scr_friendlyfire 0 = off, 2 = reflect) must not
		// trigger the hit effects or use up the helmet save.
		if(!(iDFlags & level.iDFLAGS_NO_PROTECTION) && isPlayer(eAttacker) && self != eAttacker && self.pers["team"] == eAttacker.pers["team"])
		{
			if(level.friendlyfire == "0" || level.friendlyfire == "2") back2uo_victimhit = false;
		}

		// Hand the hit to the mod's damage handler (effects, messages); it gets the unscaled damage.
		if(back2uo_victimhit) self thread back2uo\_back2uo_player::back2uo_player_damage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

		// Weapon strength: scale damage by the per-weapon percentage in level.back2uo_weaponstrength[].
		if(game["back2uo_weaponsystem_enable"])
		{
			if(isdefined(sWeapon) && isdefined(sMeansOfDeath) && sMeansOfDeath != "MOD_MELEE" && sWeapon != "None")
			{
				if(isdefined(level.back2uo_weaponstrength) && isdefined(level.back2uo_weaponstrength[sWeapon]))
				{
					// Percent to factor.
					back2uo_wdamage = level.back2uo_weaponstrength[sWeapon] / 100;
					iDamage = int(iDamage * back2uo_wdamage);
				}
			}

			// Melee (bash) damage is scaled by cvar back2uo_melee_strength (percent).
			if(isdefined(sMeansOfDeath) && sMeansOfDeath == "MOD_MELEE" && isdefined(level.back2uo_melee_strength))
			{
				back2uo_wdamage2 = level.back2uo_melee_strength / 100;
				iDamage = int(iDamage * back2uo_wdamage2);
			}
		}

		// Helmet save (cvars back2uo_helmpopping and back2uo_helmluck): the first head/neck hit per life
		// is reduced to 2/3 damage. self.pers["back2uo_helmsave"] is cleared on spawn in objects\_back2uo_helmpopping.gsc.
		if(back2uo_victimhit && game["back2uo_helmpoppping_enable"] && level.back2uo_helmpopping_luck == 1)
		{
			if(isdefined(sHitLoc) && (sHitLoc == "head" || sHitLoc == "neck"))
			{
				if(!isdefined(self.pers["back2uo_helmsave"]))
				{
					iDamage = int(iDamage / 1.5);

					self.pers["back2uo_helmsave"] = true;
				}
			}
		}
	}

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	friendly = undefined;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				friendly = true;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				friendly = true;

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			// Shellshock/Rumble
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

		if(isdefined(eAttacker) && eAttacker != self)
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly))
		{
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

/*
=============
Callback_PlayerKilled

Death handler: obituary, weapon/flag drop, score changes, K; log line, corpse,
killcam and respawn. Ends on "spawned".
Called on: player (victim)
Params: same as CodeCallback_PlayerKilled
=============
*/
Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;

	// Back2Uo: mod death handling (sounds, medipack drop, helmet popping, HUD updates).
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);

	// Back2Uo: remove the mod's HUD elements from the dead player.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_clear_elements(1);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self dropFlag();

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		// Back2Uo: enemy kill - tell the attacker hit location and distance (not gated by game["back2uo_enable"]).
		if(self.pers["team"] != attacker.pers["team"])
		{
			back2uo\_back2uo_weaponsystem::back2uo_hit_distance(attacker, sMeansOfDeath, sWeapon, sHitLoc);
		}

		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// Back2Uo: with player points on, a suicide costs level.back2uo_selfkill_mpoints points.
			if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"] && !isdefined(self.switching_teams))
			{
				attacker back2uo\_back2uo_tools::back2uo_losepoints_ofplayer(level.back2uo_selfkill_mpoints);
			}

			// switching teams
			if(isdefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1)
						attacker.score--;
				}
			}

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// Back2Uo: with player points on, a team kill costs level.back2uo_teamkill_mpoints points; an enemy kill gives +1.
			if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"])
			{
				if(self.pers["team"] == attacker.pers["team"])
				{
					attacker thread back2uo\_back2uo_tools::back2uo_losepoints_ofplayer(level.back2uo_teamkill_mpoints);
				}
				else
				{
					attacker.score++;
				}
			}
			else
			{
				if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
					attacker.score--;
				else
					attacker.score++;
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);

	// Back2Uo: blood splatter and blood pool on the corpse.
	if(game["back2uo_enable"])
	{
		if(isdefined(self) && isdefined(self.pers["team"]))
		{
			// Fall and trigger deaths have no player as attacker (no .pers)
			back2uo_attackerteam = "world";
			if(isPlayer(attacker) && isdefined(attacker.pers["team"])) back2uo_attackerteam = attacker.pers["team"];

			self thread back2uo\gore\_back2uo_killedplayer::back2uo_killedplayer_blood(body, self.pers["team"], back2uo_attackerteam);
		}
	}

	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	self thread respawn_timer(delay);

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
	{
		// Back2Uo: no killcam for artillery kills (artillery_mp).
		if(game["back2uo_enable"])
		{
			if(isdefined(sweapon) && sweapon != "artillery_mp")
			{
				self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);
			}
		}
		else
		{
			self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);
		}
	}

	self thread respawn();
}

/*
=============
spawnPlayer

Spawns the player at a team spawnpoint near teammates, sets model and weapons
and the objective text.
Called on: player
=============
*/
spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	if(self.pers["team"] == "allies")
		spawnpointname = "mp_ctf_spawn_allied";
	else
		spawnpointname = "mp_ctf_spawn_axis";

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveGrenades();
	maps\mp\gametypes\_weapons::giveBinoculars();

	// Back2Uo: give the primary weapon with 999 slot and clip ammo instead of giveWeapon/giveMaxAmmo.
	if(game["back2uo_enable"])
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);
		self setSpawnWeapon(self.pers["weapon"]);
	}
	else
	{
		self giveWeapon(self.pers["weapon"]);
		self giveMaxAmmo(self.pers["weapon"]);
		self setSpawnWeapon(self.pers["weapon"]);
	}

	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
			self setClientCvar("cg_objectiveText", &"MP_CTF_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"MP_CTF_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"MP_CAPTURE_THE_ENEMY_FLAG");

	self thread updateTimer();

	waittillframeend;
	self notify("spawned_player");

	// Back2Uo: start the mod's per-spawn threads.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spawn();

	// Back2Uo: remember the spawn ammo of both weapon slots (used by _back2uo_weaponsystem.gsc).
	self.pers["back2uo_weaponspawn_prislotammo"] = self getweaponslotammo("primary");
	self.pers["back2uo_weaponspawn_pribslotammo"] = self getweaponslotammo("primaryb");
}

/*
=============
spawnSpectator

Puts the player into spectator mode at the given position or at a random
mp_global_intermission point.
Called on: player
Params: origin, angles - optional spawn position
=============
*/
spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	self setClientCvar("cg_objectiveText", "");

	// Back2Uo: mod handling for spectators.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spectator();
}

/*
=============
spawnIntermission

Puts the player into intermission view at a random mp_global_intermission point.
Called on: player
=============
*/
spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self thread updateTimer();
}

/*
=============
respawn

Holds the dead player as a spectator at his death position until the respawn delay
(self.WaitingToSpawn) is over and, unless scr_forcerespawn is set, until he presses use.
Called on: player
=============
*/
respawn()
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"]))
		return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "spectator";

	if(isdefined(self.dead_origin) && isdefined(self.dead_angles))
	{
		origin = self.dead_origin + (0, 0, 16);
		angles = self.dead_angles;
	}
	else
	{
		origin = self.origin + (0, 0, 16);
		angles = self.angles;
	}

	self spawn(origin, angles);

	while(isdefined(self.WaitingToSpawn))
		wait .05;

	if(getCvarInt("scr_forcerespawn") <= 0)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

/*
=============
waitRespawnButton

Shows "press use to spawn" and sends "respawn" when the use button is pressed.
Called on: player
=============
*/
waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if(!isdefined(self.respawntext))
	{
		self.respawntext = newClientHudElem(self);
		self.respawntext.horzAlign = "center_safearea";
		self.respawntext.vertAlign = "center_safearea";
		self.respawntext.alignX = "center";
		self.respawntext.alignY = "middle";
		self.respawntext.x = 0;
		self.respawntext.y = -50;
		self.respawntext.archived = false;
		self.respawntext.font = "default";
		self.respawntext.fontscale = 2;
		self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");
	}

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true)
		wait .05;

	self notify("remove_respawntext");

	self notify("respawn");
}

/*
=============
removeRespawnText

Destroys the respawn hint when "remove_respawntext" arrives.
Called on: player
=============
*/
removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

/*
=============
waitRemoveRespawnText

Turns the given notify into "remove_respawntext".
Called on: player
Params: message - notify to wait for
=============
*/
waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

/*
=============
startGame

Creates the round clock (if there is a time limit) and checks the time limit once per second.
Called on: level
=============
*/
startGame()
{
	level.starttime = getTime();

	if(level.timelimit > 0)
	{
		level.clock = newHudElem();
		level.clock.horzAlign = "left";
		level.clock.vertAlign = "top";

		// Back2Uo: clock at the bottom center (640x480 virtual screen), semi-transparent.
		if(game["back2uo_enable"])
		{
			level.clock.x = 298;
			level.clock.y = 445;
			level.clock.alpha = 0.7;
		}
		else
		{
			level.clock.x = 8;
			level.clock.y = 2;
		}

		level.clock.font = "default";
		level.clock.fontscale = 2;
		level.clock setTimer(level.timelimit * 60);
	}

	for(;;)
	{
		checkTimeLimit();
		wait 1;
	}
}

/*
=============
endMap

Ends the map: announces the winner, logs W;/L; lines, moves everyone to intermission,
sets xenon ranks and exits the level after 10 seconds.
Called on: level
=============
*/
endMap()
{
	game["state"] = "intermission";
	level notify("intermission");

	// Back2Uo: mod end-of-map handling (called directly, so it finishes before the rest of endMap).
	if(game["back2uo_enable"]) back2uo\_back2uo_player::back2uo_map_end();

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MP_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
	}

	winners = "";
	losers = "";

	if(winningteam == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winningteam == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers("MP_announcer_round_draw");

	// Back2Uo: show the result as a mod message instead of the objective text.
	if(game["back2uo_enable"])
	{
		thread back2uo\_back2uo_cvars::back2uo_player_message(text);
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpGuid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpGuid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();

		// Back2Uo: clear the objective text, the result is shown by back2uo_player_message.
		if(game["back2uo_enable"])
		{
			player setClientCvar("cg_objectiveText", "");
		}
		else
		{
			player setClientCvar("cg_objectiveText", text);
		}

		player spawnIntermission();
	}

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	// set everyone's rank on xenon
	if(level.xenon)
	{
		players = getentarray("player", "classname");
		highscore = undefined;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(!isdefined(player.score))
				continue;

			if(!isdefined(highscore) || player.score > highscore)
				highscore = player.score;
		}

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(!isdefined(player.score))
				continue;

			if(highscore <= 0)
				rank = 0;
			else
			{
				rank = int(player.score * 10 / highscore);
				if(rank < 0)
					rank = 0;
			}

			if(player.pers["team"] == "allies")
				setplayerteamrank(player, 0, rank);
			else if(player.pers["team"] == "axis")
				setplayerteamrank(player, 1, rank);
			else if(player.pers["team"] == "spectator")
				setplayerteamrank(player, 2, rank);
		}
		sendranks();
	}

	wait 10;
	exitLevel(false);
}

/*
=============
checkTimeLimit

Ends the map when the time limit (minutes) has passed.
Called on: level
=============
*/
checkTimeLimit()
{
	if(level.timelimit <= 0)
		return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

/*
=============
checkScoreLimit

Ends the map when a team has reached the score limit (number of captures).
Called on: level
=============
*/
checkScoreLimit()
{
	if(level.scorelimit <= 0)
		return;

	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

/*
=============
updateGametypeCvars

Polls scr_ctf_timelimit and scr_ctf_scorelimit every second and applies changes
(the clock restarts when the time limit changes).
Called on: level
=============
*/
updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_ctf_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ctf_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_ctf_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.horzAlign = "left";
					level.clock.vertAlign = "top";

					// Back2Uo: clock at the bottom center (640x480 virtual screen), semi-transparent.
					if(game["back2uo_enable"])
					{
						level.clock.x = 298;
						level.clock.y = 445;
						level.clock.alpha = 0.7;
					}
					else
					{
						level.clock.x = 8;
						level.clock.y = 2;
					}

					level.clock.font = "default";
					level.clock.fontscale = 2;
				}
				level.clock setTimer(level.timelimit * 60);
			}
			else
			{
				if(isDefined(level.clock))
					level.clock destroy();
			}

			checkTimeLimit();
		}

		scorelimit = getCvarInt("scr_ctf_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_ctf_scorelimit", level.scorelimit);
			level notify("update_allhud_score");
		}
		checkScoreLimit();

		wait 1;
	}
}

/*
=============
printJoinedTeam

Prints "<player> joined Allies/Axis" to everyone.
Called on: player
Params: team - "allies" or "axis"
=============
*/
printJoinedTeam(team)
{
	if(!level.splitscreen)
	{
		if(team == "allies")
			iprintln(&"MP_JOINED_ALLIES", self);
		else if(team == "axis")
			iprintln(&"MP_JOINED_AXIS", self);
	}
}

/*
=============
initFlags

Finds the allied_flag and axis_flag trigger entities, spawns the flag and base models
and starts flag() on each. Prints map errors and gives up if a flag is missing or duplicated.
Called on: level
=============
*/
initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;
	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;
	axis_flag thread flag();
}

/*
=============
flag

Main loop of one flag trigger: handles pickup by an enemy, return by the owning team
and capture (owning team touches its flag at base while carrying the enemy flag).
Called on: flag trigger entity
=============
*/
flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		self waittill("trigger", other);

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isdefined(other.flag)) // Captured flag
					{
						println("CAPTURED THE FLAG!");

						friendlyAlias = "ctf_touchcapture";
						enemyAlias = "ctf_enemy_touchcapture";

						if(self.team == "axis")
							enemy = "allies";
						else
							enemy = "axis";

						thread playSoundOnPlayers(friendlyAlias, self.team);
						if(!level.splitscreen)
							thread playSoundOnPlayers(enemyAlias, enemy);

						thread printOnTeam(&"MP_ENEMY_FLAG_CAPTURED", self.team);
						thread printOnTeam(&"MP_YOUR_FLAG_WAS_CAPTURED", enemy);

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other.statusicon = "";

						if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"])
						{
							// Back2Uo: capture bonus from the player points system (level.back2uo_captureflag) instead of stock +10.
							other back2uo\_back2uo_tools::back2uo_playerpoints_system("flag_capture");
						}
						else
						{
							other.score += 10;
						}

						teamscore = getTeamScore(other.pers["team"]);
						teamscore += 1;
						setTeamScore(other.pers["team"], teamscore);
						level notify("update_allhud_score");

						checkScoreLimit();
					}
				}
				else // Returned flag
				{
					println("RETURNED THE FLAG!");
					thread playSoundOnPlayers("ctf_touchown", self.team);
					thread printOnTeam(&"MP_YOUR_FLAG_WAS_RETURNED", self.team);

					self returnFlag();

					if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"])
					{
						// Back2Uo: return bonus from the player points system (level.back2uo_defendsflag) instead of stock +2.
						other back2uo\_back2uo_tools::back2uo_playerpoints_system("flag_defending");
					}
					else
					{
						other.score += 2;
					}

					level notify("update_allhud_score");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				println("PICKED UP THE FLAG!");

				friendlyAlias = "ctf_touchenemy";
				enemyAlias = "ctf_enemy_touchenemy";

				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				thread playSoundOnPlayers(friendlyAlias, self.team);
				if(!level.splitscreen)
					thread playSoundOnPlayers(enemyAlias, enemy);

				thread printOnTeam(&"MP_YOUR_FLAG_WAS_TAKEN", self.team);
				thread printOnTeam(&"MP_ENEMY_FLAG_TAKEN", enemy);

				other pickupFlag(self); // Stolen flag
			}
		}
		wait 0.05;
	}
}

/*
=============
pickupFlag

Gives the flag to the player: hides the flag, shows the "flag missing" waypoint at the base
and makes the compass objective follow the carrier for his team.
Called on: player
Params: flag - flag trigger entity
=============
*/
pickupFlag(flag)
{
	flag notify("end_autoreturn");

	// Move the trigger far below the map so it cannot be touched while the flag is carried.
	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;

	if(self.pers["team"] == "allies")
		self.statusicon = level.hudflag_axis;
	else
		self.statusicon = level.hudflag_allies;

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity(self.flag.objective, self);
	objective_team(self.flag.objective, self.pers["team"]);

	self attachFlag();
}

/*
=============
dropFlag

Drops the carried flag on the ground below the player and starts the auto return.
Does nothing if the player has no flag.
Called on: player
=============
*/
dropFlag()
{
	if(isdefined(self.flag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.statusicon = "";

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// Return the flag at once if it was dropped into a minefield or trigger_hurt.
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

/*
=============
returnFlag

Moves the flag back to its base and restores waypoint and objective.
Called on: flag trigger entity
=============
*/
returnFlag()
{
	self notify("end_autoreturn");

	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

/*
=============
autoReturn

Returns a dropped flag after 120 seconds unless it is picked up first ("end_autoreturn").
Called on: flag trigger entity
=============
*/
autoReturn()
{
	self endon("end_autoreturn");

	wait 120;
	self thread returnFlag();
}

/*
=============
attachFlag

Attaches the carried enemy flag model to the player's back (tag J_Spine4) and shows the HUD icon.
Called on: player
=============
*/
attachFlag()
{
	if(isdefined(self.flagAttached))
		return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";

	self attach(flagModel, "J_Spine4", true);
	self.flagAttached = true;

	self thread createHudIcon();
}

/*
=============
detachFlag

Removes the carried flag model and the HUD icon.
Called on: player
Params: flag - flag trigger entity that was carried
=============
*/
detachFlag(flag)
{
	if(!isdefined(self.flagAttached))
		return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";

	self detach(flagModel, "J_Spine4");
	self.flagAttached = undefined;

	self thread deleteHudIcon();
}

/*
=============
createHudIcon

Shows the carried flag icon with a short flash effect.
Called on: player
=============
*/
createHudIcon()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);

	// Back2Uo: flag icon at the top right instead of the stock top left position.
	if(game["back2uo_enable"])
	{
		self.hud_flag.x = 612;
		self.hud_flag.y = 44;
	}
	else
	{
		self.hud_flag.x = 30;
		self.hud_flag.y = 95;
	}

	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alpha = 0;

	self.hud_flagflash = newClientHudElem(self);

	if(game["back2uo_enable"])
	{
		self.hud_flagflash.x = 612;
		self.hud_flagflash.y = 44;
	}
	else
	{
		self.hud_flagflash.x = 30;
		self.hud_flagflash.y = 95;
	}

	self.hud_flagflash.alignX = "center";
	self.hud_flagflash.alignY = "middle";
	self.hud_flagflash.horzAlign = "left";
	self.hud_flagflash.vertAlign = "top";
	self.hud_flagflash.alpha = 0;
	self.hud_flagflash.sort = 1;

	if(self.pers["team"] == "allies")
	{
		self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "axis");
		self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagflash fadeOverTime(.2);
	self.hud_flagflash.alpha = 1;

	self.hud_flag fadeOverTime(.2);
	self.hud_flag.alpha = 1;

	wait .2;

	if(isdefined(self.hud_flagflash))
	{
		self.hud_flagflash fadeOverTime(1);
		self.hud_flagflash.alpha = 0;
	}
}

/*
=============
deleteHudIcon

Destroys the carried flag HUD icons.
Called on: player
=============
*/
deleteHudIcon()
{
	if(isdefined(self.hud_flagflash))
		self.hud_flagflash destroy();

	if(isdefined(self.hud_flag))
		self.hud_flag destroy();
}

/*
=============
createFlagWaypoint

Creates the 3D waypoint icon above the flag.
Called on: flag trigger entity
=============
*/
createFlagWaypoint()
{
	self deleteFlagWaypoint();

	// Back2Uo: with back2uo_objindekator_ctf off, the waypoint is invisible (alpha 0, size 0), hiding the 3D flag icon.
	if(game["back2uo_enable"] && !game["back2uo_objindekator_ctf_enable"])
	{
		waypoint = newHudElem();
		waypoint.x = self.origin[0];
		waypoint.y = self.origin[1];
		waypoint.z = self.origin[2];
		waypoint.alpha = 0;
		waypoint.archived = false;
		waypoint setShader(self.objpointflag, 0, 0);
	}
	else
	{
		waypoint = newHudElem();
		waypoint.x = self.origin[0];
		waypoint.y = self.origin[1];
		waypoint.z = self.origin[2] + 100;
		waypoint.alpha = .61;
		waypoint.archived = true;

		if(level.splitscreen)
			waypoint setShader(self.objpointflag, 14, 14);
		else
			waypoint setShader(self.objpointflag, 7, 7);
	}

	waypoint setwaypoint(true);
	self.waypoint_flag = waypoint;
}

/*
=============
deleteFlagWaypoint

Destroys the flag waypoint.
Called on: flag trigger entity
=============
*/
deleteFlagWaypoint()
{
	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

/*
=============
createFlagMissingWaypoint

Creates the "flag missing" waypoint icon above the empty flag base.
Called on: flag trigger entity
=============
*/
createFlagMissingWaypoint()
{
	self deleteFlagMissingWaypoint();

	// Back2Uo: invisible waypoint when back2uo_objindekator_ctf is off (see createFlagWaypoint).
	if(game["back2uo_enable"] && !game["back2uo_objindekator_ctf_enable"])
	{
		waypoint = newHudElem();
		waypoint.x = self.home_origin[0];
		waypoint.y = self.home_origin[1];
		waypoint.z = self.home_origin[2] + 100;
		waypoint.alpha = 0;
		waypoint.archived = false;
		waypoint setShader(self.objpointflagmissing, 0, 0);
	}
	else
	{
		waypoint = newHudElem();
		waypoint.x = self.home_origin[0];
		waypoint.y = self.home_origin[1];
		waypoint.z = self.home_origin[2] + 100;
		waypoint.alpha = .61;
		waypoint.archived = true;

		if(level.splitscreen)
			waypoint setShader(self.objpointflagmissing, 14, 14);
		else
			waypoint setShader(self.objpointflagmissing, 7, 7);
	}

	waypoint setwaypoint(true);
	self.waypoint_base = waypoint;
}

/*
=============
deleteFlagMissingWaypoint

Destroys the "flag missing" waypoint.
Called on: flag trigger entity
=============
*/
deleteFlagMissingWaypoint()
{
	if(isdefined(self.waypoint_base))
		self.waypoint_base destroy();
}

/*
=============
playSoundOnPlayers

Plays a local sound for all players, or only for one team.
Params: sound - sound alias, team - optional team filter
=============
*/
playSoundOnPlayers(sound, team)
{
	players = getentarray("player", "classname");

	if(level.splitscreen)
	{
		if(isdefined(players[0]))
			players[0] playLocalSound(sound);
	}
	else
	{
		if(isdefined(team))
		{
			for(i = 0; i < players.size; i++)
			{
				if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
					players[i] playLocalSound(sound);
			}
		}
		else
		{
			for(i = 0; i < players.size; i++)
				players[i] playLocalSound(sound);
		}
	}
}

/*
=============
printOnTeam

Prints a message to all players of one team.
Params: text - (localized) string, team - "allies" or "axis"
=============
*/
printOnTeam(text, team)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}

/*
=============
menuAutoAssign

Auto-assign menu choice: puts the player on the smaller team (or the lower scoring team
if equal) and opens the weapon menu.
Called on: player
=============
*/
menuAutoAssign()
{
	if(!level.xenon && isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis"))
	{
		self openMenu(game["menu_team"]);
		return;
	}

	numonteam["allies"] = 0;
	numonteam["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator")
			continue;

		numonteam[player.pers["team"]]++;
	}

	// if teams are equal return the team with the lowest score
	if(numonteam["allies"] == numonteam["axis"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			teams[0] = "allies";
			teams[1] = "axis";
			assignment = teams[randomInt(2)];	// should not switch teams if already on a team
		}
		else if(getTeamScore("allies") < getTeamScore("axis"))
			assignment = "allies";
		else
			assignment = "axis";
	}
	else if(numonteam["allies"] < numonteam["axis"])
		assignment = "allies";
	else
		assignment = "axis";

	if(assignment == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		if(!isdefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies")
				self openMenu(game["menu_weapon_allies"]);
			else
				self openMenu(game["menu_weapon_axis"]);
		}

		return;
	}

	if(assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self.pers["team"] = assignment;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self setClientCvar("ui_allow_weaponchange", "1");

	if(self.pers["team"] == "allies")
	{
		self openMenu(game["menu_weapon_allies"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
	}
	else
	{
		self openMenu(game["menu_weapon_axis"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
	}

	self notify("joined_team");
	self notify("end_respawn");
}

/*
=============
menuAllies

Allies menu choice: switches the player to allies (suicide if alive) and opens the weapon menu.
Called on: player
=============
*/
menuAllies()
{
	if(self.pers["team"] != "allies")
	{
		if(!level.xenon && !maps\mp\gametypes\_teams::getJoinTeamPermissions("allies"))
		{
			self openMenu(game["menu_team"]);
			return;
		}

		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_allies"]);
}

/*
=============
menuAxis

Axis menu choice: switches the player to axis (suicide if alive) and opens the weapon menu.
Called on: player
=============
*/
menuAxis()
{
	if(self.pers["team"] != "axis")
	{
		if(!level.xenon && !maps\mp\gametypes\_teams::getJoinTeamPermissions("axis"))
		{
			self openMenu(game["menu_team"]);
			return;
		}

		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_axis"]);
}

/*
=============
menuSpectator

Spectator menu choice: moves the player to the spectators.
Called on: player
=============
*/
menuSpectator()
{
	if(self.pers["team"] != "spectator")
	{
		if(isAlive(self))
		{
			self.switching_teams = true;
			self.joining_team = "spectator";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");

		self thread updateTimer();

		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

		self notify("joined_spectators");
		self notify("end_respawn");
	}
}

/*
=============
menuWeapon

Weapon menu choice: checks server weapon restrictions, then spawns the player
or sets the weapon for the next respawn.
Called on: player
Params: response - weapon name from the menu
=============
*/
menuWeapon(response)
{
	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
		return;

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis")
			self openMenu(game["menu_weapon_axis"]);

		return;
	}

	if(level.splitscreen)
		self setClientCvar("g_scriptMainMenu", game["menu_ingame_onteam"]);
	else
		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
		return;

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;

		if(isdefined(self.WaitingToSpawn))
		{
			self thread respawn();
			self thread updateTimer();
		}
		else
			spawnPlayer();

		self thread printJoinedTeam(self.pers["team"]);
	}
	else
	{
		self.pers["weapon"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

		if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
		else
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

/*
=============
respawn_timer

Marks the player as waiting (self.WaitingToSpawn) for death delay + level.respawndelay
seconds and shows the respawn countdown.
Called on: player
Params: delay - seconds before the player becomes a spectator
=============
*/
respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	if(level.respawndelay > 0)
	{
		if(!isdefined(self.respawntimer))
		{
			self.respawntimer = newClientHudElem(self);
			self.respawntimer.x = 0;
			self.respawntimer.y = -50;
			self.respawntimer.alignX = "center";
			self.respawntimer.alignY = "middle";
			self.respawntimer.horzAlign = "center_safearea";
			self.respawntimer.vertAlign = "center_safearea";
			self.respawntimer.alpha = 0;
			self.respawntimer.archived = false;
			self.respawntimer.font = "default";
			self.respawntimer.fontscale = 2;
			self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
			self.respawntimer setTimer (level.respawndelay + delay);
		}

		wait delay;
		self thread updateTimer();

		wait level.respawndelay;

		if(isdefined(self.respawntimer))
			self.respawntimer destroy();
	}

	self.WaitingToSpawn = undefined;
}

/*
=============
updateTimer

Shows the respawn countdown only for players on a team with a chosen weapon.
Called on: player
=============
*/
updateTimer()
{
	if(isdefined(self.respawntimer))
	{
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
			self.respawntimer.alpha = 1;
		else
			self.respawntimer.alpha = 0;
	}
}
