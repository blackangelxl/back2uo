/*
	Back2Uo v2.1 - shared helper functions

	Map/playfield bounds detection (used by the weather and war FX), map rotation
	parsing and randomization, grenade/gametype/map name lookups, string utilities
	(explode, strip, splitArray, findStr), airplane vector math, and the mod's
	bonus/penalty score system. Functions are called from the other back2uo\_back2uo_*
	scripts and from the hooks in maps\mp\gametypes\*.gsc.
	Sets level.back2uo_playerdimo_*, level.back2uo_mapdimo_* and
	level.back2uo_airplanedimo_allow.
*/

/*
=============
back2uo_playerdimension

Computes the bounding box of all spawnpoints of every stock gametype, i.e. the area
where players actually fight. Weather and war FX use it to place effects
(e.g. random x/y positions inside the box).
Called on: level (from _back2uo_player.gsc at startup)
=============
*/
back2uo_playerdimension()
{
	spawnpoints = [];

	spawnpoints_s1 = getentarray("mp_dm_spawn", "classname");
	spawnpoints_s2 = getentarray("mp_tdm_spawn", "classname");
	spawnpoints_s3 = getentarray("mp_ctf_spawn_allied", "classname");
	spawnpoints_s4 = getentarray("mp_ctf_spawn_axis", "classname");
	spawnpoints_s5 = getentarray("mp_sd_spawn_attacker", "classname");
	spawnpoints_s6 = getentarray("mp_sd_spawn_defender", "classname");

	// Merge all spawnpoint classes into one array.
	for(i=0;i<spawnpoints_s1.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s1[i]);
	}

	for(i=0;i<spawnpoints_s2.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s2[i]);
	}

	for(i=0;i<spawnpoints_s3.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s3[i]);
	}

	for(i=0;i<spawnpoints_s4.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s4[i]);
	}

	for(i=0;i<spawnpoints_s5.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s5[i]);
	}

	for(i=0;i<spawnpoints_s6.size;i++)
	{
		spawnpoints = maps\mp\gametypes\_spawnlogic::add_to_array(spawnpoints, spawnpoints_s6[i]);
	}

	// Seed min/max of each axis with the first spawnpoint (assumes the map has at least one).
	xMin = spawnpoints[0].origin[0];
	xMax = spawnpoints[0].origin[0];

	yMin = spawnpoints[0].origin[1];
	yMax = spawnpoints[0].origin[1];

	zMin = spawnpoints[0].origin[2];
	zMax = spawnpoints[0].origin[2];

	for(i=1;i<spawnpoints.size;i++)
	{
		if (spawnpoints[i].origin[0] > xMax) xMax = spawnpoints[i].origin[0];
		if (spawnpoints[i].origin[1] > yMax) yMax = spawnpoints[i].origin[1];
		if (spawnpoints[i].origin[2] > zMax) zMax = spawnpoints[i].origin[2];

		if (spawnpoints[i].origin[0] < xMin) xMin = spawnpoints[i].origin[0];
		if (spawnpoints[i].origin[1] < yMin) yMin = spawnpoints[i].origin[1];
		if (spawnpoints[i].origin[2] < zMin) zMin = spawnpoints[i].origin[2];
	}

	level.back2uo_playerdimo_xMax = xMax;
	level.back2uo_playerdimo_yMax = yMax;
	level.back2uo_playerdimo_zMax = zMax;

	level.back2uo_playerdimo_xMin = xMin;
	level.back2uo_playerdimo_yMin = yMin;
	level.back2uo_playerdimo_zMin = zMin;

	// Fixed height for the width/length measurement; only x/y matter for the distances.
	ambientfx_hoehe = 800;

	level.back2uo_playerdimo_centerx = int(int(xMax + xMin)/2);
	level.back2uo_playerdimo_centery = int(int(yMax + yMin)/2);
	level.back2uo_playerdimo_centerz = int(int(zMax + zMin)/2);
	level.back2uo_playerdimo_center = (level.back2uo_playerdimo_centerx, level.back2uo_playerdimo_centery, level.back2uo_playerdimo_centerz);

	// breite = width (x extent), laenge = length (y extent), in game units.
	level.back2uo_playerdimo_breite = int(distance((xMin,yMin,ambientfx_hoehe),(xMax,yMin,ambientfx_hoehe)));
	level.back2uo_playerdimo_laenge = int(distance((xMin,yMin,ambientfx_hoehe),(xMin,yMax,ambientfx_hoehe)));
}

