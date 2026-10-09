/*
	Back2Uo v2.1 - Anti-play rules: Anti-camper monitor and compass marking.

	back2uo_antiplay_camper() is threaded from _back2uo_player.gsc on connect.
	Cvars (back2uomod.cfg): back2uo_antiplay_cmp_* (camper time, radius, marking time).
	Split from the former _back2uo_antiplay.gsc.
*/

/*
=============
back2uo_antiplay_camper

Anti-camper monitor. Counts about one tick per second while the player stays within
level.back2uo_antiplay_cmp_radius units. At level.back2uo_antiplay_cmp_timer the player is
warned; 20 ticks later he is marked on the compass of all players for
level.back2uo_antiplay_cmp_objtime seconds. Leaving the radius resets the counter and pauses 5 seconds.
Called on: self = player (threaded on connect)
=============
*/
back2uo_antiplay_camper()
{
	if(!game["back2uo_antiplay_cmp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Camper Monitor", "Run");

	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("camper_monitor", "self not exist");
		return;
	}

	level endon("intermission");
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	radius = level.back2uo_antiplay_cmp_radius;
	self.back2uo_campingtime = 0;
	self.back2uo_antiplay_camper_marked = false;

	for(;;)
	{
		// Not counted while already marked
		if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && !self.back2uo_antiplay_camper_marked)
		{
			// Blocks for 1 second
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			if(self_org > radius)
			{
				self.back2uo_campingtime = 0;

				wait 5;
			}
			else if(self_org < radius)
			{
				self.back2uo_campingtime++;
			}

			if (self.back2uo_campingtime == level.back2uo_antiplay_cmp_timer)
			{
				self iprintlnbold(&"BACK2UOMOD_CAMPING_WARNING_MSG");
			}
			else if(self.back2uo_campingtime > level.back2uo_antiplay_cmp_timer + 20)
			{
				self iprintlnbold(&"BACK2UOMOD_CAMPING_MARKED_MSG", level.back2uo_antiplay_cmp_objtime);

				// Compass marker and its timed removal
				thread back2uo_antiplay_camper_start();
				thread back2uo_antiplay_camper_remove();

				self.back2uo_antiplay_camper_marked = true;
				self.back2uo_campingtime = 0;

				continue;
			}
		}
		else
		{
			self.back2uo_campingtime = 0;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_antiplay_camper_start

Adds a compass objective with the nation-specific camper icon and moves it with the
player every server frame until the objective is removed or the player goes spectator.
objective_team "none" makes the marker visible to both teams.
Called on: self = marked player
=============
*/
back2uo_antiplay_camper_start()
{
	if(!game["back2uo_antiplay_cmp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Remove an older marker of this player first
	back2uo_antiplay_camper_remove2();

	// All slots in use: no marker this time
	objnum = back2uo_antiplay_camper_obj();
	if(!isdefined(objnum)) return;

	self.back2uo_objnum = objnum;
	level.back2uo_camper_objslot[objnum] = self;

	compass_icon = "";
	compass_team = "";

	if(self.pers["team"] == "allies")
	{
		compass_icon    = "gfx/custom/back2uo_camper_" + game["allies"] + ".tga";
		compass_team     = "none";
	}
	else if(self.pers["team"] == "axis")
	{
		compass_icon    = "gfx/custom/back2uo_camper_" + game["axis"] + ".tga";
		compass_team     = "none";
	}

	objective_add(self.back2uo_objnum, "current", self.origin, compass_icon);
	objective_team(self.back2uo_objnum, compass_team);

	// back2uo_objnum is cleared by back2uo_antiplay_camper_remove/remove2
	while(isdefined(self.back2uo_objnum) && isdefined(self) && self.pers["team"] != "spectator")
	{
		// Sets the same icon repeatedly without a wait (no visible effect)
		for(i=0; i < level.back2uo_antiplay_cmp_objtime; i++)
		{
			objective_icon(self.back2uo_objnum, compass_icon);
		}

		objective_position(self.back2uo_objnum, self.origin);

		wait 0.05;
	}
}

/*
=============
back2uo_antiplay_camper_obj

Hands out a free compass objective slot for a camper marker. Uses 6..15 so the low
slots stay free for the gametype objectives (CoD2 supports 16 objectives, 0..15).
level.back2uo_camper_objslot[n] holds the marked player of slot n; a slot whose player
has left the server counts as free again.
Returns: objective number, or undefined if all slots are in use
=============
*/
back2uo_antiplay_camper_obj()
{
	if(!isDefined(level.back2uo_camper_objslot)) level.back2uo_camper_objslot = [];

	for(n = 6; n <= 15; n++)
	{
		if(!isdefined(level.back2uo_camper_objslot[n]) || !isPlayer(level.back2uo_camper_objslot[n]))
		{
			// The slot of a disconnected player may still show its icon
			objective_delete(n);
			level.back2uo_camper_objslot[n] = undefined;

			return n;
		}
	}

	return undefined;
}

/*
=============
back2uo_antiplay_camper_remove

Removes the camper marker after level.back2uo_antiplay_cmp_objtime seconds if the player
survived that long. On death the thread ends ("killed_player"); the marker is then removed
by back2uo_antiplay_camper_remove2().
Called on: self = marked player
=============
*/
back2uo_antiplay_camper_remove()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Remove");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(z=0;z < level.back2uo_antiplay_cmp_objtime; z++)
	{
		// Disabled: debug output of the remaining marker time
		//self iprintln(&"BACK2UOMOD_CAMPER_TIME", z);

		wait 1;
	}

	if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && isDefined(self.back2uo_objnum))
	{
		self iprintlnbold(&"BACK2UOMOD_CAMPING_SURVIVED_MSG");

		back2uo_antiplay_camper_remove2();
	}

	// Also when no objective slot was free: let the monitor count again
	self.back2uo_antiplay_camper_marked = false;
}

/*
=============
back2uo_antiplay_camper_remove2

Removes the camper marker immediately and frees its objective slot (called from
_back2uo_player.gsc on player death and disconnect).
Called on: self = player
=============
*/
back2uo_antiplay_camper_remove2()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Camper", "Remove 2");

	if(isDefined(self.back2uo_objnum))
	{
		objective_delete(self.back2uo_objnum);

		if(isdefined(level.back2uo_camper_objslot)) level.back2uo_camper_objslot[self.back2uo_objnum] = undefined;

		self.back2uo_objnum = undefined;
	}

	self.back2uo_antiplay_camper_marked = false;
}
