/*
	Back2Uo v2.1 - Headquarters (HQ) gametype.

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() registers the engine callbacks and menu handlers and starts the mod (back2uo_main).
	One radio is active at a time; a team captures it by standing next to it and then scores
	1 point per second (hq_points). Dead defenders stay dead until the radio is neutralized or
	reset after level.RadioMaxHoldSeconds; attackers wait level.respawndelay.
	Cvars: scr_hq_timelimit, scr_hq_scorelimit, scr_drawfriend, scr_forcerespawn, back2uo_hq_waitrespawn.
*/

/*
	HQ
	Objective: 	Establish a headquarters and gain points as long as your team controls it
	Map ends:	When one teams score reaches the score limit, or time limit is reached
	Respawning:	Attackers respawn after 10 seconds, defenders do not respawn until they lose the radio

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

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

		Radio Position information:
			To add radios to your map add a section to your level script similar to the one below. To get the origin and angles
			values easily it is recommended that you temporarily place radio models in your level and copy the origin and angles
			values to your script. The reason these are in script and not the level itself is so radio positions can easily be
			changed if needed. See the official level scripts for more examples.

			if(getcvar("g_gametype") == "hq")
			{
				level.radio = [];
				level.radio[0] = spawn("script_model", (174, -310, 16));
				level.radio[0].angles = (0, 57, 0);
				level.radio[1] = spawn("script_model", (-31, -32, 16));
				level.radio[1].angles = (0, 1, 0);
				level.radio[2] = spawn("script_model", (-299, -277, 16));
				level.radio[2].angles = (0, 312, 0);
			}

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

/*
=============
main

Gametype entry point. Registers the engine callbacks and menu response handlers,
then starts the Back2Uo mod.
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

	// Back2Uo: load and start the mod.
	thread back2uo\_back2uo_main::back2uo_main();
}

/*
=============
Callback_StartGameType

Engine callback at map start. Sets team nationalities, precaches HQ assets, starts the stock
gametype subsystems, reads the time/score limit cvars, sets the HQ tuning values, sets up the
radios and starts the scoring, clock and cvar watcher threads.
Called on: level
=============
*/
Callback_StartGameType()
{
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if(!isdefined(game["allies"]))
		game["allies"] = "american";
	if(!isdefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getcvar("scr_allies") != "")
		game["allies"] = getcvar("scr_allies");
	if(getcvar("scr_axis") != "")
		game["axis"] = getcvar("scr_axis");

	// Objective icons for a spawning radio. A/B were for the disabled decoy marker (see hq_obj_think); index 2 is used.
	game["radio_prespawn"][0] = "objectiveA";
	game["radio_prespawn"][1] = "objectiveB";
	game["radio_prespawn"][2] = "objective";
	game["radio_prespawn_objpoint"][0] = "objpoint_A";
	game["radio_prespawn_objpoint"][1] = "objpoint_B";
	game["radio_prespawn_objpoint"][2] = "objpoint_star";
	game["radio_none"] = "objective";
	game["radio_axis"] = "objective_" + game["axis"];
	game["radio_allies"] = "objective_" + game["allies"];

	// Radio model color depends on the allied nationality.
	if(game["allies"] == "american")
		game["radio_model"] = "xmodel/military_german_fieldradio_green_nonsolid";
	else if(game["allies"] == "british")
		game["radio_model"] = "xmodel/military_german_fieldradio_tan_nonsolid";
	else if(game["allies"] == "russian")
		game["radio_model"] = "xmodel/military_german_fieldradio_grey_nonsolid";
	assert(isdefined(game["radio_model"]));

	precacheShader("white");
	precacheShader("objective");
	precacheShader("objectiveA");
	precacheShader("objectiveB");
	precacheShader("objective");
	precacheShader("objpoint_A");
	precacheShader("objpoint_B");
	precacheShader("objpoint_radio");
	precacheShader("field_radio");
	precacheShader(game["radio_allies"]);
	precacheShader(game["radio_axis"]);
	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheModel(game["radio_model"]);
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"MP_ESTABLISHING_HQ");
	precacheString(&"MP_DESTROYING_HQ");
	precacheString(&"MP_LOSING_HQ");
	precacheString(&"MP_MAXHOLDTIME_MINUTESANDSECONDS");
	precacheString(&"MP_MAXHOLDTIME_MINUTES");
	precacheString(&"MP_MAXHOLDTIME_SECONDS");
	precacheString(&"MP_UPTEAM");
	precacheString(&"MP_DOWNTEAM");
	precacheString(&"MP_RESPAWN_WHEN_RADIO_NEUTRALIZED");
	precacheString(&"MP_MATCHSTARTING");
	precacheString(&"MP_MATCHRESUMING");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	// Back2Uo: precache the mod's shaders, models and strings.
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
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");
	level.graceperiod = true;

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	level._effect["radioexplosion"] = loadfx("fx/explosions/grenadeExp_blacktop.efx");

	// Keep only entities meant for the "tdm" game object set; HQ uses the TDM spawns.
	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit in minutes, capped at 1440 (24 hours)
	if(getcvar("scr_hq_timelimit") == "")
		setcvar("scr_hq_timelimit", "30");
	else if(getcvarfloat("scr_hq_timelimit") > 1440)
		setcvar("scr_hq_timelimit", "1440");
	level.timelimit = getcvarfloat("scr_hq_timelimit");
	setCvar("ui_hq_timelimit", level.timelimit);
	makeCvarServerInfo("ui_hq_timelimit", "30");

	// Score limit per map
	if(getcvar("scr_hq_scorelimit") == "")
		setcvar("scr_hq_scorelimit", "300");
	level.scorelimit = getcvarint("scr_hq_scorelimit");
	setCvar("ui_hq_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_hq_scorelimit", "300");

	// Draws a team icon over teammates
	if(getcvar("scr_drawfriend") == "")
		setcvar("scr_drawfriend", "1");
	level.drawfriend = getcvarint("scr_drawfriend");

	if(!isdefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;
	level.roundStarted = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	level.zradioradius = 72; // Z Distance players must be from a radio to capture/neutralize it
	level.captured_radios["allies"] = 0;
	level.captured_radios["axis"] = 0;

	// Capture progress bar size in pixels. Capture progress is counted in bar pixels (see hq_radio_think).
	level.progressBarHeight = 12;

	if(level.splitscreen)
		level.progressBarWidth = 152;
	else
		level.progressBarWidth = 192;

	// HQ tuning: delay before a radio appears (s), default capture radius (units), max hold time (s),
	// points for neutralizing a radio, and extra capture speed per player in range.
	level.RadioSpawnDelay = 15;
	level.radioradius = 120;
	level.respawngracetime = 5;
	level.RadioMaxHoldSeconds = 120;
	level.timesCaptured = 0;
	level.nextradio = 0;
	level.spawnframe = 0;
	level.DefendingRadioTeam = "none";
	level.NeutralizingPoints = 10;
	level.MultipleCaptureBias = 1;

	// Back2Uo: respawn delay in seconds from back2uo_hq_waitrespawn (default 10, range 0-60).
	level.respawndelay = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hq_waitrespawn", 10, 0, 60, "int");;

	// Blocks for one frame (hq_setup waits 0.05 before reading level.radio).
	hq_setup();

	thread hq_points();
	thread startGame();
	thread updateGametypeCvars();

	// Back2Uo: run the mod's gametype start hook.
	if(game["back2uo_enable"]) thread back2uo\_back2uo_player::back2uo_start_gametype();
}

