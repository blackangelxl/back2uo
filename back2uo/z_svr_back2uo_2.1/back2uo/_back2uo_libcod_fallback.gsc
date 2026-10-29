/*
	Back2Uo v2.1 - fallbacks for the zk_libcod functions (stock functions only).

	Used by back2uo\_back2uo_libcod.gsc: always by the release stub in z_svr_back2uo_2.1.iwd,
	and by the zk_libcod version (z_svr_back2uo_2.1_libcod.iwd) when the "libcod" dvar is
	missing. Each function returns what the zk_libcod function would, as far as stock
	functions or mod state allow; otherwise a neutral value or nothing.
*/

// --- Player movement ---

/*
=============
back2uo_libcod_fallback_setspeed

No per-player speed without zk_libcod; the sprint uses the weapon swap instead.
Called on: self = player
=============
*/
back2uo_libcod_fallback_setspeed(speed)
{
}

/*
=============
back2uo_libcod_fallback_getspeed

Returns g_speed, the speed of every player without zk_libcod.
Called on: self = player
=============
*/
back2uo_libcod_fallback_getspeed()
{
	return getcvarint("g_speed");
}

/*
=============
back2uo_libcod_fallback_setholdingweapondown

No-op.
Called on: self = player
=============
*/
back2uo_libcod_fallback_setholdingweapondown(on)
{
}

// --- Player state ---

/*
=============
back2uo_libcod_fallback_aimbuttonpressed

Returns true while the player zooms in (stock playerADS()).
Called on: self = player
=============
*/
back2uo_libcod_fallback_aimbuttonpressed()
{
	return (self playerADS() > 0);
}

/*
=============
back2uo_libcod_fallback_forwardbuttonpressed

Keys are not readable without zk_libcod. Returns self.back2uo_moving_forward, set every
0.1 seconds by _back2uo_sprint::back2uo_sprintsystem_ismoving from the movement direction
compared with the view direction.
Called on: self = player
=============
*/
back2uo_libcod_fallback_forwardbuttonpressed()
{
	return (isdefined(self.back2uo_moving_forward) && self.back2uo_moving_forward);
}

/*
=============
back2uo_libcod_fallback_isusingbinoculars

Returns self.back2uo_bino_up, set on "binocular_enter" / "binocular_exit" in
hud\_back2uo_binocular.gsc.
Called on: self = player
=============
*/
back2uo_libcod_fallback_isusingbinoculars()
{
	return (isdefined(self.back2uo_bino_up) && self.back2uo_bino_up);
}

/*
=============
back2uo_libcod_fallback_isbot

Returns true when pers["bots_nosprint"] is set (test clients, _teams.gsc::TestClient).
Called on: self = player or client entity
=============
*/
back2uo_libcod_fallback_isbot()
{
	return isdefined(self.pers) && isdefined(self.pers["bots_nosprint"]);
}

/*
=============
back2uo_libcod_fallback_renameclient

renameClient: names cannot be changed without zk_libcod, bots keep their default name (bot0, ...).
Called on: self = player or bot
=============
*/
back2uo_libcod_fallback_renameclient(name)
{
}

/*
=============
back2uo_libcod_fallback_getvieworigin

Returns the eye position (stock getEye()).
Called on: self = player
=============
*/
back2uo_libcod_fallback_getvieworigin()
{
	return self getEye();
}

/*
=============
back2uo_libcod_fallback_getcurrentweaponclipammo

Returns the clip ammo of the primary slot holding the current weapon, 0 for any other weapon.
Called on: self = player
=============
*/
back2uo_libcod_fallback_getcurrentweaponclipammo()
{
	weapon = self getCurrentWeapon();

	if(weapon == self getWeaponSlotWeapon("primary")) return self getWeaponSlotClipAmmo("primary");
	if(weapon == self getWeaponSlotWeapon("primaryb")) return self getWeaponSlotClipAmmo("primaryb");

	return 0;
}

/*
=============
back2uo_libcod_fallback_false

isReloading, isOnLadder, canMantle, isMantling: not readable without zk_libcod.
Called on: self = player
=============
*/
back2uo_libcod_fallback_false()
{
	return false;
}

/*
=============
back2uo_libcod_fallback_getinactivitytime

Returns undefined: not readable without zk_libcod (or with g_inactivity 0). The AFK monitor
then measures the movement instead (antiplay\_back2uo_afk.gsc).
Called on: self = player
=============
*/
back2uo_libcod_fallback_getinactivitytime()
{
	return undefined;
}

// --- Bullets ---

/*
=============
back2uo_libcod_fallback_setbulletdrop

No-op: stock bullets fly straight, without zk_libcod (or with g_bulletDrop 0).
Called on: self = player
=============
*/
back2uo_libcod_fallback_setbulletdrop(on)
{
}

// --- Bot input ---

/*
=============
back2uo_libcod_fallback_botinput

setWalkDir, setWalkValues, setBotStance, setLean, setAim, fireWeapon, reloadWeapon,
meleeWeapon: bots cannot be steered without zk_libcod, the bot AI does not start.
Called on: self = bot
=============
*/
back2uo_libcod_fallback_botinput()
{
}
