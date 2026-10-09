/*
	Back2Uo v2.1 - Blood splatter on screen after damage, faded out after a few seconds.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_view_bloodfx

Shows four blood splatter images at random screen positions when the player is hit,
keeps them for 5 seconds and then fades them out via back2uo_update_bloodfx().
Called on: self = player
=============
*/
back2uo_view_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Run");

	// Remove splatters from a previous hit first.
	back2uo_clear_bloodfx();

	if(!isDefined(self.back2uo_bloodyscreen))
	{
		// Random position (x 0-495, y 0-335) and random size 100-198 px.
		bs1 = randomint(496);
		bs2 = randomint(336);
		bs3 = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen = newClientHudElem(self);
		self.back2uo_bloodyscreen.alignX = "center";
		self.back2uo_bloodyscreen.alignY = "top";
		self.back2uo_bloodyscreen.x = bs1;
		self.back2uo_bloodyscreen.y = bs2;
		self.back2uo_bloodyscreen.color = (1,1,1);
		self.back2uo_bloodyscreen.alpha = 1;
		self.back2uo_bloodyscreen.archived = true;
		self.back2uo_bloodyscreen SetShader("gfx/gore/back2uo_hud_blood_hit1.tga", 100 + bs3 , 100 + bs3);
	}

	if(!isDefined(self.back2uo_bloodyscreen1))
	{
		bs1a = randomint(496);
		bs2a = randomint(336);
		bs3a = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen1 = newClientHudElem(self);
		self.back2uo_bloodyscreen1.alignX = "center";
		self.back2uo_bloodyscreen1.alignY = "top";
		self.back2uo_bloodyscreen1.x = bs1a;
		self.back2uo_bloodyscreen1.y = bs2a;
		self.back2uo_bloodyscreen1.color = (1,1,1);
		self.back2uo_bloodyscreen1.alpha = 1;
		self.back2uo_bloodyscreen1.archived = true;
		self.back2uo_bloodyscreen1 SetShader("gfx/gore/back2uo_hud_blood_hit2.tga", 100 + bs3a , 100 + bs3a);
	}

	if(!isDefined(self.back2uo_bloodyscreen2))
	{
		bs1b = randomint(496);
		bs2b = randomint(336);
		bs3b = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen2 = newClientHudElem(self);
		self.back2uo_bloodyscreen2.alignX = "center";
		self.back2uo_bloodyscreen2.alignY = "top";
		self.back2uo_bloodyscreen2.x = bs1b;
		self.back2uo_bloodyscreen2.y = bs2b;
		self.back2uo_bloodyscreen2.color = (1,1,1);
		self.back2uo_bloodyscreen2.alpha = 1;
		self.back2uo_bloodyscreen2.archived = true;
		self.back2uo_bloodyscreen2 SetShader("gfx/gore/back2uo_hud_blood_hit1.tga", 100 + bs3b , 100 + bs3b);
	}

	if(!isDefined(self.back2uo_bloodyscreen3))
	{
		bs1c = randomint(496);
		bs2c = randomint(336);
		bs3c = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen3 = newClientHudElem(self);
		self.back2uo_bloodyscreen3.alignX = "center";
		self.back2uo_bloodyscreen3.alignY = "middle";
		self.back2uo_bloodyscreen3.x = bs1c;
		self.back2uo_bloodyscreen3.y = bs2c;
		self.back2uo_bloodyscreen3.color = (1,1,1);
		self.back2uo_bloodyscreen3.alpha = 1;
		self.back2uo_bloodyscreen3.archived = true;
		self.back2uo_bloodyscreen3 SetShader("gfx/gore/back2uo_hud_blood_hit2.tga", 100 + bs3c , 100 + bs3c);
	}

	wait 5;

	// Start the fade out.
	self back2uo_update_bloodfx();
}

/*
=============
back2uo_update_bloodfx

Fades the screen blood splatters out over 1 to 1.9 seconds and destroys them after 3 seconds.
Called on: self = player
=============
*/
back2uo_update_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Update");

	if(isDefined(self.back2uo_bloodyscreen))
	{
		self.back2uo_bloodyscreen.alpha = 1;
		self.back2uo_bloodyscreen fadeOverTime(1);
		self.back2uo_bloodyscreen.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen1))
	{
		self.back2uo_bloodyscreen1.alpha = 1;
		self.back2uo_bloodyscreen1 fadeOverTime(1.6);
		self.back2uo_bloodyscreen1.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen2))
	{
		self.back2uo_bloodyscreen2.alpha = 1;
		self.back2uo_bloodyscreen2 fadeOverTime(1.3);
		self.back2uo_bloodyscreen2.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen3))
	{
		self.back2uo_bloodyscreen3.alpha = 1;
		self.back2uo_bloodyscreen3 fadeOverTime(1.9);
		self.back2uo_bloodyscreen3.alpha = 0;
	}

	// Wait until all fades (max 1.9 s) are done.
	wait 3;

	// Remove the elements.
	self back2uo_clear_bloodfx();
}

/*
=============
back2uo_clear_bloodfx

Destroys all screen blood splatter elements.
Called on: self = player
=============
*/
back2uo_clear_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Clear");

	if(isDefined(self.back2uo_bloodyscreen))
		self.back2uo_bloodyscreen destroy();

	if(isDefined(self.back2uo_bloodyscreen1))
		self.back2uo_bloodyscreen1 destroy();

	if(isDefined(self.back2uo_bloodyscreen2))
		self.back2uo_bloodyscreen2 destroy();

	if(isDefined(self.back2uo_bloodyscreen3))
		self.back2uo_bloodyscreen3 destroy();
}