/*
=============
dummy

Waits until the end of the frame, then sends the level "connecting" notify for this player,
so threads started in the same frame can catch it.
Called on: self = player
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

Engine callback when a client connects. Waits for "begin", logs the join, then either restores
the team and weapon kept in self.pers (map restart) or opens the server info / team menu as a
spectator. Finally runs the mod's connect hook.
Called on: self = player
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
	// Game log line: J;guid;client number;name
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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

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

Engine callback when a client disconnects. Clears the player's Xenon team rank, logs the quit
and runs the mod's disconnect hook.
Called on: self = player
=============
*/
Callback_PlayerDisconnect()
{
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

	// Back2Uo: per-player mod cleanup on disconnect.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_disconnect();
}

/*
=============
Callback_PlayerDamage

Engine callback for every damage event on a player. Back2Uo first scales the damage (weapon
strength, melee strength, helmet save) and ignores damage on spawn protected players; then the
stock friendly fire rules apply the damage and the hit is written to the game log.
Called on: self = damaged player
Params: eInflictor - entity that did the damage (player, grenade, ...); eAttacker - entity credited
		with it; iDamage - damage amount; iDFlags - level.iDFLAGS_* bits; sMeansOfDeath - MOD_* type;
		sWeapon - weapon name; vPoint - impact point; vDir - damage direction; sHitLoc - body part hit;
		psOffsetTime - client time offset (killcam)
=============
*/
Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	// Back2Uo: hand the damage event to the mod's damage handler (threaded, cannot change iDamage here).
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_damage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	// Back2Uo: damage modifiers and spawn protection.
	if(game["back2uo_enable"])
	{
		// Weapon strength: scale damage by the per-weapon percentage in level.back2uo_weaponstrength.
		if(game["back2uo_weaponsystem_enable"])
		{
			if(isdefined(sWeapon) && isdefined(sMeansOfDeath) && sMeansOfDeath != "MOD_MELEE" && sWeapon != "None")
			{
				if(isdefined(level.back2uo_weaponstrength) && isdefined(level.back2uo_weaponstrength[sWeapon]))
				{
					back2uo_wdamage = level.back2uo_weaponstrength[sWeapon] / 100;
					iDamage = int(iDamage * back2uo_wdamage);
				}
			}

			// Melee strength: scale melee damage by level.back2uo_melee_strength percent.
			if(isdefined(sMeansOfDeath) && sMeansOfDeath == "MOD_MELEE")
			{
				back2uo_wdamage2 = level.back2uo_melee_strength / 100;
				iDamage = int(iDamage * back2uo_wdamage2);
			}
		}

		// Helmet save (back2uo_helmluck): the first head/neck hit does only 2/3 damage. The flag in self.pers
		// is cleared again by _back2uo_objects.gsc.
		// Note: '&&' binds tighter than '||', so the isdefined(sHitLoc) check does not guard the neck test.
		if(game["back2uo_helmpoppping_enable"] && level.back2uo_helmpopping_luck == 1)
		{
			if(isdefined(sHitLoc) && sHitLoc == "head" ||  sHitLoc == "neck")
			{
				if(!isdefined(self.pers["back2uo_helmsave"]))
				{
					iDamage = int(iDamage / 1.5);

					self.pers["back2uo_helmsave"] = true;
				}
			}
		}

		// Spawn protection: while the victim is protected, damage from other players is ignored and the attacker is warned.
		if(isdefined(eAttacker) && isdefined(self.back2uo_antiplay_sp_run) && isPlayer(eAttacker) && eAttacker != self && self.back2uo_antiplay_sp_run)
		{
			eAttacker thread back2uo\_back2uo_messages::back2uo_spawn_attacking();

			return;
		}
	}

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isdefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			// level.friendlyfire: 0 = off, 1 = on, 2 = reflect to attacker, 3 = shared (both take half)
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

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				friendly = true;
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
			lpattackname = eAttacker.name;
			lpattackGuid = eAttacker getGuid();
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isdefined(friendly))
		{
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}

		// Game log line: D;victim guid;num;team;name;attacker guid;num;team;name;weapon;damage;MOD;hit location
		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

