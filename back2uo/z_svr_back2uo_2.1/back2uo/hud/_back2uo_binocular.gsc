/*
	Back2Uo v2.1 - Binocular control and target distance display.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_binocular_control

Waits for the player to raise the binoculars and starts the distance display and
its cleanup thread. If the player was sprinting, binocular use is flagged and the
display is cleared again after 1 second.
Called on: self = player
=============
*/
back2uo_binocular_control()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Control", "Run");

	// The thread can start after the player has already left.
	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("bino_control", "self not exist");
		return;
	}

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	self.pers["bino_inuse"] = false;

	for (;;)
	{
		// Notified by the engine when the player raises the binoculars.
		self waittill("binocular_enter");

		// Started before the delay, so a "binocular_exit" within the delay is not lost.
		self.back2uo_bino_up = true;
		self thread back2uo_binocular_distance_clear();

		// Short delay before the display starts.
		wait (0.3);

		// Binoculars already lowered again: no display (it would block the player until death).
		if(!self.back2uo_bino_up) continue;

		self thread back2uo_binocular_distance_draw();

		wait 0.2;

		// Sprinting with binoculars: flag binocular use (stops sprinting) and clear the display again.
		if(isdefined(self.pers["sprinting"]) && self.pers["sprinting"] == true)
		{
			self.pers["bino_inuse"] = true;

			wait 1;

			self thread back2uo_binocular_distance_clear2();
		}
	}
}

/*
=============
back2uo_binocular_distance_draw

While looking through the binoculars, shows the distance in meters to the aimed point
(via mod UI cvars) and the "use artillery" hint when an artillery strike is ready.
Ends on "binocular_exit".
Called on: self = player
=============
*/
back2uo_binocular_distance_draw()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");

	self endon("disconnect");
	self endon("killed_player");

	self endon("binocular_exit");

	// Blocks other player actions (sprint message, pickups) while the binoculars are up.
	self.back2uo_playerdo = "binocularuse";

	if(game["back2uo_binocularhud_enable"])
	{
		if(!isdefined(self.back2uo_artlength))
		{
			self.back2uo_artlength = newClientHudElem( self );
			self.back2uo_artlength.alignX = "right";
			self.back2uo_artlength.alignY = "top";
			self.back2uo_artlength.fontScale = 1;
			self.back2uo_artlength.x = 340;
			self.back2uo_artlength.y = 380;
			self.back2uo_artlength.sort = 5;
			self.back2uo_artlength.alpha = 0.7;
		}
	}

	if(!isdefined(self.back2uo_artuseing))
	{
		self.back2uo_artuseing = newClientHudElem( self );
		self.back2uo_artuseing.alignX = "center";
		self.back2uo_artuseing.alignY = "top";
		self.back2uo_artuseing.fontScale = 0.8;
		self.back2uo_artuseing.x = 320;
		self.back2uo_artuseing.y = 305;
		self.back2uo_artuseing.sort = 5;
		self.back2uo_artuseing.alpha = 0;
		self.back2uo_artuseing.label = (&"BACK2UOMOD_ARTILLERY_USE");
	}

	for(;;)
	{
		if(game["back2uo_binocularhud_enable"])
		{
			binopositarget = back2uo\_back2uo_cvars::back2uo_getpositarget();

			// Show the name/meters/unknown labels of the mod's binocular UI.
			self setClientCvar("back2uo_ui_artillery_name", 1);

			if(isdefined(binopositarget))
			{
				// Units to meters: 1 unit = 2.5 cm.
				dangerzonegitter = distance( self.origin, binopositarget );
				dangerzonemeter = int(int(dangerzonegitter * 2.5) / 100);

				if(isdefined(self.back2uo_artlength))
				{
					self.back2uo_artlength.alpha = 0.7;
					self.back2uo_artlength setValue(dangerzonemeter);
				}

				self setClientCvar("back2uo_ui_artillery_meters", 1);
				self setClientCvar("back2uo_ui_artillery_unknown", 0);
			}
			else
			{
				if(isdefined(self.back2uo_artlength))
				{
					self.back2uo_artlength.alpha = 0;
				}

				self setClientCvar("back2uo_ui_artillery_meters", 0);
				self setClientCvar("back2uo_ui_artillery_unknown", 1);
			}
		}

		// Artillery strike ready: show the 'use artillery' hint and icon.
		if(isdefined(self.back2uo_artillery_go) && self.back2uo_artillery_go == true)
		{
			if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing.alpha = 1;

			self setClientCvar("back2uo_ui_artillery_icon", 1);
		}

		wait (0.1);
	}
}

/*
=============
back2uo_binocular_distance_clear

Waits for "binocular_exit", then resets the binocular state and removes the distance
and artillery hint display.
Called on: self = player
=============
*/
back2uo_binocular_distance_clear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Clear");

	// Only one waiting clear thread per player.
	self notify("back2uo_binoclear_start");
	self endon("back2uo_binoclear_start");
	self endon("disconnect");

	// Notified by the engine when the player lowers the binoculars.
	self waittill("binocular_exit");

	self.back2uo_bino_up = false;
	self.pers["bino_inuse"] = false;
	self.back2uo_playerdo = "none";

	if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

	self setClientCvar("back2uo_ui_artillery_icon", 0);

	if(!game["back2uo_binocularhud_enable"]) return;

	self setClientCvar("back2uo_ui_artillery_name", 0);
	self setClientCvar("back2uo_ui_artillery_meters", 0);
	self setClientCvar("back2uo_ui_artillery_unknown", 0);

	if(isdefined(self.back2uo_artlength)) self.back2uo_artlength destroy();
}

/*
=============
back2uo_binocular_distance_clear2

Immediately resets the binocular state and removes the distance and artillery hint
display (same as back2uo_binocular_distance_clear without waiting).
Called on: self = player
=============
*/
back2uo_binocular_distance_clear2()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Clear 2");

	self.pers["bino_inuse"] = false;
	self.back2uo_playerdo = "none";

	if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

	self setClientCvar("back2uo_ui_artillery_icon", 0);

	if(!game["back2uo_binocularhud_enable"]) return;

	self setClientCvar("back2uo_ui_artillery_name", 0);
	self setClientCvar("back2uo_ui_artillery_meters", 0);
	self setClientCvar("back2uo_ui_artillery_unknown", 0);

	if(isdefined(self.back2uo_artlength)) self.back2uo_artlength destroy();
}
