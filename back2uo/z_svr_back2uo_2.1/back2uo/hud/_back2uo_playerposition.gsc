/*
	Back2Uo v2.1 - Stance/sprint indicator (bottom left), sprint stamina bar and sprint breathing sound.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_playerposition_draw

Creates the stance icons (stand, crouch, prone, sprint) at the bottom left, all hidden,
and the sprint stamina bar below them.
Called on: self = player
=============
*/
back2uo_playerposition_draw()
{
	if(!game["back2uo_playerposition_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Run");

	// Stance icons share one position; only the active one is made visible.
	if(!isDefined(self.playerposition_crouch))
	{
		self.playerposition_crouch = newClientHudElem(self);
		self.playerposition_crouch.x = 105; // was 108
		self.playerposition_crouch.y = 415; // was 422
		self.playerposition_crouch.horzAlign = "left";
		self.playerposition_crouch.vertAlign = "top";
		self.playerposition_crouch.alpha = 0;
		self.playerposition_crouch.sort = 2;
		self.playerposition_crouch setShader("gfx/custom/back2uo_hud_stance_crouch.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_prone))
	{
		self.playerposition_prone = newClientHudElem(self);
		self.playerposition_prone.x = 105; // was 108
		self.playerposition_prone.y = 415; // was 422
		self.playerposition_prone.horzAlign = "left";
		self.playerposition_prone.vertAlign = "top";
		self.playerposition_prone.alpha = 0;
		self.playerposition_prone.sort = 2;
		self.playerposition_prone setShader("gfx/custom/back2uo_hud_stance_prone.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_stand))
	{
		self.playerposition_stand = newClientHudElem(self);
		self.playerposition_stand.x = 105; // was 108
		self.playerposition_stand.y = 415; // was 422
		self.playerposition_stand.horzAlign = "left";
		self.playerposition_stand.vertAlign = "top";
		self.playerposition_stand.alpha = 0;
		self.playerposition_stand.sort = 2;
		self.playerposition_stand setShader("gfx/custom/back2uo_hud_stance_stand.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_sprint))
	{
		self.playerposition_sprint = newClientHudElem(self);
		self.playerposition_sprint.x = 105; // was 108
		self.playerposition_sprint.y = 415; // was 422
		self.playerposition_sprint.horzAlign = "left";
		self.playerposition_sprint.vertAlign = "top";
		self.playerposition_sprint.alpha = 0;
		self.playerposition_sprint.sort = 2;
		self.playerposition_sprint setShader("gfx/custom/back2uo_hud_stance_sprint.tga", 45, 45); // was 40, 40
	}

	// Sprint stamina bar (width grows with self.hud_sprint_height)
	if(!isDefined(self.playerposition_sprintcross))
	{
		self.playerposition_sprintcross = newClientHudElem(self);
		self.playerposition_sprintcross.x = 110;
		self.playerposition_sprintcross.y = 450;
		self.playerposition_sprintcross.horzAlign = "left";
		self.playerposition_sprintcross.vertAlign = "top";
		self.playerposition_sprintcross.color = ((1/100)*3, (1/100)*2, 0);
		self.playerposition_sprintcross.alpha = 0.8;
		self.playerposition_sprintcross.sort = 3;
		self.playerposition_sprintcross.archived = true;
		self.playerposition_sprintcross setShader("white", 1, 5);
	}
}

/*
=============
back2uo_playerposition_update

Starts the sprint bar and breathing threads, then every 0.1 seconds shows the icon
of the current stance (from back2uo_player_stance()) and hides the others.
Icons only become visible when level.back2uo_sprint_onhud is set.
Called on: self = player
=============
*/
back2uo_playerposition_update()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self thread back2uo_playerposition_sprint();
	self thread back2uo_playerposition_sprintsound();

	for(;;)
	{
		posi_type = back2uo\_back2uo_cvars::back2uo_player_stance();

		switch(posi_type)
		{
		default:

			if(isdefined(self.playerposition_crouch)) self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_stand) && level.back2uo_sprint_onhud) self.playerposition_stand.alpha = 0.9;

			break;

		case "crouch":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_crouch) && level.back2uo_sprint_onhud)self.playerposition_crouch.alpha = 0.9;

			break;

		case "prone":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_crouch))self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_prone) && level.back2uo_sprint_onhud) self.playerposition_prone.alpha = 0.9;

			break;

		case "sprint":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_crouch))self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;

			if(isdefined(self.playerposition_sprint) && level.back2uo_sprint_onhud) self.playerposition_sprint.alpha = 0.9;

			break;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_sprint

