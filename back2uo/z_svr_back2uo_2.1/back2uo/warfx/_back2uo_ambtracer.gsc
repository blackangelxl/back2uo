/*
	Back2Uo v2.1 - Ambient tracer effects in the sky.

	back2uo_ambtracerfx_control() is started from _back2uo_player::back2uo_start_gametype.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
*/

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
