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
 // Weiterleitung - Precache Fx
 precachefx();

 // Weiterleitung - Play Fx
 playfx(); 

 level.scr_sound["flak88_explode"]	= "flak88_explode";  

 // Weiterleitung - Play Sound
 playsound(); 
}

precachefx()
{
 // String
 level._effect["lamp_fire"] = loadfx ("fx/props/glow_latern.efx");  
 level._effect["lampglow_fire"] = loadfx ("fx/props/glow_moroccan_chainlamp.efx");
 level._effect["taunt_fire"] = loadfx ("fx/fire/tank_fire_engine.efx");
 level._effect["taunt_smoke"] = loadfx ("fx/smoke/thin_black_smoke_S.efx");
 level._effect["dust_wind"] = loadfx ("fx/dust/dust_wind_eldaba.efx");
 level._effect["black_smoke"] = loadfx ("fx/smoke/thin_black_smoke_M.efx");
 level._effect["funnel_smoke"] = loadfx ("fx/smoke/vehicle_steam.efx");
 level._effect["building_fire"] = loadfx ("fx/fire/building_fire_med.efx");
 level._effect["fogbank_small_duhoc"] = loadfx ("fx/misc/fogbank_small_duhoc.efx");
}

playfx()
{
 // String - Oil Lamps
 maps\mp\_fx::loopfx("lamp_fire", (72, -1259, 63), 0.4);
 maps\mp\_fx::loopfx("lamp_fire", (1120, -1591, 41), 0.4); 
 maps\mp\_fx::loopfx("lamp_fire", (1776, -1524, 43), 0.4);
 maps\mp\_fx::loopfx("lamp_fire", (-528, -387, 149), 0.4);
 maps\mp\_fx::loopfx("lamp_fire", (1128, 92, -16), 0.4);
 
 // String - Oil Lampsglow
 maps\mp\_fx::loopfx("lampglow_fire", (72, -1259, 63), 0.4);
 maps\mp\_fx::loopfx("lampglow_fire", (1120, -1591, 41), 0.4); 
 maps\mp\_fx::loopfx("lampglow_fire", (1776, -1524, 43), 0.4);
 maps\mp\_fx::loopfx("lampglow_fire", (-528, -387, 149), 0.4);
 maps\mp\_fx::loopfx("lampglow_fire", (1128, 92, -16), 0.4);

 // String - Taunt Fire
 maps\mp\_fx::loopfx("taunt_fire", (1366, -1192, 0), 0.4);

 // String - Taunt Smoke
 maps\mp\_fx::loopfx("taunt_smoke", (1376, -1192, 25), .5,(1396, -1192, 45));

 // String - Street Dust
 maps\mp\_fx::loopfx("dust_wind", (-532, -650, 16), 1.6, (-432, -650, 116)); 
 maps\mp\_fx::loopfx("dust_wind", (1700, -224, -24), .6, (1500, -224, 86));
 
 // String - Ruine Smoke  
 maps\mp\_fx::loopfx("black_smoke" , (456, -952, 248), 1);
 maps\mp\_fx::loopfx("black_smoke" , (3871.08, 2253.39, -23), 1); 
 maps\mp\_fx::loopfx("black_smoke" , (-3738, -1740, 321), 1);
 
 // String - Trainstation Smoke
 maps\mp\_fx::loopfx("funnel_smoke", (-68, -1524, 619), 1, (-68, -1524, 629)); 
 maps\mp\_fx::loopfx("funnel_smoke", (3880.9, 1317.98, 8), 1, (3880.9, 1317.98, 18));
 
 // String - House Fire
 maps\mp\_fx::loopfx("building_fire", (3056, -1264, 100), 1, (3056, -1204, 110));
 
  // String - Fogbank small
 maps\mp\_fx::loopfx("fogbank_small_duhoc", (456, 1184, -138), 1, (456, 1284, -138));
 
}

playsound()
{
 // String - Taunt Fire
 maps\mp\_fx::soundfx("taunt_fire", (1376, -1192, -10));

 // String - Radio Voice
 maps\mp\_fx::soundfx("radio_voice", (2364, -1718, 6));
 
 // String - Med Fire
 maps\mp\_fx::soundfx("medfire1", (3056, -1264, 100));
}