/*
=============
Callback_PlayerKilled

Engine callback when a player dies. Updates scores (Back2Uo replaces the stock suicide and team kill
penalties), logs the kill and drops the body. If the last living defender died, the radio is
neutralized. Otherwise starts the respawn wait (respawn_timer / respawn_staydead), shows the
killcam and starts respawn().
Called on: self = killed player
Params: eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime - as in
		Callback_PlayerDamage; deathAnimDuration - death animation length, used for the body clone
=============
*/
Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;

	// Back2Uo: mod death handling (threaded).
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);

	// Back2Uo: remove the mod's per-player HUD effects (1 = keep the player position display).
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_clear_elements(1);

	doKillcam = false;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

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
		// Back2Uo: hit distance message for kills on enemies (called without the back2uo_enable check).
		if(self.pers["team"] != attacker.pers["team"])
		{
			back2uo\_back2uo_weaponsystem::back2uo_hit_distance(attacker, sMeansOfDeath, sWeapon, sHitLoc);
		}

		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// Back2Uo: deduct level.back2uo_selfkill_mpoints from the player's score for a suicide.
			if(game["back2uo_enable"] && game["back2uo_playerpoints_enable"])
			{
				attacker back2uo\_back2uo_tools::back2uo_losepoints_ofplayer(level.back2uo_selfkill_mpoints);
			}

			// Suicide from a team switch: take a point back if the switch makes the teams uneven by more than one.
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

			// Back2Uo: team kills deduct level.back2uo_teamkill_mpoints instead of the stock -1; enemy kills give +1.
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

	level hq_removeall_hudelems(self);

	body = self cloneplayer(deathAnimDuration);

	// Back2Uo: blood/gore effects on the dropped body.
	if(game["back2uo_enable"])
	{
		if(isdefined(self) && isdefined(attacker) && isdefined(self.pers["team"]) && isdefined(attacker.pers["team"]))
		{
			self thread back2uo\gore\_back2uo_killedplayer::back2uo_killedplayer_blood(body, self.pers["team"], attacker.pers["team"]);
		}
	}

	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	// Note: both checks below read level.DefendingRadioTeam at the same moment, so allowInstantRespawn
	// stays false here; only the last-defender check further down sets it.
	defendingBeforeDeath = true;
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam != self.pers["team"]))
		defendingBeforeDeath = false;

	defendingAfterDeath = false;
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]))
		defendingAfterDeath = true;

	allowInstantRespawn = false;
	if((!defendingBeforeDeath) && (defendingAfterDeath))
		allowInstantRespawn = true;

	// If the last living defender died, the radio is neutralized and nobody has to wait.
	level updateTeamStatus();
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && (level.exist[self.pers["team"]] <= 0))
	{
		allowInstantRespawn = true;
		for(i = 0; i < level.radio.size; i++)
		{
			if(level.radio[i].hidden == true)
				continue;
			level hq_radio_capture(level.radio[i], "none");
			break;
		}
	}

	// Seconds before the killcam / respawn starts.
	delay = 2;

	if((level.roundStarted) && (!allowInstantRespawn))
	{
		self thread respawn_timer(delay);
		self thread respawn_staydead(delay);
	}

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
	{
		// Back2Uo: no killcam for artillery kills.
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

Spawns the player at a team spawnpoint away from the radios, sets model, loadout and objective
text, then runs the mod's spawn hook.
Called on: self = player
=============
*/
spawnPlayer()
{
	self endon("disconnect");

	if((!isdefined(self.pers["weapon"])) || (!isdefined(self.pers["team"])))
		return;

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

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	// HQ spawn logic: near teammates and away from the active radio.
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints);

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

	if(!isdefined(self))
		return;

	// Back2Uo: put the weapon straight into the primary slot and request 999 ammo/clip ammo (full).
	if(game["back2uo_enable"])
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);
		self setSpawnWeapon(self.pers["weapon"]);
	}
	else
	{
		// Stock: give the weapon with full ammo.
		self giveWeapon(self.pers["weapon"]);
		self giveMaxAmmo(self.pers["weapon"]);
		self setSpawnWeapon(self.pers["weapon"]);
	}

	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
			self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"MP_ESTABLISH_AND_DEFEND");

	self thread updateTimer();

	// Let other end-of-frame scripts finish before announcing the spawn.
	waittillframeend;
	self notify("spawned_player");

	// Back2Uo: run the mod's spawn hook.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spawn();

	// Back2Uo: remember the spawn ammo of both slots; the weapon system uses it as the full ammo reference.
	self.pers["back2uo_weaponspawn_prislotammo"] = self getweaponslotammo("primary");
	self.pers["back2uo_weaponspawn_pribslotammo"] = self getweaponslotammo("primaryb");
}

/*
=============
spawnSpectator

Puts the player into spectator mode at the given position or at a random intermission
spawnpoint, and runs the mod's spectator hook.
Called on: self = player
Params: origin - optional spawn position; angles - optional view angles
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

	// Back2Uo: run the mod's spectator hook.
	if(game["back2uo_enable"]) self thread back2uo\_back2uo_player::back2uo_player_spectator();

	level hq_removeall_hudelems(self);
}

/*
=============
spawnIntermission

Moves the player into the end-of-map intermission view at a random intermission spawnpoint.
Called on: self = player
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

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	level hq_removeall_hudelems(self);
	self thread updateTimer();
}

/*
=============
respawn

Respawn flow after death. Leaves the dead player spectating at the death position, waits for the
respawn timer (and, for defenders, for the radio to be neutralized), then waits for the use button
unless scr_forcerespawn is set, and spawns the player.
Called on: self = player
=============
*/
respawn()
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isdefined(self.pers["weapon"]))
		return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "spectator";

	if(isdefined(self.dead_origin) && isdefined(self.dead_angles))
	{
		// Spectate from 16 units above the death position.
		origin = self.dead_origin + (0, 0, 16);
		angles = self.dead_angles;
	}
	else
	{
		origin = self.origin + (0, 0, 16);
		angles = self.angles;
	}

	self spawn(origin, angles);

	// WaitingOnTimer = respawn delay running; WaitingOnNeutralize = defenders stay dead until the radio is gone.
	while(isdefined(self.WaitingOnTimer) || ((self.pers["team"] == level.DefendingRadioTeam) && isdefined(self.WaitingOnNeutralize)))
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

Shows the "press use to spawn" hint and notifies "respawn" when the use button is pressed.
The hint is removed on "respawn" or "end_respawn".
Called on: self = player
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

Destroys the respawn hint once "remove_respawntext" is notified.
Called on: self = player
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

Waits for the given notify, then triggers removal of the respawn hint.
Called on: self = player
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

Records the start time, creates the map clock if a time limit is set, and checks the time
limit once per second.
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

		// Back2Uo: clock at the bottom center of the 640x480 screen, semi transparent.
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

