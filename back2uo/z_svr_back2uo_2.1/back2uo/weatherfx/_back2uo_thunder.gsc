/*
	Back2Uo v2.1 - Thunder and lightning flashes.

	Level entry point (from _back2uo_player::back2uo_start_gametype): back2uo_thunder_draw.
	Split from the former _back2uo_weatherfx.gsc.
	Cvars/flags: game["back2uo_weatherfx_enable"], game["back2uo_rainfx_enable"], game["back2uo_snowfx_enable"],
	game["back2uo_thunderfx_enable"], game["back2uo_coldbreath_enable"], level.back2uo_weatherfx_strength.
*/

/*
=============
back2uo_thunder_draw

Plays a lightning flash with thunder at random intervals of 0-29 seconds.
Rain maps only (not on winter maps).
Called on: level
=============
*/
back2uo_thunder_draw()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_thunderfx_enable"] || !isdefined(game["weather_allow"])) return;
	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Thunder Play", "Run");

	level endon("back2uo_killthreads");

	for (;;)
	{
		wait randomint(30);

		// Not threaded: the next wait starts after the flash sequence is done.
		back2uo_lightningflash();
	}
}

/*
=============
back2uo_lightningflash

Plays one lightning event at a random position inside the player area at middle map
height: thunder sound on all players, then a quick, double or triple flash using one
random lightning effect. In 1 of 6 cases an extra close thunder sound follows.
=============
*/
back2uo_lightningflash()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Lightning Flash", "Run");

	// Flash patterns.
	flash[0] = "quick";
	flash[1] = "double";
	flash[2] = "triple";

	// Keys into level.back2uo_effect.
	lightfx[0] = "lightning";
	lightfx[1] = "thunder_flash";

	wait 0.5;

	// Random x/y inside the player area.
	if(!isdefined(level.back2uo_playerdimo_xMin) || !isdefined(level.back2uo_playerdimo_yMin) || !isdefined(level.back2uo_mapdimo_zMax)) return;
	xpos = level.back2uo_playerdimo_xMin + randomint(level.back2uo_playerdimo_breite);
	ypos = level.back2uo_playerdimo_yMin + randomint(level.back2uo_playerdimo_laenge);
	// Disabled: flash at the map ceiling instead of middle height.
	//zpos = level.back2uo_mapdimo_zMax;
	zpos = level.back2uo_mapdimo_centerz;
	position = ( xpos, ypos, zpos);

	thread back2uo\_back2uo_sounds::back2uo_soundonplayers("elm_thunder");

	flashType = randomint(flash.size);
	lightFx = lightfx[randomInt(lightfx.size)];

	// Unused.
	lit_num = 0;

	switch (flash[flashType])
	{
	case "quick":
		{
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	case "double":
		{
			back2uo_thunderdraw(lightFx, position);
			wait (0.05);
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	case "triple":
		{
			back2uo_thunderdraw(lightFx, position);
			wait (0.05);
			back2uo_thunderdraw(lightFx, position);
			wait (0.5);
			back2uo_thunderdraw(lightFx, position);
			break;
		}
	}

	// 1 in 6 chance for an additional close thunder clap.
	thunder_in = randomint(6);
	if(thunder_in == 3) thread back2uo\_back2uo_sounds::back2uo_soundonplayers("elm_thunderin");
}

/*
=============
back2uo_thunderdraw

Plays a single lightning effect.
Params: lightFx - key into level.back2uo_effect ("lightning" or "thunder_flash")
		position - effect position
=============
*/
back2uo_thunderdraw(lightFx, position)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Thunder Draw", "Run");

	playfx(level.back2uo_effect[lightFx], position);
}
