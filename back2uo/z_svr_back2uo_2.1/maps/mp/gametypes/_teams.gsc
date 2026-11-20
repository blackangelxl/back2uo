/*
	Back2Uo v2.1 - Team handling: models, auto balance, join permissions, test bots

	init() is threaded by every gametype script. It precaches team flags, sets the player
	models for game["allies"] / game["axis"], keeps the ui_allow_join* client cvars up to date
	and runs the auto team balance (scr_teambalance; per round in sd, every minute otherwise).
	Uses level.teambalance, level.teamlimit, level.maxclients and self.pers["teamTime"].
	Back2Uo adds addTestClients() / TestClient() for test bots (back2uo_testbots_active,
	back2uo_testbots), started from back2uo\_back2uo_player.gsc.
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
init

Precaches team names and flags, sets up player models, starts the connect watchers and
runs the auto team balance loop (not in dm). In sd the balance check happens once per
round on "restarting"; in other gametypes it is checked every minute with a 15 second warning.
Called on: level
=============
*/
init()
{
	precacheString(&"MP_AMERICAN");
	precacheString(&"MP_BRITISH");
	precacheString(&"MP_RUSSIAN");

	switch(game["allies"])
	{
	case "american":
		precacheShader("mpflag_american");
		break;

	case "british":
		precacheShader("mpflag_british");
		break;

	case "russian":
		precacheShader("mpflag_russian");
		break;
	}

	assert(game["axis"] == "german");
	precacheShader("mpflag_german");
	precacheShader("mpflag_spectator");

	if(getCvar("scr_teambalance") == "")
		setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");
	level.teambalancetimer = 0;

	level.maxclients = getCvarInt("sv_maxclients");

	setPlayerModels();

	level thread onPlayerConnecting();
	level thread onPlayerConnected();

	if(getcvar("g_gametype") != "dm")
	{
		level.teamlimit = level.maxclients / 2;

		level thread updateTeamBalanceCvar();

		// Give the gametype time to finish its own setup before checking balance.
		wait .15;

		if(getcvar("g_gametype") == "sd")
		{
			// sd: an unbalanced round is announced and the teams are balanced on the next map_restart.
			if(level.teambalance > 0)
			{
				if(isdefined(game["BalanceTeamsNextRound"]))
					iprintlnbold(&"MP_AUTOBALANCE_NEXT_ROUND");

				level waittill("restarting");

				if(isdefined(game["BalanceTeamsNextRound"]))
				{
					level balanceTeams();
					game["BalanceTeamsNextRound"] = undefined;
				}
				else if(!getTeamBalance())
					game["BalanceTeamsNextRound"] = true;
			}
		}
		else
		{
			for(;;)
			{
				if(level.teambalance > 0)
				{
					if(!getTeamBalance())
					{
						iprintlnbold(&"MP_AUTOBALANCE_SECONDS", 15);
						wait 15;

						if(!getTeamBalance())
							level balanceTeams();
					}

					wait 59;
				}

				wait 1;
			}
		}
	}
}

/*
=============
onPlayerConnecting

Starts the per-player team watchers for every connecting player.
Called on: level
=============
*/
onPlayerConnecting()
{
	for(;;)
	{
		level waittill("connecting", player);

		player thread onJoinedTeam();
		player thread onJoinedSpectators();

		if(!level.xenon)
			player updateAutoAssignCvar();
	}
}

/*
=============
onPlayerConnected

Refreshes the team join permissions of all players whenever a player has connected.
Called on: level
=============
*/
onPlayerConnected()
{
	for(;;)
	{
		level waittill("connected", player);

		if(!level.xenon)
			level updateTeamChangeCvars();
	}
}

/*
=============
onJoinedTeam

On every "joined_team" notify: stores the join time used by auto balance and
updates the menu join permissions.
Called on: player
=============
*/
onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");
		self updateTeamTime();

		if(!level.xenon)
		{
			self updateAutoAssignCvar();
			level updateTeamChangeCvars();
		}
	}
}

