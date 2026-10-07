/*
	Back2Uo v2.1 - Objective waypoints (3D world markers on the HUD)

	Keeps lists of objective points per team (level.objpoints_allies / _axis) and for all
	players (level.objpoints_allplayers) and draws them as waypoint hud elements.
	Gametypes call addObjpoint / addTeamObjpoint / removeObjpoints / removeTeamObjpoints;
	player hud elements are rebuilt on spawn and cleared on death or team change.
	Back2Uo gates everything that adds or removes points with game["back2uo_objindekator_enable"]
	(cvar back2uo_objindekator).
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
init

Precaches the default waypoint icon, creates the empty objpoint lists and starts the
connect watcher. Icon size is doubled in splitscreen.
Called on: level
=============
*/
init()
{
	precacheShader("objpoint_default");

	level.objpoints_allies = spawnstruct();
	level.objpoints_allies.array = [];
	level.objpoints_axis = spawnstruct();
	level.objpoints_axis.array = [];
	level.objpoints_allplayers = spawnstruct();
	level.objpoints_allplayers.array = [];
	level.objpoints_allplayers.hudelems = [];

	if(level.splitscreen)
		level.objpoint_scale = 14;
	else
		level.objpoint_scale = 7;

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Gives every connecting player an empty objpoint hud list and starts the per-player watchers.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player.objpoints = [];

		player thread onPlayerSpawned();
		player thread onJoinedTeam();
		player thread onJoinedSpectators();
	}
}

/*
=============
onJoinedTeam

Clears the player's team waypoints when changing team.
Called on: player
=============
*/
onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");
		self thread clearPlayerObjpoints();
	}
}

/*
=============
onJoinedSpectators

Clears the player's team waypoints when going to spectator.
Called on: player
=============
*/
onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self thread clearPlayerObjpoints();
	}
}

/*
=============
onPlayerSpawned

Builds the player's team waypoints on each spawn.
Called on: player
=============
*/
onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		self thread updatePlayerObjpoints();
		// Note: starts a new onPlayerKilled loop on every spawn; the old ones keep running.
		self thread onPlayerKilled();
	}
}

/*
=============
onPlayerKilled

Clears the player's team waypoints on death.
Called on: player
=============
*/
onPlayerKilled()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("killed_player");

		self thread clearPlayerObjpoints();
	}
}

/*
=============
addObjpoint

Adds (or replaces) a waypoint visible to all players.
Params: origin - world position
		name - unique point name; an existing point with this name is replaced
		material - optional shader, defaults to "objpoint_default"
=============
*/
addObjpoint(origin, name, material)
{
	// Back2Uo: objective indicator switch (back2uo_objindekator, 0 = off, 1 = on)
	if(game["back2uo_objindekator_enable"])
	{
		thread addTeamObjpoint(origin, name, "all", material);
	}
}

/*
=============
addTeamObjpoint

Adds (or replaces) a named waypoint for one team or all players and rebuilds the hud
elements: one global hud element per point for "all", per-client elements for a team.
Params: origin - world position
		name - unique point name; an existing point with this name is replaced
		team - "allies", "axis" or "all"
		material - optional shader, defaults to "objpoint_default"
=============
*/
addTeamObjpoint(origin, name, team, material)
{
	// Back2Uo: objective indicator switch (back2uo_objindekator, 0 = off, 1 = on)
	if(game["back2uo_objindekator_enable"])
	{
		assert(team == "allies" || team == "axis" || team == "all");
		if(team == "allies")
		{
			assert(isdefined(level.objpoints_allies));
			objpoints = level.objpoints_allies;
		}
		else if(team == "axis")
		{
			assert(isdefined(level.objpoints_axis));
			objpoints = level.objpoints_axis;
		}
		else
		{
			assert(isdefined(level.objpoints_allplayers));
			objpoints = level.objpoints_allplayers;
		}

		// Rebuild objpoints array minus named
		cleanpoints = [];
		for(i = 0; i < objpoints.array.size; i++)
		{
			objpoint = objpoints.array[i];

			if(isdefined(objpoint.name) && objpoint.name != name)
				cleanpoints[cleanpoints.size] = objpoint;
		}
		objpoints.array = cleanpoints;

		newpoint = spawnstruct();
		newpoint.name = name;
		newpoint.x = origin[0];
		newpoint.y = origin[1];
		newpoint.z = origin[2];
		newpoint.archived = false;

		if(isdefined(material))
			newpoint.material = material;
		else
			newpoint.material = "objpoint_default";

		objpoints.array[objpoints.array.size] = newpoint;

		// Update objpoints for the team specified

		if (team == "all")
		{
			clearGlobalObjpoints();

			for(j = 0; j < objpoints.array.size; j++)
			{
				objpoint = objpoints.array[j];

				newobjpoint = newHudElem();
				newobjpoint.name = objpoint.name;
				newobjpoint.x = objpoint.x;
				newobjpoint.y = objpoint.y;
				newobjpoint.z = objpoint.z;
				newobjpoint.alpha = .61;
				// archived = false: not recorded for killcam playback
				newobjpoint.archived = objpoint.archived;
				newobjpoint setShader(objpoint.material, level.objpoint_scale, level.objpoint_scale);
				// x/y/z are a world position; the engine projects the icon onto the screen
				newobjpoint setwaypoint(true);

				level.objpoints_allplayers.hudelems[level.objpoints_allplayers.hudelems.size] = newobjpoint;
			}
		}
		else
		{
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(isDefined(player.pers["team"]) && player.pers["team"] == team && player.sessionstate == "playing")
				{
					player clearPlayerObjpoints();

					for(j = 0; j < objpoints.array.size; j++)
					{
						objpoint = objpoints.array[j];

						newobjpoint = newClientHudElem(player);
						newobjpoint.name = objpoint.name;
						newobjpoint.x = objpoint.x;
						newobjpoint.y = objpoint.y;
						newobjpoint.z = objpoint.z;
						newobjpoint.alpha = .61;
						newobjpoint.archived = objpoint.archived;
						newobjpoint setShader(objpoint.material, level.objpoint_scale, level.objpoint_scale);
						newobjpoint setwaypoint(true);

						player.objpoints[player.objpoints.size] = newobjpoint;
					}
				}
			}
		}
	}
}

