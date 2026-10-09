/*
	Back2Uo v2.1 - anti-play rules: spawn protection, AFK monitor, anti-camper marking

	Threads are started from _back2uo_player.gsc: back2uo_antiplay_afk(), back2uo_antiplay_camper()
	and back2uo_client_autodownload_init() on connect, back2uo_antiplay_spawn_start() on spawn,
	back2uo_switchspec() once on the level at init.
	Cvars (back2uomod.cfg): back2uo_antiplay_sp_* (spawn protection), back2uo_antiplay_afk_*
	(AFK limit), back2uo_antiplay_cmp_* (camper time, radius, marking time), back2uo_autodownload.
	AFK players are moved to spectator via the cvar g_switchspec (entity number of the player).
	The compass enemy firing functions at the end are not in use.
*/

/*
=============
back2uo_antiplay_spawn_start

Spawn protection. Runs one iteration per second (back2uo_player_origin waits 1 second) for
level.back2uo_antiplay_sp_time seconds and updates the spawn protection bar. While
self.back2uo_antiplay_sp_run is true the gametype damage callbacks ignore damage from
other players, and the artillery (warfx\_back2uo_artillery) skips this player.
With back2uo_antiplay_sp_move 1 the protection ends early when the player moves more than
50 units in a second or presses attack, melee or use.
Called on: self = player (threaded on spawn)
=============
*/
back2uo_antiplay_spawn_start()
{
	if(!game["back2uo_antiplay_sp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Spawn Save", "Run");

	level endon("back2uo_killthreads");
	self endon("disconnect");

	self.back2uo_spawntime = 0;
	// Allowed movement per second in units
	radius = 50;

	self iprintln(&"BACK2UOMOD_SPAWN_ENABLE_MSG");

	self.back2uo_antiplay_sp_run = true;

	// One iteration per second (the wait is inside back2uo_player_origin)
	for(self.back2uo_spawntime=0; self.back2uo_spawntime < level.back2uo_antiplay_sp_time; self.back2uo_spawntime++)
	{
		self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

		self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime);

		// Protection is waived on movement or action
		if(level.back2uo_antiplay_sp_move == 1)
		{
			if(isdefined(self_org) && self_org > radius || self attackButtonPressed() || self meleeButtonPressed() || self useButtonPressed())
			{
				// "1" = end of spawn protection, resets the bar
				self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime, "1");

				self iprintln(&"BACK2UOMOD_SPAWN_DISABLED_MSG");

				self.back2uo_antiplay_sp_run = false;

				return;
			}
		}
	}

	// Protection time is over
	self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime, "1");

	self iprintln(&"BACK2UOMOD_SPAWN_DISABLED_MSG");

	self.back2uo_antiplay_sp_run = false;
}