/*
=============
back2uo_mapdimension

Estimates the outer bounds of the map geometry: from every entity origin it traces
80000 units along +/- x, y and z and keeps the furthest wall hits. Also disables
the airplane FX (level.back2uo_airplanedimo_allow = 0) on maps too small for a fly-over.
Takes one server frame per entity, so it runs for a while after map start.
Called on: level (from _back2uo_player.gsc at startup)
=============
*/
back2uo_mapdimension()
{
	entitytypes = getentarray();

	// Start with inverted extremes so the first real hit replaces them.
	xMax2 = -80000;
	xMin2 = 80000;

	yMax2 = -80000;
	yMin2 = 80000;

	zMax2 = -80000;
	zMin2 = 80000;

	// Fallback hit positions used when a trace never hits anything. Only the
	// component of the matching axis is read below.
	xMin_e[0] = xMax2;
	yMin_e[1] = yMax2;
	zMin_e[2] = zMax2;

	xMax_e[0] = xMin2;
	yMax_e[1] = yMin2;
	zMax_e[2] = zMin2;

	// Note: starts at index 1, entity 0 (usually the worldspawn) is skipped.
	for(i = 1; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].origin))
		{
			// Trace in each axis direction; fraction != 1 means geometry was hit.
			// A miss keeps the previous hit position.
			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin - (80000,0,0), false, undefined);
			if(trace["fraction"] != 1)  xMin_e  = trace["position"];

			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin + (80000,0,0), false, undefined);
			if(trace["fraction"] != 1)  xMax_e  = trace["position"];

			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin - (0,80000,0), false, undefined);
			if(trace["fraction"] != 1)  yMin_e  = trace["position"];

			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin + (0,80000,0), false, undefined);
			if(trace["fraction"] != 1)  yMax_e  = trace["position"];

			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin - (0,0,80000), false, undefined);
			if(trace["fraction"] != 1)  zMin_e  = trace["position"];

			trace = bulletTrace(entitytypes[i].origin, entitytypes[i].origin + (0,0,80000), false, undefined);
			if(trace["fraction"] != 1)  zMax_e  = trace["position"];

			if (xMin_e[0] < xMin2)   xMin2 = xMin_e[0];
			if (yMin_e[1] < yMin2)   yMin2 = yMin_e[1];
			if (zMin_e[2] < zMin2)   zMin2 = zMin_e[2];

			if (xMax_e[0] > xMax2)   xMax2 = xMax_e[0];
			if (yMax_e[1] > yMax2)   yMax2 = yMax_e[1];
			if (zMax_e[2] > zMax2)   zMax2 = zMax_e[2];
		}

		// One entity per server frame to spread the trace cost.
		wait 0.05;
	}

	level.back2uo_mapdimo_xMin = xMin2;
	level.back2uo_mapdimo_xMax = xMax2;

	level.back2uo_mapdimo_yMin = yMin2;
	level.back2uo_mapdimo_yMax = yMax2;

	level.back2uo_mapdimo_zMin = zMin2;
	level.back2uo_mapdimo_zMax = zMax2;

	// Development mode: place visible marker models at the four horizontal bounds.
	if(game["back2uo_development_enable"])
	{
		thread backuo_mapdimo_model((xMin2, 0, 800));
		thread backuo_mapdimo_model((xMax2, 0, 800));
		thread backuo_mapdimo_model((0, yMin2, 800));
		thread backuo_mapdimo_model((0, yMax2, 800));
	}

	// If an airplane at speed 750 would cross the map in under 4 seconds on both
	// axes, the map is too small for the airplane FX.
	mapdimo_max = 0;
	mapdimo_x = back2uo\warfx\_back2uo_airplane::back2uo_airplane_flytime(750, (level.back2uo_mapdimo_xMin, 0, 800), (level.back2uo_mapdimo_xMax, 0, 800));
	mapdimo_y = back2uo\warfx\_back2uo_airplane::back2uo_airplane_flytime(750, (0, level.back2uo_mapdimo_yMin, 800), (0, level.back2uo_mapdimo_yMax, 800));

	if(mapdimo_x < 4) mapdimo_max++;
	if(mapdimo_y < 4) mapdimo_max++;
	if(mapdimo_max >= 2) level.back2uo_airplanedimo_allow = 0;

	level.back2uo_mapdimo_centerx = int(int(xMax2 + xMin2)/2);
	level.back2uo_mapdimo_centery = int(int(yMax2 + yMin2)/2);
	level.back2uo_mapdimo_centerz = int(int(zMax2 + zMin2)/2);

	// Release the entity array.
	entitytypes = [];
	entitytypes = undefined;
}