Ends the map: picks the winner by team score, plays the announcer, logs winners and losers,
moves everyone to intermission, sets Xenon ranks, waits 10 seconds and exits the level.
Also registered as level.endgameconfirmed.
Called on: level
=============
*/
endMap()
{
	game["state"] = "intermission";
	level notify("intermission");

	// Back2Uo: run the mod's end-of-map hook (blocking call).
	if(game["back2uo_enable"]) back2uo\_back2uo_player::back2uo_map_end();

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	winners = undefined;
	losers = undefined;

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		// Note: plain string, not a localized &"..." reference like the win texts.
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

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		winners = "";
		losers = "";
	}

	if(winningteam == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winningteam == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers("MP_announcer_round_draw");

	// Back2Uo: show the result through the mod's message instead of the objective text.
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
			if((isdefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isdefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpGuid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();

		// Back2Uo: clear the objective text; the result is shown by back2uo_player_message above.
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

	// Show the scoreboard for 10 seconds before the map changes.
	wait 10;
	exitLevel(false);
}

/*
=============
checkTimeLimit

Ends the map once level.timelimit (minutes) has passed.
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

Ends the map once either team reaches level.scorelimit.
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

Polls scr_hq_timelimit and scr_hq_scorelimit every second so they can be changed at runtime.
A time limit change restarts the clock from now.
Called on: level
=============
*/
updateGametypeCvars()
{
	wait 1;
	for(;;)
	{
		timelimit = getcvarfloat("scr_hq_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setcvar("scr_hq_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_hq_timelimit", level.timelimit);
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isdefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.horzAlign = "left";
					level.clock.vertAlign = "top";

					// Back2Uo: same clock position as in startGame().
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

		scorelimit = getcvarint("scr_hq_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_hq_scorelimit", level.scorelimit);
			level notify("update_allhud_score");
		}
		checkScoreLimit();

		wait 1;
	}
}

/*
=============
printJoinedTeam

Announces that the player joined allies or axis (not on splitscreen).
Called on: self = player
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
hq_setup

Sets up the radios: uses level.radio from the level script or the "hqradio" entities and aborts
with a map error if there are fewer than 3. Resets team scores, hides every radio, starts one
hq_radio_think per radio, shuffles the radio order and starts hq_obj_think.
Called on: level
=============
*/
hq_setup()
{
	wait 0.05;

	maperrors = [];

	if(!isdefined(level.radio))
		level.radio = getentarray("hqradio", "targetname");

	if(level.radio.size < 3)
		maperrors[maperrors.size] = "^1Less than 3 entities found with \"targetname\" \"hqradio\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	setTeamScore("allies", 0);
	setTeamScore("axis", 0);

	for(i = 0; i < level.radio.size; i++)
	{
		level.radio[i] setmodel(game["radio_model"]);
		level.radio[i].team = "none";
		level.radio[i].holdtime_allies = 0;
		level.radio[i].holdtime_axis = 0;
		level.radio[i].hidden = true;
		level.radio[i] hide();

		// script_radius on the radio entity overrides the default capture radius.
		if((!isdefined(level.radio[i].script_radius)) || (level.radio[i].script_radius <= 0))
			level.radio[i].radius = level.radioradius;
		else
			level.radio[i].radius = level.radio[i].script_radius;

		level thread hq_radio_think(level.radio[i]);
	}

	hq_randomize_radioarray();

	level thread hq_obj_think();
}

/*
=============
hq_randomize_radioarray

Shuffles level.radio in place; the array order is the order in which radios appear.
=============
*/
hq_randomize_radioarray()
{
	for(i = 0; i < level.radio.size; i++)
	{
		rand = randomint(level.radio.size);
		temp = level.radio[i];
		level.radio[i] = level.radio[rand];
		level.radio[rand] = temp;
	}
}

/*
=============
hq_obj_think

Spawns the next radio if none is visible: takes the next radio in the shuffled order (reshuffles
at the end and avoids the same radio twice in a row), waits until both teams have players,
waits level.RadioSpawnDelay, then shows the radio and adds its objective and objpoint.
Called on: level
Params: radio - the radio that was just in play (optional)
=============
*/
hq_obj_think(radio)
{
	NeutralRadios = 0;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true)
			continue;
		NeutralRadios++;
	}

	if(NeutralRadios <= 0)
	{
		if(level.nextradio > level.radio.size - 1)
		{
			hq_randomize_radioarray();
			level.nextradio = 0;

			if(isdefined(radio))
			{
				// same radio twice in a row so go to the next radio
				if(radio == level.radio[level.nextradio])
					level.nextradio++;
			}
		}

		// Pick a decoy position (not the last or next radio) for a fake A/B marker. The decoy markers
		// are disabled below, so only randAorB is still used.
		randAorB = undefined;
		if(level.radio.size >= 4)
		{
			fakeposition = level.radio[randomint(level.radio.size)];
			if(isdefined(level.radio[(level.nextradio - 1)]))
			{
				while((fakeposition == level.radio[level.nextradio]) || (fakeposition == level.radio[level.nextradio - 1]))
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			else
			{
				while(fakeposition == level.radio[level.nextradio])
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			randAorB = randomint(2);
			// Disabled: decoy objective and objpoint at the fake position.
			//			objective_add(1, "current", fakeposition.origin, game["radio_prespawn"][randAorB]);
			//			thread maps\mp\gametypes\_objpoints::addObjpoint(fakeposition.origin, "1", game["radio_prespawn_objpoint"][randAorB]);
		}

		if(!isdefined(randAorB))
			otherAorB = 2; //use original icon since there is only one objective that will show
		else if(randAorB == 1)
			otherAorB = 0;
		else
			otherAorB = 1;
		// Disabled: A/B prespawn objective for the next radio (replaced by the plain objective below).
		//		objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][otherAorB]);
		//		thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", game["radio_prespawn_objpoint"][otherAorB]);

		level hq_check_teams_exist();
		restartRound = false;

		// Wait until both teams have players; restartRound() resets the match on the first start.
		while((!level.alliesexist) || (!level.axisexist))
		{
			restartRound = true;
			wait 2;
			level hq_check_teams_exist();
		}

		if(restartRound)
			restartRound();
		level.roundStarted = true;

		iprintln(&"MP_RADIOS_SPAWN_IN_SECONDS", level.RadioSpawnDelay);
		wait level.RadioSpawnDelay;

		level.radio[level.nextradio] show();
		level.radio[level.nextradio].hidden = false;

		level thread playSoundOnPlayers("explo_plant_no_tick");
		objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][2]);
		// Disabled: neutral icon and removal of the decoy objective.
		//		objective_icon(0, game["radio_none"]);
		//		objective_delete(1);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", "objpoint_radio");

		if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) // AXIS HAVE A RADIO AND ALLIES DONT
			objective_team(0, "allies");
		else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) // ALLIES HAVE A RADIO AND AXIS DONT
			objective_team(0, "axis");
		else // NO TEAMS HAVE A RADIO
			objective_team(0, "none");

		level.nextradio++;
	}
}

