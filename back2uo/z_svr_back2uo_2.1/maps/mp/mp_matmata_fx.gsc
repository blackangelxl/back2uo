/*
	Back2Uo v2.1 - map effects for Matmata (mp_matmata)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_matmata.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientdustfx (stored in level.<cvar>).
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
	// Back2Uo: default 1 as in _back2uo_main.gsc (an unset cvar means the mod is on).
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 1, 0, 1);

	// Back2Uo: per-group effect switches (back2uo_getcvardef also honours _<gametype> / _<mapname> overrides).
	// With the mod off, all groups stay on as in stock.
	if(game["back2uo_enable"])
	{
		level.back2uo_ambientdustfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientdustfx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientdustfx = 1;
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
	if(level.back2uo_ambientdustfx) level._effect["dust_wind"] = loadfx ("fx/dust/dust_wind_brown_thick.efx");

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
	if(level.back2uo_ambientdustfx)
	{
		maps\mp\_fx::loopfx("dust_wind", (2693,5237,-7), 3, (2693,5237,2));
		maps\mp\_fx::loopfx("dust_wind", (2758,6086,-7), 3, (2758,6086,2));
		maps\mp\_fx::loopfx("dust_wind", (3225,5742,-7), 3, (3225,5742,2));
		maps\mp\_fx::loopfx("dust_wind", (3007,7063,11), 3, (3007,7063,21));
		maps\mp\_fx::loopfx("dust_wind", (3700,8032,33), 3, (3700,8032,43));
		maps\mp\_fx::loopfx("dust_wind", (4310,7680,33), 3, (4310,7680,43));
		maps\mp\_fx::loopfx("dust_wind", (4318,6863,9), 3, (4318,6863,19));
		maps\mp\_fx::loopfx("dust_wind", (4323,6232,9), 3, (4323,6232,19));
		maps\mp\_fx::loopfx("dust_wind", (5695,7583,9), 3, (5695,7583,19));
		maps\mp\_fx::loopfx("dust_wind", (5485,6965,9), 3, (5485,6965,19));
		maps\mp\_fx::loopfx("dust_wind", (5387,6282,-54), 3, (5387,6282,-44));
		maps\mp\_fx::loopfx("dust_wind", (4888,5676,9), 3, (4888,5676,19));
		maps\mp\_fx::loopfx("dust_wind", (4878,5168,15), 3, (4878,5168,25));
		maps\mp\_fx::loopfx("dust_wind", (4875,4523,15), 3, (4875,4523,25));
		maps\mp\_fx::loopfx("dust_wind", (6537,6190,-17), 3, (6537,6190,-7));
	}
}