/*
=============
backuo_mapdimo_model

Development helper: spawns a marker model at posi and spins it forever
(12 steps of 30 degrees) so the computed map bounds are visible in game.
Params: posi - world position of the marker
=============
*/
backuo_mapdimo_model(posi)
{
	mapdimomodel = spawn("script_model", posi);
	mapdimomodel setModel("xmodel/tree_destroyed_snow_fallen_log_a");
	mapdimomodel show();

	for(;;)
	{
		for(x= 0; x < 12; x++)
		{
			angles = x * 30;

			mapdimomodel.angles = (0, angles, 0);

			wait 0.3;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_getgranade_type

Builds the weapon name of the frag or smoke grenade matching the player's team and
nationality. level.back2uo_specialgranade / level.back2uo_specialsmoke hold an optional
"_special<n>" suffix set in _weapons.gsc when the special grenade cvars are enabled.
Called on: player
Params: type - "granade" for frag grenades, "smoke" for smoke grenades
Returns: grenade weapon name, or "" for an unknown type
=============
*/
back2uo_getgranade_type(type)
{
	grenadetype = "";

	if(type == "granade")
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
			case "american":
				grenadetype = "frag_grenade_american_mp" + level.back2uo_specialgranade;
				break;

			case "british":
				grenadetype = "frag_grenade_british_mp" + level.back2uo_specialgranade;
				break;

			default:
				grenadetype = "frag_grenade_russian_mp" + level.back2uo_specialgranade;
				break;
			}
		}
		else
		{
			grenadetype = "frag_grenade_german_mp" + level.back2uo_specialgranade;
		}
	}

	if(type == "smoke")
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
			case "american":
				grenadetype = "smoke_grenade_american_mp" + level.back2uo_specialsmoke;
				break;

			case "british":
				grenadetype = "smoke_grenade_british_mp" + level.back2uo_specialsmoke;
				break;

			default:
				grenadetype = "smoke_grenade_russian_mp" + level.back2uo_specialsmoke;
				break;
			}
		}
		else
		{
			grenadetype = "smoke_grenade_german_mp" + level.back2uo_specialsmoke;
		}
	}

	return grenadetype;
}

/*
=============
back2uo_get_gametypename

Maps a gametype short name to its localized display string.
Params: gt - gametype short name ("dm", "tdm", "sd", "hq", "ctf")
Returns: localized string, or gt itself for unknown gametypes
=============
*/
back2uo_get_gametypename(gt)
{
	switch(gt)
	{
	case "dm":
		gtname = &"BACK2UOMOD_GT_DM";
		break;

	case "tdm":
		gtname = &"BACK2UOMOD_GT_TDM";
		break;

	case "sd":
		gtname = &"BACK2UOMOD_GT_SD";
		break;

	case "hq":
		gtname = &"BACK2UOMOD_GT_HQ";
		break;

	case "ctf":
		gtname = &"BACK2UOMOD_GT_CTF";
		break;

	default:
		gtname = gt;
		break;
	}

	return gtname;
}

/*
=============
back2uo_get_mapname

Maps a stock map name to its localized display string (used by the next map message).
Params: map - map BSP name, e.g. "mp_toujane"
Returns: localized string, or map itself for custom maps
=============
*/
back2uo_get_mapname(map)
{
	switch(map)
	{
	case "mp_farmhouse":
		mapname = &"BACK2UOMOD_MAP_MP_FARMHOUSE";
		break;

	case "mp_brecourt":
		mapname = &"BACK2UOMOD_MAP_MP_BRECOURT";
		break;

	case "mp_burgundy":
		mapname = &"BACK2UOMOD_MAP_MP_BURGUNDY";
		break;

	case "mp_trainstation":
		mapname = &"BACK2UOMOD_MAP_MP_TRAINSTATION";
		break;

	case "mp_carentan":
		mapname = &"BACK2UOMOD_MAP_MP_CARENTAN";
		break;

	case "mp_decoy":
		mapname = &"BACK2UOMOD_MAP_MP_DECOY";
		break;

	case "mp_leningrad":
		mapname = &"BACK2UOMOD_MAP_MP_LENINGRAD";
		break;

	case "mp_matmata":
		mapname = &"BACK2UOMOD_MAP_MP_MATMATA";
		break;

	case "mp_downtown":
		mapname = &"BACK2UOMOD_MAP_MP_DOWNTOWN";
		break;

	case "mp_dawnville":
		mapname = &"BACK2UOMOD_MAP_MP_DAWNVILLE";
		break;

	case "mp_railyard":
		mapname = &"BACK2UOMOD_MAP_MP_RAILYARD";
		break;

	case "mp_toujane":
		mapname = &"BACK2UOMOD_MAP_MP_TOUJANE";
		break;

	case "mp_breakout":
		mapname = &"BACK2UOMOD_MAP_MP_BREAKOUT";
		break;

	case "mp_harbor":
		mapname = &"BACK2UOMOD_MAP_MP_HARBOR";
		break;

	case "mp_rhine":
		mapname = &"BACK2UOMOD_MAP_MP_RHINE";
		break;

	default:
		mapname = map;
		break;
	}

	return mapname;
}

