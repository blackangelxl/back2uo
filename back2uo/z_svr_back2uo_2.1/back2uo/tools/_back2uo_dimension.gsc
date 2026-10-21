/*
	Back2Uo v2.1 - Map/playfield bounds detection used by the weather and war FX.
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
		thread backuo_mapdimo_model((xMin2, 0, zMax2));
		thread backuo_mapdimo_model((xMax2, 0, zMax2));
		thread backuo_mapdimo_model((0, yMin2, zMax2));
		thread backuo_mapdimo_model((0, yMax2, zMax2));
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
	mapdimomodel setModel("xmodel/sundirection_arrow");
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
