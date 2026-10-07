/*
	Back2Uo v2.1 - map effects for Carentan (mp_carentan)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_carentan.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientsmokefx, back2uo_ambientfogbankfx, back2uo_ambientdustfx (stored in level.<cvar>).
	With the mod off (back2uo_status 0) the map behaves like stock.
*/

/*
=============
main

Entry point of the map FX script. Reads the Back2Uo switches, then precaches
and starts the map effects.
Called on: level
=============
*/
main()
{
	// Back2Uo: read the mod on/off switch. This runs before the mod's main script, so back2uo_status is read here.
	// Note: the default here is 0 (1 in _back2uo_main.gsc); an unset cvar is set to 0 by this call.
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 0, 0, 1);

	// Back2Uo: per-group effect switches (back2uo_getcvardef also honours _<gametype> / _<mapname> overrides).
	// With the mod off, all groups stay on as in stock.
	if(game["back2uo_enable"])
	{
		level.back2uo_ambientfogbankfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfogbankfx", 1, 0, 1, "int");
		level.back2uo_ambientsmokefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientsmokefx", 1, 0, 1, "int");
		level.back2uo_ambientdustfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientdustfx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientfogbankfx = 1;
		level.back2uo_ambientsmokefx = 1;
		level.back2uo_ambientdustfx = 1;
	}

	precacheFX();
	ambientFX();
	level.scr_sound["flak88_explode"]			= "flak88_explode";
}

/*
=============
precacheFX

Loads the map's effects into level._effect[].
Back2Uo: effect groups that are switched off are not loaded.
=============
*/
precacheFX()
{
	level._effect["flak_explosion"]				= loadfx("fx/explosions/flak88_explosion.efx");
	// Back2Uo: load each effect group only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientdustfx) level._effect["dust_wind"] = loadfx("fx/dust/dust_wind_eldaba.efx");
	if(level.back2uo_ambientfogbankfx) level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");
	if(level.back2uo_ambientsmokefx) level._effect["thin_black_smoke_M"] = loadfx ("fx/smoke/thin_black_smoke_M.efx");

}

/*
=============
ambientFX

Starts the looping map effects.
loopfx args: effect name, origin, repeat delay in seconds, second point that sets
the effect direction (usually straight above the origin).
Back2Uo: each group only runs when it was loaded in precacheFX().
=============
*/
ambientFX()
{
	// Back2Uo: each block below runs only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientfogbankfx)
	{
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (1568,2712,-47), 2, (1568,2712,52));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-1102,1725,-27), 2, (-1102,1725,72));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (567,3433,-52), 2, (567,3433,47));
	}

	if(level.back2uo_ambientsmokefx)
	{
		maps\mp\_fx::loopfx("thin_black_smoke_M", (266,620,280), 1, (266,620,379));
	}

	if(level.back2uo_ambientdustfx)
	{
		maps\mp\_fx::loopfx("dust_wind", (-240,1574,-23), 1, (-240,1574,76));
		maps\mp\_fx::loopfx("dust_wind", (-240,1110,-23), 1, (-240,1110,76));
		maps\mp\_fx::loopfx("dust_wind", (473,966,-2), 1, (473,966,97));
		maps\mp\_fx::loopfx("dust_wind", (1546,2003,-42), 1, (1546,2003,57));
		maps\mp\_fx::loopfx("dust_wind", (1511,1078,-39), 1, (1511,1078,60));
		maps\mp\_fx::loopfx("dust_wind", (1398,349,-16), 1, (1398,349,83));
		maps\mp\_fx::loopfx("dust_wind", (935,2569,-49), 1, (935,2569,50));
		maps\mp\_fx::loopfx("dust_wind", (-228,2353,-15), 1, (-228,2353,84));
		maps\mp\_fx::loopfx("dust_wind", (470,238,2), 1, (470,238,101));
		maps\mp\_fx::loopfx("dust_wind", (362,-202,46), 1, (362,-202,145));
		maps\mp\_fx::loopfx("dust_wind", (372,-673,46), 1, (372,-673,145));
		maps\mp\_fx::loopfx("dust_wind", (-242,485,-8), 1, (-242,485,90));
	}
}