/*
=============
back2uo_getmaprotation_control

Entry point for the map rotation handling at map start. With the mod's map system
enabled it shuffles the rotation and writes it to sv_maprotationcurrent; otherwise it
only reads the next entry of the current rotation. Either way the next map message
is started with the parsed rotation.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_getmaprotation_control()
{
	if(game["back2uo_mapsystem_enable"])
	{
		// Parse sv_maprotation and shuffle it.
		x = back2uo_getmaprotation(true, false, undefined);

		thread back2uo_randommap_rotation(x);

		thread back2uo\messages\_back2uo_nextmap::back2uo_nextmap_messages_draw(x);
	}
	else
	{
		// Only the next entry of the running rotation is needed.
		x = back2uo_getmaprotation(false, true, 1);

		thread back2uo\messages\_back2uo_nextmap::back2uo_nextmap_messages_draw(x);
	}
}

/*
=============
back2uo_get_randommap_rotation

Returns: a shuffled copy of sv_maprotation (see back2uo_getmaprotation)
=============
*/
back2uo_get_randommap_rotation()
{
	return back2uo_getmaprotation(true, false, undefined);
}

/*
=============
back2uo_randommap_rotation

Serializes a parsed rotation back into rotation syntax and stores it in
sv_maprotationcurrent, so the engine plays the shuffled order. exec / allow_jeeps /
allow_tanks / gametype tokens are only written when they change from the previous entry.
Params: x - rotation object returned by back2uo_getmaprotation (uses x.maps)
=============
*/
back2uo_randommap_rotation(x)
{
	if(!game["back2uo_mapsystem_enable"]) return;

	if(!isdefined(x)) return;

	self endon("disconnect");
	level endon("kill_endround");

	maps = undefined;

	if(isdefined(x.maps)) maps = x.maps;

	if(!isdefined(maps) || !maps.size) return;

	// Last written values, used to skip redundant tokens.
	lastexec = "";
	lastjeep = "";
	lasttank = "";
	lastgt = "";
	newmaprotation = "";

	for(i = 0; i < maps.size; i++)
	{
		if(!isdefined(maps[i]["exec"]) || lastexec == maps[i]["exec"])
			exec = "";
		else
		{
			lastexec = maps[i]["exec"];
			exec = " exec " + maps[i]["exec"];
		}

		if(!isdefined(maps[i]["jeep"]) || lastjeep == maps[i]["jeep"])
			jeep = "";
		else
		{
			lastjeep = maps[i]["jeep"];
			jeep = " allow_jeeps " + maps[i]["jeep"];
		}

		if(!isdefined(maps[i]["tank"]) || lasttank == maps[i]["tank"])
			tank = "";
		else
		{
			lasttank = maps[i]["tank"];
			tank = " allow_tanks " + maps[i]["tank"];
		}

		if(!isdefined(maps[i]["gametype"]) || lastgt == maps[i]["gametype"])
			gametype = "";
		else
		{
			lastgt = maps[i]["gametype"];
			gametype = " gametype " + maps[i]["gametype"];
		}

		temp = exec + jeep + tank + gametype + " map " + maps[i]["map"];

		// Cvar strings near 1024 chars crash the server; stop appending before that.
		if(int(newmaprotation.size + temp.size) > 975)
		{
			iprintlnbold("Maprotation: ^1Limiting sv_maprotation to avoid server crash! String1 size:" + newmaprotation.size + " String2 size:" + temp.size);
			break;
		}

		newmaprotation += temp;
	}

	setCvar("sv_maprotationcurrent", newmaprotation);
	setCvar("back2uo_random_maprotation", "2");
}

