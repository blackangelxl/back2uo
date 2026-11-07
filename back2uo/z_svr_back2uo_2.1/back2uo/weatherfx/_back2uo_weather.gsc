/*
	Back2Uo v2.1 - Rain/snow: per-map random roll, weather control loop and per-player drawing.

	The weather type follows the map: winter maps (game["german_soldiertype"] is "winterlight"
	or "winterdark") get snow, all other maps get rain. Whether a map gets weather at all is
	rolled once per map against level.back2uo_weatherfx_random and stored in game["weather_allow"].
	Level entry points (from _back2uo_player::back2uo_start_gametype): back2uo_weather_randomallow,
	back2uo_weathercontrol. Player entry point (from back2uo_player_spawn): back2uo_weather_startup.
	Split from the former _back2uo_weatherfx.gsc.
	Cvars/flags: game["back2uo_weatherfx_enable"], game["back2uo_rainfx_enable"], game["back2uo_snowfx_enable"],
	game["back2uo_thunderfx_enable"], game["back2uo_coldbreath_enable"], level.back2uo_weatherfx_strength.
*/

/*
=============
back2uo_weather_randomallow

Rolls once per map whether weather effects are shown. The result is kept in
game["weather_allow"] (true or undefined); game["weather_allow_q"] marks that the
roll was already done, so later rounds of the same map keep the result.
Called on: level
=============
*/
back2uo_weather_randomallow()
{
	if(!game["back2uo_weatherfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weather Random Allow", "Run");

	if(isdefined(game["weather_allow_q"]))
	{
		weather_allow = 0;
		if(isdefined(game["weather_allow"])) weather_allow = 1;

		back2uo\_back2uo_cvars::back2uo_logevent("weather", "keep", "allow=" + weather_allow);
		return;
	}
	game["weather_allow_q"] = true;

	// level.back2uo_weatherfx_random = chance in percent.
	weather_roll = randomInt(100);
	weather_allow = 0;

	if(weather_roll < level.back2uo_weatherfx_random)
	{
		game["weather_allow"] = true;
		weather_allow = 1;
	}
	else
	{
		game["weather_allow"] = undefined;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("weather", "roll", "roll=" + weather_roll + " chance=" + level.back2uo_weatherfx_random + " allow=" + weather_allow);
}

/*
=============
back2uo_weathercontrol

Chooses snow (winter maps) or rain (all other maps), stores it in level.back2uo_weatherart
and starts the weather loop if that weather type is enabled and allowed for this map.
Called on: level
=============
*/
back2uo_weathercontrol()
{
	if(!game["back2uo_weatherfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weather Control", "Run");

	// Winter uniforms = winter map.
	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
	{
		if(!game["back2uo_snowfx_enable"] || !isdefined(game["weather_allow"]))
		{
			weather_reason = "notallowed";
			if(!game["back2uo_snowfx_enable"]) weather_reason = "disabled";

			back2uo\_back2uo_cvars::back2uo_logevent("weather", "skip", "reason=" + weather_reason + " type=snow");
			return;
		}

		level.back2uo_weatherart = "snow";
	}
	else
	{
		if(!game["back2uo_rainfx_enable"] || !isdefined(game["weather_allow"]))
		{
			weather_reason = "notallowed";
			if(!game["back2uo_rainfx_enable"]) weather_reason = "disabled";

			back2uo\_back2uo_cvars::back2uo_logevent("weather", "skip", "reason=" + weather_reason + " type=rain");
			return;
		}

		level.back2uo_weatherart = "rain";
	}

	back2uo\_back2uo_cvars::back2uo_logevent("weather", "start", "type=" + level.back2uo_weatherart + " strength=" + level.back2uo_weatherfx_strength + " pause=" + (2 / level.back2uo_weatherfx_strength) + " soldiertype=" + game["german_soldiertype"]);

	thread back2uo_weatherdraw();
}

/*
=============
back2uo_weather_startup

Search and Destroy only: plays rain/snow above the freshly spawned player every 0.5 seconds
until back2uo_weatherdraw has completed a pass and clears level.rain_startup.
Called on: self = player
=============
*/
back2uo_weather_startup()
{
	if(!game["back2uo_weatherfx_enable"] || !isdefined(game["weather_allow"])) return;

	if(getCvar("g_gametype") != "sd") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weather Startup", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	is_rain = false;

	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
	{
		if(!game["back2uo_snowfx_enable"] || !isdefined(game["weather_allow"])) return;

		back2uo_weathertyp = level.back2uo_effect["snow"];
	}
	else
	{
		if(!game["back2uo_rainfx_enable"] || !isdefined(game["weather_allow"])) return;

		back2uo_weathertyp = level.back2uo_effect["rain"];
		is_rain = true;
	}

	// Cleared by back2uo_weatherdraw.
	level.rain_startup = true;

	while(level.rain_startup)
	{
		if(isdefined(self.origin) && isdefined(back2uo_weathertyp))
		{
			// Snow: fixed height of 600 units above the world origin plane.
			startup_z = 600;
			if(is_rain) startup_z = back2uo_rain_height(self.origin);

			playfx(back2uo_weathertyp, (self.origin[0], self.origin[1], startup_z));
		}

		wait 0.5;
	}
}

/*
=============
back2uo_rain_height

Height for the rain effect above a player. The drops of fx/back2uo/rain.efx only live 800 ms
and fade out after about 600 ms, so they must start close enough to be seen at the player.
A height derived from the map bounds fails on maps with a high sky (mp_dawnville_cl: 1850+
units above every spawnpoint), so this traces up from the player instead:
- open sky: 600 units above the player, but below the sky
- roof: at least 128 units above the roof, so the drops land on it and stay out of the building
Needs no map bounds, so it also works before back2uo_mapdimension has finished.
Surface "default" is the sky (see back2uo_getpositarget).
Params: pos - player origin
Returns: z of the effect
=============
*/
back2uo_rain_height(pos)
{
	rain_z = pos[2] + 600;

	trace = bulletTrace(pos + (0, 0, 60), pos + (0, 0, 80000), false, undefined);
	if(trace["fraction"] == 1) return rain_z;

	hit_z = trace["position"][2];

	if(trace["surfacetype"] == "default")
	{
		if(rain_z > hit_z - 8) rain_z = hit_z - 8;
		return rain_z;
	}

	if(rain_z < hit_z + 128) rain_z = hit_z + 128;

	// A roof close to the sky: stay inside the map (bounds are unset during the first seconds).
	if(isdefined(level.back2uo_mapdimo_zMax) && rain_z > level.back2uo_mapdimo_zMax - 8) rain_z = level.back2uo_mapdimo_zMax - 8;

	return rain_z;
}

/*
=============
back2uo_weatherdraw

Main weather loop. Plays the rain/snow effect above every living player, spread over
at most 5 effect spawns per pass. Rain height comes from back2uo_rain_height. Snow: players
below the map's middle height get the effect at middle height (so it is not spawned above
roofs/ceilings of lower areas), players above it get it at the map ceiling.
Pass frequency scales with level.back2uo_weatherfx_strength.
Ends on level notify "back2uo_weather_stop" (admin command, see _back2uo_admin.gsc).
Called on: level
Params: force - optional, true = run even if this map did not roll weather (admin command)
=============
*/
back2uo_weatherdraw(force)
{
	if(!game["back2uo_weatherfx_enable"] || (!isdefined(game["weather_allow"]) && !isdefined(force))) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weather Draw", "Run");

	level endon("back2uo_killthreads");
	level endon("back2uo_weather_stop");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// "drops" = the effect chosen in back2uo_weathercontrol (rain or snow).
	level.back2uo_effect["drops"] = level.back2uo_effect[level.back2uo_weatherart];

	is_rain = (level.back2uo_weatherart == "rain");
	middlezpos = 0;
	maxzpos = 0;

	// Snow is placed by the map bounds, rain by back2uo_rain_height.
	if(!is_rain)
	{
		if(!isdefined(level.back2uo_mapdimo_zMax) || !isdefined(level.back2uo_mapdimo_centerz))
		{
			back2uo\_back2uo_cvars::back2uo_logevent("weather", "skip", "reason=nodimension type=" + level.back2uo_weatherart);
			return;
		}
		middlezpos = level.back2uo_mapdimo_centerz;
		maxzpos = level.back2uo_mapdimo_zMax;
	}

	while(1)
	{
		players = getentarray("player", "classname");

		if(players.size > 0)
		{
			// Budget of 5 effect spawns per pass, split across all players (can be < 1).
			max_nodes = 5;
			max_nodes_per_player = max_nodes / players.size;

			for(ii=0; ii < max_nodes_per_player; ii++)
			{
				for(i=0; i < players.size; i++)
				{
					player = players[i];

					if(isAlive(player))
					{
						if(isdefined(level.back2uo_effect["drops"]))
						{
							if(is_rain)
							{
								playfx(level.back2uo_effect["drops"], (player.origin[0], player.origin[1], back2uo_rain_height(player.origin)));
							}
							else if(player.origin[2] < middlezpos)
							{
								playfx(level.back2uo_effect["drops"], (player.origin[0], player.origin[1], middlezpos));
							}
							else
							{
								playfx(level.back2uo_effect["drops"], (player.origin[0], player.origin[1], maxzpos));
							}
						}

						// Spread the effect spawns over several frames.
						wait 0.12;
					}
				}
			}

			// Higher strength = shorter pause = denser weather.
			wait (2 / level.back2uo_weatherfx_strength);
		}

		// First pass done: stop the per-player startup weather (back2uo_weather_startup).
		if(isdefined(level.rain_startup) && level.rain_startup == true) level.rain_startup = false;

		wait 0.1;
	}
}
