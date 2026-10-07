/*
	Back2Uo v2.1 - grenade danger indicator client cvars

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from the gametype scripts. For every connected player a thread pushes the
	cg_hudGrenade* client cvars, re-sending them whenever the splitscreen state changes.
	Back2Uo: game["back2uo_granatenindecator_enable"] (cvar back2uo_granatenindecator) turns the
	indicator on (stock sizes) or hides it by setting all icon/pointer sizes to 0.
*/

/*
=============
init

Starts the connect watcher.
=============
*/
init()
{
	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Starts the grenade indicator cvar thread for every connecting player.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player thread updateGrenadeIndicators();
	}
}

/*
=============
updateGrenadeIndicators

Sends the grenade indicator client cvars, then waits until the splitscreen state flips and
sends them again. Both halves of the loop send identical values (the stock splitscreen
values were replaced by the mod), so the toggle only matters as a resend trigger.
Called on: player
=============
*/
updateGrenadeIndicators()
{
	self endon("disconnect");

	for(;;)
	{
		// Back2Uo: grenade indicator ( 0 = off | 1 = on, default 0 ).
		if(game["back2uo_granatenindecator_enable"])
		{
			// Indicator on: stock icon and pointer sizes.
			self setClientCvar("cg_hudGrenadeIconHeight", "25");
			self setClientCvar("cg_hudGrenadeIconWidth", "25");
			self setClientCvar("cg_hudGrenadePointerHeight", "12");
			self setClientCvar("cg_hudGrenadePointerWidth", "25");
		}
		else
		{
			// Indicator off: zero size hides icon and pointer.
			self setClientCvar("cg_hudGrenadeIconHeight", "0");
			self setClientCvar("cg_hudGrenadeIconWidth", "0");
			self setClientCvar("cg_hudGrenadePointerHeight", "0");
			self setClientCvar("cg_hudGrenadePointerWidth", "0");
		}

		self setClientCvar("cg_hudGrenadeIconOffset", "50");
		// Disabled: hide the indicator while scoped / limit its range (engine defaults are used).
		//self setClientCvar("cg_hudGrenadeIconInScope", "0");
		//self setClientCvar("cg_hudGrenadeIconMaxRange", "250");
		self setClientCvar("cg_hudGrenadePointerPivot", "12 27");
		self setClientCvar("cg_fovscale", "1");

		// Poll every server frame until splitscreen becomes active.
		while(!isSplitScreen())
			wait .05;

		// Back2Uo: grenade indicator ( 0 = off | 1 = on, default 0 ).
		if(game["back2uo_granatenindecator_enable"])
		{
			// Indicator on: stock icon and pointer sizes.
			self setClientCvar("cg_hudGrenadeIconHeight", "25");
			self setClientCvar("cg_hudGrenadeIconWidth", "25");
			self setClientCvar("cg_hudGrenadePointerHeight", "12");
			self setClientCvar("cg_hudGrenadePointerWidth", "25");
		}
		else
		{
			// Indicator off: zero size hides icon and pointer.
			self setClientCvar("cg_hudGrenadeIconHeight", "0");
			self setClientCvar("cg_hudGrenadeIconWidth", "0");
			self setClientCvar("cg_hudGrenadePointerHeight", "0");
			self setClientCvar("cg_hudGrenadePointerWidth", "0");
		}

		self setClientCvar("cg_hudGrenadeIconOffset", "50");
		// Disabled: hide the indicator while scoped / limit its range (engine defaults are used).
		//self setClientCvar("cg_hudGrenadeIconInScope", "0");
		//self setClientCvar("cg_hudGrenadeIconMaxRange", "250");
		self setClientCvar("cg_hudGrenadePointerPivot", "12 27");
		self setClientCvar("cg_fovscale", "1");

		// Poll every server frame until splitscreen is turned off again.
		while(isSplitScreen())
			wait .05;
	}
}
