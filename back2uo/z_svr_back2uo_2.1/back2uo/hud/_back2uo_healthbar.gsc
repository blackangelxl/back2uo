/*
	Back2Uo v2.1 - Health bar (bottom right): draw, update, low-health blinking, spawn protection tint and clear.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_healthbar_draw

Creates the health bar at the bottom right: background, colored bar and a red cross icon.
Called on: self = player
=============
*/
back2uo_healthbar_draw()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Run");

	// Full bar width in pixels at 100 health (1.28 px per health point).
	balkenWidth = 128;

	// Position of the bar relative to the bottom right screen corner.
	// horzAlign "right" / vertAlign "bottom" anchor the elements to that corner,
	// so the bar stays in place on 4:3 and widescreen (16:9, 16:10) resolutions.
	// Equals x = 501, y = 460 on the 640x480 virtual screen.
	healthbar_x = -139;
	healthbar_y = -20;

	// Background
	if(!isDefined(self.healthbar_bg))
	{
		self.healthbar_bg = newClientHudElem(self);
		self.healthbar_bg.x = healthbar_x;
		self.healthbar_bg.y = healthbar_y + 1;
		self.healthbar_bg.horzAlign = "right";
		self.healthbar_bg.vertAlign = "bottom";
		self.healthbar_bg.alpha = 1;
		self.healthbar_bg.sort = 1;
		self.healthbar_bg.archived = true;
		self.healthbar_bg setShader("gfx/hud/hud@health_back.tga", 130, 10);
	}

	// Colored bar: red = 1 - health/100, green = health/100 - 0.4 (green to red).
	if(!isDefined(self.healthbar_gruen))
	{
		self.healthbar_gruen = newClientHudElem(self);
		self.healthbar_gruen.x = healthbar_x + 1;
		self.healthbar_gruen.y = healthbar_y + 2;
		self.healthbar_gruen.horzAlign = "right";
		self.healthbar_gruen.vertAlign = "bottom";
		self.healthbar_gruen.color = (1.0-(self.health/100.0), (self.health/100.0)-0.4, 0);
		self.healthbar_gruen.alpha = 0.4;
		self.healthbar_gruen.sort = 4;
		self.healthbar_gruen.archived = true;
		self.healthbar_gruen setShader("gfx/hud/hud@health_bar.tga", balkenWidth, 8);
	}

	// Cross icon left of the bar
	if(!isDefined(self.healthbar_kreuz))
	{
		self.healthbar_kreuz = newClientHudElem(self);
		self.healthbar_kreuz.x = healthbar_x - 13;
		self.healthbar_kreuz.y = healthbar_y;
		self.healthbar_kreuz.horzAlign = "right";
		self.healthbar_kreuz.vertAlign = "bottom";
		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz.sort = 1;
		self.healthbar_kreuz.archived = true;
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
	}
}

/*
=============
back2uo_healthbar_spawn_prot

Colors the health bar cross while spawn protection is active and resets it to
white when protection ends. Called each tick of the spawn protection loop in
back2uo\antiplay\_back2uo_spawnprotection.gsc.
Called on: self = player
Params: time - elapsed spawn protection time (unused)
		wert - if defined, spawn protection has ended and the cross is reset
=============
*/
back2uo_healthbar_spawn_prot(time, wert)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar Spawn Pro", "Run");

	// Spawn protection active: tint the cross cyan and fade it out (blinks once per call).
	if(isdefined(self.healthbar_kreuz))
	{
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
		self.healthbar_kreuz.color = (0, 2, 2);

		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz fadeOverTime(1);
		self.healthbar_kreuz.alpha = 0;
	}

	// Spawn protection ended: show the white cross again.
	if(isdefined(self.healthbar_kreuz) && isdefined(wert))
	{
		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
		self.healthbar_kreuz.color = (1, 1, 1);
	}
}

/*
=============
back2uo_healthbar_update

Polls the player's health every 0.05 seconds and rescales and recolors the health
bar when it changed. The bar goes from green (full) to red (low).
Called on: self = player
=============
*/
back2uo_healthbar_update()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	balkenWidth = 128;

	for(;;)
	{
		// Sample health twice, 0.05 s apart, and only redraw on change.
		health_status1 = self.health;
		wait .05;
		health_status2 = self.health;

		if(health_status2 != health_status1)
		{
			balkenWidth = Int(health_status2 * 1.28);

			// Health 0 or less: remove the bar.
			if (balkenWidth == 0 || balkenWidth < 0)
			{
				if(isdefined(self.healthbar_gruen)) self.healthbar_gruen destroy();
			}

			// Rescale and recolor
			if(isdefined(self.healthbar_gruen))
			{
				self.healthbar_gruen.alpha = 0.4;
				self.healthbar_gruen setShader("gfx/hud/hud@health_bar.tga", balkenWidth, 8);
				self.healthbar_gruen.color = (1.0-(self.health/100.0), (self.health/100.0)-0.4, 0);
			}
		}
	}
}

/*
=============
back2uo_healthbar_glow

Makes the health bar blink while health is below 50. Lower health means a faster
fade (fade time = health / 100 seconds). Started on every damage event.
Called on: self = player
=============
*/
back2uo_healthbar_glow()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar Glow", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	while(isdefined(self.health) && self.health < 50)
	{
		blink = self.health / 100;

		if(isdefined(self.healthbar_gruen))
		{
			self.healthbar_gruen.alpha = 0.4;
			self.healthbar_gruen fadeOverTime(blink);
			self.healthbar_gruen.alpha = 0;
		}

		wait 0.45;
	}

	if(isDefined(self.healthbar_gruen)) self.healthbar_gruen.alpha = 0.4;
}

/*
=============
back2uo_healthbar_clear

Destroys the health bar elements.
Called on: self = player
=============
*/
back2uo_healthbar_clear()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Clear");

	if(isDefined(self.healthbar_bg))
		self.healthbar_bg destroy();

	if(isDefined(self.healthbar_gruen))
		self.healthbar_gruen destroy();

	if(isDefined(self.healthbar_kreuz))
		self.healthbar_kreuz destroy();
}
