/*
	Back2Uo v2.1 - Deathmatch gametype (g_gametype "dm")

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() registers the engine callbacks and menu handlers and starts back2uo_main().
	The callbacks forward connect/disconnect/damage/kill/spawn/map end to back2uo\_back2uo_player.gsc
	when game["back2uo_enable"] is set. Callback_PlayerDamage applies the mod's weapon/melee
	strength, helmet save and spawn protection. Cvars: scr_dm_timelimit, scr_dm_scorelimit, scr_forcerespawn.
*/

/*
	Deathmatch
	Objective:	Score points by eliminating other players
	Map ends:	When one player reaches the score limit, or time limit is reached
	Respawning:	No wait / Away from other players

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_dm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of enemies at the time of spawn.
			Players generally spawn away from enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			Because Deathmatch doesn't have teams with regard to gameplay or scoring, this effectively sets the available weapons.

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

/*QUAKED mp_dm_spawn (1.0 0.5 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies at one of these positions.*/

/*
=============
main

Gametype entry point, run by the engine on map load. Registers the engine callbacks
and the menu callbacks used by _menus.gsc, then starts the Back2Uo mod.
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

	// Back2Uo: load the mod (reads cvars, sets game["back2uo_enable"] and the other mod settings).
	thread back2uo\_back2uo_main::back2uo_main();
}

/*
=============
Callback_StartGameType

Engine callback at gametype start: sets teams, precaches assets, starts the shared
gametype modules, validates spawnpoints and reads the time/score limit cvars.
Called on: level
=============
*/
Callback_StartGameType()
{
	precacheStatusIcon("hud_status_connecting");
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if(!isdefined(game["allies"]))
		game["allies"] = "american";
	if(!isdefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");

	precacheStatusIcon("hud_status_dead");
	precacheRumble("damage_heavy");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	// Back2Uo: precache the mod's models, shaders, strings and effects.
	if(game["back2uo_enable"]) thread back2uo\_back2uo_main::back2uo_precached();

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	if(getCvar("scr_dm_timelimit") == "")
		setCvar("scr_dm_timelimit", "30");
	else if(getCvarFloat("scr_dm_timelimit") > 1440)
		setCvar("scr_dm_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_dm_timelimit");
	setCvar("ui_dm_timelimit", level.timelimit);
	makeCvarServerInfo("ui_dm_timelimit", "30");

	// Score limit per map
	if(getCvar("scr_dm_scorelimit") == "")
		setCvar("scr_dm_scorelimit", "100");
	level.scorelimit = getCvarInt("scr_dm_scorelimit");
	setCvar("ui_dm_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_dm_scorelimit", "100");

	// Force respawning
	if(getCvar("scr_forcerespawn") == "")
		setCvar("scr_forcerespawn", "0");

	if(!isdefined(game["state"]))
		game["state"] = "playing";

	level.QuickMessageToAll = true;
	level.mapended = false;

	thread startGame();
	thread updateGametypeCvars();

	// Back2Uo: start the mod's per-map gametype logic.
	if(game["back2uo_enable"]) thread back2uo\_back2uo_player::back2uo_start_gametype();
}

/*
=============
dummy

Sends level notify "connecting" for this player one frame-end later, so that
listeners such as _menus.gsc::onPlayerConnect() get the player before "begin".
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

Engine callback when a client connects. Waits for "begin", logs the join, then either
respawns a returning player (team and weapon kept in self.pers) or puts a new player
into spectator mode with the server info / team menu open.
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
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");
		self.sessionteam = "none";

		if(isdefined(self.pers["weapon"]))
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

	// Back2Uo: per-player mod setup on connect.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_connect();
}

/*
=============
Callback_PlayerDisconnect

Engine callback when a client leaves: announces and logs the disconnect.
Called on: player
=============
*/
Callback_PlayerDisconnect()
{
	if(!level.splitscreen) iprintln(&"MP_DISCONNECTED", self);

	if(isdefined(self.clientid))
		setplayerteamrank(self, self.clientid, 0);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	// Back2Uo: per-player mod cleanup on disconnect.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_disconnect();
}

/*
=============
Callback_PlayerDamage

Engine callback for every hit on a player. Back2Uo scales the damage by weapon/melee
strength, softens the first head/neck hit (helmet save) and blocks damage to
spawn-protected players before the stock damage handling runs.
Called on: player (the victim)
Params: eInflictor - entity that caused the damage (projectile, grenade, player)
	eAttacker - entity credited with the damage
	iDamage - damage amount
	iDFlags - damage flags (level.iDFLAGS_*)
	sMeansOfDeath - "MOD_*" damage type
	sWeapon - weapon name
	vPoint - impact point
	vDir - damage direction
	sHitLoc - hit body part
	psOffsetTime - client time offset, used by killcam
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
	if(!isdefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// Make sure at least one point of damage is done
	if(iDamage < 1)
		iDamage = 1;

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	// Apply the damage to the player
	self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	// Shellshock/Rumble
	self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
	self playrumble("damage_heavy");
	if(isdefined(eAttacker) && eAttacker != self)
		eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();

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

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

/*
=============
Callback_PlayerKilled

Engine callback when a player dies: obituary, weapon drop, score update, log line,
corpse, death icon, killcam and respawn.
Called on: player (the victim)
Params: eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime -
	same meaning as in Callback_PlayerDamage
	deathAnimDuration - length of the death animation, passed to cloneplayer()
=============
*/
Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	// A new spawn ends this thread (e.g. during the killcam wait).
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;

	// Back2Uo: mod death handling.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);

	// Back2Uo: remove the player's mod HUD elements (1 = keep the player position display).
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_clear_elements(1);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	if(!isdefined(self.switching_teams))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfteam = "";
	lpselfguid = self getGuid();
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		// Back2Uo: show hit location and kill distance (checks game["back2uo_hit_distance_enable"] itself).
		back2uo\_back2uo_weaponsystem::back2uo_hit_distance(attacker, sMeansOfDeath, sWeapon, sHitLoc);

		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// Back2Uo: suicide costs mod player points (cvar back2uo_mpoints_suicide).
			if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"] && !isdefined(self.switching_teams))
			{
				attacker back2uo\_back2uo_tools::back2uo_losepoints_ofplayer(level.back2uo_selfkill_mpoints);
			}

			if(!isdefined(self.switching_teams))
				attacker.score--;
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			attacker.score++;
			attacker checkScoreLimit();
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;

		attacker notify("update_playerhud_score");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";

		self notify("update_playerhud_score");
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);

	// Back2Uo: blood/gore effects on the corpse.
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

	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"]);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
	{
		// Back2Uo: no killcam for artillery kills.
		if(game["back2uo_enable"])
		{
			if(isdefined(sweapon) && sweapon != "artillery_mp")
			{
				self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);
			}
		}
		else
		{
			self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);
		}
	}

	self thread respawn();
}

