/*
	Back2Uo v2.1 - zk_libcod function wrappers, release stub without zk_libcod.

	Same functions as the zk_libcod version in z_svr_back2uo_2.1_libcod.iwd, which replaces this
	file when it is installed (see there). This stub calls no zk_libcod function, so the mod
	also loads on a stock server; every wrapper runs its fallback from
	back2uo\_back2uo_libcod_fallback.gsc:
	- sprint: weapon swap instead of speed mode (_back2uo_sprint.gsc)
	- test bots: stand at their spawn, the bot AI does not start (bots\_back2uo_botai.gsc)
*/

/*
=============
back2uo_libcod_active

Returns false: zk_libcod is not used. Logs the fallback once per map.
=============
*/
back2uo_libcod_active()
{
	if(!isdefined(level.back2uo_libcod))
	{
		level.back2uo_libcod = false;

		// The log switch may not be read yet when this runs before back2uo_main.
		if(isdefined(game["back2uo_logprint_enable"])) back2uo\_back2uo_cvars::back2uo_logevent("libcod", "stub", "fallback=on");
	}

	return false;
}

// --- Player movement ---

back2uo_libcod_setspeed(speed)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setspeed(speed);
}

back2uo_libcod_getspeed()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getspeed();
}

back2uo_libcod_setholdingweapondown(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setholdingweapondown(on);
}

// --- Player state ---

back2uo_libcod_aimbuttonpressed()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_aimbuttonpressed();
}

back2uo_libcod_isusingbinoculars()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isusingbinoculars();
}

back2uo_libcod_isbot()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isbot();
}

back2uo_libcod_renameclient(name)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_renameclient(name);
}

back2uo_libcod_getvieworigin()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getvieworigin();
}

back2uo_libcod_getcurrentweaponclipammo()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getcurrentweaponclipammo();
}

back2uo_libcod_isreloading()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

back2uo_libcod_isonladder()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

back2uo_libcod_canmantle()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

back2uo_libcod_ismantling()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

back2uo_libcod_getinactivitytime()
{
	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getinactivitytime();
}

// --- Bullets ---

back2uo_libcod_setbulletdrop(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setbulletdrop(on);
}

// --- Bot input ---

back2uo_libcod_setwalkdir(dir)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_setwalkvalues(forward, right)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_setbotstance(stance)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_setlean(lean)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_setaim(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_fireweapon(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_reloadweapon(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

back2uo_libcod_meleeweapon(on)
{
	self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}