/*
=============
hq_radio_think

Per-radio loop (every 0.05 s) while the radio is visible. Counts players of each team in range,
draws the per-player capture/destroy bars and the team-wide "losing HQ" bars, advances hold time
and calls hq_radio_capture when a bar is full. A neutral radio is captured by a team alone in
range (only if that team holds no radio); an owned radio is neutralized by the enemy team.
Called on: level
Params: radio - radio entity to watch
=============
*/
hq_radio_think(radio)
{
	level endon("intermission");
	while(!level.mapended)
	{
		wait 0.05;
		if(!radio.hidden)
		{
			players = getentarray("player", "classname");
			radio.allies = 0;
			radio.axis = 0;
			for(i = 0; i < players.size; i++)
			{
				if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
				{
					// In range: 3D distance within radio.radius and height difference within level.zradioradius.
					if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
					{
						if(players[i].pers["team"] == radio.team)
							continue;

						// A team that already holds a radio cannot capture another neutral one.
						if((level.captured_radios[players[i].pers["team"]] > 0) && (radio.team == "none"))
							continue;

						if((!isdefined(players[i].radioicon)) || (!isdefined(players[i].radioicon[0])))
						{
							players[i].radioicon[0] = newClientHudElem(players[i]);

							// Back2Uo: radio icon at the top right (same spot as the mod's bomb timer icon).
							if(game["back2uo_enable"])
							{
								players[i].radioicon[0].x = 612;
								players[i].radioicon[0].y = 44;
							}
							else
							{
								players[i].radioicon[0].x = 30;
								players[i].radioicon[0].y = 95;
							}

							players[i].radioicon[0].alignX = "center";
							players[i].radioicon[0].alignY = "middle";
							players[i].radioicon[0].horzAlign = "left";
							players[i].radioicon[0].vertAlign = "top";
							players[i].radioicon[0] setShader("field_radio", 40, 32);
						}

						// Capturing a neutral radio: the white bar grows with the hold time.
						if((level.captured_radios[players[i].pers["team"]] <= 0) && (radio.team == "none"))
						{
							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture.y = 70;
								else
									players[i].progressbar_capture.y = 104;

								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}
							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);
							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);

								if(level.splitscreen)
									players[i].progressbar_capture2.y = 70;
								else
									players[i].progressbar_capture2.y = 105;

								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}
							if(players[i].pers["team"] == "allies")
								players[i].progressbar_capture2 setShader("white", radio.holdtime_allies, level.progressBarHeight - 4);
							else
								players[i].progressbar_capture2 setShader("white", radio.holdtime_axis, level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture3.y = 16;
								else
									players[i].progressbar_capture3.y = 50;

								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_ESTABLISHING_HQ");
							}
						}
						else if(radio.team != "none")
						{
							// Destroying an enemy radio: the white bar shrinks as the hold time grows.
							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture.y = 70;
								else
									players[i].progressbar_capture.y = 104;

								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}
							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);

							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);

								if(level.splitscreen)
									players[i].progressbar_capture2.y = 70;
								else
									players[i].progressbar_capture2.y = 105;

								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}
							if(players[i].pers["team"] == "allies")
								players[i].progressbar_capture2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
							else
								players[i].progressbar_capture2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture3.y = 16;
								else
									players[i].progressbar_capture3.y = 50;

								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_DESTROYING_HQ");
							}

							// Team-wide red bar for the owners, showing how far the enemy is with destroying their HQ.
							if(radio.team == "allies")
							{
								if(!isdefined(level.progressbar_axis_neutralize))
								{
									level.progressbar_axis_neutralize = newTeamHudElem("allies");
									level.progressbar_axis_neutralize.x = 0;

									if(level.splitscreen)
										level.progressbar_axis_neutralize.y = 70;
									else
										level.progressbar_axis_neutralize.y = 104;

									level.progressbar_axis_neutralize.alignX = "center";
									level.progressbar_axis_neutralize.alignY = "middle";
									level.progressbar_axis_neutralize.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize.alpha = 0.5;
								}
								level.progressbar_axis_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

								if(!isdefined(level.progressbar_axis_neutralize2))
								{
									level.progressbar_axis_neutralize2 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);

									if(level.splitscreen)
										level.progressbar_axis_neutralize2.y = 70;
									else
										level.progressbar_axis_neutralize2.y = 105;

									level.progressbar_axis_neutralize2.alignX = "left";
									level.progressbar_axis_neutralize2.alignY = "middle";
									level.progressbar_axis_neutralize2.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize2.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize2.color = (.8,0,0);
								}
								if(players[i].pers["team"] == "allies")
									level.progressbar_axis_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
								else
									level.progressbar_axis_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

								if(!isdefined(level.progressbar_axis_neutralize3))
								{
									level.progressbar_axis_neutralize3 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize3.x = 0;

									if(level.splitscreen)
										level.progressbar_axis_neutralize3.y = 16;
									else
										level.progressbar_axis_neutralize3.y = 50;

									level.progressbar_axis_neutralize3.alignX = "center";
									level.progressbar_axis_neutralize3.alignY = "middle";
									level.progressbar_axis_neutralize3.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize3.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize3.archived = false;
									level.progressbar_axis_neutralize3.font = "default";
									level.progressbar_axis_neutralize3.fontscale = 2;
									level.progressbar_axis_neutralize3 settext(&"MP_LOSING_HQ");
								}
							}
							else
								if(radio.team == "axis")
								{
									if(!isdefined(level.progressbar_allies_neutralize))
									{
										level.progressbar_allies_neutralize = newTeamHudElem("axis");
										level.progressbar_allies_neutralize.x = 0;

										if(level.splitscreen)
											level.progressbar_allies_neutralize.y = 70;
										else
											level.progressbar_allies_neutralize.y = 104;

										level.progressbar_allies_neutralize.alignX = "center";
										level.progressbar_allies_neutralize.alignY = "middle";
										level.progressbar_allies_neutralize.horzAlign = "center_safearea";
										level.progressbar_allies_neutralize.vertAlign = "center_safearea";
										level.progressbar_allies_neutralize.alpha = 0.5;
									}
									level.progressbar_allies_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

									if(!isdefined(level.progressbar_allies_neutralize2))
									{
										level.progressbar_allies_neutralize2 = newTeamHudElem("axis");
										level.progressbar_allies_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);

										if(level.splitscreen)
											level.progressbar_allies_neutralize2.y = 70;
										else
											level.progressbar_allies_neutralize2.y = 105;

										level.progressbar_allies_neutralize2.alignX = "left";
										level.progressbar_allies_neutralize2.alignY = "middle";
										level.progressbar_allies_neutralize2.horzAlign = "center_safearea";
										level.progressbar_allies_neutralize2.vertAlign = "center_safearea";
										level.progressbar_allies_neutralize2.color = (.8,0,0);
									}
									if(players[i].pers["team"] == "allies")
										level.progressbar_allies_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
									else
										level.progressbar_allies_neutralize2 setShader("white", ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

									if(!isdefined(level.progressbar_allies_neutralize3))
									{
										level.progressbar_allies_neutralize3 = newTeamHudElem("axis");
										level.progressbar_allies_neutralize3.x = 0;

										if(level.splitscreen)
											level.progressbar_allies_neutralize3.y = 16;
										else
											level.progressbar_allies_neutralize3.y = 50;

										level.progressbar_allies_neutralize3.alignX = "center";
										level.progressbar_allies_neutralize3.alignY = "middle";
										level.progressbar_allies_neutralize3.horzAlign = "center_safearea";
										level.progressbar_allies_neutralize3.vertAlign = "center_safearea";
										level.progressbar_allies_neutralize3.archived = false;
										level.progressbar_allies_neutralize3.font = "default";
										level.progressbar_allies_neutralize3.fontscale = 2;
										level.progressbar_allies_neutralize3 settext(&"MP_LOSING_HQ");
									}
							}
						}

						if(players[i].pers["team"] == "allies")
							radio.allies++;
						else
							radio.axis++;

						players[i].inrange = true;
					}
					else if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
					{
						// Out of range: remove the player's radio HUD.
						if((isdefined(players[i].radioicon)) || (isdefined(players[i].radioicon[0])))
							players[i].radioicon[0] destroy();
						if(isdefined(players[i].progressbar_capture))
							players[i].progressbar_capture destroy();
						if(isdefined(players[i].progressbar_capture2))
							players[i].progressbar_capture2 destroy();
						if(isdefined(players[i].progressbar_capture3))
							players[i].progressbar_capture3 destroy();

						players[i].inrange = undefined;
					}
				}
			}

			if(radio.team == "none") // Radio is captured if no enemies around
			{
				if((radio.allies > 0) && (radio.axis <= 0) && (radio.team != "allies"))
				{
					// Adds one bar pixel per player per frame (times level.MultipleCaptureBias).
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));

					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
					{
						// Note: the first branch never runs, radio.team is always "none" in this block.
						if((level.captured_radios["allies"] > 0) && (radio.team != "none"))
							level hq_radio_capture(radio, "none");
						else if(level.captured_radios["allies"] <= 0)
							level hq_radio_capture(radio, "allies");
					}
				}
				else if((radio.axis > 0) && (radio.allies <= 0) && (radio.team != "axis"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));

					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
					{
						if((level.captured_radios["axis"] > 0) && (radio.team != "none"))
							level hq_radio_capture(radio, "none");
						else if(level.captured_radios["axis"] <= 0)
							level hq_radio_capture(radio, "axis");
					}
				}
				else
				{
					// Contested or empty: reset progress and remove the bars of players still in range.
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
						{
							if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
							{
								if(isdefined(players[i].progressbar_capture))
									players[i].progressbar_capture destroy();
								if(isdefined(players[i].progressbar_capture2))
									players[i].progressbar_capture2 destroy();
								if(isdefined(players[i].progressbar_capture3))
									players[i].progressbar_capture3 destroy();
							}
						}
					}
				}
			}
			else // Radio should go to neutral first
			{
				// No enemy near the owned radio: remove the owners' warning bar.
				if((radio.team == "allies") && (radio.axis <= 0))
				{
					if(isdefined(level.progressbar_axis_neutralize))
						level.progressbar_axis_neutralize destroy();
					if(isdefined(level.progressbar_axis_neutralize2))
						level.progressbar_axis_neutralize2 destroy();
					if(isdefined(level.progressbar_axis_neutralize3))
						level.progressbar_axis_neutralize3 destroy();
				}
				else if((radio.team == "axis") && (radio.allies <= 0))
				{
					if(isdefined(level.progressbar_allies_neutralize))
						level.progressbar_allies_neutralize destroy();
					if(isdefined(level.progressbar_allies_neutralize2))
						level.progressbar_allies_neutralize2 destroy();
					if(isdefined(level.progressbar_allies_neutralize3))
						level.progressbar_allies_neutralize3 destroy();
				}

				if((radio.allies > 0) && (radio.team == "axis"))
				{
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));
					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else if((radio.axis > 0) && (radio.team == "allies"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));
					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;
				}
			}
		}
	}
}