/*
=============
onJoinedSpectators

On every "joined_spectators" notify: clears the team join time (spectators are never
auto balanced) and updates the menu join permissions.
Called on: player
=============
*/
onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self.pers["teamTime"] = undefined;

		if(!level.xenon)
		{
			self updateAutoAssignCvar();
			level updateTeamChangeCvars();
		}
	}
}

/*
=============
updateTeamTime

Stores when the player joined the current team in self.pers["teamTime"].
In sd this is game minutes across rounds, otherwise seconds since map start.
The highest value marks the most recent joiner, who is moved first by balanceTeams.
Called on: player
=============
*/
updateTeamTime()
{
	if(getcvar("g_gametype") == "sd")
		self.pers["teamTime"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	else
		self.pers["teamTime"] = (gettime() / 1000);
}

/*
=============
updateTeamBalanceCvar

Polls scr_teambalance once a second so the setting can be changed during a map.
Called on: level
=============
*/
updateTeamBalanceCvar()
{
	for(;;)
	{
		teambalance = getCvarInt("scr_teambalance");
		if(level.teambalance != teambalance)
			level.teambalance = getCvarInt("scr_teambalance");

		wait 1;
	}
}

/*
=============
getTeamBalance

Counts the players per team into level.team[] and checks the difference against
level.teambalance (allowed surplus of players).
Returns: true if the teams are balanced, false otherwise
=============
*/
getTeamBalance()
{
	level.team["allies"] = 0;
	level.team["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			level.team["allies"]++;
		else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			level.team["axis"]++;
	}

	if((level.team["allies"] > (level.team["axis"] + level.teambalance)) || (level.team["axis"] > (level.team["allies"] + level.teambalance)))
		return false;
	else
		return true;
}

/*
=============
balanceTeams

Moves the most recently joined players from the larger team to the smaller one until the
difference is at most one player. Players with dont_auto_balance set are skipped.
Called on: level
=============
*/
balanceTeams()
{
	iprintlnbold(&"MP_AUTOBALANCE_NOW");
	// Create/clear the team arrays
	AlliedPlayers = [];
	AxisPlayers = [];

	// Populate the team arrays (only players with a join time are candidates)
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i].pers["teamTime"]))
			continue;

		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			AlliedPlayers[AlliedPlayers.size] = players[i];
		else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			AxisPlayers[AxisPlayers.size] = players[i];
	}

	MostRecent = undefined;

	while((AlliedPlayers.size > (AxisPlayers.size + 1)) || (AxisPlayers.size > (AlliedPlayers.size + 1)))
	{
		if(AlliedPlayers.size > (AxisPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AlliedPlayers.size; j++)
			{
				if(isdefined(AlliedPlayers[j].dont_auto_balance))
					continue;

				if(!isdefined(MostRecent))
					MostRecent = AlliedPlayers[j];
				else if(AlliedPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"])
					MostRecent = AlliedPlayers[j];
			}

			if(getcvar("g_gametype") == "sd")
				MostRecent changeTeam_RoundBased("axis");
			else
				MostRecent changeTeam("axis");
		}
		else if(AxisPlayers.size > (AlliedPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AxisPlayers.size; j++)
			{
				if(isdefined(AxisPlayers[j].dont_auto_balance))
					continue;

				if(!isdefined(MostRecent))
					MostRecent = AxisPlayers[j];
				else if(AxisPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"])
					MostRecent = AxisPlayers[j];
			}

			if(getcvar("g_gametype") == "sd")
				MostRecent changeTeam_RoundBased("allies");
			else
				MostRecent changeTeam("allies");
		}

		// Recount the teams after the move
		MostRecent = undefined;
		AlliedPlayers = [];
		AxisPlayers = [];

		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				AlliedPlayers[AlliedPlayers.size] = players[i];
			else if((isdefined(players[i].pers["team"])) &&(players[i].pers["team"] == "axis"))
				AxisPlayers[AxisPlayers.size] = players[i];
		}
	}
}

