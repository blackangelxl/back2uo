/*
	Back2Uo v2.1 - War effects entry point: random triggers for tracers, mortars and airplanes.

	back2uo_warfx_random() is called from _back2uo_player::back2uo_start_gametype and starts
	level threads that randomly raise the level.back2uo_*fx_allow flags polled by the
	*_control() loops in the other warfx scripts.
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
