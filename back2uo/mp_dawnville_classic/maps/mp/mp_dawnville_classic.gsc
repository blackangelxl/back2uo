///////////////////////////////
// Dawnville Classic 		 //
// ------------------------- //
//    created by Le-Style    //
// ------------------------- //
//  powered by               //
//        www.mod-united.de  //
//  www.gcf-team.de          //
// ------------------------- //
//   admins@mod-united.de    //
//    admins@gcf-team.de     //
///////////////////////////////

main()
{
    maps\mp\mp_dawnville_classic_fx::main();
    maps\mp\_load::main();

    setExpFog (0.00025, 0.32, 0.36, 0.40, 0);
    ambientPlay("ambient_mp_dawnville_classic");
 
    game["allies"] = "american";
    game["axis"] = "german";
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    game["american_soldiertype"] = "normandy";
    game["german_soldiertype"] = "normandy";

    setCvar("r_glowbloomintensity0", ".25");
    setCvar("r_glowbloomintensity1", ".25");
    setcvar("r_glowskybleedintensity0",".3");

    if(getcvar("g_gametype") == "hq")
    {
        level.radio = [];
        level.radio[0] = spawn("script_model", (1311, 1043, -46));
        level.radio[0].angles = (359, 31, 0);

        level.radio[1] = spawn("script_model", (384, 2173, -92));
        level.radio[1].angles = (359, 266, 8);

        level.radio[2] = spawn("script_model", (-261, 954, -95));
        level.radio[2].angles = (4.5, 105.5, -2.9);

        level.radio[3] = spawn("script_model", (4053.46, 1607.12, -111.875));
        level.radio[3].angles = (5.81335, 65.4657, -3.04688);

        level.radio[4] = spawn("script_model", (-64.4553, -1436.31, -0.0437865));
        level.radio[4].angles = (359.913, 359.993, 0.283987);

        level.radio[5] = spawn("script_model", (1426.76, -945.505, 109.956));
        level.radio[5].angles = (359.913, 261.693, 0.283987);
    }

    level.killtriggers[0] = spawnstruct();
	level.killtriggers[0].origin = (-44, -15292, 168);
	level.killtriggers[0].radius = 192;
	level.killtriggers[0].height = 80;

	level.killtriggers[1] = spawnstruct();
	level.killtriggers[1].origin = (-1340, -16068, 24);
	level.killtriggers[1].radius = 64;
	level.killtriggers[1].height = 80;

	level.killtriggers[2] = spawnstruct();
	level.killtriggers[2].origin = (-1340, -16212, 24);
	level.killtriggers[2].radius = 64;
	level.killtriggers[2].height = 80;

	level.killtriggers[3] = spawnstruct();
	level.killtriggers[3].origin = (-528, -16488, 92);
	level.killtriggers[3].radius = 12;
	level.killtriggers[3].height = 12;

	level.killtriggers[4] = spawnstruct();
	level.killtriggers[4].origin = (1024, -16416, 244);
	level.killtriggers[4].radius = 260;
	level.killtriggers[4].height = 120;

	level.killtriggers[5] = spawnstruct();
	level.killtriggers[5].origin = (196, -15596, 243);
	level.killtriggers[5].radius = 280;
	level.killtriggers[5].height = 180;

	level.killtriggers[6] = spawnstruct();
	level.killtriggers[6].origin = (192, -16100, 227);
	level.killtriggers[6].radius = 280;
	level.killtriggers[6].height = 180;

	level.killtriggers[7] = spawnstruct();
	level.killtriggers[7].origin = (220, -16992, 250);
	level.killtriggers[7].radius = 165;
	level.killtriggers[7].height = 100;

	level.killtriggers[8] = spawnstruct();
	level.killtriggers[8].origin = (148, -16672, 250);
	level.killtriggers[8].radius = 210;
	level.killtriggers[8].height = 170;

	level.killtriggers[9] = spawnstruct();
	level.killtriggers[9].origin = (1024, -14720, 120);
	level.killtriggers[9].radius = 192;
	level.killtriggers[9].height = 80;
}