/*
=============
changeTeam

Moves the player to another team immediately: kills a living player (without score
penalty), resets the weapon choice and opens the new team's weapon menu.
Called on: player
Params: team - "allies" or "axis"
=============
*/
changeTeam(team)
{
	if (self.sessionstate != "dead")
	{
		// Set a flag on the player so they aren't robbed points for dying - the callback will remove the flag
		self.switching_teams = true;
		self.joining_team = team;
		self.leaving_team = self.pers["team"];

		// Suicide the player so they can't hit escape and fail the team balance
		self suicide();
	}

	self.pers["team"] = team;
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self.sessionteam = self.pers["team"];

	// Update spectator permissions immediately on change of team
	self maps\mp\gametypes\_spectating::setSpectatePermissions();

	self setClientCvar("ui_allow_weaponchange", "1");
	if(self.pers["team"] == "allies")
	{
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		self openMenu(game["menu_weapon_allies"]);
	}
	else
	{
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		self openMenu(game["menu_weapon_axis"]);
	}

	self updateTeamTime();

	// Stops a pending respawn wait for the old team
	self notify("end_respawn");
}

/*
=============
changeTeam_RoundBased

Round-based (sd) variant of changeTeam: only switches pers["team"] and resets the weapon
choice; the switch takes effect when the next round spawns the player.
Called on: player
Params: team - "allies" or "axis"
=============
*/
changeTeam_RoundBased(team)
{
	self.pers["team"] = team;
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self updateTeamTime();
}

/*
=============
getJoinTeamPermissions

Checks whether a team still has room (level.teamlimit = half of sv_maxclients).
Params: team - "allies" or "axis"
Returns: true if the team can be joined
=============
*/
getJoinTeamPermissions(team)
{
	teamcount = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if((isdefined(player.pers["team"])) && (player.pers["team"] == team))
			teamcount++;
	}

	if(teamcount < level.teamlimit)
		return true;
	else
		return false;
}

/*
=============
updateTeamChangeCvars

Sets the client cvars ui_allow_joinallies / ui_allow_joinaxis for every player
(1 = button enabled, 2 = disabled because the team is full or is the player's own team).
The values are cached on the player so a cvar is only sent when it changes.
Called on: level
=============
*/
updateTeamChangeCvars()
{
	players = CountPlayers();

	if(getcvar("g_gametype") == "dm" || level.maxclients < 2)
	{
		joinallies = 1;
		joinaxis = 1;
	}
	else
	{
		if(players["allies"] >= level.teamlimit)
			joinallies = 2;
		else
			joinallies = 1;

		if(players["axis"] >= level.teamlimit)
			joinaxis = 2;
		else
			joinaxis = 1;
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator")
		{
			if(player.pers["team"] == "allies")
			{
				if(!isdefined(player.allow_joinallies) || player.allow_joinallies != 2)
				{
					player.allow_joinallies = 2;
					player setClientCvar("ui_allow_joinallies", player.allow_joinallies);
				}

				if(!isdefined(player.allow_joinaxis) || player.allow_joinaxis != joinaxis)
				{
					player.allow_joinaxis = joinaxis;
					player setClientCvar("ui_allow_joinaxis", player.allow_joinaxis);
				}
			}
			else if(player.pers["team"] == "axis")
			{
				if(!isdefined(player.allow_joinallies) || player.allow_joinallies != joinallies)
				{
					player.allow_joinallies = joinallies;
					player setClientCvar("ui_allow_joinallies", player.allow_joinallies);
				}

				if(!isdefined(player.allow_joinaxis) || player.allow_joinaxis != 2)
				{
					player.allow_joinaxis = 2;
					player setClientCvar("ui_allow_joinaxis", player.allow_joinaxis);
				}
			}
		}
		else
		{
			if(!isdefined(player.allow_joinallies) || player.allow_joinallies != joinallies)
			{
				player.allow_joinallies = joinallies;
				player setClientCvar("ui_allow_joinallies", player.allow_joinallies);
			}

			if(!isdefined(player.allow_joinaxis) || player.allow_joinaxis != joinaxis)
			{
				player.allow_joinaxis = joinaxis;
				player setClientCvar("ui_allow_joinaxis", player.allow_joinaxis);
			}
		}
	}
}