/*
=============
spawnPlayer

Spawns the player at a DM spawnpoint away from enemies, sets model and loadout
(pistol, grenades, binoculars, chosen primary weapon) and the objective text.
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

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveGrenades();
	maps\mp\gametypes\_weapons::giveBinoculars();

	// Back2Uo: put the weapon into the primary slot explicitly; 999 makes the engine clamp
	// reserve and clip to the weapon's maximum.
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
			self setClientCvar("cg_objectiveText", &"MP_GAIN_POINTS_BY_ELIMINATING", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"MP_GAIN_POINTS_BY_ELIMINATING_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"MP_ELIMINATE_ENEMIES");

	// Let other spawn code finish this frame before listeners react to "spawned_player".
	waittillframeend;
	self notify("spawned_player");

	// Back2Uo: per-spawn mod setup.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spawn();

	// Back2Uo: remember the spawn reserve ammo of both slots; the mod's weapon system uses it
	// as the maximum when topping up ammo.
	self.pers["back2uo_weaponspawn_prislotammo"] = self getweaponslotammo("primary");
	self.pers["back2uo_weaponspawn_pribslotammo"] = self getweaponslotammo("primaryb");
}

/*
=============
spawnSpectator

Puts the player into free spectator mode, at the given position or at a random
mp_global_intermission spawnpoint.
Called on: player
Params: origin - optional spawn position
	angles - optional view angles (used together with origin)
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

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	if(isdefined(origin) && isdefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isdefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	self setClientCvar("cg_objectiveText", "");

	// Back2Uo: mod setup for spectators.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spectator();
}

/*
=============
spawnIntermission

Puts the player into intermission view at a random mp_global_intermission spawnpoint
(end of map scoreboard).
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

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

/*
=============
respawn

Respawns the dead player, either immediately (scr_forcerespawn > 0) or after the
use button is pressed. Ended by "end_respawn" (team change, spectator, new spawn).
Called on: player
=============
*/
respawn()
{
	if(!isdefined(self.pers["weapon"]))
		return;

	self endon("end_respawn");

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

Shows the "press use to spawn" text and polls the use button every server frame;
notifies "respawn" when pressed.
Called on: player
=============
*/
waitRespawnButton()
{
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

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

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while((isdefined(self)) && (self useButtonPressed() != true))
		wait .05;

	if(isdefined(self))
	{
		self notify("remove_respawntext");
		self notify("respawn");
	}
}

/*
=============
removeRespawnText

Destroys the respawn hint HUD element on "remove_respawntext".
Called on: player
=============
*/
removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isdefined(self.respawntext))
		self.respawntext destroy();
}

