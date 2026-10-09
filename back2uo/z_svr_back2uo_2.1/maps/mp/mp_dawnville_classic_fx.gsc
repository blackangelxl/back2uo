/*
	Back2Uo v2.1 - map effects for St. Mere Eglise - Classic (mp_dawnville_classic)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_dawnville.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientsmokefx, back2uo_ambientfirefx (stored in level.<cvar>).
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
	level._effect["flak_explosion"]		= loadfx("fx/explosions/flak88_explosion.efx");

	// Back2Uo: load each effect group only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientsmokefx)
	{
		level._effect["taunt_smoke"] = loadfx ("fx/smoke/thin_black_smoke_S.efx");
		level._effect["black_smoke"] = loadfx ("fx/smoke/thin_black_smoke_M.efx");
 		level._effect["funnel_smoke"] = loadfx ("fx/smoke/vehicle_steam.efx");
 		level._effect["dust_wind"] = loadfx ("fx/dust/dust_wind_eldaba.efx");
		level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");
	}

	if(level.back2uo_ambientfirefx)
	{
		level._effect["lamp_fire"] = loadfx ("fx/props/glow_latern.efx");
		level._effect["building_fire"] = loadfx ("fx/fire/building_fire_med.efx");
 		level._effect["lampglow_fire"] = loadfx ("fx/props/glow_moroccan_chainlamp.efx");
		level._effect["taunt_fire"] = loadfx ("fx/fire/tank_fire_engine.efx");
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
	if(level.back2uo_ambientsmokefx)
	{
		// String - Taunt Smoke
		maps\mp\_fx::loopfx("taunt_smoke", (1376, -1192, 25), .5,(1396, -1192, 45));

		// String - Ruine Smoke  
		maps\mp\_fx::loopfx("black_smoke" , (456, -952, 248), 1);
		maps\mp\_fx::loopfx("black_smoke" , (3871.08, 2253.39, -23), 1); 
		maps\mp\_fx::loopfx("black_smoke" , (-3738, -1740, 321), 1);

		// String - Trainstation Smoke
		maps\mp\_fx::loopfx("funnel_smoke", (-68, -1524, 619), 1, (-68, -1524, 629)); 
		maps\mp\_fx::loopfx("funnel_smoke", (3880.9, 1317.98, 8), 1, (3880.9, 1317.98, 18));

		// String - Street Dust
		maps\mp\_fx::loopfx("dust_wind", (-532, -650, 16), 1.6, (-432, -650, 116)); 
		maps\mp\_fx::loopfx("dust_wind", (1700, -224, -24), .6, (1500, -224, 86));

		// String - Fogbank small
		maps\mp\_fx::loopfx("fogbank_small_duhoc", (456, 1184, -138), 1, (456, 1284, -138));
	}

	if(level.back2uo_ambientfirefx)
	{
		// String - Oil Lamps
		maps\mp\_fx::loopfx("lamp_fire", (72, -1259, 63), 0.4);
		maps\mp\_fx::loopfx("lamp_fire", (1120, -1591, 41), 0.4); 
		maps\mp\_fx::loopfx("lamp_fire", (1776, -1524, 43), 0.4);
		maps\mp\_fx::loopfx("lamp_fire", (-528, -387, 149), 0.4);
		maps\mp\_fx::loopfx("lamp_fire", (1128, 92, -16), 0.4);

		// String - House Fire
		maps\mp\_fx::loopfx("building_fire", (3056, -1264, 100), 1, (3056, -1204, 110));

		// String - Oil Lampsglow
		maps\mp\_fx::loopfx("lampglow_fire", (72, -1259, 63), 0.4);
		maps\mp\_fx::loopfx("lampglow_fire", (1120, -1591, 41), 0.4); 
		maps\mp\_fx::loopfx("lampglow_fire", (1776, -1524, 43), 0.4);
		maps\mp\_fx::loopfx("lampglow_fire", (-528, -387, 149), 0.4);
		maps\mp\_fx::loopfx("lampglow_fire", (1128, 92, -16), 0.4);

		// String - Taunt Fire
		maps\mp\_fx::loopfx("taunt_fire", (1366, -1192, 0), 0.4);
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("taunt_fire", (1376, -1192, -10));
	maps\mp\_fx::soundfx("radio_voice", (2364, -1718, 6));
	maps\mp\_fx::soundfx("medfire1", (3056, -1264, 100));
}