/*
=============
hq_radio_capture

Changes the owner of a radio and clears all capture HUD. If the radio was owned, it explodes and
the shutdown is announced. team "none": the radio is hidden, the neutralizing team gets
level.NeutralizingPoints and living players are healed. Otherwise the team becomes the defender,
its living players are healed and the max hold timer starts. In both cases all waiting dead
players are released and hq_obj_think runs (it spawns a new radio only when none is visible).
Called on: level
Params: radio - radio entity; team - new owner: "allies", "axis" or "none" (neutralize)
=============
*/
hq_radio_capture(radio, team)
{
	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				if(isdefined(players[i].progressbar_capture))
					players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2))
					players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3))
					players[i].progressbar_capture3 destroy();
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;
		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;
		// Announce the shutdown and remove the owners' "losing HQ" bars.
		if(radio.team == "allies")
		{
			if(getTeamCount("axis") && !level.splitscreen)
				iprintln(&"MP_SHUTDOWN_ALLIED_HQ");

			if(isdefined(level.progressbar_axis_neutralize))
				level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2))
				level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3))
				level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			if(getTeamCount("allies") && !level.splitscreen)
				iprintln(&"MP_SHUTDOWN_AXIS_HQ");

			if(isdefined(level.progressbar_allies_neutralize))
				level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2))
				level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3))
				level.progressbar_allies_neutralize3 destroy();
		}
	}

	if(radio.team == "none")
		radio playsound("explo_plant_no_tick");

	NeutralizingTeam = undefined;
	if(radio.team == "allies")
		NeutralizingTeam = "axis";
	else if(radio.team == "axis")
		NeutralizingTeam = "allies";
	radio.team = team;

	// Ends hq_maxholdtime_think of the previous owner.
	level notify("Radio State Changed");

	if(team == "none")
	{
		// RADIO GOES NEUTRAL
		radio setmodel(game["radio_model"]);
		radio hide();
		radio.hidden = true;

		radio playsound("explo_radio");
		if(isdefined(NeutralizingTeam))
		{
			if(NeutralizingTeam == "allies")
				level thread playSoundOnPlayers("mp_announcer_axishqdest");
			else if(NeutralizingTeam == "axis")
				level thread playSoundOnPlayers("mp_announcer_alliedhqdest");
		}

		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		level.DefendingRadioTeam = "none";
		level notify("Radio Neutralized");

		// Give points to the neutralizing team
		if(isdefined(NeutralizingTeam))
		{
			if((NeutralizingTeam == "allies") || (NeutralizingTeam == "axis"))
			{
				if(getTeamCount(NeutralizingTeam))
				{
					setTeamScore(NeutralizingTeam, getTeamScore(NeutralizingTeam) + level.NeutralizingPoints);
					level notify("update_allhud_score");

					if(!level.splitscreen)
					{
						if(NeutralizingTeam == "allies")
							iprintln(&"MP_SCORED_ALLIES", level.NeutralizingPoints);
						else
							iprintln(&"MP_SCORED_AXIS", level.NeutralizingPoints);
					}
				}
			}
		}

		// Heal all living players to full health
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_removehudelem_allplayers(radio);
	}
	else
	{
		// RADIO CAPTURED BY A TEAM
		level.captured_radios[team] = 1;
		level.DefendingRadioTeam = team;

		if(team == "allies")
		{
			if(!level.splitscreen)
				iprintln(&"MP_SETUP_HQ_ALLIED");

			if(game["allies"] == "british")
				alliedsound = "UK_mp_hqsetup";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_hqsetup";
			else
				alliedsound = "US_mp_hqsetup";

			level thread playSoundOnPlayers(alliedsound, "allies");
			if(!level.splitscreen)
				level thread playSoundOnPlayers("GE_mp_enemyhqsetup", "axis");
		}
		else
		{
			if(!level.splitscreen)
				iprintln(&"MP_SETUP_HQ_AXIS");

			if(game["allies"] == "british")
				alliedsound = "UK_mp_enemyhqsetup";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_enemyhqsetup";
			else
				alliedsound = "US_mp_enemyhqsetup";

			level thread playSoundOnPlayers("GE_mp_hqsetup", "axis");
			if(!level.splitscreen)
				level thread playSoundOnPlayers(alliedsound, "allies");
		}

		// Heal the living players of the new defending team
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == level.DefendingRadioTeam && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_maxholdtime_think();
	}

	objective_icon(0, (game["radio_" + team ]));
	objective_team(0, "none");

	objteam = "none";
	if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0))
		objteam = "allies";
	else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0))
		objteam = "axis";

	// Make all neutral radio objectives go to the right team
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true)
			continue;
		if(level.radio[i].team == "none")
			objective_team(0, objteam);
	}

	// Releases players waiting in respawn_staydead().
	level notify("finish_staydead");

	level thread hq_obj_think(radio);
}

