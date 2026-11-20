/*
	Back2Uo v2.1 - War effects entry point: random triggers for tracers, mortars and airplanes.

	back2uo_warfx_random() is called from _back2uo_player::back2uo_start_gametype and starts
	level threads that randomly send the level events "back2uo_warfx_tracer" / "_mortar" /
	"_airplane" (see _back2uo_events.gsc), handled by the *_control() loops in the other warfx scripts.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
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
	if(!game["back2uo_warfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("warfx", "skip", "reason=disabled");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Random", "Run");

	back2uo\_back2uo_cvars::back2uo_logevent("warfx", "start", "chance=" + level.back2uo_warfx_random + " tracer=" + game["back2uo_ambtracerfx_enable"] + " mortar=" + game["back2uo_mortarfx_enable"] + " airplane=" + game["back2uo_airplanesfx_enable"]);

	thread back2uo_warfx_ambtrace_random();
	thread back2uo_warfx_mortar_random();
	thread back2uo_warfx_airplane_random();
}

/*
=============
back2uo_warfx_ambtrace_random

Every 10-19 seconds rolls a random number and, if it is below level.back2uo_warfx_random
(cvar back2uo_warfx_random, 1-100), sends "back2uo_warfx_tracer" (one ambient tracer wave).
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
		roll = randomintrange(1, 100);

		if(roll < level.back2uo_warfx_random)
		{
			back2uo\_back2uo_cvars::back2uo_logevent("warfx", "allow", "fx=tracer roll=" + roll + " chance=" + level.back2uo_warfx_random);

			back2uo\_back2uo_events::back2uo_event_warfx("tracer");
		}

		wait (10 + randomfloatrange(1, 10));
	}
}

/*
=============
back2uo_warfx_mortar_random

Every 20-49 seconds rolls against level.back2uo_warfx_random and, on success,
sends "back2uo_warfx_mortar" (one mortar barrage, see back2uo_mortarfx_control).
Called on: level
=============
*/
back2uo_warfx_mortar_random()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Mortar Random", "Run");

	for(;;)
	{
		roll = randomintrange(1, 100);

		if(roll < level.back2uo_warfx_random)
		{
			back2uo\_back2uo_cvars::back2uo_logevent("warfx", "allow", "fx=mortar roll=" + roll + " chance=" + level.back2uo_warfx_random);

			back2uo\_back2uo_events::back2uo_event_warfx("mortar");
		}

		wait (20 + randomfloatrange(1, 30));
	}
}

/*
=============
back2uo_warfx_airplane_random

Every 10-39 seconds rolls against level.back2uo_warfx_random and, on success,
sends "back2uo_warfx_airplane" (one airplane fly-over, see back2uo_airplanefx_control).
Called on: level
=============
*/
back2uo_warfx_airplane_random()
{
	level endon("back2uo_killthreads");

	back2uo\_back2uo_cvars::back2uo_logprint("War Fx Airplane Random", "Run");

	for(;;)
	{
		roll = randomintrange(1, 100);

		if(roll < level.back2uo_warfx_random)
		{
			back2uo\_back2uo_cvars::back2uo_logevent("warfx", "allow", "fx=airplane roll=" + roll + " chance=" + level.back2uo_warfx_random);

			back2uo\_back2uo_events::back2uo_event_warfx("airplane");
		}

		wait (10 + randomfloatrange(1, 30));
	}
}