/*
=============
back2uo_getmaprotation

Parses a map rotation string into a list of map entries. Each entry carries the exec
config, allow_jeeps, allow_tanks and gametype that apply to it. Malformed tokens are
guessed as gametype, .cfg or map name.
Params: random - true to keep settings sticky across entries and shuffle the result
		current - true to read sv_maprotationcurrent first (falls back to sv_maprotation)
		number - stop after this many maps (0 / undefined = all)
Returns: script_origin entity whose .maps[n]["exec"|"jeep"|"tank"|"gametype"|"map"]
		 holds the entries, or undefined if no rotation is set
=============
*/
back2uo_getmaprotation(random, current, number)
{
	level endon("back2uo_killthreads");
	level endon("kill_endround");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	maprot = "";

	if(!isdefined(number)) number = 0;

	if(current) maprot = strip(getcvar("sv_maprotationcurrent"));

	if(maprot == "") maprot = strip(getcvar("sv_maprotation"));

	if(maprot == "") return undefined;

	// Split the rotation string on spaces.
	j=0;
	temparr2[j] = "";

	for(i=0; i < maprot.size; i++)
	{
		if(maprot[i] == " ")
		{
			j++;
			temparr2[j] = "";
		}
		else
			temparr2[j] += maprot[i];
	}

	// Drop empty tokens caused by repeated spaces.
	temparr = [];

	for(i=0;i<temparr2.size;i++)
	{
		element = strip(temparr2[i]);

		if(element != "")
		{
			temparr[temparr.size] = element;
		}
	}

	// A script_origin is used as a container object because GSC has no structs.
	x = spawn("script_origin",(0,0,0));
	x.maps = [];
	lastexec = undefined;
	lastjeep = undefined;
	lasttank = undefined;
	lastgt = level.back2uo_gametype;

	// Walk the tokens; keywords consume their value (i += 2).
	for(i=0;i<temparr.size;)
	{
		switch(temparr[i])
		{
		case "allow_jeeps":
			if(isdefined(temparr[i+1]))
				lastjeep = temparr[i+1];
			i += 2;
			break;

		case "allow_tanks":
			if(isdefined(temparr[i+1]))
				lasttank = temparr[i+1];
			i += 2;
			break;

		case "exec":
			if(isdefined(temparr[i+1]))
				lastexec = temparr[i+1];
			i += 2;
			break;

		case "gametype":
			if(isdefined(temparr[i+1]))
				lastgt = temparr[i+1];
			i += 2;
			break;

		case "map":
			if(isdefined(temparr[i+1]))
			{
				x.maps[x.maps.size]["exec"]		= lastexec;
				x.maps[x.maps.size-1]["jeep"]	= lastjeep;
				x.maps[x.maps.size-1]["tank"]	= lasttank;
				x.maps[x.maps.size-1]["gametype"]	= lastgt;
				x.maps[x.maps.size-1]["map"]	= temparr[i+1];
			}

			// In a plain (non-shuffled) rotation the settings only apply to the next map,
			// so reset them. A shuffled rotation keeps them so every entry is self-contained.
			if(!random)
			{
				lastexec = undefined;
				lastjeep = undefined;
				lasttank = undefined;
				lastgt = undefined;
			}

			i += 2;
			break;

		default:
			// Unknown token: guess whether it is a gametype, a config or a bare map name.
			iprintlnbold("ERROR IN MAPROTATION!!! Will try to fix.");

			if(isGametype(temparr[i]))
				lastgt = temparr[i];
			else if(isConfig(temparr[i]))
				lastexec = temparr[i];
			else
			{
				x.maps[x.maps.size]["exec"]		= lastexec;
				x.maps[x.maps.size-1]["jeep"]	= lastjeep;
				x.maps[x.maps.size-1]["tank"]	= lasttank;
				x.maps[x.maps.size-1]["gametype"]	= lastgt;
				x.maps[x.maps.size-1]["map"]	= temparr[i];

				if(!random)
				{
					lastexec = undefined;
					lastjeep = undefined;
					lasttank = undefined;
					lastgt = undefined;
				}
			}

			i += 1;
			break;
		}

		if(number && x.maps.size >= number) break;
	}

	// Shuffle: 20 passes of random swaps.
	if(random)
	{
		for(k = 0; k < 20; k++)
		{
			for(i = 0; i < x.maps.size; i++)
			{
				j = randomInt(x.maps.size);
				element = x.maps[i];
				x.maps[i] = x.maps[j];
				x.maps[j] = element;
			}
		}
	}

	return x;
}

