/*
	Back2Uo v2.1 - map effects for Burgundy (mp_burgundy)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_burgundy.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects and exploders.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientfirefx, back2uo_ambientfogbankfx, back2uo_ambientdustfx (stored in level.<cvar>).
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
	// Back2Uo: default 1 as in _back2uo_main.gsc (an unset cvar means the mod is on).
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 1, 0, 1);

	// Back2Uo: per-group effect switches (back2uo_getcvardef also honours _<gametype> / _<mapname> overrides).
	// With the mod off, all groups stay on as in stock.
	if(game["back2uo_enable"])
	{
		level.back2uo_ambientfogbankfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfogbankfx", 1, 0, 1, "int");
		level.back2uo_ambientfirefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfirefx", 1, 0, 1, "int");
		level.back2uo_ambientdustfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientdustfx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientfogbankfx = 1;
		level.back2uo_ambientfirefx = 1;
		level.back2uo_ambientdustfx = 1;
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
	if(level.back2uo_ambientdustfx) level._effect["dust_wind"] = loadfx("fx/dust/dust_wind_eldaba.efx");
	if(level.back2uo_ambientfogbankfx) level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");
	if(level.back2uo_ambientfirefx)
	{
		level._effect["tank_fire_turret"] = loadfx ("fx/fire/tank_fire_turret_large.efx");
		level._effect["tank_fire_engine"] = loadfx ("fx/fire/tank_fire_engine.efx");
	}

}

/*
=============
ambientFX

Starts the looping map effects and ambient fire sounds.
loopfx args: effect name, origin, repeat delay in seconds, second point that sets
the effect direction (usually straight above the origin).
soundfx args: sound alias, origin (looping sound, not switchable).
Back2Uo: each group only runs when it was loaded in precacheFX().
=============
*/
ambientFX()
{
	// Back2Uo: each block below runs only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientfogbankfx)
	{
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (235,1406,10), 2, (235,1406,20));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (31,877,0), 2, (31,877,10));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (1674,2014,-39), 2, (1674,2014,-29));
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (1571,359,4), 2, (1571,359,14));
	}

	if(level.back2uo_ambientfirefx)
	{
		maps\mp\_fx::loopfx("tank_fire_turret", (207,306,83), 1, (207,306,93));
		maps\mp\_fx::loopfx("tank_fire_engine", (217,324,114), 1, (217,324,124));
		maps\mp\_fx::loopfx("tank_fire_engine", (139,361,82), 1, (139,361,92));
		maps\mp\_fx::loopfx("tank_fire_engine", (289,278,70), 1, (289,278,80));
		maps\mp\_fx::loopfx("tank_fire_engine", (244,394,54), 1, (244,394,64));
	}

	// Wind-blown dust
	if(level.back2uo_ambientdustfx)
	{
		maps\mp\_fx::loopfx("dust_wind", (769,-189,40), 1, (769,-189,50));
		maps\mp\_fx::loopfx("dust_wind", (941,351,40), 1, (941,351,50));
		maps\mp\_fx::loopfx("dust_wind", (286,-26,8), 1, (286,-26,18));
		maps\mp\_fx::loopfx("dust_wind", (-1154,1517,19), 1, (-1154,1517,29));
		maps\mp\_fx::loopfx("dust_wind", (-1060,797,19), 1, (-1060,797,29));
		maps\mp\_fx::loopfx("dust_wind", (-1071,2040,19), 1, (-1071,2040,29));
		maps\mp\_fx::loopfx("dust_wind", (-402,2658,4), 1, (-402,2658,14));
		maps\mp\_fx::loopfx("dust_wind", (725,3334,16), 1, (725,3334,26));
		maps\mp\_fx::loopfx("dust_wind", (803,2819,16), 1, (803,2819,26));
		maps\mp\_fx::loopfx("dust_wind", (667,2331,16), 1, (667,2331,26));
		maps\mp\_fx::loopfx("dust_wind", (646,1728,16), 1, (646,1728,26));
		maps\mp\_fx::loopfx("dust_wind", (777,1292,16), 1, (777,1292,26));
		maps\mp\_fx::loopfx("dust_wind", (605,752,16), 1, (605,752,26));
		maps\mp\_fx::loopfx("dust_wind", (1520,1368,14), 1, (1520,1368,24));
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("medfire", (201,312,100));

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
	maps\mp\_fx::exploderfx(1, "flak_explosion", (-420,295,44), 0, (-420,295,54));
	maps\mp\_fx::exploderfx(2, "flak_explosion", (-420,295,44), 0, (-420,295,54));
	maps\mp\_fx::exploderfx(3, "flak_explosion", (-420,295,44), 0, (-420,295,54));
}
