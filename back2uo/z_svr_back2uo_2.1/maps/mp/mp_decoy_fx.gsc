/*
	Back2Uo v2.1 - map effects for El Alamein (mp_decoy)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_decoy.gsc) at level load,
	before the gametype starts. It precaches and starts the map's looping effects.
	Back2Uo lets the server switch effect groups off (e.g. to save client FPS):
	back2uo_ambientfirefx, back2uo_ambientdustfx (stored in level.<cvar>).
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
		level.back2uo_ambientdustfx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientdustfx", 1, 0, 1, "int");
		level.back2uo_ambientfirefx = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_ambientfirefx", 1, 0, 1, "int");
	}
	else
	{
		level.back2uo_ambientdustfx = 1;
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
	level._effect["flak_explosion"]				= loadfx("fx/explosions/flak88_explosion.efx");
	// Back2Uo: load each effect group only when its back2uo_ambient*fx switch is on.
	if(level.back2uo_ambientdustfx) level._effect["dust_wind_night"] = loadfx ("fx/dust/dust_wind_night.efx");

	if(level.back2uo_ambientfirefx)
	{
		level._effect["tank_fire_turret"] = loadfx ("fx/fire/tank_fire_turret_small.efx");
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
	if(level.back2uo_ambientfirefx)
	{
		maps\mp\_fx::loopfx("tank_fire_turret", (6278,-12882,-426), 1, (6278,-12882,-326));
		maps\mp\_fx::loopfx("tank_fire_engine", (6307,-12952,-463), 1, (6403,-12979,-474));
		maps\mp\_fx::loopfx("tank_fire_engine", (6217,-12988,-440), 1, (6217,-12988,-340));
		maps\mp\_fx::loopfx("tank_fire_engine", (8223,-13346,-470), 1, (8313,-13306,-452));
		maps\mp\_fx::loopfx("tank_fire_engine", (8198,-13409,-398), 1, (8288,-13369,-381));
		maps\mp\_fx::loopfx("tank_fire_engine", (8214,-13503,-434), 1, (8214,-13503,-334));
		maps\mp\_fx::loopfx("tank_fire_engine", (7875,-12708,-442), 1, (7875,-12708,-342));
		maps\mp\_fx::loopfx("tank_fire_engine", (7837,-12562,-442), 1, (7837,-12562,-342));
		maps\mp\_fx::loopfx("tank_fire_engine", (7917,-12603,-460), 1, (8009,-12564,-453));
		maps\mp\_fx::loopfx("tank_fire_turret", (8193,-13408,-422), 1, (8197,-13406,-323));
		maps\mp\_fx::loopfx("tank_fire_turret", (7860,-12626,-423), 1, (7864,-12624,-324));
	}

	if(level.back2uo_ambientdustfx)
	{
		maps\mp\_fx::loopfx("dust_wind_night", (8823,-12338,-441), .6, (8823,-12338,-341));
		maps\mp\_fx::loopfx("dust_wind_night", (6469,-12810,-496), .6, (6469,-12810,-396));
		maps\mp\_fx::loopfx("dust_wind_night", (7128,-13570,-489), .6, (7128,-13570,-389));
		maps\mp\_fx::loopfx("dust_wind_night", (7008,-12849,-496), .6, (7008,-12849,-396));
		maps\mp\_fx::loopfx("dust_wind_night", (7228,-12212,-450), .6, (7228,-12212,-350));
		maps\mp\_fx::loopfx("dust_wind_night", (7645,-12160,-396), .6, (7645,-12160,-296));
		maps\mp\_fx::loopfx("dust_wind_night", (8566,-12053,-513), .6, (8566,-12053,-413));
		maps\mp\_fx::loopfx("dust_wind_night", (8469,-11695,-480), .6, (8469,-11695,-380));
		maps\mp\_fx::loopfx("dust_wind_night", (8015,-11958,-474), .6, (8015,-11958,-374));
		maps\mp\_fx::loopfx("dust_wind_night", (7642,-12674,-496), .6, (7642,-12674,-396));
		maps\mp\_fx::loopfx("dust_wind_night", (6701,-13118,-496), .6, (6701,-13118,-396));
		maps\mp\_fx::loopfx("dust_wind_night", (7493,-13248,-480), .6, (7493,-13248,-380));
		maps\mp\_fx::loopfx("dust_wind_night", (8316,-12883,-493), .6, (8316,-12883,-393));
		maps\mp\_fx::loopfx("dust_wind_night", (8528,-14377,-702), .6, (8528,-14377,-602));
		maps\mp\_fx::loopfx("dust_wind_night", (9220,-13096,-508), .6, (9220,-13096,-408));
		maps\mp\_fx::loopfx("dust_wind_night", (8674,-13699,-599), .6, (8674,-13699,-499));
		maps\mp\_fx::loopfx("dust_wind_night", (8723,-13259,-492), .6, (8723,-13259,-392));
		maps\mp\_fx::loopfx("dust_wind_night", (9863,-13181,-499), .6, (9863,-13181,-400));
		maps\mp\_fx::loopfx("dust_wind_night", (9590,-13828,-499), .6, (9590,-13828,-399));
		maps\mp\_fx::loopfx("dust_wind_night", (9263,-14137,-579), .6, (9263,-14137,-479));
		maps\mp\_fx::loopfx("dust_wind_night", (9528,-12412,-520), .6, (9528,-12412,-420));
		maps\mp\_fx::loopfx("dust_wind_night", (7244,-14192,-453), .6, (7244,-14192,-353));
		maps\mp\_fx::loopfx("dust_wind_night", (5963,-13410,-520), .6, (5963,-13410,-420));
		maps\mp\_fx::loopfx("dust_wind_night", (6185,-14084,-341), .6, (6185,-14084,-241));
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("medfire", (6271,-12902,-435));
	maps\mp\_fx::soundfx("medfire", (7852,-12631,-438));
	maps\mp\_fx::soundfx("medfire", (8197,-13405,-438));

}