/*
=============
hq_maxholdtime_think

Resets the radio via hq_radio_resetall once a team has held it for level.RadioMaxHoldSeconds.
Ended early by "Radio State Changed" when the radio is neutralized first.
Called on: level
=============
*/
hq_maxholdtime_think()
{
	level endon("Radio State Changed");
	assert(level.RadioMaxHoldSeconds > 2);
	if(level.RadioMaxHoldSeconds > 0)
		wait(level.RadioMaxHoldSeconds - 0.05);
	level thread hq_radio_resetall();
}

/*
=============
hq_points

Gives the defending team 1 point per second while it has players, then checks the score limit.
Called on: level
=============
*/
hq_points()
{
	while(!level.mapended)
	{
		if(level.DefendingRadioTeam != "none")
		{
			if(getTeamCount(level.DefendingRadioTeam))
			{
				setTeamScore(level.DefendingRadioTeam, getTeamScore(level.DefendingRadioTeam) + 1);
				level notify("update_allhud_score");
				checkScoreLimit();
			}
		}
		wait 1;
	}
}

/*
=============
hq_radio_resetall

Max hold time expired: removes the active radio without awarding neutralize points. Clears the
capture HUD, announces the max hold time, hides the radio, ends the grace period, releases all
waiting dead players and starts the next radio cycle.
Called on: level
=============
*/
hq_radio_resetall()
{
	// Find the radio that is in play
	radio = undefined;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == false)
			radio = level.radio[i];
	}

	if(!isdefined(radio))
		return;

	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				if(isdefined(players[i].progressbar_capture))
					players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2))
					players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3))
					players[i].progressbar_capture3 destroy();
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;

		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;

		// Team name argument for the max hold time message.
		localizedTeam = undefined;
		if(radio.team == "allies")
		{
			localizedTeam = (&"MP_UPTEAM");
			if(isdefined(level.progressbar_axis_neutralize))
				level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2))
				level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3))
				level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			localizedTeam = (&"MP_DOWNTEAM");
			if(isdefined(level.progressbar_allies_neutralize))
				level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2))
				level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3))
				level.progressbar_allies_neutralize3 destroy();
		}

		// Split the max hold time into minutes and seconds for the message.
		minutes = 0;
		maxTime = level.RadioMaxHoldSeconds;
		while(maxTime >= 60)
		{
			minutes++;
			maxTime -= 60;
		}
		seconds = maxTime;
		if((minutes > 0) && (seconds > 0))
			iprintlnbold(&"MP_MAXHOLDTIME_MINUTESANDSECONDS", localizedTeam, minutes, seconds);
		else
			if((minutes > 0) && (seconds <= 0))
				iprintlnbold(&"MP_MAXHOLDTIME_MINUTES", localizedTeam);
		else
			if((minutes <= 0) && (seconds > 0))
				iprintlnbold(&"MP_MAXHOLDTIME_SECONDS", localizedTeam, seconds);
	}

	radio.team = "none";
	level.DefendingRadioTeam = "none";
	objective_team(0, "none");

	radio setmodel(game["radio_model"]);
	radio hide();

	if(!level.mapended)
	{
		radio playsound("explo_radio");
		level thread playSoundOnPlayers("mp_announcer_hqdefended");
	}

	radio.hidden = true;
	objective_delete(0);
	thread maps\mp\gametypes\_objpoints::removeObjpoints();

	level.graceperiod = false;
	level thread hq_obj_think(radio);
	level thread hq_removehudelem_allplayers(radio);

	// All dead people should now respawn
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
	}

	level notify("finish_staydead");
}

/*
=============
hq_removeall_hudelems

Destroys one player's radio icon and capture progress bars. The loop over level.radio only
repeats the same checks.
Called on: level
Params: player - player whose HUD elements are removed
=============
*/
hq_removeall_hudelems(player)
{
	if(isdefined(self))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if((isdefined(player.radioicon)) && (isdefined(player.radioicon[0])))
				player.radioicon[0] destroy();
			if(isdefined(player.progressbar_capture))
				player.progressbar_capture destroy();
			if(isdefined(player.progressbar_capture2))
				player.progressbar_capture2 destroy();
			if(isdefined(player.progressbar_capture3))
				player.progressbar_capture3 destroy();
		}
	}
}

