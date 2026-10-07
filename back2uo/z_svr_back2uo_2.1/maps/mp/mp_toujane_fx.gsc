/*
	Back2Uo v2.1 - map effects for Toujane (mp_toujane)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_toujane.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects and exploders.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientsmokefx, back2uo_ambientfogbankfx, back2uo_ambientdustfx (stored in level.<cvar>).
	With the mod off (back2uo_status 0) the map behaves like stock.
*/

/*
=============
main

Entry point of the map FX script. Reads the Back2Uo switches, then precaches
and starts the map effects and exploders.
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
		level.back2uo_ambientsmokefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientsmokefx", 1, 0, 1, "int");
		level.back2uo_ambientdustfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientdustfx", 1, 0, 1, "int");
		level.back2uo_ambientfogbankfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfogbankfx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientsmokefx = 1;
		level.back2uo_ambientdustfx = 1;
		level.back2uo_ambientfogbankfx = 1;
	}

	precacheFX();
	ambientFX();
	exploderFX();
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
	if(level.back2uo_ambientdustfx) level._effect["dust_wind"] = loadfx("fx/dust/dust_wind_brown.efx");
	if(level.back2uo_ambientfogbankfx) level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");
	if(level.back2uo_ambientsmokefx) level._effect["smoke_plumeBG"] = loadfx ("fx/smoke/smoke_plumeBG_toujane.efx");

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
	if(level.back2uo_ambientsmokefx)
	{
		maps\mp\_fx::loopfx("smoke_plumeBG", (8624,881,61), 1, (8624,881,71));
		maps\mp\_fx::loopfx("smoke_plumeBG", (-6206,8708,214), 1, (-6206,8708,224));
		// Disabled: unused stock effect position.
		//	maps\mp\_fx::loopfx("smoke_plumeBG", (-2234,-3032,12), 1, (-2234,-3032,22));
	}

	if(level.back2uo_ambientdustfx)
	{
		maps\mp\_fx::loopfx("dust_wind", (2027,692,21), 0.3, (2027,692,31));
		maps\mp\_fx::loopfx("dust_wind", (1365,3161,69), 0.3, (1365,3161,79));
		maps\mp\_fx::loopfx("dust_wind", (1856,2662,69), 0.3, (1856,2662,79));
		maps\mp\_fx::loopfx("dust_wind", (2250,2078,69), 0.3, (2250,2078,79));
		maps\mp\_fx::loopfx("dust_wind", (2519,1565,69), 0.3, (2519,1565,79));
		maps\mp\_fx::loopfx("dust_wind", (2434,890,69), 0.3, (2434,890,79));
		maps\mp\_fx::loopfx("dust_wind", (956,1213,-20), 0.3, (956,1213,-10));
		maps\mp\_fx::loopfx("dust_wind", (1480,587,-7), 0.3, (1480,587,2));
		maps\mp\_fx::loopfx("dust_wind", (988,520,-2), 0.3, (988,520,7));
		maps\mp\_fx::loopfx("dust_wind", (97,1566,23), 0.3, (97,1566,33));
		maps\mp\_fx::loopfx("dust_wind", (7,1042,23), 0.3, (7,1042,33));
		maps\mp\_fx::loopfx("dust_wind", (49,550,23), 0.3, (49,550,33));
		maps\mp\_fx::loopfx("dust_wind", (1548,1959,36), 0.3, (1548,1959,46));
		maps\mp\_fx::loopfx("dust_wind", (1763,1525,70), 0.3, (1763,1525,80));
		maps\mp\_fx::loopfx("dust_wind", (1304,1571,13), 0.3, (1304,1571,23));
		maps\mp\_fx::loopfx("dust_wind", (898,2122,35), 0.3, (898,2122,45));
		maps\mp\_fx::loopfx("dust_wind", (971,2615,67), 0.3, (971,2615,77));
	}
}

/*
=============
exploderFX

Registers the flak explosion exploders. exploderfx args: exploder number, effect name,
origin, delay, direction point. The effect plays when the map fires that exploder number.
=============
*/
exploderFX()
{
	maps\mp\_fx::exploderfx(1, "flak_explosion", (1069,2761,87), 0, (1069,2761,97));
	maps\mp\_fx::exploderfx(2, "flak_explosion", (2818,1640,79), 0, (2818,1640,89));

}
