/*
	Back2Uo v2.1 - Airplane flyovers: squadrons, flak hits, crashes and flight time calculation.

	back2uo_airplanefx_control() is started from _back2uo_player::back2uo_start_gametype.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
*/

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

	thread back2uo\warfx\_back2uo_flak::back2uo_flakfx_play(airplane_count);

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
	airplane moveto(airplane_endpoint, airplane_flytime, .5, .5);

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
Note: randomint(1) always returns 0, so case 1 (mirrored wobble) is never used.
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
		switch(randomint(1))
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
