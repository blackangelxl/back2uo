/*
	Back2Uo v2.1 - Map rotation parsing and randomization (sv_maprotation /
	sv_maprotationcurrent) and the next map message start.
*/

/*
=============
back2uo_getmaprotation_control

Entry point for the map rotation handling at map start. With the mod's map system
enabled it shuffles the rotation and writes it to sv_maprotationcurrent, but only when a
new rotation cycle starts (first map after server start, or sv_maprotationcurrent is empty:
last map of the rotation). Otherwise, and on every further round (SD), it only reads the next entry
of the running rotation. Either way the next map message is started with the parsed rotation.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_getmaprotation_control()
{
	// "map_rotate" in maprotation.cfg already fills sv_maprotationcurrent at server start, so the
	// first map would never shuffle. back2uo_random_maprotation is only "2" after a shuffle.
	if(game["back2uo_mapsystem_enable"] && (back2uo\tools\_back2uo_strings::strip(getcvar("sv_maprotationcurrent")) == "" || getcvar("back2uo_random_maprotation") != "2"))
	{
		// Parse sv_maprotation and shuffle it.
		x = back2uo_getmaprotation(true, false, undefined);

		// Don't play the running map twice in a row: swap it away from the first slot.
		if(isdefined(x) && x.maps.size > 1 && x.maps[0]["map"] == getcvar("mapname"))
		{
			j = 1 + randomInt(x.maps.size - 1);
			element = x.maps[0];
			x.maps[0] = x.maps[j];
			x.maps[j] = element;
		}

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
Returns: struct whose .maps[n]["exec"|"jeep"|"tank"|"gametype"|"map"]
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

	if(current) maprot = back2uo\tools\_back2uo_strings::strip(getcvar("sv_maprotationcurrent"));

	if(maprot == "") maprot = back2uo\tools\_back2uo_strings::strip(getcvar("sv_maprotation"));

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
		element = back2uo\tools\_back2uo_strings::strip(temparr2[i]);

		if(element != "")
		{
			temparr[temparr.size] = element;
		}
	}

	// Container object for the map list (a struct, not an entity, so nothing has to be deleted)
	x = spawnstruct();
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
	temparr = back2uo\tools\_back2uo_strings::explode(cfg,".");

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