/*
=============
waitRemoveRespawnText

Turns the given notify into "remove_respawntext", so the hint disappears on respawn or abort.
Called on: player
Params: message - notify name to wait for
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

Creates the map timer HUD and checks the time limit once per second.
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

		// Back2Uo: timer at the bottom center of the 640x480 virtual screen, semi-transparent.
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

Ends the map: finds the top scorer (or a tie), shows the result, moves everyone to
intermission, sends ranks on Xenon and changes the map after 10 seconds.
Also used as level.endgameconfirmed.
Called on: level
=============
*/
endMap()
{
	game["state"] = "intermission";
	level notify("intermission");

	// Back2Uo: stop the mod's level threads at map end.
	if(game["back2uo_enable"]) back2uo\_back2uo_player::back2uo_map_end();

	players = getentarray("player", "classname");
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	name = undefined;
	guid = undefined;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
			continue;

		if(!isdefined(highscore))
		{
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
			continue;
		}

		if(player.score == highscore)
			tied = true;
		else if(player.score > highscore)
		{
			tied = false;
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
		}
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();

		if(isdefined(tied) && tied == true)
			player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else if(isdefined(playername))
			player setClientCvar("cg_objectiveText", &"MP_WINS", playername);

		player spawnIntermission();
	}

	if(isdefined(name))
		logPrint("W;;" + guid + ";" + name + "\n");

	// set everyone's rank on xenon
	if(level.xenon)
	{
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
				continue;

			if(highscore <= 0)
				rank = 0;
			else
			{
				rank = int(player.score * 10 / highscore);
				if(rank < 0)
					rank = 0;
			}

			// since DM is a free-for-all, give every player their own team number
			setplayerteamrank(player, player.clientid, rank);
		}
		sendranks();
	}

	wait 10;

	exitLevel(false);
}

/*
=============
checkTimeLimit

Ends the map once the elapsed time (ms converted to minutes) reaches level.timelimit.
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

Ends the map when this player's score reaches level.scorelimit.
Called on: player
=============
*/
checkScoreLimit()
{
	// Wait until the score change of this frame is applied.
	waittillframeend;

	if(level.scorelimit <= 0)
		return;

	if(self.score < level.scorelimit)
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

Polls scr_dm_timelimit and scr_dm_scorelimit every second so admins can change them
during the map; updates the timer HUD and re-checks the limits.
Called on: level
=============
*/
updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_dm_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_dm_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_dm_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isdefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.horzAlign = "left";
					level.clock.vertAlign = "top";

					// Back2Uo: timer at the bottom center, semi-transparent (same as startGame).
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
				if(isdefined(level.clock))
					level.clock destroy();
			}

			checkTimeLimit();
		}

		scorelimit = getCvarInt("scr_dm_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_dm_scorelimit", level.scorelimit);
			level notify("update_allhud_score");

			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
				players[i] checkScoreLimit();
		}

		wait 1;
	}
}

/*
=============
menuAutoAssign

Team menu "autoassign": in DM the team only selects the weapon set, so a random side
is picked. Kills a living player first and opens the weapon menu if no weapon is chosen.
Called on: player
=============
*/
menuAutoAssign()
{
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self suicide();
		}

		teams[0] = "allies";
		teams[1] = "axis";
		self.pers["team"] = teams[randomInt(2)];
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
	{
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else
			self openMenu(game["menu_weapon_axis"]);
	}
}

/*
=============
menuAllies

Team menu "allies": switches to the allied weapon set (suicide if alive, weapon reset)
and opens the allied weapon menu.
Called on: player
=============
*/
menuAllies()
{
	if(self.pers["team"] != "allies")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
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

Team menu "axis": switches to the axis weapon set (suicide if alive, weapon reset)
and opens the axis weapon menu.
Called on: player
=============
*/
menuAxis()
{
	if(self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
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

Team menu "spectator": kills a living player and moves him to spectator mode.
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
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");
		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

		self notify("joined_spectators");
	}
}

/*
=============
menuWeapon

Weapon menu selection. Checks the weapon against the server restrictions; on the
first choice the player spawns at once, later choices apply on the next respawn.
Called on: player
Params: response - weapon name sent by the weapon menu
=============
*/
menuWeapon(response)
{
	if(!isdefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
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

	if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
		return;

	if(!isdefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		spawnPlayer();
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
}
