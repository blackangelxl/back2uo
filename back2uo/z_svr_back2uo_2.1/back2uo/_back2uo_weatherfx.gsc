/*
	Back2Uo v2.1 - Weather effects: rain/snow, thunder and lightning, cold breath.

	The weather type follows the map: winter maps (game["german_soldiertype"] is "winterlight"
	or "winterdark") get snow, all other maps get rain. Whether a map gets weather at all is
	rolled once per map against level.back2uo_weatherfx_random and stored in game["weather_allow"].
	Level entry points (from _back2uo_player::back2uo_start_gametype): back2uo_weather_randomallow,
	back2uo_weathercontrol, back2uo_thunder_draw. Player entry points (from back2uo_player_spawn):
	back2uo_weather_startup, back2uo_coldbreath_draw.
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

	if(isdefined(game["weather_allow_q"])) return;
	game["weather_allow_q"] = true;

	// level.back2uo_weatherfx_random = chance in percent.
	if(randomInt(100) < level.back2uo_weatherfx_random)
	{
		game["weather_allow"] = true;
	}
	else
	{
		game["weather_allow"] = undefined;
	}
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
		if(!game["back2uo_snowfx_enable"] || !isdefined(game["weather_allow"])) return;

		level.back2uo_weatherart = "snow";
	}
	else
	{
		if(!game["back2uo_rainfx_enable"] || !isdefined(game["weather_allow"])) return;

		level.back2uo_weatherart = "rain";
	}

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

	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
	{
		if(!game["back2uo_snowfx_enable"] || !isdefined(game["weather_allow"])) return;

		back2uo_weathertyp = level.back2uo_effect["snow"];
	}
	else
	{
		if(!game["back2uo_rainfx_enable"] || !isdefined(game["weather_allow"])) return;

		back2uo_weathertyp = level.back2uo_effect["rain"];
	}

	// Cleared by back2uo_weatherdraw.
	level.rain_startup = true;

	while(level.rain_startup)
	{
		if(isdefined(self.origin) && isdefined(back2uo_weathertyp))
		{
			// Fixed height of 600 units above the world origin plane.
			playfx(back2uo_weathertyp, (self.origin[0], self.origin[1], 600));
		}

		wait 0.5;
	}
}

/*
=============
back2uo_weatherdraw

Main weather loop. Plays the rain/snow effect above every living player, spread over
at most 5 effect spawns per pass. Players below the map's middle height get the effect
at middle height (so it is not spawned above roofs/ceilings of lower areas), players above
it get it at the map ceiling. Pass frequency scales with level.back2uo_weatherfx_strength.
Called on: level
=============
*/
back2uo_weatherdraw()
{
	if(!game["back2uo_weatherfx_enable"] || !isdefined(game["weather_allow"])) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weather Draw", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// "drops" = the effect chosen in back2uo_weathercontrol (rain or snow).
	level.back2uo_effect["drops"] = level.back2uo_effect[level.back2uo_weatherart];

	if(!isdefined(level.back2uo_mapdimo_zMax) || !isdefined(level.back2uo_mapdimo_centerz)) return;
	middlezpos = level.back2uo_mapdimo_centerz;
	maxzpos = level.back2uo_mapdimo_zMax;

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
							if(player.origin[2] < middlezpos)
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

/*
=============
back2uo_thunder_draw

Plays a lightning flash with thunder at random intervals of 0-29 seconds.
Rain maps only (not on winter maps).
Called on: level
=============
*/
back2uo_thunder_draw()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_thunderfx_enable"] || !isdefined(game["weather_allow"])) return;
	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Thunder Play", "Run");

	level endon("back2uo_killthreads");

	for (;;)
	{
		wait randomint(30);

		// Not threaded: the next wait starts after the flash sequence is done.
		back2uo_lightningflash();
	}
}

/*
=============
back2uo_lightningflash

Plays one lightning event at a random position inside the player area at middle map
height: thunder sound on all players, then a quick, double or triple flash using one
random lightning effect. In 1 of 6 cases an extra close thunder sound follows.
=============
*/
back2uo_lightningflash()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Lightning Flash", "Run");

	// Flash patterns.
	flash[0] = "quick";
	flash[1] = "double";
	flash[2] = "triple";

	// Keys into level.back2uo_effect.
	lightfx[0] = "lightning";
	lightfx[1] = "thunder_flash";

	wait 0.5;

	// Random x/y inside the player area.
	if(!isdefined(level.back2uo_playerdimo_xMin) || !isdefined(level.back2uo_playerdimo_yMin) || !isdefined(level.back2uo_mapdimo_zMax)) return;
	xpos = level.back2uo_playerdimo_xMin + randomint(level.back2uo_playerdimo_breite);
	ypos = level.back2uo_playerdimo_yMin + randomint(level.back2uo_playerdimo_laenge);
	// Disabled: flash at the map ceiling instead of middle height.
	//zpos = level.back2uo_mapdimo_zMax;
	zpos = level.back2uo_mapdimo_centerz;
	position = ( xpos, ypos, zpos);

	thread back2uo\_back2uo_sounds::back2uo_soundonplayers("elm_thunder");

	flashType = randomint(flash.size);
	lightFx = lightfx[randomInt(lightfx.size)];

	// Unused.
	lit_num = 0;

	switch (flash[flashType])
	{
	case "quick":
		{
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	case "double":
		{
			back2uo_thunderdraw(lightFx, position);
			wait (0.05);
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	case "triple":
		{
			back2uo_thunderdraw(lightFx, position);
			wait (0.05);
			back2uo_thunderdraw(lightFx, position);
			wait (0.5);
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	}

	// 1 in 6 chance for an additional close thunder clap.
	thunder_in = randomint(6);
	if(thunder_in == 3) thread back2uo\_back2uo_sounds::back2uo_soundonplayers("elm_thunderin");
}

/*
=============
back2uo_thunderdraw

Plays a single lightning effect.
Params: lightFx - key into level.back2uo_effect ("lightning" or "thunder_flash")
		position - effect position
=============
*/
back2uo_thunderdraw(lightFx, position)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Thunder Draw", "Run");

	playfx(level.back2uo_effect[lightFx], position);
}

/*
=============
back2uo_coldbreath_draw

Winter maps only: shows a cold breath puff at the player's eyes every 2.5-4.5 seconds
while the player stands (nearly) still. back2uo_player_origin waits 1 second and returns
the distance moved, so "< 15" means almost no movement.
Note: self_org is only refreshed in the outer loop, so once breathing starts it continues
until the player dies or leaves the "playing" state, even if the player starts moving.
Called on: self = player
=============
*/
back2uo_coldbreath_draw()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_coldbreath_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Cold Breath Draw", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
	{
		for(;;)
		{
			// Distance moved during the last second (blocks for 1 second).
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			while(isdefined(self) && self_org < 15 && isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
			{
				// Effect is attached to the eye tag so it follows the head.
				playfxontag (level.back2uo_breathfx, self, "TAG_EYE");

				wait randomfloatrange(2.5,4.5);
			}

			wait 0.1;
		}
	}
}