/*
=============
isConfig

Params: cfg - rotation token
Returns: true if the token looks like a config file name ("name.cfg")
=============
*/
isConfig(cfg)
{
	temparr = explode(cfg,".");

	if(temparr.size == 2 && temparr[1] == "cfg")
		return true;
	else
		return false;
}

/*
=============
isGametype

Params: gt - rotation token
Returns: true if the token is one of the stock gametypes
=============
*/
isGametype(gt)
{
	switch(gt)
	{
	case "dm":
	case "tdm":
	case "sd":
	case "hq":
	case "ctf":
		return true;
	default:
		return false;
	}
}

/*
=============
explode

Splits a string on a single-character delimiter. Empty fields are kept.
Params: s - string to split
		delimiter - one character
Returns: array of substrings
=============
*/
explode(s,delimiter)
{
	j=0;
	temparr[j] = "";

	for(i=0;i<s.size;i++)
	{
		if(s[i]==delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else
			temparr[j] += s[i];
	}

	return temparr;
}

/*
=============
strip

Removes leading and trailing spaces (spaces only, not tabs).
Params: s - string to trim
Returns: trimmed string
=============
*/
strip(s)
{
	if(s=="") return "";

	s2="";
	s3="";
	i=0;

	// Skip leading spaces.
	while(i<s.size && s[i]==" ")

		i++;

	if(i==s.size) return "";

	for(;i<s.size;i++)
	{
		s2 += s[i];
	}

	// Find the last non-space character.
	i=s2.size-1;

	while(s2[i]==" " && i>0)

		i--;

	for(j=0;j<=i;j++)
	{
		s3 += s2[j];
	}

	return s3;
}

/*
=============
splitArray

Splits a string into a (possibly nested) array. Each character of sep is one nesting
level: sep[0] splits the top level, sep[1] splits each field again, and so on.
Separators inside quote characters are ignored.
Params: str - string to split
		sep - separator characters, one per level (default ";")
		quote - quote character (default none)
		skipEmpty - if defined (any value), empty fields are dropped
Returns: array of strings for a single level; for nested levels each element is
		 an array with ["str"] (raw field) and ["fields"] (sub-split)
=============
*/
splitArray( str, sep, quote, skipEmpty )
{
	if(!isdefined(str) || str == "") return ( [] );

	if(!isdefined(sep) || sep == "") sep = ";";	// Default separator

	if(!isdefined(quote)) quote = "";

	// Only presence matters: any defined value enables skipping.
	skipEmpty = isdefined( skipEmpty );
	a = _splitRecur( 0, str, sep, quote, skipEmpty );

	return ( a );
}

/*
=============
_splitRecur

Recursive worker for splitArray; splits str on sep[iter] and recurses for deeper levels.
Params: iter - current nesting level (index into sep)
		str, sep, quote, skipEmpty - see splitArray
Returns: array for this level
=============
*/
_splitRecur( iter, str, sep, quote, skipEmpty )
{
	s = sep[ iter ];
	_a = [];
	_s = "";
	doQuote = false;

	for(i = 0; i < str.size; i++)
	{
		ch = str[i];

		if(ch == quote)
		{
			doQuote = !doQuote;

			// Keep the quote characters while deeper levels still need them.
			if(iter + 1 < sep.size) _s += ch;
		}
		else
			if(ch == s && !doQuote )
			{
				// End of a field.
				if( _s != "" || !skipEmpty)
				{
					_l = _a.size;

					if(iter + 1 < sep.size)
					{
						_x = _splitRecur( iter + 1, _s,	sep, quote, skipEmpty );

						if(_x.size > 0 || !skipEmpty)
						{
							_a[ _l ][ "str" ] = _s;
							_a[ _l ][ "fields" ] = _x;
						}
					}
					else
						_a[ _l ] = _s;
				}

				_s = "";
		}
		else
			_s += ch;
	}

	// Flush the last field (no trailing separator).
	if( _s != "")
	{
		_l = _a.size;

		if(iter + 1 < sep.size)
		{
			_x = _splitRecur( iter + 1, _s, sep, quote, skipEmpty);

			if(_x.size > 0 )
			{
				_a[ _l ][ "str" ] = _s;
				_a[ _l ][ "fields" ] = _x;
			}
		}
		else
			_a[ _l ] = _s;
	}

	return ( _a );
}

/*
=============
findStr

Searches for a substring.
Params: find - substring to look for
		str - string to search in
		pos - "start" (match only at the beginning), "end" (match only at the end),
			  anything else searches the whole string
Returns: index of the match, or -1
=============
*/
findStr( find, str, pos )
{
	if ( !isdefined( find ) || ( find == "" ) || !isdefined( str ) || !isdefined( pos ) || ( find.size > str.size ) ) return ( -1 );

	fsize = find.size;
	ssize = str.size;

	switch ( pos )
	{
	case "start":
		place = 0 ;
		break;

	case "end":
		place = ssize - fsize;
		break;

	default:
		place = 0 ;
		break;
	}

	for ( i = place; i < ssize; i++ )
	{
		if ( i + fsize > ssize ) break;

		// Compare character by character; j reaches fsize on a full match.
		for ( j = 0; j < fsize; j++ )

			if ( str[ i + j ] != find[ j ] ) break;

		if ( j >= fsize ) return ( i );

		// "start" only checks position 0.
		if ( pos == "start" ) break;
	}

	return ( -1 );
}

/*
=============
back2uo_calcshellpos

Picks a random impact point within 360 units (horizontally) of targetPos by tracing
3000 units straight down. Retries every 0.1 seconds until the trace hits ground.
Used for artillery shell impacts.
Params: targetPos - center of the impact area
Returns: impact position on the ground
=============
*/
back2uo_calcshellpos(targetPos)
{
	shellPos = undefined;

	while(!isdefined (shellPos))
	{
		shellPos = targetPos;
		angle = randomfloat( 360 );
		radius = randomfloat( 360 );
		randomOffset = (cos(angle) * radius, sin(angle) * radius, 0);
		shellPos += randomOffset;
		startOrigin = shellPos;
		endOrigin = shellPos - (0, 0, 3000);

		trace = bulletTrace( startOrigin, endOrigin, true, undefined );

		// No ground below: try another random point.
		if(trace["fraction"] < 1.0)
			shellPos = trace["position"];
		else
			shellPos = undefined;

		wait 0.1;
	}

	return ( shellPos );
}

/*
=============
back2uo_playerpoints_waitdefending

Waits for "bomb_exploded" on the player and awards the bomb defense bonus once
(the notify "give_defendingpoint" ends this thread via its own endon).
Called on: player
=============
*/
back2uo_playerpoints_waitdefending()
{
	level endon("back2uo_killthreads");
	level endon("round_ended");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	// Ensures the bonus is given only once.
	self endon("give_defendingpoint");

	for (;;)
	{
		self waittill("bomb_exploded");

		// Note: back2uo_playerpoints_system has no "bomb_defense" case, so the bonus is 0.
		self back2uo_playerpoints_system("bomb_defense");

		self notify("give_defendingpoint");
	}
}

/*
=============
back2uo_airplane_vectorpos

Computes the start and end point of an airplane fly-over: from startpos (+ offset)
it traces 50000 units backwards and forwards along the yaw angle and stops at map
geometry, so the plane enters and leaves at the map edges.
Params: startpos - center position of the flight path
		angle - flight yaw in degrees
		airplane_extras - offset vector added to startpos (formation position)
Returns: array [0] = start point, [1] = end point
=============
*/
back2uo_airplane_vectorpos(startpos, angle, airplane_extras)
{
	startpos = startpos + airplane_extras;
	forwardvector = anglestoforward((0,angle,0));

	backpos = startpos + (back2uo_airplane_vectormulti(forwardvector,-50000));
	trace = bulletTrace(startpos, backpos, false, undefined);

	if(trace["fraction"] != 1)
	{
		startpoint = trace["position"];
	}
	else
	{
		startpoint = backpos;
	}

	frontpos = startpos + (back2uo_airplane_vectormulti(forwardvector,50000));
	trace = bulletTrace(startpos, frontpos, false, undefined);

	if(trace["fraction"] != 1)
	{
		endpoint = trace["position"];
	}
	else
	{
		endpoint = frontpos;
	}

	stenpos[0] = startpoint;
	stenpos[1] = endpoint;

	return stenpos;
}

/*
=============
back2uo_airplane_vectormulti

Multiplies a vector by a scalar.
Params: vec - vector
		size - scale factor
Returns: scaled vector
=============
*/
back2uo_airplane_vectormulti(vec, size)
{
	x = vec[0] * size;
	y = vec[1] * size;
	z = vec[2] * size;
	vec = (x,y,z);

	return vec;
}

/*
=============
back2uo_playerpoints_system

Adds the mod's objective bonus points to the player's score and prints a message.
Bonus values come from level.back2uo_sd_plant_points, level.back2uo_sd_defuse_points,
level.back2uo_captureflag and level.back2uo_defendsflag.
Called on: player (from the sd.gsc / ctf.gsc hooks)
Params: wert - event: "bomb_planted", "bomb_defused", "flag_capture", "flag_defending"
=============
*/
back2uo_playerpoints_system(wert)
{
	if(!game["back2uo_enable"]) return;

	if(!game["back2uo_playerpoints_enable"]) return;

	if(!isdefined(wert)) return;

	bonus = 0;
	text = "";
	msg = "";

	switch(wert)
	{
	case "bomb_planted":
		bonus = level.back2uo_sd_plant_points;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_PLANT";
		break;

	case "bomb_defused":
		bonus = level.back2uo_sd_defuse_points;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_DEFUSE";
		break;

	case "flag_capture":
		bonus = level.back2uo_captureflag;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_CAPTURE";
		break;

	case "flag_defending":
		bonus = level.back2uo_defendsflag;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_DEFENDING";
		break;
	}

	// pers["score"] survives rounds; score is the scoreboard value.
	self.pers["score"] = self.pers["score"] + bonus;
	self.score = self.pers["score"];

	if(bonus != 0)
	{
		self iprintln(&"BACK2UOMOD_RANKINGPOINTS_ADD", msg);
	}
}

/*
=============
back2uo_givepoints_toplayer

Gives survival bonus points to every living player of a team.
Params: team - "allies" or "axis"
		points - points to add
=============
*/
back2uo_givepoints_toplayer(team, points)
{
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isAlive(player) && player.pers["team"] == team)
		{
			player.pers["score"] = player.pers["score"] + points;
			player.score = player.pers["score"];

			if(points != 0)
			{
				player iprintln(&"BACK2UOMOD_RANKINGPOINTS_ADD", &"BACK2UOMOD_RANKINGPOINTS_FOR_SURVIVE");
			}
		}
	}
}