/*
=============
back2uo_antiplay_afk

AFK monitor. Counts about one tick per second while a living player moves less than 20 units,
stands upright and presses no attack/melee/use button. At level.back2uo_antiplay_afk_limit
the player gets a warning, 10 ticks later he is moved to spectator by writing his entity
number to g_switchspec (handled by back2uo_switchspec).
Called on: self = player (threaded on connect)
=============
*/
back2uo_antiplay_afk()
{
	if(!game["back2uo_antiplay_afk_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("AFK Monitor", "Run");

	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("afk_monitor", "self not exist");
		return;
	}

	level endon("intermission");
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Movement per second (units) below which the player counts as AFK
	radius = 20;
	self.back2uo_afk_time = 0;

	for(;;)
	{
		if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator")
		{
			// Disabled: debug output of the AFK counter
			//self iprintln(&"BACK2UOMOD_AFK_TIME", self.back2uo_afk_time);

			posi_type = back2uo\_back2uo_cvars::back2uo_player_stance();
			// Blocks for 1 second
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			// Movement, crouch/prone or a button press resets the counter
			if(self_org > radius || posi_type == "crouch" || posi_type == "prone" || self attackButtonPressed() || self meleeButtonPressed() || self useButtonPressed())
			{
				self.back2uo_afk_time = 0;
			}
			else if(self_org < radius)
			{
				self.back2uo_afk_time++;
			}

			if (self.back2uo_afk_time == level.back2uo_antiplay_afk_limit)
			{
				self iprintlnbold(&"BACK2UOMOD_AFK_WARNING_MSG");
			}
			else if(self.back2uo_afk_time >= level.back2uo_antiplay_afk_limit + 10)
			{
				// Request the move to spectator; back2uo_switchspec() polls this cvar
				thisPlayerNum = self getEntityNumber();
				setcvar("g_switchspec", thisPlayerNum);
				self iprintlnbold(&"BACK2UOMOD_AFK_SWICHTING_MSG");
				self.back2uo_afk_time = 0;
			}
		}
		else
		{
			self.back2uo_afk_time = 0;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_antiplay_camper

Anti-camper monitor. Counts about one tick per second while the player stays within
level.back2uo_antiplay_cmp_radius units. At level.back2uo_antiplay_cmp_timer the player is
warned; 20 ticks later he is marked on the compass of all players for
level.back2uo_antiplay_cmp_objtime seconds. Leaving the radius resets the counter and pauses 5 seconds.
Called on: self = player (threaded on connect)
=============
*/
back2uo_antiplay_camper()
{
	if(!game["back2uo_antiplay_cmp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Camper Monitor", "Run");

	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("camper_monitor", "self not exist");
		return;
	}

	level endon("intermission");
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	radius = level.back2uo_antiplay_cmp_radius;
	self.back2uo_campingtime = 0;
	self.back2uo_antiplay_camper_marked = false;

	for(;;)
	{
		// Not counted while already marked
		if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && !self.back2uo_antiplay_camper_marked)
		{
			// Blocks for 1 second
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			if(self_org > radius)
			{
				self.back2uo_campingtime = 0;

				wait 5;
			}
			else if(self_org < radius)
			{
				self.back2uo_campingtime++;
			}

			if (self.back2uo_campingtime == level.back2uo_antiplay_cmp_timer)
			{
				self iprintlnbold(&"BACK2UOMOD_CAMPING_WARNING_MSG");
			}
			else if(self.back2uo_campingtime > level.back2uo_antiplay_cmp_timer + 20)
			{
				self iprintlnbold(&"BACK2UOMOD_CAMPING_MARKED_MSG", level.back2uo_antiplay_cmp_objtime);

				// Compass marker and its timed removal
				thread back2uo_antiplay_camper_start();
				thread back2uo_antiplay_camper_remove();

				self.back2uo_antiplay_camper_marked = true;
				self.back2uo_campingtime = 0;

				continue;
			}
		}
		else
		{
			self.back2uo_campingtime = 0;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_antiplay_camper_start

Adds a compass objective with the nation-specific camper icon and moves it with the
player every server frame until the objective is removed or the player goes spectator.
objective_team "none" makes the marker visible to both teams.
Called on: self = marked player
=============
*/
back2uo_antiplay_camper_start()
{
	if(!game["back2uo_antiplay_cmp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Remove an older marker of this player first
	if(isDefined(self.back2uo_objnum))
	{
		objective_delete(self.back2uo_objnum);
		self.back2uo_objnum = undefined;
	}

	self.back2uo_objnum = back2uo_antiplay_camper_obj();

	compass_icon = "";
	compass_team = "";

	if(self.pers["team"] == "allies")
	{
		compass_icon    = "gfx/custom/back2uo_camper_" + game["allies"] + ".tga";
		compass_team     = "none";
	}
	else if(self.pers["team"] == "axis")
	{
		compass_icon    = "gfx/custom/back2uo_camper_" + game["axis"] + ".tga";
		compass_team     = "none";
	}

	objective_add(self.back2uo_objnum, "current", self.origin, compass_icon);
	objective_team(self.back2uo_objnum, compass_team);

	// back2uo_objnum is cleared by back2uo_antiplay_camper_remove/remove2
	while(isdefined(self.back2uo_objnum) && isdefined(self) && self.pers["team"] != "spectator")
	{
		// Sets the same icon repeatedly without a wait (no visible effect)
		for(i=0; i < level.back2uo_antiplay_cmp_objtime; i++)
		{
			objective_icon(self.back2uo_objnum, compass_icon);
		}

		objective_position(self.back2uo_objnum, self.origin);

		wait 0.05;
	}
}

/*
=============
back2uo_antiplay_camper_obj

Hands out compass objective slots for camper markers. Cycles through 6..15 so the
low slots stay free for the gametype objectives (CoD2 supports 16 objectives, 0..15).
Returns: objective number
=============
*/
back2uo_antiplay_camper_obj()
{
	if(!isDefined(level.objectives)) level.objectives = 5;

	level.objectives++;

	if(level.objectives > 15) level.objectives = 6;

	return level.objectives;
}

/*
=============
back2uo_antiplay_camper_remove

Removes the camper marker after level.back2uo_antiplay_cmp_objtime seconds if the player
survived that long. On death the thread ends ("killed_player"); the marker is then removed
by back2uo_antiplay_camper_remove2().
Called on: self = marked player
=============
*/
back2uo_antiplay_camper_remove()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Remove");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(z=0;z < level.back2uo_antiplay_cmp_objtime; z++)
	{
		// Disabled: debug output of the remaining marker time
		//self iprintln(&"BACK2UOMOD_CAMPER_TIME", z);

		wait 1;
	}

	if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && isDefined(self.back2uo_objnum))
	{
		self iprintlnbold(&"BACK2UOMOD_CAMPING_SURVIVED_MSG");

		objective_delete(self.back2uo_objnum);

		self.back2uo_antiplay_camper_marked = false;
		self.back2uo_objnum = undefined;
	}
}

/*
=============
back2uo_antiplay_camper_remove2

Removes the camper marker immediately (called from _back2uo_player.gsc on player death).
Called on: self = player
=============
*/
back2uo_antiplay_camper_remove2()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Remove 2");

	if(isDefined(self.back2uo_objnum))
	{
		objective_delete(self.back2uo_objnum);

		self.back2uo_antiplay_camper_marked = false;
		self.back2uo_objnum = undefined;
	}
}

/*
=============
back2uo_switchspec

Polls the cvar g_switchspec every server frame. When it holds an entity number, that player
is killed (if alive) and moved to spectator through the gametype's spawnSpectator().
The cvar is set by back2uo_antiplay_afk() and can also be set by an admin via rcon.
Called on: self = level (threaded once at init)
=============
*/
back2uo_switchspec()
{
	back2uo\_back2uo_cvars::back2uo_logprint("AFK", "Run");

	level endon("boot");
	self endon("disconnect");

	setcvar("g_switchspec", "");

	while(1)
	{
		if(getcvar("g_switchspec") != "")
		{
			movePlayerNum = getcvarint("g_switchspec");
			players = getentarray("player", "classname");

			for(i = 0; i < players.size; i++)
			{
				thisPlayerNum = players[i] getEntityNumber();

				if(thisPlayerNum == movePlayerNum)
				{
					player = players[i];

					// switching_teams: the gametype's killed callback does not count this suicide as a death
					if(isAlive(player))
					{
						player.switching_teams = true;
						player suicide();
					}

					player.pers["team"] = "spectator";
					player.pers["weapon"] = undefined;
					player.pers["savedmodel"] = undefined;
					player.sessionteam = "spectator";
					player setClientCvar("ui_allow_weaponchange", "0");

					level.back2uo_playername = player.name;

					// Each gametype has its own spawnSpectator()
					if(getcvar("g_gametype") == "dm")
					{
						player thread maps\mp\gametypes\dm::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "tdm")
					{
						player thread maps\mp\gametypes\tdm::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "sd")
					{
						player thread maps\mp\gametypes\sd::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "hq")
					{
						player thread maps\mp\gametypes\hq::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "ctf")
					{
						player thread maps\mp\gametypes\ctf::spawnSpectator();
					}

					// Note: self is the level here, not the moved player
					self notify("joined_spectators");
				}
			}

			// Announce the move to all players
			thread back2uo\_back2uo_cvars::back2uo_playeraction_msg(&"BACK2UOMOD_PLAYER_SPECTATOR", self);

			setcvar("g_switchspec", "");
		}

		wait 0.05;
	}
}

/*
=============
back2uo_client_autodownload_init

Shows the "client autodownload disabled" notice to the player every 12 seconds.
The loop has no end condition other than the player entity going away.
Called on: self = player (threaded on connect)
=============
*/
back2uo_client_autodownload_init()
{
	if(!game["back2uo_autodownload_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Client Autodownload", "Run");

	for(;;)
	{
		if(isdefined(self)) self iprintlnbold(&"EXE_AUTODL_CLIENTDISABLED");

		wait 12;
	}
}

/*
=============
back2uo_compass_enemyfiring

Not in use. Every second starts back2uo_compass_enemyfiring_show() for each living player,
to show firing players as red dots on the enemy compass.
=============
*/
back2uo_compass_enemyfiring()
{
	if(!game["back2uo_compass_enemyfire"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Enemy Firing", "Run");

	while(1)
	{
		players = getentarray("player", "classname");

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player) && player.sessionstate == "playing")
			{
				player thread back2uo_compass_enemyfiring_show(player.clientid);
			}
		}

		wait 1;
	}
}

/*
=============
back2uo_compass_enemyfiring_show

Not in use. While the player holds the attack button, shows a compass objective at his
position to the enemy team (everyone in DM) for level.back2uo_compass_firefade * 0.3 seconds.
Uses the client id as objective number.
Called on: self = player
Params: player_id - client id of the player (objective number)
=============
*/
back2uo_compass_enemyfiring_show(player_id)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Enemy Firing", "Show");

	// Already running for this player
	if(isdefined(self.pers["enemyfiring_nr"]) && self.pers["enemyfiring_nr"] == player_id) return;

	if(!isdefined(self.pers["enemyfiring_nr"])) self.pers["enemyfiring_nr"] = player_id;

	// The marker is shown to the opposing team
	if(getcvar("g_gametype") == "dm")
	{
		compass_enemyfiring_team  = "none";
	}
	else
	{
		if(self.pers["team"] == "allies")
		{
			compass_enemyfiring_team  = "axis";
		}
		else
		{
			compass_enemyfiring_team  = "allies";
		}
	}

	self endon("disconnect");
	self endon("killed_player");

	while(isdefined(self.pers["enemyfiring_nr"]))
	{
		if(isdefined(self.pers["enemyfiring_nr"]) && isdefined(self) && self attackButtonPressed())
		{
			objective_add(self.pers["enemyfiring_nr"], "current", self.origin, "gfx/custom/back2uo_compass_enemyfiring.tga");
			objective_team(self.pers["enemyfiring_nr"], compass_enemyfiring_team);

			// Follow the player while the marker is visible
			for(i=0; i < level.back2uo_compass_firefade; i++)
			{
				if(isdefined(self.pers["enemyfiring_nr"])) objective_position(self.pers["enemyfiring_nr"], self.origin);

				wait 0.3;
			}

			if(isdefined(self.pers["enemyfiring_nr"]) && !self attackButtonPressed())
			{
				objective_delete(self.pers["enemyfiring_nr"]);

				self.pers["enemyfiring_nr"] = undefined;
			}
		}
		else
		{
			// Hide the objective while not firing
			if(isdefined(self.pers["enemyfiring_nr"])) objective_state(self.pers["enemyfiring_nr"], "empty");
		}

		wait 0.1;
	}
}

/*
=============
back2uo_compass_enemyfiring_clear

Not in use. Removes the enemy firing compass objective of the player.
Called on: self = player
=============
*/
back2uo_compass_enemyfiring_clear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Enemy Firing", "Clear");

	if(isDefined(self.pers["enemyfiring_nr"]))
	{
		objective_delete(self.pers["enemyfiring_nr"]);

		self.pers["enemyfiring_nr"] = undefined;
	}
}
