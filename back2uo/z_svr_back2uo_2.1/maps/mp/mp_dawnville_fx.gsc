/*
	Back2Uo v2.1 - map effects for St. Mere Eglise (mp_dawnville)

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
	// Note: the default here is 0 (1 in _back2uo_main.gsc); an unset cvar is set to 0 by this call.
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 0, 0, 1);

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
		level._effect["thin_black_smoke_S"] = loadfx ("fx/smoke/thin_black_smoke_S.efx");
		level._effect["thin_light_smoke_L"] = loadfx ("fx/smoke/thin_light_smoke_L.efx");
		level._effect["thin_light_smoke_M"] = loadfx ("fx/smoke/thin_light_smoke_M.efx");
		level._effect["battlefield_smokebank_S"] = loadfx ("fx/smoke/battlefield_smokebank_S.efx");
	}

	if(level.back2uo_ambientfirefx)
	{
		level._effect["tank_fire_turret"] = loadfx ("fx/fire/tank_fire_turret_small.efx");
		level._effect["tank_fire_engine"] = loadfx ("fx/fire/tank_fire_engine.efx");
		level._effect["building_fire_small"] = loadfx ("fx/fire/building_fire_small.efx");
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
		maps\mp\_fx::loopfx("thin_light_smoke_M", (-804,-16125,-74), 1, (-804,-16125,25));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (-400,-15553,-62), 1, (-400,-15553,36));

		maps\mp\_fx::loopfx("battlefield_smokebank_S", (620,-15642,1), 1, (620,-15642,101));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (2536,-15436,-84), 1, (2536,-15436,15));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-302,-17245,32), 1, (-302,-17245,132));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (1048,-14864,-41), 1, (1048,-14864,58));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-91,-14659,6), 1, (-91,-14659,105));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (626,-16903,56), 1, (626,-16903,156));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-1014,-17478,37), 1, (-1014,-17478,137));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (-1819,-17836,-11), 1, (-1819,-17836,88));

		maps\mp\_fx::loopfx("thin_black_smoke_S", (-563,-17506,65), 0.6, (-563,-17506,164));
		maps\mp\_fx::loopfx("thin_black_smoke_S", (390,-17422,56), 0.6, (390,-17422,155));
	}

	if(level.back2uo_ambientfirefx)
	{
		maps\mp\_fx::loopfx("tank_fire_turret", (655,-16348,37), 2, (655,-16348,136));
		maps\mp\_fx::loopfx("tank_fire_engine", (593,-16308,-2), 2, (601,-16209,14));
		maps\mp\_fx::loopfx("tank_fire_engine", (821,-17057,59), 2, (821,-17057,159));
		maps\mp\_fx::loopfx("tank_fire_engine", (724,-17202,53), 2, (724,-17202,153));
		maps\mp\_fx::loopfx("tank_fire_engine", (784,-17043,41), 2, (708,-16980,58));
		maps\mp\_fx::loopfx("tank_fire_engine", (732,-17091,45), 2, (657,-17028,62));
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("medfire", (785,-17095,82));
	maps\mp\_fx::soundfx("medfire", (658,-16335,17));

}
