/*
	Back2Uo v2.1 - map effects for Moscow (mp_downtown)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_downtown.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	This map has no switchable effect groups.
	The stock snow effects only run with the mod off; Back2Uo draws its own snow (_back2uo_weatherfx.gsc).
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
	level._effect["flak_explosion"]			= loadfx("fx/explosions/flak88_explosion.efx");

	// Back2Uo: stock snow only with the mod off; the mod's weather system replaces it.
	if(!game["back2uo_enable"])
	{
		level._effect["snow_light"]				= loadfx ("fx/misc/snow_light_mp_downtown.efx");
		level._effect["snow_wind_cityhall"]		= loadfx ("fx/misc/snow_wind_cityhall.efx");
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
	// Back2Uo: stock snow only with the mod off (matches precacheFX).
	if(!game["back2uo_enable"])
	{
		// World snow
		maps\mp\_fx::loopfx("snow_light", (1635,-1393,375), 0.8, (1635,-1393,475));

		// Snow blowing along the ground
		maps\mp\_fx::loopfx("snow_wind_cityhall", (414,-2231,32), 0.5, (414,-2231,132));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (1711,-2363,129), 0.5, (1711,-2363,229));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (3635,-1707,143), 0.5, (3635,-1707,243));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (2866,1016,13), 0.5, (2866,1016,113));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (2931,-271,9), 0.5, (2931,-271,109));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (354,124,61), 0.5, (354,124,161));
		maps\mp\_fx::loopfx("snow_wind_cityhall", (482,-1161,3), 0.5, (482,-1161,103));
	}
}
