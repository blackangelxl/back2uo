/*
	Back2Uo v2.1 - War ambience effects: mortars, ambient tracers, airplanes, flak and player-called artillery.

	back2uo_warfx_random() (called from _back2uo_player::back2uo_start_gametype) starts three
	level threads that randomly raise the level.back2uo_*fx_allow flags. The matching *_control()
	loops (also started from back2uo_start_gametype) poll those flags and play one effect wave.
	Artillery is a per-player reward: back2uo_artilleryfx_control() is started from the ranking
	code in _back2uo_hudfx.gsc; the player then marks a target with the binoculars + Use key.
	Main switches: game["back2uo_warfx_enable"], game["back2uo_mortarfx_enable"],
	game["back2uo_ambtracerfx_enable"], game["back2uo_airplanesfx_enable"], game["back2uo_flakfx_enable"],
	game["back2uo_artilleryfx_enable"]. Positions come from level.back2uo_mapdimo_* / level.back2uo_playerdimo_*
	(computed in _back2uo_tools.gsc). All loops end on level notify "back2uo_killthreads".
*/

/*
=============
back2uo_warfx_random

Entry point for the random war effects. Starts the three random trigger threads
(ambient tracers, mortars, airplanes) if war FX are enabled.
Called on: level
=============
*/
back2uo_warfx_random()
{
	if(!game["back2uo_warfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Random", "Run");

	thread back2uo_warfx_ambtrace_random();
	thread back2uo_warfx_mortar_random();
	thread back2uo_warfx_airplane_random();
}

/*
=============
back2uo_warfx_ambtrace_random

Every 10-19 seconds rolls a random number and, if it is below level.back2uo_warfx_random
(cvar back2uo_warfx_random, 1-100), allows one ambient tracer wave.
Called on: level
=============
*/
back2uo_warfx_ambtrace_random()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Ambtrace Random", "Run");

	for(;;)
	{
		// Sum of two randomInt(50) gives a 0-98 roll weighted toward the middle.
		if(int(randomInt(50) + randomInt(50)) < level.back2uo_warfx_random)
		{
			level.back2uo_ambtracerfx_allow = true;
		}

		wait (10 + randomint(10));
	}
}

/*
=============
back2uo_warfx_mortar_random

Every 20-49 seconds rolls against level.back2uo_warfx_random and, on success,
allows one mortar barrage (picked up by back2uo_mortarfx_control).
Called on: level
=============
*/
back2uo_warfx_mortar_random()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Mortar Random", "Run");

	for(;;)
	{
		if(int(randomInt(50) + randomInt(50)) < level.back2uo_warfx_random)
		{
			level.back2uo_mortarfx_allow = true;
		}

		wait (20 + randomint(30));
	}
}

/*
=============
back2uo_warfx_airplane_random

Every 10-39 seconds rolls against level.back2uo_warfx_random and, on success,
allows one airplane fly-over (picked up by back2uo_airplanefx_control).
Called on: level
=============
*/
back2uo_warfx_airplane_random()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Airplane Random", "Run");

	for(;;)
	{
		if(int(randomInt(50) + randomInt(50)) < level.back2uo_warfx_random)
		{
			level.back2uo_airplanefx_allow = true;
		}

		wait (10 + randomint(30));
	}
}

