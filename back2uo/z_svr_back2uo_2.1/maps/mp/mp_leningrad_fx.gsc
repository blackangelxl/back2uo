/*
	Back2Uo v2.1 - map effects for Leningrad (mp_leningrad)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_leningrad.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientsmokefx, back2uo_ambientfirefx (stored in level.<cvar>).
	The stock snow effects only run with the mod off; Back2Uo draws its own snow (weatherfx\_back2uo_weather.gsc).
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
		level.back2uo_ambientfirefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfirefx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientsmokefx = 1;
		level.back2uo_ambientfirefx = 1;
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
	level._effect["flak_explosion"]	= loadfx("fx/explosions/flak88_explosion.efx");

	// Back2Uo: load each effect group only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientfirefx)
	{
		level._effect["building_fire_large"] = loadfx ("fx/fire/building_fire_large.efx");
		level._effect["building_fire_small"] = loadfx ("fx/fire/building_fire_small.efx");
	}

	if(level.back2uo_ambientsmokefx) level._effect["thin_black_smoke_M"] = loadfx ("fx/smoke/thin_black_smoke_M.efx");

	// Back2Uo: stock snow only with the mod off; the mod's weather system replaces it.
	if(!game["back2uo_enable"])
	{
		level._effect["snow_light"]					= loadfx ("fx/misc/snow_light_mp_downtown.efx");
		level._effect["snow_wind_cityhall"]			= loadfx ("fx/misc/snow_wind_cityhall.efx");
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
	// Back2Uo: stock snow only with the mod off (matches precacheFX).
	if(!game["back2uo_enable"])
	{
		// World snow
		maps\mp\_fx::loopfx("snow_light", (-75,-208,232), 0.6, (-75,-208,332));
	}

	// Back2Uo: smoke group, only with back2uo_ambientsmokefx on.
	if(level.back2uo_ambientsmokefx)
	{
		maps\mp\_fx::loopfx("thin_black_smoke_M", (1444,-893,517), 2, (1444,-893,532));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (1680,1468,484), 1, (1680,1468,498));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-2211,1574,540), 2, (-2211,1574,550));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-1599,1828,585), 1, (-1599,1828,595));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (-630,-958,71), 2, (-657,-955,168));
	}

	if(level.back2uo_ambientfirefx)
	{
		maps\mp\_fx::loopfx("building_fire_large", (-2236,1405,362), 1, (-2137,1396,369));
		maps\mp\_fx::loopfx("building_fire_large", (-1355,-1509,599), 2, (-1355,-1509,610));
		maps\mp\_fx::loopfx("building_fire_large", (1371,-738,506), 2, (1371,-738,517));
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("bigfire", (1384,-746,-575));
	maps\mp\_fx::soundfx("bigfire", (-1352,-1494,656));
	maps\mp\_fx::soundfx("bigfire", (-2236,1405,362));
}