/*
=============
back2uo_losepoints_ofplayer

Subtracts penalty points from the player (suicide / teamkill, called from the
gametype Callback_PlayerKilled hooks) and prints a message.
Called on: player
Params: points - points to subtract
=============
*/
back2uo_losepoints_ofplayer(points)
{
	if(!isdefined(points)) return;

	if(isdefined(self))
	{
		if(isdefined(self.pers["score"]))
		{
			self.pers["score"] = self.pers["score"] - points;
			self.score = self.pers["score"];
		}
		else
		{
			self.score = self.score - points;
		}

		// Note: the message always says "suicide", also for teamkills.
		if(points != 0)
		{
			self iprintln(&"BACK2UOMOD_RANKINGPOINTS_SUB", &"BACK2UOMOD_RANKINGPOINTS_FOR_SUICIDE");
		}
	}
}

/*
=============
back2uo_teams

Returns the two-letter nation code of a player's side, used to pick
nation-specific sounds and effects.
Params: attacker - player whose team is checked
Returns: "US", "UK", "RU" for allies, "GE" for axis
=============
*/
back2uo_teams(attacker)
{
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("killed_player");
	self endon("disconnect");

	kurz = "GE";

	if(attacker.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			kurz = "US";
			break;

		case "british":
			kurz = "UK";
			break;

		case "russian":
			kurz = "RU";
			break;
		}
	}

	return kurz;
}

/*
=============
back2uo_spawn_Spectator

Puts the player into spectator mode, optionally at a given position; otherwise at a
random mp_global_intermission spawnpoint. Clears shellshock and rumble first.
Called on: player
Params: origin - optional spawn position
		angles - optional view angles (both must be given to be used)
=============
*/
back2uo_spawn_Spectator(origin, angles)
{
	level endon("back2uo_killthreads");

	resettimeout();

	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator") self.statusicon = "";

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
}