/*
=============
updateAutoAssignCvar

Disables the "auto assign" menu button (2) for players already on a team, enables it (1) otherwise.
Called on: player
=============
*/
updateAutoAssignCvar()
{
	if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis"))
		self setClientCvar("ui_allow_joinauto", "2");
	else
		self setClientCvar("ui_allow_joinauto", "1");
}

/*
=============
setPlayerModels

Precaches the character models and stores the model setup function per team in
game["allies_model"] / game["axis_model"], depending on the map's soldier type
(game["british_soldiertype"], game["russian_soldiertype"], game["german_soldiertype"]).
=============
*/
setPlayerModels()
{
	switch(game["allies"])
	{
	case "british":
		if(isdefined(game["british_soldiertype"]) && game["british_soldiertype"] == "africa")
		{
			mptype\british_africa::precache();
			game["allies_model"] = mptype\british_africa::main;
		}
		else
		{
			mptype\british_normandy::precache();
			game["allies_model"] = mptype\british_normandy::main;
		}
		break;

	case "russian":
		if(isdefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "padded")
		{
			mptype\russian_padded::precache();
			game["allies_model"] = mptype\russian_padded::main;
		}
		else
		{
			mptype\russian_coat::precache();
			game["allies_model"] = mptype\russian_coat::main;
		}
		break;

	case "american":
	default:
		mptype\american_normandy::precache();
		game["allies_model"] = mptype\american_normandy::main;
	}

	if(isdefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
	{
		mptype\german_winterdark::precache();
		game["axis_model"] = mptype\german_winterdark::main;
	}
	else if(isdefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterlight")
	{
		mptype\german_winterlight::precache();
		game["axis_model"] = mptype\german_winterlight::main;
	}
	else if(isdefined(game["german_soldiertype"]) && game["german_soldiertype"] == "africa")
	{
		mptype\german_africa::precache();
		game["axis_model"] = mptype\german_africa::main;
	}
	else
	{
		mptype\german_normandy::precache();
		game["axis_model"] = mptype\german_normandy::main;
	}
}

/*
=============
model

Applies the team's character model to the player and saves it in self.pers["savedmodel"]
so it can be restored with _utility::loadModel on later spawns.
Called on: player
=============
*/
model()
{
	self detachAll();

	if(self.pers["team"] == "allies")
		[[game["allies_model"] ]]();
	else if(self.pers["team"] == "axis")
		[[game["axis_model"] ]]();

	self.pers["savedmodel"] = maps\mp\_utility::saveModel();
}

/*
=============
CountPlayers

Counts the players on each team.
Returns: array with the keys "allies" and "axis" (the player entities stay in the numeric part)
=============
*/
CountPlayers()
{
	players = getentarray("player", "classname");
	allies = 0;
	axis = 0;
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			allies++;
		else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			axis++;
	}
	players["allies"] = allies;
	players["axis"] = axis;
	return players;
}

/*
=============
addTestClients

Back2Uo: adds back2uo_testbots test clients (bots) when back2uo_testbots_active is on.
Bots alternate between allies and axis. game["botsaktiv"] makes sure this happens only
once per map (game[] survives round restarts).
Bots of the previous map are kicked first: after a map change the server sends no new
gamestate to test clients, so they hang in CS_CONNECTED, block their slots and time out.
Called from back2uo\_back2uo_player.gsc.
=============
*/
addTestClients()
{
	// Some custom maps (mp_dawnville_cl) call this from their main(), before the
	// gametype has precached its status icons. Connecting a bot then is a script runtime
	// error, so wait until the gametype init of this frame has run.
	waittillframeend;

	if(!isdefined(game["back2uo_testbots_enable"]) || !game["back2uo_testbots_enable"]) return;

	// Bots were already added earlier on this map
	if(isdefined(game["botsaktiv"])) return;

	game["botsaktiv"] = true;

	// Test clients added in the first frames after the map start hang: libcod does not see
	// them as connected and they never move. Until the trace cache (tools/tcgen.py) the map
	// dimension traces delayed this call by several seconds by chance; now wait on purpose.
	wait 5;

	// The old bots have no "player" classname yet, so search all client entities
	ents = getentarray();
	maxclients = getCvarInt("sv_maxclients");
	kicked = false;

	for(i = 0; i < ents.size; i++)
	{
		num = ents[i] getEntityNumber();

		if(num < maxclients && ents[i] back2uo\_back2uo_libcod::back2uo_libcod_isbot())
		{
			kick(num);
			kicked = true;
		}
	}

	// Kicked clients are zombies for a moment before their slot is free again
	if(kicked) wait 3;

	testclients = getCvarInt("back2uo_testbots");

	for(i = 0; i < testclients; i++)
	{
		ent[i] = addtestclient();

		// Odd bots join axis, even bots join allies
		if(i & 1)
			team = "axis";
		else
			team = "allies";

		// addtestclient() returns undefined when the server is full
		if(isDefined(ent[i]))
		{
			ent[i] thread TestClient(team);
		}
	}
}

/*
=============
TestClient

Back2Uo: drives a test bot through the menus. Waits until the bot is initialized, joins
the given team, then picks a random weapon of the team it really joined (the team menu can
change it, e.g. "auto team only") with TestClient_weapons and sends it to the team's weapon
menu. Bots are excluded from the mod's sprint via pers["bots_nosprint"].
Called on: player (test client)
Params: team - "allies" or "axis"
=============
*/
TestClient(team)
{
	// pers["team"] is set by the connect callback
	while(!isdefined(self.pers["team"]))
		wait .05;

	self notify("menuresponse", game["menu_team"], team);
	wait 0.5;

	// The team the bot is on now; the requested one only if the menu has not answered yet
	if(self.pers["team"] == "allies" || self.pers["team"] == "axis")
		team = self.pers["team"];

	// Give the bot a name that matches the nationality of its team (game["allies"] / game["axis"])
	self back2uo\_back2uo_libcod::back2uo_libcod_renameclient(back2uo\bots\_back2uo_botnames::back2uo_botname_get(game[team]));

	weapons = self TestClient_weapons(team);

	if(weapons.size)
	{
		botsweapon = weapons[randomInt(weapons.size)];
	}
	else
	{
		// Nothing allowed or every weapon at its limit: the team's shotgun, as before
		botsweapon = maps\mp\gametypes\_weapons::back2uo_teamshotgun(team);
		back2uo\_back2uo_cvars::back2uo_logevent("bot", "weapon_fallback", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " weapon=" + botsweapon);
	}

	// Counted by TestClient_weaponcount of the other bots until the menu has set pers["weapon"]
	self.back2uo_botweapon = botsweapon;

	self notify("menuresponse", game["menu_weapon_" + team], botsweapon);

	// Log the chosen weapon to the server log
	logPrint("Bot Weapon: ", botsweapon, "\n");
	back2uo\_back2uo_cvars::back2uo_logevent("bot", "weapon", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " weapon=" + botsweapon + " choices=" + weapons.size);

	// Tells the mod's sprint and HUD code to skip this bot
	self.pers["bots_nosprint"] = "noallow";
}

/*
=============
TestClient_weapons

Back2Uo: returns the weapons a bot of a team may take, the same the player's weapon menu offers:
- weapons of the team's nation (allies: game["allies"], axis: german) plus the optional G43
  sniper and Panzerschreck; with a weapon class (back2uo_weapons_allow 1 - 4) the class
  weapons of every nation, as in the shared weapons_only_* menus
- only the team's own shotgun; no grenades or binoculars; pistols only in the pistol class
- allowed by restrictWeaponByServerCvars (scr_allow_*, class, limit already marked full)
- below the sniper/shotgun limit, counting the weapons other players and bots have chosen.
  The limiter only counts every 0.5 seconds, so bots that join together would pass it.
Called on: player (test client)
Params: team - "allies" or "axis"
Returns: array of weapon names, may be empty
=============
*/
TestClient_weapons(team)
{
	classmode = game["back2uo_weaponsystem_enable"] && level.back2uo_weapon_limit != 0;
	pistolmode = classmode && level.back2uo_weapon_limit == 4;

	if(team == "axis") nation = "german";
	else nation = game["allies"];

	teamshotgun = maps\mp\gametypes\_weapons::back2uo_teamshotgun(team);
	list = [];

	for(i = 0; i < level.weaponnames.size; i++)
	{
		weapon = level.weaponnames[i];

		if(weapon == "fraggrenade" || weapon == "smokegrenade" || weapon == "binoculars_mp") continue;
		if(maps\mp\gametypes\_weapons::isPistol(weapon) != pistolmode) continue;

		if(weapon == "shotgun_mp_allies" || weapon == "shotgun_mp_axis")
		{
			if(weapon != teamshotgun) continue;
		}
		else if(!classmode && !TestClient_nationweapon(weapon, nation)) continue;

		if(self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(weapon) == "restricted") continue;

		limit = back2uo\_back2uo_weaponsystem::back2uo_weaponlimit_get(weapon);
		if(isdefined(limit) && TestClient_weaponcount(weapon) >= limit) continue;

		list[list.size] = weapon;
	}

	return list;
}

/*
=============
TestClient_nationweapon

Back2Uo: true if the weapon menu of a nation offers the weapon (the stock weapon menus; the
British menu also has the M1 Garand and Thompson). The optional G43 sniper and Panzerschreck
are in every nation's menu. Shotguns are handled by the caller.
Params: weapon - weapon name
		nation - "american", "british", "russian" or "german"
=============
*/
TestClient_nationweapon(weapon, nation)
{
	if(weapon == "g43_sniper_mp" || weapon == "panzerschreck_mp") return true;

	switch(nation)
	{
	case "american":
		switch(weapon)
		{
		case "m1carbine_mp":
		case "m1garand_mp":
		case "thompson_mp":
		case "bar_mp":
		case "springfield_mp":
		case "greasegun_mp":
		case "colt_mp":
			return true;
		}
		return false;

	case "british":
		switch(weapon)
		{
		case "enfield_mp":
		case "sten_mp":
		case "bren_mp":
		case "enfield_scope_mp":
		case "m1garand_mp":
		case "thompson_mp":
		case "webley_mp":
			return true;
		}
		return false;

	case "russian":
		switch(weapon)
		{
		case "mosin_nagant_mp":
		case "SVT40_mp":
		case "PPS42_mp":
		case "ppsh_mp":
		case "mosin_nagant_sniper_mp":
		case "TT30_mp":
			return true;
		}
		return false;

	case "german":
		switch(weapon)
		{
		case "kar98k_mp":
		case "g43_mp":
		case "mp40_mp":
		case "mp44_mp":
		case "kar98k_sniper_mp":
		case "luger_mp":
			return true;
		}
		return false;
	}

	return false;
}

/*
=============
TestClient_weaponcount

Back2Uo: number of other players that carry or have just chosen a weapon: pers["weapon"],
or self.back2uo_botweapon of a bot whose weapon menu response is not handled yet.
Called on: player (test client)
Params: weapon - weapon name
=============
*/
TestClient_weaponcount(weapon)
{
	count = 0;
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(player == self) continue;

		chosen = undefined;
		if(isdefined(player.pers["weapon"])) chosen = player.pers["weapon"];
		else if(isdefined(player.back2uo_botweapon)) chosen = player.back2uo_botweapon;

		if(isdefined(chosen) && chosen == weapon) count++;
	}

	return count;
}