/*
=============
back2uo_mortarfx_control

Polls level.back2uo_mortarfx_allow every 0.1 seconds. When set, starts one mortar
barrage and clears the flag again.
Called on: level
=============
*/
back2uo_mortarfx_control()
{
	if(!game["back2uo_warfx_enable"] || !game["back2uo_mortarfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Mortar Fx Control", "Run");

	if(!isdefined(level.back2uo_mortarfx_allow)) level.back2uo_mortarfx_allow = false;

	level endon("back2uo_killthreads");

	for(;;)
	{
		if(level.back2uo_mortarfx_allow)
		{
			thread back2uo_mortarfx_play();

			level.back2uo_mortarfx_allow = false;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_mortarfx_play

Plays one mortar barrage: an optional "incoming mortar" voice alert, then a series of
shells 2.2 seconds apart. Shell count is level.back2uo_mortar_count, or 5-9 if that is 0.
Called on: level
=============
*/
back2uo_mortarfx_play()
{
	if(!game["back2uo_mortarfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Mortar Fx Play", "Run");

	level endon("back2uo_killthreads");

	thread back2uo_mortar_sound();

	// Short random delay between the voice alert and the first shell.
	wait randomfloat(4) + 0.5;
	mortarcount = 0;

	// 0 = random shell count.
	// Back2Uo: local count so concurrent barrages do not overwrite each other.
	if(level.back2uo_mortar_count == 0)
	{
		mortar_count2 = int(5 + randomint(5));
	}
	else
	{
		mortar_count2 = level.back2uo_mortar_count;
	}

	while(mortarcount < mortar_count2)
	{
		thread back2uo_mortar_draw();

		mortarcount++;

		wait 2.2;
	}
}

/*
=============
back2uo_mortar_draw

Drops a single mortar shell at a random point inside the player area: plays the
incoming whistle, moves a shell model down to the ground, then plays a surface
dependent impact effect and explosion sound. Optionally deals radius damage
(level.back2uo_mortar_damage) and shakes the screen (level.back2uo_mortar_quake).
Params: wert - optional entity; its x/y are read but then overwritten by the random position
=============
*/
back2uo_mortar_draw(wert)
{
	if(!game["back2uo_mortarfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Mortar Fx Draw", "Run");

	// Note: x/y from wert are overwritten below, so the parameter has no effect.
	if(isdefined(wert))
	{
		x = wert.origin[0];
		y = wert.origin[1];
	}

	// Random x/y inside the area where players spawn/move (player dimension box).
	if(!isdefined(level.back2uo_playerdimo_xMin) || !isdefined(level.back2uo_playerdimo_yMin) || !isdefined(level.back2uo_mapdimo_zMax)) return;
	x = level.back2uo_playerdimo_xMin + randomint(level.back2uo_playerdimo_breite);
	y = level.back2uo_playerdimo_yMin + randomint(level.back2uo_playerdimo_laenge);

	// Start height: map ceiling on low maps, otherwise 600-799 units.
	if(level.back2uo_mapdimo_zMax < 1000) z = level.back2uo_mapdimo_zMax;
	else z = 600 + randomint(200);

	// Ground target is a random point below the start position (see back2uo_calcshellpos).
	startposition = (x, y, z);
	endposition = back2uo\_back2uo_tools::back2uo_calcshellpos(startposition);

	// Shell model, nose pointing down, hidden until the whistle has started.
	mortar = spawn("script_model", startposition);
	mortar setModel("xmodel/prop_mortar_ammunition");
	mortar.origin = startposition;
	mortar.angles = (90, 0, 0);
	mortar hide();

	// Trace to the ground to get the impact point and surface type.
	trace = bulletTrace(startposition, endposition, false, undefined);

	// Map the hit surface to one of the level.back2uo_effect["mortar_*"] impact effects.
	mortarfx = "dirt";

	switch(trace["surfacetype"])
	{
	case "beach":
	case "sand":
		mortarfx = "beach";
		break;

	case "asphalt":
	case "metal":
		mortarfx = "concrete";
		break;

	case "mud":
	case "dirt":
	case "grass":
		mortarfx = "dirt";
		break;

	case "snow":
		mortarfx = "snow";
		break;

	case "wood":
		mortarfx = "wood";
		break;

	case "water":
		mortarfx = "water";
		break;
	}

	wait 0.05;

	// Incoming whistle. randomint(2) only picks index 0 or 1.
	soundfx_moerfall[0] = "moerser_fallincome1";
	soundfx_moerfall[1] = "moerser_fallincome2";
	soundfx_moerfall[2] = "moerser_fallincome1";

	random_fallsound = randomint(2);

	mortar playsound(soundfx_moerfall[random_fallsound]);

	// Let the whistle play before the shell becomes visible.
	wait 1;

	// Fall time scales with the drop height, minimum 0.5 seconds.
	fall_distance = distance(startposition, trace["position"]);
	fall_time = (fall_distance / 1000) / 4;

	if(fall_time < 0.5) fall_time = 0.5;

	mortar show();

	mortar moveto(trace["position"], fall_time);

	mortar thread back2uo_mortar_rotate();

	wait fall_time;

	// Impact effect for the surface type.
	playfx(level.back2uo_effect["mortar_" + mortarfx], trace["position"]);

	// Random explosion sound.
	soundfx_moerexplo[0] = "moerser_explod1";
	soundfx_moerexplo[1] = "moerser_explod2";
	soundfx_moerexplo[2] = "moerser_explod3";

	moerexplo_efx = randomInt(soundfx_moerexplo.size);

	mortar playsound(soundfx_moerexplo[moerexplo_efx]);

	mortar hide();

	// Stops back2uo_mortar_rotate.
	mortar notify("end_mortarfly");

	// Damage origin is lifted 12 units so the trace is not blocked by the ground.
	if(level.back2uo_mortar_damage)
	{
		radiusDamage(trace["position"] + (0,0,12), level.back2uo_mortar_radius, level.back2uo_mortar_strength, 0);
	}

	// Screen shake: scale 0.25, 2 seconds, radius 1250 units.
	if(level.back2uo_mortar_quake)
	{
		earthquake(0.25, 2, trace["position"], 1250);
	}

	mortar delete();
}

/*
=============
back2uo_mortar_rotate

Spins the falling shell model around its roll axis until "end_mortarfly" is notified.
Called on: entity (mortar shell model)
=============
*/
back2uo_mortar_rotate()
{
	level endon("back2uo_killthreads");
	self endon("end_mortarfly");

	back2uo\_back2uo_cvars::back2uo_logprint("Mortar Fx Rotate", "Run");

	for(;;)
	{
		// Back2Uo: randomint(2) so both roll directions are used (randomint(1) was always 0).
		switch(randomint(2))
		{
		default:
			break;

		case 0:

			// Full roll in 0.8 seconds, half the time accelerating and half decelerating.
			self rotateroll(360, 0.8, 0.8 / 2, 0.8 / 2);

			wait 0.8;

			break;

		case 1:

			self rotateroll(-360, 0.8, 0.8 / 2, 0.8 / 2);

			wait 0.8;

			break;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_mortar_sound

Plays a random "incoming mortar" voice line to all players if level.back2uo_mortar_alert is set.
The alias prefix depends on the caller's team nationality (US_, UK_, RU_, GE_).
Called on: level (from back2uo_mortarfx_play). Level has no origin/team, so this
always falls through to the "GE_" voice set.
=============
*/
back2uo_mortar_sound()
{
	if(!game["back2uo_mortarfx_enable"]) return;

	if(!level.back2uo_mortar_alert) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Mortar Fx Sound", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Sound alias nationality prefix.
	nat="";

	if(isdefined(self.origin) && self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			nat = "US_";
			break;

		case "british":
			nat = "UK_";
			break;

		case "russian":
			nat = "RU_";
			break;
		}
	}
	else if(isdefined(self.origin) && self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
		case "german":
			nat = "GE_";
			break;
		}
	}
	else
	{
		nat = "GE_";
	}

	// Pick voice variant 0-3.
	pc = randomInt(100);
	num = 0;

	// Back2Uo: proper range checks so variants 2/3 are used too.
	if(pc < 25) num = 0;
	else if(pc < 50) num = 1;
	else if(pc < 75) num = 2;
	else num = 3;

	// Alias e.g. "GE_1_inform_incoming_mortar".
	alias = nat + num + "_inform_incoming_mortar";

	level thread back2uo\_back2uo_sounds::back2uo_soundonplayers(alias);
}

/*
=============
back2uo_ambtracerfx_control

Polls level.back2uo_ambtracerfx_allow every 0.1 seconds. When set, starts one
ambient tracer wave and clears the flag again.
Called on: level
=============
*/
back2uo_ambtracerfx_control()
{
	if(!game["back2uo_warfx_enable"] || !game["back2uo_ambtracerfx_enable"]) return;

	if(!isdefined(level.back2uo_ambtracerfx_allow)) level.back2uo_ambtracerfx_allow = false;

	back2uo\_back2uo_cvars::back2uo_logprint("Ambtrace Fx Control", "Run");

	level endon("back2uo_killthreads");

	for(;;)
	{
		if(level.back2uo_ambtracerfx_allow)
		{
			thread back2uo_ambtracerfx_play();

			level.back2uo_ambtracerfx_allow = false;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_ambtracerfx_play

Plays bursts of the "ambiente_tracer" effect from random corners of the map bounding box,
so tracer fire appears to come from outside the playable area. Burst count is
level.back2uo_ambtracer_count, or 4-7 if that is 0; each burst fires the same count of effects.
Called on: level
=============
*/
back2uo_ambtracerfx_play()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("Ambtrace Fx Play", "Run");

	xpos = level.back2uo_mapdimo_xMin;
	ypos = level.back2uo_mapdimo_yMin;

	// 0 = random count.
	if(level.back2uo_ambtracer_count == 0) tracer_delay = int(4 + randomint(4));
	else tracer_delay = level.back2uo_ambtracer_count;

	for(z=0; z < tracer_delay; z++)
	{
		// Pick one of the four map corners.
		map_outside = randomInt(4);

		switch (map_outside)
		{
		case 0:

			xpos = level.back2uo_mapdimo_xMin;
			ypos = level.back2uo_mapdimo_yMin;

			break;

		case 1:

			xpos = level.back2uo_mapdimo_xMin;
			ypos = level.back2uo_mapdimo_yMax;

			break;

		case 2:

			xpos = level.back2uo_mapdimo_xMax;
			ypos = level.back2uo_mapdimo_yMin;

			break;

		case 3:

			xpos = level.back2uo_mapdimo_xMax;
			ypos = level.back2uo_mapdimo_yMax;

			break;
		}

		for(x=0; x < tracer_delay; x++)
		{
			// Low height (2-11 units) at the map corner.
			position = ( xpos, ypos, int(2 + randomint(10)));

			playfx(level.back2uo_effect["ambiente_tracer"], position);

			wait 0.5;
		}

		wait 1;
	}
}

/*
=============
back2uo_airplanefx_control

Polls level.back2uo_airplanefx_allow every 0.1 seconds. When set, starts one
airplane fly-over and clears the flag again.
Called on: level
=============
*/
back2uo_airplanefx_control()
{
	if(!game["back2uo_warfx_enable"] || !game["back2uo_airplanesfx_enable"]) return;

	if(!isdefined(level.back2uo_airplanefx_allow)) level.back2uo_airplanefx_allow = false;

	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Control", "Run");

	level endon("back2uo_killthreads");

	for(;;)
	{
		if(level.back2uo_airplanefx_allow)
		{
			thread back2uo_airplanefx_play();

			level.back2uo_airplanefx_allow = false;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_airplanefx_play

Starts one squadron fly-over across the map center at map ceiling height, in one of the
directions 0, 90 or 180 degrees, plus a matching flak barrage. Plane count is
level.back2uo_airplanes_count, or 3-5 if that is 0. Skipped on maps that are too small
(level.back2uo_airplanedimo_allow == 0, set in _back2uo_tools.gsc).
Called on: level
=============
*/
back2uo_airplanefx_play()
{
	if(!game["back2uo_airplanesfx_enable"]) return;

	if(level.back2uo_airplanedimo_allow == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Play", "Run");

	level endon("back2uo_killthreads");

	// Fly-over reference point: map center at map ceiling height.
	map_x = level.back2uo_mapdimo_centerx;
	map_y = level.back2uo_mapdimo_centery;
	map_z = level.back2uo_mapdimo_zMax;

	// Heading 0, 90 or 180 degrees. Type 0/2 = Stuka, 1 = Spitfire (see back2uo_airplanefx_draw).
	airplane_angles = 90 * randomint(3);
	airplane_type = randomint(3);

	airplane_startpoint = [];
	airplane_endpoint = [];
	airplane_extra = [];

	// 0 = random plane count.
	if(level.back2uo_airplanes_count == 0) airplane_count = int(3 + randomint(3));
	else airplane_count = level.back2uo_airplanes_count;

	thread back2uo_flakfx_play(airplane_count);

	// Index starts at 1 because back2uo_airplanefx_staffel uses 1-6 as formation slots.
	for(i=1; i < airplane_count + 1; i++)
	{
		// Formation offset and spawn delay for this plane.
		airplane_opt = back2uo_airplanefx_staffel(i, airplane_angles);
		airplane_extra[i] =  airplane_opt[0];
		airplane_wait[i] = airplane_opt[1];

		// Start/end points on the map edges along the heading, shifted by the formation offset.
		airplane_vectorpos = back2uo\_back2uo_tools::back2uo_airplane_vectorpos((map_x, map_y, map_z), airplane_angles, airplane_extra[i]);
		airplane_startpoint[i] = airplane_vectorpos[0];
		airplane_endpoint[i] = airplane_vectorpos[1];

		thread back2uo_airplanefx_draw(airplane_type, airplane_startpoint[i], airplane_endpoint[i], airplane_angles);

		wait airplane_wait[i];
	}
}

/*
=============
back2uo_airplanefx_staffel

Returns the formation ("Staffel" = squadron) offset for plane number i. The offset is
applied sideways to the flight direction: on the y axis for headings 0/180, on the x axis
for 90/270. Slots above 6 get no offset.
Params: i - plane slot (1-based)
		airplane_angles - flight heading in degrees
Returns: array [0] = offset vector, [1] = wait time in seconds before the next plane (always 0.4)
=============
*/
back2uo_airplanefx_staffel(i, airplane_angles)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Staffel", "Run");

	airplane_extra = (0, 0, 0);
	airplane_wait = 0.4;

	if(i == 1)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, -30, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (-30, 0, 0);
		}
	}
	else if(i == 2)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, -1500, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (-1500, 0, 0);
		}
	}
	else if(i == 3)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, 1500, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (1500, 0, 0);
		}
	}
	else if(i == 4)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, 50, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (50, 0, 0);
		}
	}
	else if(i == 5)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, -3000, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (-3000, 0, 0);
		}
	}
	else if(i == 6)
	{
		if(airplane_angles == 0 || airplane_angles == 180)
		{
			airplane_extra = (0, 3000, 0);
		}
		else if(airplane_angles == 90 || airplane_angles == 270)
		{
			airplane_extra = (3000, 0, 0);
		}
	}

	airplane_opt[0] = airplane_extra;
	airplane_opt[1] = airplane_wait;

	return airplane_opt;
}

/*
=============
back2uo_airplanefx_draw

Spawns one airplane model with a looping engine sound, flies it from start to end point,
wobbles it (back2uo_airplane_rotate) and lets it be hit by flak (back2uo_airplane_flakimpact).
The model is deleted when it reaches the end point.
Params: airplane_type - 0/2 = Stuka (axis), otherwise Spitfire (allies)
		airplane_startpoint, airplane_endpoint - flight path
		airplane_angles - yaw of the model in degrees
=============
*/
back2uo_airplanefx_draw(airplane_type, airplane_startpoint, airplane_endpoint, airplane_angles)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Draw", "Run");

	// Flight time at speed 750.
	airplane_flytime = back2uo_airplane_flytime(750, airplane_startpoint, airplane_endpoint);

	// The "_short" sound alias is immediately overwritten; only "_long" is used.
	if(airplane_type == 0 || airplane_type == 2)
	{
		airplane_model = "xmodel/vehicle_stuka_flying";

		airplane_sound = "stuka_flying_short";
		airplane_sound = "stuka_flying_long";
	}
	else
	{
		airplane_model = "xmodel/vehicle_spitfire_flying";

		airplane_sound = "spitfire_flying_short";
		airplane_sound = "spitfire_flying_long";
	}

	airplane = spawn("script_model", airplane_startpoint);
	airplane setModel(airplane_model);
	airplane.angles = (0, airplane_angles, 0);
	airplane hide();

	// Separate sound entity linked to the plane so the loop sound moves with it.
	airplane.sound = spawn("script_model", (0, 0, 0));
	airplane.sound.origin = airplane_startpoint;
	airplane.sound linkto(airplane);
	airplane.sound playloopsound(airplane_sound);

	airplane show();

	// Ease in/out of 0.5 seconds each.
	// Back2Uo: moveto needs a time > 0 and accel + decel <= time, so no easing on short flights.
	if(airplane_flytime < 0.1) airplane_flytime = 0.1;

	airplane_ease = 0.5;
	if(airplane_flytime <= 1.0) airplane_ease = 0;

	airplane moveto(airplane_endpoint, airplane_flytime, airplane_ease, airplane_ease);

	// Each wobble step takes a fifth of the flight time.
	airplane_rottime = airplane_flytime / 5;

	airplane thread back2uo_airplane_rotate(airplane_rottime);

	airplane thread back2uo_airplane_flakimpact();

	wait airplane_flytime;

	if(isdefined(airplane.sound))
	{
		airplane.sound stopLoopSound();
		airplane.sound delete();
	}

	// Stops the rotate and flak impact threads.
	airplane notify("end_airplanefly");

	if(isdefined(airplane)) airplane delete();
}

/*
=============
back2uo_airplane_flakimpact

Checks every 0.1 seconds whether the plane is within 500 units of the last flak burst
(level.back2uo_flakposition). If so, the plane crashes.
Called on: entity (airplane model)
=============
*/
back2uo_airplane_flakimpact()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Flak Impact", "Run");

	level endon("back2uo_killthreads");
	self endon("end_airplanefly");
	self endon("end_airplanecrash");

	for(;;)
	{
		airplane_origin = self getorigin();

		if(isdefined(level.back2uo_flakposition))
		{
			flaktoplane_distance = distance(airplane_origin, level.back2uo_flakposition);

			if(flaktoplane_distance < 500)
			{
				// Not threaded: blocks until the crash sequence is done (3 seconds).
				self back2uo_airplane_crash();

				self notify("end_airplanecrash");
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_airplane_crash

Plays the explosion/smoke effects for 3 seconds, then removes the plane and its
sound entity. Does nothing if level.back2uo_airplanes_crash is 0.
Called on: entity (airplane model)
=============
*/
back2uo_airplane_crash()
{
	if(level.back2uo_airplanes_crash == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Crash", "Run");

	// Unused ground position below the plane.
	airplane_crashpos = (self.origin[0], self.origin[1], 0);

	self thread back2uo_airplane_crashfx();

	wait 3;

	// Ends crashfx, rotate and flak impact threads.
	self notify("end_airplanefly");

	if(isdefined(self.sound))
	{
		self.sound stopLoopSound();
		self.sound delete();
	}

	if(isdefined(self)) self delete();
}

/*
=============
back2uo_airplane_crashfx

Plays one explosion effect at the plane, then a smoke trail and explosion sound
every second until "end_airplanefly" is notified.
Called on: entity (airplane model)
=============
*/
back2uo_airplane_crashfx()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Crash Effekt", "Run");

	level endon("back2uo_killthreads");
	self endon("end_airplanefly");

	playfx(level.back2uo_effect["plane_explosion"], self.origin);

	for(;;)
	{
		thread back2uo\_back2uo_sounds::back2uo_soundonplayers("airplane_explosion");

		playfx(level.back2uo_effect["plane_smoke"], self.origin);

		wait 1;
	}
}

/*
=============
back2uo_airplane_rotate

Rocks the plane left and right around its roll axis (+10, -20, +10 degrees) for a
light wobble during the flight, until "end_airplanefly" is notified.
Called on: entity (airplane model)
Params: rottime - duration of one roll step in seconds
=============
*/
back2uo_airplane_rotate(rottime)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Rotate", "Run");

	level endon("back2uo_killthreads");
	self endon("end_airplanefly");

	for(;;)
	{
		// Back2Uo: randomint(2) so the mirrored wobble is used too (randomint(1) was always 0).
		switch(randomint(2))
		{
		default:
			break;

		case 0:

			// rotateroll(degrees, time, accel time, decel time)
			self rotateroll(10, rottime, rottime / 2, rottime / 2);

			wait rottime;

			self rotateroll(-20, rottime, rottime / 2, rottime / 2);

			wait rottime;

			self rotateroll(10, rottime, rottime / 2, rottime / 2);

			break;

		case 1:

			self rotateroll(-10, rottime, rottime / 2, rottime / 2);

			wait rottime;

			self rotateroll(20, rottime, rottime / 2, rottime / 2);

			wait rottime;

			self rotateroll(-10, rottime, rottime / 2, rottime / 2);

			break;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_airplane_flytime

Computes how long a plane needs between two points. Also used by
_back2uo_tools.gsc to decide whether the map is large enough for airplanes.
Params: airplane_speed - speed in units per second (before the /4 scaling)
		airplane_startpoint, airplane_endpoint - flight path
Returns: flight time in seconds ((distance / speed) / 4), at least 0.1
=============
*/
back2uo_airplane_flytime(airplane_speed, airplane_startpoint, airplane_endpoint)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Flytime", "Run");

	if(airplane_speed < 1) return 0.1;

	fly_distance = distance(airplane_startpoint, airplane_endpoint);
	fly_time = (fly_distance / airplane_speed) / 4;

	// Note: fly_time is never negative; a 0 distance still returns 0.
	if(fly_time < 0) fly_time = 0.1;

	return fly_time;
}

/*
=============
back2uo_flakfx_play

Fires flak bursts during an airplane fly-over: for each plane, 3-4 bursts at random
positions inside the player area just below the map ceiling. Each burst position is
stored in level.back2uo_flakposition so back2uo_airplane_flakimpact can test for hits.
Called on: level
Params: aircount - number of planes in the fly-over
=============
*/
back2uo_flakfx_play(aircount)
{
	if(!game["back2uo_flakfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Airplane Fx Play", "Run");

	level endon("back2uo_killthreads");

	// Give the planes time to enter the map.
	wait 2;

	for(z=0;z<aircount;z++)
	{
		level.back2uo_flakfx_count = int(3 + randomint(2));

		for(x=0;x<level.back2uo_flakfx_count;x++)
		{
			// Random x/y inside the player area, 0-199 units below the map ceiling.
			if(!isdefined(level.back2uo_playerdimo_xMin) || !isdefined(level.back2uo_playerdimo_yMin) || !isdefined(level.back2uo_mapdimo_zMax) ) return;
			xpos = level.back2uo_playerdimo_xMin + randomint(level.back2uo_playerdimo_breite);
			ypos = level.back2uo_playerdimo_yMin + randomint(level.back2uo_playerdimo_laenge);
			zpos = level.back2uo_mapdimo_zMax - randomint(200);

			level.back2uo_flakposition = ( xpos, ypos, zpos);

			thread back2uo_flakfx_sound(level.back2uo_flakposition);

			thread back2uo_flakfx_draw(level.back2uo_flakposition);

			wait 0.6;
		}

		wait 2;
	}

	return;
}

/*
=============
back2uo_flakfx_draw

Plays one flak burst as three effects in sequence: flash, smoke, dust (0.25 seconds apart).
Params: position - burst position
=============
*/
back2uo_flakfx_draw(position)
{
	if(!game["back2uo_flakfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Flak Fx Draw", "Run");

	playfx(level.back2uo_effect["flak_flash"], position);
	wait 0.25;

	playfx(level.back2uo_effect["flak_smoke"], position);
	wait 0.25;

	playfx(level.back2uo_effect["flak_dust"], position);
	wait 0.25;
}

/*
=============
back2uo_flakfx_sound

Plays the flak explosion sound at the burst position from a temporary entity, then
plays it once more on all players after it has finished.
Params: position - burst position
=============
*/
back2uo_flakfx_sound(position)
{
	if(!game["back2uo_flakfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Flak Fx Sound", "Run");

	// Temporary sound entity. The one-frame wait lets the spawn reach clients before
	// the origin is moved. playsound with a notify string sends "sounddone" when finished.
	flak = spawn ("script_model", (0, 0, 0) );
	wait 0.05;
	flak.origin = position;
	flak playsound ("flak_explosion", "sounddone");
	flak waittill ("sounddone");
	flak delete();

	thread back2uo\_back2uo_sounds::back2uo_soundonplayers("flak_explosion");
}

/*
=============
back2uo_artilleryfx_control

Grants the player one artillery strike (ranking reward). Marks it in
self.pers["artillery_save"] so it survives a respawn, shows a message, plays the
"artillery ready" voice and starts waiting for binocular use.
Called on: self = player (from _back2uo_hudfx.gsc ranking code)
=============
*/
back2uo_artilleryfx_control()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Control", "Run");

	self endon("disconnect");
	self endon("killed_player");

	// Persistent flag: the strike is still available after death/respawn
	// (_back2uo_hudfx.gsc restarts back2uo_artilleryfx_binowaituse when it is set).
	self.pers["artillery_save"] = true;

	// Only one active artillery grant per player.
	if(!isdefined(self.back2uo_artillery_go)) self.back2uo_artillery_go = false;
	if(self.back2uo_artillery_go) return;

	self.back2uo_artillery_go = true;

	if(self.back2uo_artillery_go)
	{
		self thread back2uo_artilleryfx_binowaituse();

		self iprintlnbold(&"BACK2UOMOD_ARTILLERY_GO");

		// Nation specific "artillery ready" voice, e.g. "artillery_german_ready".
		land = back2uo\_back2uo_tools::back2uo_teams(self);
		sound = "artillery_" + land + "_ready";
		back2uo\_back2uo_sounds::back2uo_soundonplayer(sound, self);
	}
}

/*
=============
back2uo_artilleryfx_binowaituse

Waits for the player to raise the binoculars ("binocular_enter" notify from
_back2uo_hudfx.gsc) and then starts the target selection. Ends once the strike
was called in ("end_waitforuse") or the player dies.
Called on: self = player
=============
*/
back2uo_artilleryfx_binowaituse()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Binocular Use", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("end_waitforuse");
	self endon("killed_player");

	for (;;)
	{
		self waittill("binocular_enter");

		self thread back2uo_artilleryfx_binousing();

		wait 0.2;
	}
}

/*
=============
back2uo_artilleryfx_binousing

While the binoculars are up, checks every 0.2 seconds for the Use key. On Use, traces
the view direction for a target; a valid target fires the strike, an invalid one plays
the "target invalid" voice (if level.back2uo_artillery_order is 1).
Called on: self = player
=============
*/
back2uo_artilleryfx_binousing()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Binocular Using", "Run");

	// Kill any older instance of this thread first, then register the endon after the
	// short wait so this thread does not end on its own notify.
	self notify("binocular_exit");
	wait(0.1);
	self endon("binocular_exit");

	self endon("back2uo_killplayerthreads");
	self endon("artillery_fired");
	self endon("killed_player");

	for (;;)
	{
		if(isPlayer(self) && self useButtonPressed())
		{
			// Ground position the player is looking at, undefined if sky/out of range.
			binopositarget = back2uo\_back2uo_cvars::back2uo_getpositarget();

			if(isdefined(binopositarget))
			{
				self thread back2uo_artilleryfx_fire(binopositarget, self.origin[0], self.origin[1]);

				// Stop both the wait-for-use loop and this thread.
				self notify("end_waitforuse");
				self notify ("artillery_fired");
			}
			else
			{
				// "Target invalid" radio voice.
				if(level.back2uo_artillery_order == 1)
				{
					if(self.pers["team"] == "allies")
					{
						back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_allies_targetfalse", self);
					}
					else
					{
						back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_axis_targetfalse", self);
					}
				}
			}
		}

		wait .2;
	}
}

/*
=============
back2uo_artilleryfx_fire

Confirms the target, warns the player if the target is closer than
level.back2uo_artillery_danger, removes the artillery HUD icon, starts the strike and
consumes the player's artillery grant.
Called on: self = player
Params: binopositarget - target position
		selftarget_x, selftarget_y - player x/y; shells are launched from above this point
=============
*/
back2uo_artilleryfx_fire(binopositarget, selftarget_x, selftarget_y)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Fire", "Run");

	if(isdefined(binopositarget))
	{
		// "Target confirmed" radio voice.
		if(level.back2uo_artillery_order == 1)
		{
			if(self.pers["team"] == "allies")
			{
				back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_allies_targettrue", self);
			}
			else
			{
				back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_axis_targettrue", self);
			}
		}

		dangerdist = distance( self.origin, binopositarget );

		// Danger-close warning (0 disables it).
		if(isdefined(level.back2uo_artillery_danger) && level.back2uo_artillery_danger != 0 && dangerdist < level.back2uo_artillery_danger)
		{
			self iprintlnbold(&"BACK2UOMOD_ARTILLERY_DANGER");
		}

		if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

		// Hide the artillery icon in the client UI.
		self setClientCvar("back2uo_ui_artillery_icon", 0);

		thread back2uo_artilleryfx_play(binopositarget, selftarget_x, selftarget_y);

		self iprintlnbold(&"BACK2UOMOD_ARTILLERY_FIRING");

		// Strike used up.
		self.pers["artillery_save"] = undefined;
		self.back2uo_artillery_go = false;

		return;
	}

	return;
}

/*
=============
back2uo_artilleryfx_play

Runs the artillery strike: incoming voice alert, a launch sound after 4-5 seconds, then
three salvos 3 seconds apart. Salvo 2 and 3 are shifted around the target to spread the
impacts. Shells per salvo is level.back2uo_artillery_count, or 4-7 if that is 0.
Called on: self = player who called the strike
Params: binopositarget - target position
		selftarget_x, selftarget_y - launch x/y (player position when firing)
=============
*/
back2uo_artilleryfx_play(binopositarget, selftarget_x, selftarget_y)
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Play", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Back2Uo: team of the caller at the time the strike is fired (used for friendly fire checks).
	attacker_team = self.pers["team"];

	thread back2uo_artillery_sound();

	// Salvo counter.
	art_wait = 0;

	// Random launch sound.
	soundfx_artlaun[0] = "artillery_launch1";
	soundfx_artlaun[1] = "artillery_launch2";
	soundfx_artlaun[2] = "artillery_launch3";

	artlaun_efx = randomInt(soundfx_artlaun.size);

	wait (4 + randomint(2));

	self thread back2uo\_back2uo_sounds::back2uo_soundonplayers(soundfx_artlaun[artlaun_efx]);

	// Shell flight time before the first impacts.
	wait 4 + randomint(4);

	while(art_wait < 3)
	{
		// Shift the aim point for salvo 2 (+0..99) and salvo 3 (-100..-199 from that).
		if(art_wait == 1) binopositarget = binopositarget + (randomint(100), randomint(100), 0);
		else if(art_wait == 2) binopositarget = binopositarget - (int(100 + randomint(100)), int(100 + randomint(100)), 0);

		artillerycount = 0;

		// 0 = random shell count.
		// Back2Uo: local count so concurrent strikes do not overwrite each other.
		if(level.back2uo_artillery_count == 0)
		{
			artillery_count2 = int(4 + randomint(4));
		}
		else
		{
			artillery_count2 = level.back2uo_artillery_count;
		}

		while(artillerycount < artillery_count2)
		{
			// Back2Uo: run the shell on level so it is always deleted, even if the caller disconnects.
			level thread back2uo_artillery_draw(binopositarget, selftarget_x, selftarget_y, self, attacker_team);

			artillerycount++;

			wait 0.6;
		}

		art_wait++;

		wait 3;
	}
}

/*
=============
back2uo_artillery_draw

Drops a single artillery shell: a shell model falls from the map ceiling above the
caller toward a random point around the target, then plays a surface dependent impact
effect, explosion sound, screen shake and radius damage credited to the caller.
Called on: level (no caller endons, so the shell model is always deleted)
Params: binopositarget - target position
		selftarget_x, selftarget_y - x/y of the shell start point
		attacker - player who called the strike (damage attacker)
		attacker_team - team of the caller when the strike was fired
=============
*/
back2uo_artillery_draw(binopositarget, selftarget_x, selftarget_y, attacker, attacker_team)
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Draw", "Run");

	artillery_zmax = level.back2uo_mapdimo_zMax;

	// Start high above the caller's position.
	startposition = (selftarget_x, selftarget_y, artillery_zmax);

	// Ground point scattered randomly around the target.
	endposition = back2uo\_back2uo_tools::back2uo_calcshellpos(binopositarget);

	// Shell model, nose pointing along the flight path, hidden until the whistle has started.
	artillery = spawn("script_model", startposition);
	artillery setModel("xmodel/vehicle_halftrack_rockets_shell_d");
	artillery.origin = startposition;
	artillery.angles = vectortoangles(vectornormalize((endposition) - startposition));;
	artillery hide();

	// Trace along the flight path to get the impact point and surface type.
	trace = bulletTrace( startposition, endposition, false, undefined );

	// Map the hit surface to one of the level.back2uo_effect["artillery_*"] impact effects.
	artilleryfx = "dirt";

	switch(trace["surfacetype"])
	{
	case "beach":
	case "sand":
	case "mud":
		artilleryfx = "beach";
		break;

	case "asphalt":
	case "metal":
		artilleryfx = "concrete";
		break;

	case "snow":
		artilleryfx = "snow";
		break;

	case "wood":
	case "grass":
	case "dirt":
		artilleryfx = "wood";
		break;

	case "water":
		artilleryfx = "water";
		break;
	}

	wait 0.05;

	// Random incoming whistle.
	soundfx_artincom[0] = "artillery_fallincome1";
	soundfx_artincom[1] = "artillery_fallincome2";
	soundfx_artincom[2] = "artillery_fallincome3";

	artincom_efx = randomInt(soundfx_artincom.size);

	artillery playsound(soundfx_artincom[artincom_efx]);

	wait 0.3;

	artillery show();

	// Fall time scales with the flight distance, minimum 0.5 seconds (like the mortar).
	fall_distance = distance(startposition, trace["position"]);
	fall_time = (fall_distance / 1000) / 4;

	if(fall_time < 0.5) fall_time = 0.5;

	artillery moveto(trace["position"], fall_time);

	wait fall_time;

	// Impact effect for the surface type.
	playfx(level.back2uo_effect["artillery_" + artilleryfx], trace["position"]);

	// Random explosion sound.
	soundfx_artexplo[0] = "artillery_explod1";
	soundfx_artexplo[1] = "artillery_explod2";
	soundfx_artexplo[2] = "artillery_explod3";

	artexplo_efx = randomInt(soundfx_artexplo.size);

	artillery playsound(soundfx_artexplo[artexplo_efx]);

	artillery hide();

	thread back2uo_artillery_damage(trace["position"], attacker, attacker_team);

	// Strong screen shake (scale 0.8, radius 3000), length 0.5 or 1.5 seconds.
	// Back2Uo: randomint(2), randomint(1) was always 0.
	length = 0.5 + randomint(2);
	earthquake(0.8, length, trace["position"], 3000);

	artillery delete();
}

/*
=============
back2uo_artillery_damage

Applies artillery damage to all players within 600 units of the impact. Damage falls off
quadratically with distance (max 300) and is reduced to 2 percent if the line from the
impact to the player's chest is blocked. Players under spawn protection and players that
are not alive are skipped. Friendly fire follows level.friendlyfire like Callback_PlayerDamage
in tdm.gsc: "0" off, "1" on, "2" reflect half to the caller, "3" victim and caller take half.
Params: endposition - impact position
		attacker - player who called the strike
		attacker_team - team of the caller when the strike was fired
=============
*/
back2uo_artillery_damage(endposition, attacker, attacker_team)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Damage", "Run");

	damage_radius = 600;
	damage_strength = 300;

	// Back2Uo: credit the caller only while he is still connected and in the team that fired the strike.
	eAttacker = undefined;
	if(isdefined(attacker) && isPlayer(attacker) && isdefined(attacker_team) && isdefined(attacker.pers["team"]) && attacker.pers["team"] == attacker_team) eAttacker = attacker;

	players = getEntArray("player", "classname");

	for(i=0; i < players.size; i++)
	{
		player = players[i];

		// Back2Uo: only living players (no spectators or dead players).
		if(!isdefined(player.sessionstate) || player.sessionstate != "playing") continue;

		dist = distance(player.origin, endposition);

		// back2uo_antiplay_sp_run = spawn protection active (_back2uo_antiplay.gsc).
		if(!isdefined(player.back2uo_antiplay_sp_run)) player.back2uo_antiplay_sp_run = false;

		if(isdefined(player.back2uo_antiplay_sp_run) && player.back2uo_antiplay_sp_run != true)
		{
			if(dist <= damage_radius)
			{
				// Back2Uo: teammate of the caller (by the team captured when the strike was fired).
				teamhit = false;
				if(getcvar("g_gametype") != "dm" && isdefined(attacker_team) && isdefined(player.pers["team"]) && player.pers["team"] == attacker_team && (!isdefined(eAttacker) || player != eAttacker)) teamhit = true;

				// Friendly fire off: no damage to this teammate (Back2Uo: continue instead of return).
				if(teamhit && level.friendlyfire == "0") continue;

				// Quadratic falloff: full damage at the impact, 0 at the radius edge.
				damage_percent = (damage_radius - dist) / damage_radius;
				iDamage = (damage_strength * damage_percent) * damage_percent;

				// Cover check from the impact to the player's chest (40 units up).
				trace = bulletTrace(endposition, player.origin + (0,0,40), false, undefined);
				if(trace["fraction"] != 1) iDamage = iDamage * 0.02;

				// Back2Uo: reflect/shared friendly fire deals half damage, at least 1 point.
				if(teamhit && (level.friendlyfire == "2" || level.friendlyfire == "3"))
				{
					iDamage = int(iDamage * .5);
					if(iDamage < 1) iDamage = 1;
				}

				// Direct damage call, bypassing the gametype Callback_PlayerDamage.
				// Back2Uo: the victim is not damaged on reflected friendly fire ("2").
				if(!teamhit || level.friendlyfire != "2")
				{
					player finishPlayerDamage(player, eAttacker, int(iDamage), 1, "MOD_EXPLOSIVE", "artillery_mp", undefined, undefined, "none", player.psOffsetTime);
					if(isdefined(eAttacker) && eAttacker != player) eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
					player thread back2uo_artillery_shellshockOnDamage(iDamage);
					player playrumble("damage_heavy");
				}

				// Back2Uo: reflect ("2") or shared ("3") damage to the caller, only while he is connected and alive.
				if(teamhit && (level.friendlyfire == "2" || level.friendlyfire == "3") && isdefined(eAttacker) && eAttacker.sessionstate == "playing")
				{
					eAttacker.friendlydamage = true;
					eAttacker finishPlayerDamage(eAttacker, eAttacker, int(iDamage), 1, "MOD_EXPLOSIVE", "artillery_mp", undefined, undefined, "none", eAttacker.psOffsetTime);
					eAttacker.friendlydamage = undefined;
				}
			}
		}
	}
}

/*
=============
back2uo_artillery_shellshockOnDamage

Applies the "default" shellshock with a duration based on the damage taken
(>10: 1s, >=25: 2s, >=50: 3s, >=90: 4s).
Called on: self = player
Params: damage - damage dealt by the artillery hit
=============
*/
back2uo_artillery_shellshockOnDamage(damage)
{
	time = 0;

	if(damage >= 90)
		time = 4;
	else if(damage >= 50)
		time = 3;
	else if(damage >= 25)
		time = 2;
	else if(damage > 10)
		time = 1;

	if(time) self shellshock("default", time);
}

/*
=============
back2uo_artillery_sound

Plays a random "incoming artillery" voice line to all players if level.back2uo_artillery_alert
is set. All nationalities map to the "GE_" voice set.
Called on: self = player who called the strike
=============
*/
back2uo_artillery_sound()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	if(!level.back2uo_artillery_alert) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Sound", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Sound alias nationality prefix (only the German voice set is used).
	nat="";

	if(isdefined(self.origin) && self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			nat = "GE_";
			break;

		case "british":
			nat = "GE_";
			break;

		case "russian":
			nat = "GE_";
			break;
		}
	}
	else if(isdefined(self.origin) && self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
		case "german":
			nat = "GE_";
			break;
		}
	}
	else
	{
		nat = "GE_";
	}

	// Pick voice variant 0-3.
	// Back2Uo: proper range checks so variants 2/3 are used too.
	pc = randomInt(100);
	num = 0;

	if(pc < 25) num = 0;
	else if(pc < 50) num = 1;
	else if(pc < 75) num = 2;
	else num = 3;

	// Alias e.g. "GE_1_inform_incoming_artillery".
	alias = nat + num + "_inform_incoming_artillery";

	thread back2uo\_back2uo_sounds::back2uo_soundonplayers(alias);
}
