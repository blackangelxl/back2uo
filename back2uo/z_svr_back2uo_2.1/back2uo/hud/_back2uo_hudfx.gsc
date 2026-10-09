/*
	Back2Uo v2.1 - Weather/war FX status icons.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_hudfx_draw

Creates the small FX status icons next to the stance icon: weather (snow, rain,
thunder or none), impact (mortar or none) and air (airplanes, flak or none).
Icons are placed left to right, 15 pixels apart.
Called on: self = player
=============
*/
back2uo_hudfx_draw()
{
	if(!game["back2uo_hudfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Run");

	if(!isdefined(level.back2uo_weather_allow)) level.back2uo_weather_allow = false;

	back2uo_hudfx_clear();

	// Start position of the first icon; each icon moves 15 px to the right.
	level.hudfx_x = 93;
	level.hudfx_y = 465;

	// Weather icon
	if(!isDefined(self.hud_weatherfx))
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_weatherfx = newClientHudElem(self);
		self.hud_weatherfx.x = level.hudfx_x;
		self.hud_weatherfx.y = level.hudfx_y;
		self.hud_weatherfx.horzAlign = "left";
		self.hud_weatherfx.vertAlign = "top";
		self.hud_weatherfx.alpha = 0.6;
		self.hud_weatherfx.sort = 1;
		self.hud_weatherfx.archived = true;

		if(isdefined(game["weather_allow"]) && game["back2uo_weatherfx_enable"])
		{
			// Snow on winter maps, rain without thunder, or thunder.
			if(game["back2uo_snowfx_enable"] && game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_snowfx.tga", 10, 10);
			}
			else if(game["back2uo_rainfx_enable"] && !game["back2uo_thunderfx_enable"] && game["german_soldiertype"] != "winterlight" && game["german_soldiertype"] != "winterdark")
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_rainfx.tga", 10, 10);
			}
			else if(game["back2uo_thunderfx_enable"])
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_thunderfx.tga", 10, 10);
			}
		}
		else
		{
			self.hud_weatherfx setShader("gfx/custom/back2uo_hud_noweatherfx.tga", 10, 10);
		}
	}

	// Impact icon (mortar), only with war FX enabled
	if(!isDefined(self.hud_impactfx) && game["back2uo_warfx_enable"])
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_impactfx = newClientHudElem(self);
		self.hud_impactfx.x = level.hudfx_x;
		self.hud_impactfx.y = level.hudfx_y;
		self.hud_impactfx.horzAlign = "left";
		self.hud_impactfx.vertAlign = "top";
		self.hud_impactfx.alpha = 0.6;
		self.hud_impactfx.sort = 1;
		self.hud_impactfx.archived = true;

		if(game["back2uo_mortarfx_enable"])
		{
			self.hud_impactfx setShader("gfx/custom/back2uo_hud_mortarfx.tga", 10, 10);
		}
		else
		{
			self.hud_impactfx setShader("gfx/custom/back2uo_hud_nomortarfx.tga", 10, 10);
		}
	}

	// Air icon (airplanes or flak), only with war FX enabled
	if(!isDefined(self.hud_airfx) && game["back2uo_warfx_enable"])
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_airfx = newClientHudElem(self);
		self.hud_airfx.x = level.hudfx_x;
		self.hud_airfx.y = level.hudfx_y;
		self.hud_airfx.horzAlign = "left";
		self.hud_airfx.vertAlign = "top";
		self.hud_airfx.sort = 1;
		self.hud_airfx.alpha = 0.6;
		self.hud_airfx.archived = true;

		if(isdefined(level.back2uo_airplanedimo_allow) && level.back2uo_airplanedimo_allow == 1)
		{
			if(game["back2uo_airplanesfx_enable"] && !game["back2uo_flakfx_enable"])
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_airplanefx.tga", 10, 10);
			}
			else if(game["back2uo_flakfx_enable"])
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_flakfx.tga", 10, 10);
			}
			else
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_noplanefx.tga", 10, 10);
			}
		}
		else
		{
			self.hud_airfx setShader("gfx/custom/back2uo_hud_noplanefx.tga", 10, 10);
		}
	}
}

/*
=============
back2uo_hudfx_update

Every 0.1 seconds switches the impact icon to the artillery icon while the player
owns an artillery strike (self.pers["artillery_save"]), otherwise back to mortar/none.
Called on: self = player
=============
*/
back2uo_hudfx_update()
{
	if(!game["back2uo_hudfx_enable"]) return;

	if(!game["back2uo_warfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		// Artillery strike available: show the artillery icon instead of the mortar icon.
		if(game["back2uo_artilleryfx_enable"] && isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
		{
			if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_artilleryfx.tga", 10, 10);
		}
		else
		{
			if(game["back2uo_mortarfx_enable"])
			{
				if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_mortarfx.tga", 10, 10);
			}
			else
			{
				if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_nomortarfx.tga", 10, 10);
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_hudfx_clear

Destroys the FX status icons.
Called on: self = player
=============
*/
back2uo_hudfx_clear()
{
	if(!game["back2uo_hudfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Clear");

	if(isDefined(self.hud_weatherfx))
		self.hud_weatherfx destroy();

	if(isDefined(self.hud_airfx))
		self.hud_airfx destroy();

	if(isDefined(self.hud_impactfx))
		self.hud_impactfx destroy();
}