/*
=============
removeObjpoints

Removes all waypoints that are visible to all players.
=============
*/
removeObjpoints()
{
	// Back2Uo: objective indicator switch (back2uo_objindekator, 0 = off, 1 = on)
	if(game["back2uo_objindekator_enable"])
	{
		thread removeTeamObjpoints("all");
	}
}

/*
=============
removeTeamObjpoints

Empties the waypoint list of a team (or of all players) and destroys the matching hud elements.
Params: team - "allies", "axis" or "all"
=============
*/
removeTeamObjpoints(team)
{
	// Back2Uo: objective indicator switch (back2uo_objindekator, 0 = off, 1 = on)
	if(game["back2uo_objindekator_enable"])
	{
		assert(team == "allies" || team == "axis" || team == "all");
		if(team == "allies")
		{
			assert(isdefined(level.objpoints_allies));
			level.objpoints_allies.array = [];
		}
		else if(team == "axis")
		{
			assert(isdefined(level.objpoints_axis));
			level.objpoints_axis.array = [];
		}
		else
		{
			assert(isdefined(level.objpoints_allplayers));
			assert(isdefined(level.objpoints_allplayers.hudelems));
			level.objpoints_allplayers.array = [];
			for (i=0;i<level.objpoints_allplayers.hudelems.size;i++)
				level.objpoints_allplayers.hudelems[i] destroy();
			level.objpoints_allplayers.hudelems = [];
			return;
		}

		// Clear objpoints for the team specified
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isDefined(player.pers["team"]) && player.pers["team"] == team && player.sessionstate == "playing")
				player clearPlayerObjpoints();
		}
	}
}

/*
=============
updatePlayerObjpoints

Recreates the player's client hud waypoints from the own team's objpoint list.
Only for living players on a team.
Called on: player
=============
*/
updatePlayerObjpoints()
{
	// Back2Uo: objective indicator switch (back2uo_objindekator, 0 = off, 1 = on)
	if(game["back2uo_objindekator_enable"])
	{
		if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator" && self.sessionstate == "playing")
		{
			assert(self.pers["team"] == "allies" || self.pers["team"] == "axis");
			if(self.pers["team"] == "allies")
			{
				assert(isdefined(level.objpoints_allies));
				objpoints = level.objpoints_allies;
			}
			else
			{
				assert(isdefined(level.objpoints_axis));
				objpoints = level.objpoints_axis;
			}

			self clearPlayerObjpoints();

			for(i = 0; i < objpoints.array.size; i++)
			{
				objpoint = objpoints.array[i];

				newobjpoint = newClientHudElem(self);
				newobjpoint.name = objpoint.name;
				newobjpoint.x = objpoint.x;
				newobjpoint.y = objpoint.y;
				newobjpoint.z = objpoint.z;
				newobjpoint.alpha = .61;
				newobjpoint.archived = objpoint.archived;
				newobjpoint setShader(objpoint.material, level.objpoint_scale, level.objpoint_scale);
				newobjpoint setwaypoint(true);

				self.objpoints[self.objpoints.size] = newobjpoint;
			}
		}
	}
}

/*
=============
clearPlayerObjpoints

Destroys all client waypoint hud elements of the player.
Called on: player
=============
*/
clearPlayerObjpoints()
{
	for(i = 0; i < self.objpoints.size; i++)
		self.objpoints[i] destroy();

	self.objpoints = [];
}

/*
=============
clearGlobalObjpoints

Destroys all global (all players) waypoint hud elements; the point list itself is kept.
=============
*/
clearGlobalObjpoints()
{
	for(i = 0; i < level.objpoints_allplayers.hudelems.size; i++)
		level.objpoints_allplayers.hudelems[i] destroy();

	level.objpoints_allplayers.hudelems = [];
}

// Disabled: removePlayerObjpoint destroyed one named waypoint of a player (stock, unused).
//removePlayerObjpoint(name)
//{
//	for(i = 0; i < self.objpoints.size; i++)
//	{
//		objpoint = self.objpoints[i];
//
//		if(isdefined(objpoint.name) && objpoint.name == name)
//			objpoint destroy();
//	}
//}
