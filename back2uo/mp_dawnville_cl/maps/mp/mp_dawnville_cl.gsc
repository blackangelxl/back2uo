///////////////////////////////
// Dawnville Classic         //
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
 // Load
 maps\mp\mp_dawnville_cl_fx::main();
 maps\mp\_load::main();

 // String - Ambiente Sound
 ambientPlay("ambient_mp_dawnville_cl");
 
 // String - Ambiente Fog 
 setExpFog (0.00025, 0.32, 0.36, 0.40, 0);
 
 // String
 game["allies"] = "american";
 game["axis"] = "german";
 game["attackers"] = "allies";
 game["defenders"] = "axis";
 game["american_soldiertype"] = "normandy";
 game["german_soldiertype"] = "normandy";

 // Set Cvars
 setCvar("r_glowbloomintensity0", ".25");
 setCvar("r_glowbloomintensity1", ".25");
 setcvar("r_glowskybleedintensity0",".3");

 // String - HQ Radios
 if(getcvar("g_gametype") == "hq")
 {
  // String - Radio Models
  // "xmodel/military_german_fieldradio_grey_nonsolid"
  // level.radio[x] = spawn("script_model", (y, x, z));
  // level.radio[x].angles = (y, x, z);

  // String - Array
  level.radio = [];

  // String - Radio 1
  level.radio[0] = spawn("script_model", (1311, 1043, -46));
  level.radio[0].angles = (359, 31, 0);
 
  // String - Radio 2		
  level.radio[1] = spawn("script_model", (384, 2173, -92));
  level.radio[1].angles = (359, 266, 8);
		
  // String - Radio 3
  level.radio[2] = spawn("script_model", (-261, 954, -95));
  level.radio[2].angles = (4.5, 105.5, -2.9);
		
  // String - Radio 4
  level.radio[3] = spawn("script_model", (4053.46, 1607.12, -111.875));
  level.radio[3].angles = (5.81335, 65.4657, -3.04688);
		
  // String - Radio 5
  level.radio[4] = spawn("script_model", (-64.4553, -1436.31, -0.0437865));
  level.radio[4].angles = (359.913, 359.993, 0.283987);
		
  // String - Radio 6
  level.radio[5] = spawn("script_model", (1426.76, -945.505, 109.956));
  level.radio[5].angles = (359.913, 261.693, 0.283987);
 }
}
