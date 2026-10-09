/*
	Back2Uo v2.1 - Kill triggers (map exploit spots)

	level.killtriggers is a list of cylinders (origin, radius, height) set up by a map script
	to block exploit positions; no script in this mod fills it or calls init(), so it only
	runs when a map script does. A player inside a cylinder is killed, or with the Back2Uo
	settings only damaged.
	Cvars: back2uo_killtrigger (1 = kill), back2uo_killtrigger_damage (1 = small radius damage
	instead). Both are read only when the mod is enabled (back2uo_status).
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
init

Reads the kill trigger settings, lowers every kill trigger by 16 units and then checks
all living players against the triggers every frame (at most 4 players per frame).
Called on: level
=============
*/
init()
{
	// Back2Uo: mod master switch
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_getstatus();

	// Mod enabled: read the settings; mod disabled: stock behaviour (always kill)
	if(game["back2uo_enable"])
	{
		level.back2uo_killtrigger = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_killtrigger", 0, 0, 1, "int");
		level.back2uo_killtrigger_damage = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_killtrigger_damage", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_killtrigger = 1;
	}

	// Both switches off: no kill trigger checks at all
	if(level.back2uo_killtrigger == 0 && level.back2uo_killtrigger_damage == 0) return;

	if(isdefined(level.killtriggers))
	{
		for(i = 0; i < level.killtriggers.size; i++)
		{
			killtrigger = level.killtriggers[i];
			killtrigger.origin = (killtrigger.origin[0], killtrigger.origin[1], (killtrigger.origin[2] - 16));
		}

		// Unused here; checkKillTriggers has its own copy
		playerradius = 16;

		for(;;)
		{
			players = getentarray("player", "classname");
			counter = 0;

			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(isdefined(player) && isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
				{
					player checkKillTriggers();
					counter++;

					// Spread the checks: wait a frame after every 4 players
					if(!(counter % 4))
					{
						wait .05;
						counter = 0;
					}
				}
			}

			wait .05;
		}
	}
}

/*
=============
checkKillTriggers

Tests the player against every kill trigger cylinder (2D distance plus height range,
with a player radius of 16 units) and kills or damages the player on the first hit.
Called on: player
=============
*/
checkKillTriggers()
{
	playerradius = 16;

	for(i = 0; i < level.killtriggers.size; i++)
	{
		killtrigger = level.killtriggers[i];
		diff = killtrigger.origin - self.origin;

		if((self.origin[2] >= killtrigger.origin[2]) && (self.origin[2] <= killtrigger.origin[2] + killtrigger.height))
		{
			diff2 = (diff[0], diff[1], 0);

			if(length(diff2) < killtrigger.radius + playerradius)
			{
				// Back2Uo: damage mode does 5 damage at the center (0 at the edge) of a radius
				// around the player instead of killing; it repeats every check while inside.
				if(level.back2uo_killtrigger == 0 && level.back2uo_killtrigger_damage == 1)
				{
					radiusDamage(self.origin, killtrigger.radius, 5, 0);
				}
				else
				{
					self suicide();
				}

				return;
			}
		}
	}
}
