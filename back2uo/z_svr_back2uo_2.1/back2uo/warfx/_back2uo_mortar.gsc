/*
	Back2Uo v2.1 - Mortar effects: random mortar waves with flying shell, impact FX and sound.

	back2uo_mortarfx_control() is started from _back2uo_player::back2uo_start_gametype.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
*/

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
	if(level.back2uo_mortar_count == 0)
	{
		level.back2uo_mortar_count2 = int(5 + randomint(5));
	}
	else
	{
		level.back2uo_mortar_count2 = level.back2uo_mortar_count;
	}

	while(mortarcount < level.back2uo_mortar_count2)
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
Note: randomint(1) always returns 0, so only the positive roll (case 0) is ever used.
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
		switch(randomint(1))
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
	num = randomInt(4);

	// Alias e.g. "GE_1_inform_incoming_mortar".
	alias = nat + num + "_inform_incoming_mortar";

	level thread back2uo\_back2uo_sounds::back2uo_soundonplayers(alias);
}
