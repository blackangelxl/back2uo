/*
	Back2Uo v2.1 - Flak bursts shot at passing airplanes.

	Started from the airplane effects in warfx\_back2uo_airplane.gsc.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
*/

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
