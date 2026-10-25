/*
	Back2Uo v2.1 - zk_libcod function wrappers, zk_libcod version (z_svr_back2uo_2.1_libcod.iwd).

	Every zk_libcod function the mod uses is called only from here. This file replaces the
	release stub back2uo\_back2uo_libcod.gsc in z_svr_back2uo_2.1.iwd: CoD2 searches .iwd files
	in reverse order of their upper-cased names, so z_svr_back2uo_2.1_libcod.iwd comes first.

	CoD2 resolves builtin functions when the script is compiled, so this file only loads on a
	server with zk_libcod. Without zk_libcod, leave z_svr_back2uo_2.1_libcod.iwd out; the stub
	then runs the fallbacks of back2uo\_back2uo_libcod_fallback.gsc. They are also used here
	when the "libcod" dvar of zk_libcod is missing.
*/

/*
=============
back2uo_libcod_active

Returns true when zk_libcod is loaded. Read once per map from the "libcod" dvar.
=============
*/
back2uo_libcod_active()
{
	if(!isdefined(level.back2uo_libcod))
	{
		level.back2uo_libcod = (getCvar("libcod") != "");

		// The log switch may not be read yet when this runs before back2uo_main.
		if(!level.back2uo_libcod && isdefined(game["back2uo_logprint_enable"])) back2uo\_back2uo_cvars::back2uo_logevent("libcod", "missing", "fallback=on");
	}

	return level.back2uo_libcod;
}

// --- Player movement ---

/*
=============
back2uo_libcod_setspeed

Sets the player's movement speed; 0 returns to g_speed.
Called on: self = player
=============
*/
back2uo_libcod_setspeed(speed)
{
	if(back2uo_libcod_active()) self setSpeed(speed);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setspeed(speed);
}

/*
=============
back2uo_libcod_getspeed

Returns the player's movement speed.
Called on: self = player
=============
*/
back2uo_libcod_getspeed()
{
	if(back2uo_libcod_active()) return self getSpeed();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getspeed();
}

/*
=============
back2uo_libcod_setholdingweapondown

Holds the weapon down (no firing, no weapon switch) or raises it again.
Called on: self = player
=============
*/
back2uo_libcod_setholdingweapondown(on)
{
	if(back2uo_libcod_active()) self setHoldingWeaponDown(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setholdingweapondown(on);
}

// --- Player state ---

/*
=============
back2uo_libcod_aimbuttonpressed

Returns true while the player holds the zoom (ADS) key. zk_libcod reads the key itself, so
this also works while the weapon is held down.
Called on: self = player
=============
*/
back2uo_libcod_aimbuttonpressed()
{
	if(back2uo_libcod_active()) return self aimButtonPressed();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_aimbuttonpressed();
}

/*
=============
back2uo_libcod_isusingbinoculars

Returns true while the player looks through the binoculars.
Called on: self = player
=============
*/
back2uo_libcod_isusingbinoculars()
{
	if(back2uo_libcod_active()) return self isUsingBinoculars();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isusingbinoculars();
}

/*
=============
back2uo_libcod_isbot

Returns true for test clients.
Called on: self = player or client entity
=============
*/
back2uo_libcod_isbot()
{
	if(back2uo_libcod_active()) return self isBot();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isbot();
}

/*
=============
back2uo_libcod_getvieworigin

Returns the player's eye position.
Called on: self = player
=============
*/
back2uo_libcod_getvieworigin()
{
	if(back2uo_libcod_active()) return self getViewOrigin();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getvieworigin();
}

/*
=============
back2uo_libcod_getcurrentweaponclipammo

Returns the clip ammo of the current weapon.
Called on: self = player
=============
*/
back2uo_libcod_getcurrentweaponclipammo()
{
	if(back2uo_libcod_active()) return self getCurrentWeaponClipAmmo();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getcurrentweaponclipammo();
}

/*
=============
back2uo_libcod_isreloading

Returns true while the player reloads.
Called on: self = player
=============
*/
back2uo_libcod_isreloading()
{
	if(back2uo_libcod_active()) return self isReloading();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_isonladder

Returns true while the player is on a ladder.
Called on: self = player
=============
*/
back2uo_libcod_isonladder()
{
	if(back2uo_libcod_active()) return self isOnLadder();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_canmantle

Returns true when the player can mantle over the obstacle in front.
Called on: self = player
=============
*/
back2uo_libcod_canmantle()
{
	if(back2uo_libcod_active()) return self canMantle();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_ismantling

Returns true while the player mantles.
Called on: self = player
=============
*/
back2uo_libcod_ismantling()
{
	if(back2uo_libcod_active()) return self isMantling();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

// --- Bot input ---

/*
=============
back2uo_libcod_setwalkdir

Bot walk direction: "none", "forward", "back", "left" or "right".
Called on: self = bot
=============
*/
back2uo_libcod_setwalkdir(dir)
{
	if(back2uo_libcod_active()) self setWalkDir(dir);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setwalkvalues

Bot forward and right move values (-128 to 127).
Called on: self = bot
=============
*/
back2uo_libcod_setwalkvalues(forward, right)
{
	if(back2uo_libcod_active()) self setWalkValues(forward, right);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setbotstance

Bot stance: "stand", "crouch", "prone" or "jump".
Called on: self = bot
=============
*/
back2uo_libcod_setbotstance(stance)
{
	if(back2uo_libcod_active()) self setBotStance(stance);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setlean

Bot lean: "none", "left" or "right".
Called on: self = bot
=============
*/
back2uo_libcod_setlean(lean)
{
	if(back2uo_libcod_active()) self setLean(lean);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setaim

Bot zoom (ADS) on or off.
Called on: self = bot
=============
*/
back2uo_libcod_setaim(on)
{
	if(back2uo_libcod_active()) self setAim(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_fireweapon

Bot holds or releases the fire button.
Called on: self = bot
=============
*/
back2uo_libcod_fireweapon(on)
{
	if(back2uo_libcod_active()) self fireWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_reloadweapon

Bot holds or releases the reload button.
Called on: self = bot
=============
*/
back2uo_libcod_reloadweapon(on)
{
	if(back2uo_libcod_active()) self reloadWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_meleeweapon

Bot holds or releases the melee button.
Called on: self = bot
=============
*/
back2uo_libcod_meleeweapon(on)
{
	if(back2uo_libcod_active()) self meleeWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}
