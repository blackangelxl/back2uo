/*
	Back2Uo v2.1 - map effects for Beltot (mp_farmhouse)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_farmhouse.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientsmokefx, back2uo_ambientfogbankfx (stored in level.<cvar>).
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
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_getstatus();

	// Back2Uo: per-group effect switches (back2uo_getcvardef also honours _<gametype> / _<mapname> overrides).
	// With the mod off, all groups stay on as in stock.
	if(game["back2uo_enable"])
	{
		level.back2uo_ambientsmokefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientsmokefx", 1, 0, 1, "int");
		level.back2uo_ambientfogbankfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfogbankfx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientsmokefx = 1;
		level.back2uo_ambientfogbankfx = 1;
	}

	precacheFX();
	ambientFX();
	level.scr_sound["flak88_explode"]	= "flak88_explode";
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
	level._effect["flak_explosion"]		= loadfx("fx/explosions/flak88_explosion.efx");

	// Back2Uo: load each effect group only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientfogbankfx) level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");

	if(level.back2uo_ambientsmokefx)
	{
		level._effect["thin_light_smoke_M"] = loadfx ("fx/smoke/thin_light_smoke_M.efx");
		level._effect["battlefield_smokebank_S"] = loadfx ("fx/smoke/battlefield_smokebank_S.efx");
	}
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
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-2218,-614,-56), 2, (-2218,-614,43));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-3140,386,-76), 2, (-3140,386,23));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-2220,1820,-38), 2, (-2220,1820,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-848,-2588,-38), 2, (-848,-2588,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-863,-1618,-38), 2, (-863,-1618,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-998,-894,-38), 2, (-998,-894,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-1157,-148,-38), 2, (-1157,-148,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-1134,508,-38), 2, (-1134,508,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-998,1051,-38), 2, (-998,1051,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-1722,1775,-38), 2, (-1722,1775,61));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-2178,-1683,-52), 2, (-2178,-1683,47));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (-3492,-425,-69), 2, (-3492,-425,30));
	}

	if(level.back2uo_ambientsmokefx)
	{
		maps\mp\_fx::loopfx("thin_light_smoke_M", (854,264,142), 1, (854,264,242));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-257,1154,91), 1, (-257,1154,191));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-3502,-1477,-68), 1, (-3502,-1477,31));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (196,-1383,47), 1, (196,-1383,147));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (-237,-1389,158), 1, (-237,-1389,258));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (-317,4,56), 1, (-317,4,156));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (144,698,78), 1, (144,698,178));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (-2282,1110,-30), 1, (-2282,1110,69));
	}
}