Drives the sprint stamina bar. While sprinting, self.hud_sprint_height grows from 1 to 36
(the bar width in pixels); when not sprinting it shrinks back. Also controls
self.pers["breathing"], which triggers the heavy breathing sound.
back2uo_sprint_length and back2uo_sprint_rehatime are total seconds; divided by 35 they
become the time per bar step.
Called on: self = player
=============
*/
back2uo_playerposition_sprint()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Postion Sprint", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	breath_timeon = 1;
	breath_timeoff = 1;
	sprint_waiton = 0.2;
	sprint_waitoff = 1;
	sprint_length = level.back2uo_sprint_length / 35;
	sprint_rehatime =  level.back2uo_sprint_rehatime / 35;
	self.hud_sprint_height = 1;
	self.pers["breathing"] = false;
	self.sprint_breathingout = 0;
	self.sprint_stop = undefined;

	for(;;)
	{
		// Slow the loop down at the bar limits (empty while sprinting, full while resting).
		if(self.pers["sprinting"] && self.hud_sprint_height < 2)
		{
			wait sprint_waiton;
		}
		else if(!self.pers["sprinting"] && self.hud_sprint_height > 35)
		{
			wait sprint_waitoff;
		}

		// Bar above 15: start heavy breathing; below 15 keep breathing for another 20 loop passes.
		if(self.hud_sprint_height > 15)
		{
			self.pers["breathing"] = true;
			self.sprint_breathingout = 0;
		}
		else if(self.hud_sprint_height < 15)
		{
			if(self.sprint_breathingout == 20)
			{
				self.pers["breathing"] = false;
				self.sprint_breathingout = 0;
			}
			else
			{
				self.sprint_breathingout++;
			}
		}

		// Sprinting: grow the bar one step per sprint_length seconds up to 36.
		while(self.pers["sprinting"] && self usebuttonpressed())
		{
			self.sprint_stop = undefined;

			if(isdefined(self.playerposition_sprintcross))
			{
				self.playerposition_sprintcross scaleOverTime(breath_timeon, self.hud_sprint_height, 5);
				self.playerposition_sprintcross.color = ((self.hud_sprint_height/100)*3, (self.hud_sprint_height/100)*2, 0);
			}

			if(self.hud_sprint_height < 36) self.hud_sprint_height++;
			else self.pers["breathing"] = true;

			wait sprint_length;
		}

		// Not sprinting: after a short delay shrink the bar one step per sprint_rehatime seconds.
		if(!self.pers["sprinting"] && self.hud_sprint_height >= 2)
		{
			if(!isdefined(self.sprint_stop))
			{
				wait 0.8;

				self.sprint_stop = true;
			}

			// Only regenerate while the sprint key is released or the player stands still.
			if(!self usebuttonpressed() || self.pers["is_moving"] == false)
			{
				if(isdefined(self.playerposition_sprintcross))
				{
					self.playerposition_sprintcross scaleOverTime(breath_timeoff, self.hud_sprint_height, 5);
					self.playerposition_sprintcross.color = ((self.hud_sprint_height/100)*3, (self.hud_sprint_height/100)*2, 0);
				}

				if(self.hud_sprint_height >= 2) self.hud_sprint_height = self.hud_sprint_height - 1;

				wait sprint_rehatime;
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_sprintsound

Plays the sprint breathing sound every 1.4 seconds while self.pers["breathing"] is set.
Called on: self = player
=============
*/
back2uo_playerposition_sprintsound()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position Sprintsound", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(self.pers["breathing"])
		{
			self thread back2uo\_back2uo_sounds::back2uo_soundonplayerorigin("sprint_breathing", self);

			wait 1.4;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_clear

Destroys the stance icons and the sprint stamina bar.
Called on: self = player
=============
*/
back2uo_playerposition_clear()
{
	if(!game["back2uo_playerposition_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Clear");

	// Stand icon
	if(isDefined(self.playerposition_stand)) self.playerposition_stand destroy();

	// Crouch icon
	if(isDefined(self.playerposition_crouch)) self.playerposition_crouch destroy();

	// Prone icon
	if(isDefined(self.playerposition_prone)) self.playerposition_prone destroy();

	// Sprint icon
	if(isDefined(self.playerposition_sprint)) self.playerposition_sprint destroy();

	// Sprint stamina bar
	if(isDefined(self.playerposition_sprintcross)) self.playerposition_sprintcross destroy();
}