/*
=============
hq_removehudelem_allplayers

Destroys the radio icon and capture progress bars of every player.
Called on: level
Params: radio - unused
=============
*/
hq_removehudelem_allplayers(radio)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i]))
			continue;
		if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			players[i].radioicon[0] destroy();
		if(isdefined(players[i].progressbar_capture))
			players[i].progressbar_capture destroy();
		if(isdefined(players[i].progressbar_capture2))
			players[i].progressbar_capture2 destroy();
		if(isdefined(players[i].progressbar_capture3))
			players[i].progressbar_capture3 destroy();
	}
}

/*
=============
hq_check_teams_exist

Sets level.alliesexist / level.axisexist if at least one player (alive or dead) is on that team.
Called on: level
=============
*/
hq_check_teams_exist()
{
	players = getentarray("player", "classname");
	level.alliesexist = false;
	level.axisexist = false;
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i].pers["team"]) || players[i].pers["team"] == "spectator")
			continue;
		if(players[i].pers["team"] == "allies")
			level.alliesexist = true;
		else if(players[i].pers["team"] == "axis")
			level.axisexist = true;

		if(level.alliesexist && level.axisexist)
			return;
	}
}

/*
=============
updateTeamStatus

Counts the living players of each team into level.exist[team].
Called on: level
=============
*/
updateTeamStatus()
{
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
			level.exist[players[i].pers["team"]]++;
	}
}

/*
=============
restartRound

Called when both teams have players again. Before the first round it announces the match start,
waits 5 seconds, resets score and deaths and respawns all team players. Once the round has
started it only prints "match resuming".
Called on: level
=============
*/
restartRound()
{
	if(level.roundStarted)
	{
		iprintln(&"MP_MATCHRESUMING");
		return;
	}
	else
	{
		iprintln(&"MP_MATCHSTARTING");
		wait 5;
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && (player.pers["team"] == "allies" || player.pers["team"] == "axis"))
		{
			player.score = 0;
			player.deaths = 0;

			player spawnPlayer();
		}
	}
}

/*
=============
menuAutoAssign

Menu handler for auto-assign. Puts the player on the smaller team (lower score or random if equal),
kills the player if this means a team switch, and opens the weapon menu. On PC a player already
on a team gets the team menu instead.
Called on: self = player
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

		if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator")
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

Menu handler for joining the allies. Checks the team balance permission, kills the player if
switching teams, clears the weapon choice and opens the allied weapon menu.
Called on: self = player
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

Menu handler for joining the axis. Checks the team balance permission, kills the player if
switching teams, clears the weapon choice and opens the axis weapon menu.
Called on: self = player
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

Menu handler for joining the spectators. Kills a living player, clears team and weapon choice
and spawns the player as a spectator.
Called on: self = player
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

Menu handler for a weapon choice. Applies the server weapon restrictions. The first choice spawns
the player (or starts respawn() if a respawn wait is running); later choices take effect on the
next respawn.
Called on: self = player
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

		if(isdefined(self.WaitingOnTimer) || ((self.pers["team"] == level.DefendingRadioTeam) && isdefined(self.WaitingOnNeutralize)))
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

Keeps self.WaitingOnTimer set for delay + level.respawndelay seconds and shows the
"time till spawn" countdown (visibility is handled by updateTimer).
Called on: self = player
Params: delay - seconds after death before the countdown is shown
=============
*/
respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingOnTimer = true;

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
			// Hidden until updateTimer() decides which text this player sees.
			self.respawntimer.alpha = 0;
			self.respawntimer.archived = false;
			self.respawntimer.font = "default";
			self.respawntimer.fontscale = 2;
			self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
			self.respawntimer setTimer(level.respawndelay + delay);
		}

		wait delay;
		self thread updateTimer();

		wait level.respawndelay;

		if(isdefined(self.respawntimer))
			self.respawntimer destroy();
	}

	self.WaitingOnTimer = undefined;
}

/*
=============
respawn_staydead

Keeps self.WaitingOnNeutralize set and shows "respawn when radio neutralized" until the level
notifies "finish_staydead" (radio state change). respawn() only waits on this flag for
players on the defending team.
Called on: self = player
Params: delay - seconds before updateTimer() runs
=============
*/
respawn_staydead(delay)
{
	self endon("disconnect");

	if(isdefined(self.WaitingOnNeutralize))
		return;
	self.WaitingOnNeutralize = true;

	if(!isdefined(self.staydead))
	{
		self.staydead = newClientHudElem(self);
		self.staydead.x = 0;
		self.staydead.y = -50;
		self.staydead.alignX = "center";
		self.staydead.alignY = "middle";
		self.staydead.horzAlign = "center_safearea";
		self.staydead.vertAlign = "center_safearea";
		self.staydead.alpha = 0;
		self.staydead.archived = false;
		self.staydead.font = "default";
		self.staydead.fontscale = 2;
		self.staydead setText(&"MP_RESPAWN_WHEN_RADIO_NEUTRALIZED");
	}

	self thread delayUpdateTimer(delay);
	level waittill("finish_staydead");

	if(isdefined(self.staydead))
		self.staydead destroy();

	if(isdefined(self.respawntimer))
		self.respawntimer destroy();

	self.WaitingOnNeutralize = undefined;
}

/*
=============
delayUpdateTimer

Calls updateTimer() after the given delay.
Called on: self = player
Params: delay - seconds to wait
=============
*/
delayUpdateTimer(delay)
{
	self endon("disconnect");

	wait delay;
	thread updateTimer();
}

/*
=============
updateTimer

Shows the stay-dead text to players on the defending team and the respawn countdown to all
other team players; hides both for spectators and players without a weapon.
Called on: self = player
=============
*/
updateTimer()
{
	if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
	{
		if((isdefined(self.pers["team"])) && (self.pers["team"] == level.DefendingRadioTeam))
		{
			if(isdefined(self.respawntimer))
				self.respawntimer.alpha = 0;

			if(isdefined(self.staydead))
				self.staydead.alpha = 1;
		}
		else
		{
			if(isdefined(self.respawntimer))
				self.respawntimer.alpha = 1;

			if(isdefined(self.staydead))
				self.staydead.alpha = 0;
		}
	}
	else
	{
		if(isdefined(self.respawntimer))
			self.respawntimer.alpha = 0;

		if(isdefined(self.staydead))
			self.staydead.alpha = 0;
	}
}

/*
=============
playSoundOnPlayers

Plays a local sound for all players or for one team. On splitscreen only the first player
hears it.
Params: sound - sound alias; team - optional team filter
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
getTeamCount

Counts the players on a team (alive or dead).
Params: team - "allies" or "axis"
Returns: number of players
=============
*/
getTeamCount(team)
{
	count = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && (player.pers["team"] == team))
			count++;
	}

	return count;
}
