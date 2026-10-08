/*
	Back2Uo v2.1 - map effects for Caen (mp_trainstation)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	main() is called from the map's own script (maps\mp\mp_trainstation.gsc) at level load,
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
	// Back2Uo: default 1 as in _back2uo_main.gsc (an unset cvar means the mod is on).
	game["back2uo_enable"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_status", 1, 0, 1);

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
		level._effect["thin_black_smoke_M"] = loadfx ("fx/smoke/thin_black_smoke_M.efx");
		level._effect["thin_light_smoke_L"] = loadfx ("fx/smoke/thin_light_smoke_L.efx");
		level._effect["thin_light_smoke_M"] = loadfx ("fx/smoke/thin_light_smoke_M.efx");
		level._effect["battlefield_smokebank_S"] = loadfx ("fx/smoke/battlefield_smokebank_S.efx");
	}

	if(level.back2uo_ambientfirefx)
	{
		level._effect["tank_fire_turret"] = loadfx ("fx/fire/tank_fire_turret_small.efx");
		level._effect["tank_fire_turret_large"] = loadfx ("fx/fire/tank_fire_turret_large.efx");
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
		maps\mp\_fx::loopfx("thin_light_smoke_M", (3537,-3753,-4), 1, (3537,-3753,95));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (6754,-2441,405), 0.8, (6754,-2441,505));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (4168,-3115,301), 0.8, (4168,-3115,401));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (4168,-3115,301), 0.8, (4168,-3115,401));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (7634,-4585,-67), 0.8, (7634,-4585,31));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (7735,-3622,-37), 0.8, (7735,-3622,61));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (7642,-1806,-23), 0.8, (7642,-1806,75));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (6777,-2895,-28), 0.8, (6777,-2895,70));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (4807,-3306,0), 1, (4807,-3306,99));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (7495,-3321,-53), 1, (7495,-3321,46));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (7662,-2473,-67), 1, (7662,-2473,32));
		maps\mp\_fx::loopfx("thin_light_smoke_M", (6849,-4013,6), 1, (6849,-4013,106));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (5880,-1868,-34), 0.8, (5880,-1868,64));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (3909,-3186,-24), 0.8, (3909,-3186,74));
		maps\mp\_fx::loopfx("thin_black_smoke_M", (6901,-3773,261), 0.8, (6901,-3773,361));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (4090,-4227,-38), 0.8, (4090,-4227,61));
		maps\mp\_fx::loopfx("battlefield_smokebank_S", (5938,-4938,-31), 0.8, (5938,-4938,67));
	}

	if(level.back2uo_ambientfirefx)
	{
		maps\mp\_fx::loopfx("building_fire_small", (4294,-3288,169), 2, (4284,-3387,169));
		// Disabled: unused stock effect position.
		//	maps\mp\_fx::loopfx("tank_fire_engine", (6356,-2068,47), 1, (6356,-2068,147));
		maps\mp\_fx::loopfx("tank_fire_turret", (6380,-4174,20), 2, (6380,-4174,120));
		// Disabled: unused stock effect position.
		//	maps\mp\_fx::loopfx("tank_fire_turret_large", (6456,-2043,63), 2, (6449,-2023,161));
		maps\mp\_fx::loopfx("tank_fire_engine", (4176,-3262,285), 1, (4176,-3262,385));
		maps\mp\_fx::loopfx("tank_fire_engine", (4194,-4207,62), 1, (4194,-4207,162));
		maps\mp\_fx::loopfx("tank_fire_engine", (4300,-4086,46), 1, (4300,-4086,146));
		maps\mp\_fx::loopfx("building_fire_small", (6678,-2444,277), 2, (6681,-2446,377));
		maps\mp\_fx::loopfx("building_fire_small", (7707,-4243,162), 2, (7710,-4245,262));
		maps\mp\_fx::loopfx("tank_fire_engine", (4234,-4131,94), 1, (4234,-4131,194));
		maps\mp\_fx::loopfx("tank_fire_engine", (7721,-4353,52), 1, (7721,-4353,152));
		maps\mp\_fx::loopfx("tank_fire_engine", (7703,-4164,52), 1, (7703,-4164,152));
		// Disabled: unused stock effect position.
		//	maps\mp\_fx::loopfx("tank_fire_engine", (6426,-2028,89), 1, (6426,-2028,189));
		maps\mp\_fx::loopfx("tank_fire_engine", (6666,-2413,456), 1, (6666,-2413,556));
		maps\mp\_fx::loopfx("tank_fire_engine", (6720,-2473,254), 1, (6720,-2473,354));
		maps\mp\_fx::loopfx("tank_fire_engine", (6919,-2542,259), 1, (6919,-2542,359));
		maps\mp\_fx::loopfx("tank_fire_engine", (6822,-2544,344), 1, (6822,-2544,444));
	}

	// Ambient fire sounds
	maps\mp\_fx::soundfx("medfire", (6684,-2432,288));
	// Disabled: fire sound that belonged to a disabled tank fire effect.
	//	maps\mp\_fx::soundfx("medfire", (6466,-2049,67));
	maps\mp\_fx::soundfx("medfire", (4300,-3282,178));
	maps\mp\_fx::soundfx("medfire", (4221,-4133,54));
	maps\mp\_fx::soundfx("medfire", (6390,-4173,13));
	maps\mp\_fx::soundfx("medfire", (7741,-4229,94));

}
