/*
	Back2Uo v2.1 - weapon precache, allow cvars, grenades, pistols and weapon dropping

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is threaded from every gametype and never returns (it polls the scr_allow_* cvars).
	The gametypes call givePistol(), giveGrenades(), giveBinoculars(), dropWeapon(), dropOffhand(),
	restrictWeaponByServerCvars(), getWeaponName() and useAn(); the mod also uses the grenade count helpers.
	Back2Uo additions: weapon class limit (level.back2uo_weapon_limit), *_sprint weapon variants for the
	sprint system, special grenade variants, optional G43 sniper / Panzerschreck / binoculars,
	turret removal and script_model weapon/grenade pickups instead of the engine dropItem.
	Main switches: game["back2uo_enable"], game["back2uo_weaponsystem_enable"], game["back2uo_sprint_enable"].
*/

#include maps\mp\_utility;

/*
=============
init

Precaches all weapons the server may hand out, builds level.weaponnames / level.weapons
(allow cvars per weapon), sets the initial allow flags, removes restricted map items and then
re-checks the allow cvars every 5 seconds forever.
Back2Uo: with the weapon system on and back2uo_weapons_allow 1-3 only one weapon class is precached
(1 = SMG/LMG, 2 = rifles, 3 = snipers); otherwise the stock per-nation set is used.
Called on: level
=============
*/
init()
{
	// Back2Uo: weapon class limit active ( back2uo_weapons_allow 1 -> 4 ); precache only that class.
	if(game["back2uo_weaponsystem_enable"] && level.back2uo_weapon_limit != 0)
	{
		if(level.back2uo_weapon_limit == 1) // Only Mg's Weapon
		{
			// Standard weapons
			precacheItem("bar_mp");
			precacheItem("bren_mp");
			precacheItem("greasegun_mp");
			precacheItem("mp40_mp");
			precacheItem("mp44_mp");
			precacheItem("ppsh_mp");
			precacheItem("PPS42_mp");
			precacheItem("sten_mp");
			precacheItem("thompson_mp");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("bar_mp_sprint");
			precacheItem("bren_mp_sprint");
			precacheItem("greasegun_mp_sprint");
			precacheItem("mp40_mp_sprint");
			precacheItem("mp44_mp_sprint");
			precacheItem("ppsh_mp_sprint");
			precacheItem("PPS42_mp_sprint");
			precacheItem("sten_mp_sprint");
			precacheItem("thompson_mp_sprint");
		}
		else if(level.back2uo_weapon_limit == 2) // Only Rifle Weapon
		{
			// Standard weapons
			precacheItem("enfield_mp");
			precacheItem("g43_mp");
			precacheItem("kar98k_mp");
			precacheItem("m1carbine_mp");
			precacheItem("m1garand_mp");
			precacheItem("mosin_nagant_mp");
			precacheItem("SVT40_mp");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("enfield_mp_sprint");
			precacheItem("g43_mp_sprint");
			precacheItem("kar98k_mp_sprint");
			precacheItem("m1carbine_mp_sprint");
			precacheItem("m1garand_mp_sprint");
			precacheItem("mosin_nagant_mp_sprint");
			precacheItem("SVT40_mp_sprint");
		}
		else if(level.back2uo_weapon_limit == 3) // Only Sniper Weapon
		{
			// Standard weapons
			precacheItem("enfield_scope_mp");
			precacheItem("kar98k_sniper_mp");
			precacheItem("mosin_nagant_sniper_mp");
			precacheItem("springfield_mp");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("enfield_scope_mp_sprint");
			precacheItem("kar98k_sniper_mp_sprint");
			precacheItem("mosin_nagant_sniper_mp_sprint");
			precacheItem("springfield_mp_sprint");
		}

		// Grenades: only the German set is precached in class-limit mode.
		precacheItem("frag_grenade_german_mp");
		precacheItem("frag_grenade_german_mp_special1");
		precacheItem("frag_grenade_german_mp_special2");
		precacheItem("smoke_grenade_german_mp");
		precacheItem("smoke_grenade_german_mp_special1");

		// Back2Uo: pistols only when back2uo_pistel_allow is 1 (always in pistol-only mode).
		if(level.back2uo_pistel_allow || level.back2uo_weapon_limit == 4)
		{
			// Standard weapons
			precacheItem("colt_mp");
			precacheItem("webley_mp");
			precacheItem("TT30_mp");
			precacheItem("luger_mp");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("colt_mp_sprint");
			precacheItem("webley_mp_sprint");
			precacheItem("TT30_mp_sprint");
			precacheItem("luger_mp_sprint");
		}
	}
	else
	{
		// Stock: precache the weapons of the map's allied nation, then the German (axis) set.
		switch(game["allies"])
		{
		case "american":
			// Nation grenades: stock and Back2Uo special variants.
			precacheItem("frag_grenade_american_mp");
			precacheItem("frag_grenade_american_mp_special1");
			precacheItem("frag_grenade_american_mp_special2");
			precacheItem("smoke_grenade_american_mp");
			precacheItem("smoke_grenade_american_mp_special1");

			// Standard weapons
			precacheItem("colt_mp");
			precacheItem("m1carbine_mp");
			precacheItem("m1garand_mp");
			precacheItem("thompson_mp");
			precacheItem("bar_mp");
			precacheItem("springfield_mp");
			precacheItem("greasegun_mp");
			precacheItem("shotgun_mp_allies");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("colt_mp_sprint");
			precacheItem("m1carbine_mp_sprint");
			precacheItem("m1garand_mp_sprint");
			precacheItem("thompson_mp_sprint");
			precacheItem("bar_mp_sprint");
			precacheItem("springfield_mp_sprint");
			precacheItem("greasegun_mp_sprint");
			precacheItem("shotgun_mp_allies_sprint");

			// Disabled: unused weapons.
			//precacheItem("30cal_mp");
			//precacheItem("M9_Bazooka");
			break;

		case "british":
			// Nation grenades: stock and Back2Uo special variants.
			precacheItem("frag_grenade_british_mp");
			precacheItem("frag_grenade_british_mp_special1");
			precacheItem("frag_grenade_british_mp_special2");
			precacheItem("smoke_grenade_british_mp");
			precacheItem("smoke_grenade_british_mp_special1");

			// Standard weapons
			precacheItem("webley_mp");
			precacheItem("enfield_mp");
			precacheItem("sten_mp");
			precacheItem("bren_mp");
			precacheItem("enfield_scope_mp");
			precacheItem("m1garand_mp");
			precacheItem("thompson_mp");
			precacheItem("shotgun_mp_allies");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("webley_mp_sprint");
			precacheItem("enfield_mp_sprint");
			precacheItem("sten_mp_sprint");
			precacheItem("bren_mp_sprint");
			precacheItem("enfield_scope_mp_sprint");
			precacheItem("m1garand_mp_sprint");
			precacheItem("thompson_mp_sprint");
			precacheItem("shotgun_mp_allies_sprint");

			// Disabled: unused weapons.
			//precacheItem("30cal_mp");
			//precacheItem("M9_Bazooka");
			break;

		case "russian":
			// Nation grenades: stock and Back2Uo special variants.
			precacheItem("frag_grenade_russian_mp");
			precacheItem("frag_grenade_russian_mp_special1");
			precacheItem("frag_grenade_russian_mp_special2");
			precacheItem("smoke_grenade_russian_mp");
			precacheItem("smoke_grenade_russian_mp_special1");

			// Standard weapons
			precacheItem("TT30_mp");
			precacheItem("mosin_nagant_mp");
			precacheItem("SVT40_mp");
			precacheItem("PPS42_mp");
			precacheItem("ppsh_mp");
			precacheItem("mosin_nagant_sniper_mp");
			precacheItem("shotgun_mp_allies");

			// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
			precacheItem("TT30_mp_sprint");
			precacheItem("mosin_nagant_mp_sprint");
			precacheItem("SVT40_mp_sprint");
			precacheItem("PPS42_mp_sprint");
			precacheItem("ppsh_mp_sprint");
			precacheItem("mosin_nagant_sniper_mp_sprint");
			precacheItem("shotgun_mp_allies_sprint");

			// Disabled: unused weapons.
			//precacheItem("dp28_mp");
			//precacheItem("M9_Bazooka");
			break;
		}

		// German grenades: stock and Back2Uo special variants.
		precacheItem("frag_grenade_german_mp");
		precacheItem("frag_grenade_german_mp_special1");
		precacheItem("frag_grenade_german_mp_special2");
		precacheItem("smoke_grenade_german_mp");
		precacheItem("smoke_grenade_german_mp_special1");

		// Standard weapons
		precacheItem("luger_mp");
		precacheItem("kar98k_mp");
		precacheItem("g43_mp");
		precacheItem("mp40_mp");
		precacheItem("mp44_mp");
		precacheItem("kar98k_sniper_mp");
		precacheItem("shotgun_mp_axis");

		// *_sprint variants, swapped in by the sprint system (_back2uo_sprint.gsc)
		precacheItem("luger_mp_sprint");
		precacheItem("kar98k_mp_sprint");
		precacheItem("g43_mp_sprint");
		precacheItem("mp40_mp_sprint");
		precacheItem("mp44_mp_sprint");
		precacheItem("kar98k_sniper_mp_sprint");
		precacheItem("shotgun_mp_axis_sprint");

		// Disabled: unused weapons.
		//precacheItem("dp28_mp");
		//precacheItem("panzerfaust_mp");
		//precacheItem("panzerschreck_mp");
	}

	// Back2Uo: optional extra weapons and binoculars.
	if(game["back2uo_weaponsystem_enable"])
	{
		// Back2Uo: G43 sniper ( back2uo_g43sniper_on ).
		if(level.back2uo_g43sniper_allow)
		{
			precacheItem("g43_sniper_mp");
			precacheItem("g43_sniper_mp_sprint");
		}

		// Back2Uo: Panzerschreck ( back2uo_rocketlancher_on ).
		if(level.back2uo_rocketl_allow)
		{
			precacheItem("panzerschreck_mp");
			// Disabled: panzerfaust.
			//precacheItem("panzerfaust_mp");
		}

		// Back2Uo: binoculars ( back2uo_binocular_allow ).
		if(level.back2uo_binocular_allow) precacheItem("binoculars_mp");
	}

	// All weapons that have an allow cvar.
	level.weaponnames = [];
	level.weaponnames[0] = "greasegun_mp";
	level.weaponnames[1] = "m1carbine_mp";
	level.weaponnames[2] = "m1garand_mp";
	level.weaponnames[3] = "springfield_mp";
	level.weaponnames[4] = "thompson_mp";
	level.weaponnames[5] = "bar_mp";
	level.weaponnames[6] = "sten_mp";
	level.weaponnames[7] = "enfield_mp";
	level.weaponnames[8] = "enfield_scope_mp";
	level.weaponnames[9] = "bren_mp";
	level.weaponnames[10] = "PPS42_mp";
	level.weaponnames[11] = "mosin_nagant_mp";
	level.weaponnames[12] = "SVT40_mp";
	level.weaponnames[13] = "mosin_nagant_sniper_mp";
	level.weaponnames[14] = "ppsh_mp";
	level.weaponnames[15] = "mp40_mp";
	level.weaponnames[16] = "kar98k_mp";
	level.weaponnames[17] = "g43_mp";
	level.weaponnames[18] = "kar98k_sniper_mp";
	level.weaponnames[19] = "mp44_mp";
	level.weaponnames[20] = "shotgun_mp_allies";
	level.weaponnames[21] = "shotgun_mp_axis";
	level.weaponnames[22] = "fraggrenade";
	level.weaponnames[23] = "smokegrenade";
	level.weaponnames[24] = "colt_mp";
	level.weaponnames[25] = "webley_mp";
	level.weaponnames[26] = "luger_mp";
	level.weaponnames[27] = "TT30_mp";

	// Back2Uo: optional extra weapons use fixed indices 28 and 29.
	if(game["back2uo_weaponsystem_enable"])
	{
		// Back2Uo: G43 sniper.
		if(level.back2uo_g43sniper_allow) level.weaponnames[28] = "g43_sniper_mp";

		// Back2Uo: Panzerschreck.
		if(level.back2uo_rocketl_allow)
		{
			level.weaponnames[29] = "panzerschreck_mp";
			// Disabled: panzerfaust.
			//level.weaponnames[30] = "panzerfaust_mp";
		}
	}

	// Per weapon: server cvar (scr_allow_*), client cvar (ui_allow_*, used by the weapon menu) and default.
	level.weapons = [];
	level.weapons["greasegun_mp"] = spawnstruct();
	level.weapons["greasegun_mp"].server_allowcvar = "scr_allow_greasegun";
	level.weapons["greasegun_mp"].client_allowcvar = "ui_allow_greasegun";
	level.weapons["greasegun_mp"].allow_default = 1;

	level.weapons["m1carbine_mp"] = spawnstruct();
	level.weapons["m1carbine_mp"].server_allowcvar = "scr_allow_m1carbine";
	level.weapons["m1carbine_mp"].client_allowcvar = "ui_allow_m1carbine";
	level.weapons["m1carbine_mp"].allow_default = 1;

	level.weapons["m1garand_mp"] = spawnstruct();
	level.weapons["m1garand_mp"].server_allowcvar = "scr_allow_m1garand";
	level.weapons["m1garand_mp"].client_allowcvar = "ui_allow_m1garand";
	level.weapons["m1garand_mp"].allow_default = 1;

	level.weapons["springfield_mp"] = spawnstruct();
	level.weapons["springfield_mp"].server_allowcvar = "scr_allow_springfield";
	level.weapons["springfield_mp"].client_allowcvar = "ui_allow_springfield";
	level.weapons["springfield_mp"].allow_default = 1;

	level.weapons["thompson_mp"] = spawnstruct();
	level.weapons["thompson_mp"].server_allowcvar = "scr_allow_thompson";
	level.weapons["thompson_mp"].client_allowcvar = "ui_allow_thompson";
	level.weapons["thompson_mp"].allow_default = 1;

	level.weapons["bar_mp"] = spawnstruct();
	level.weapons["bar_mp"].server_allowcvar = "scr_allow_bar";
	level.weapons["bar_mp"].client_allowcvar = "ui_allow_bar";
	level.weapons["bar_mp"].allow_default = 1;

	level.weapons["sten_mp"] = spawnstruct();
	level.weapons["sten_mp"].server_allowcvar = "scr_allow_sten";
	level.weapons["sten_mp"].client_allowcvar = "ui_allow_sten";
	level.weapons["sten_mp"].allow_default = 1;

	level.weapons["enfield_mp"] = spawnstruct();
	level.weapons["enfield_mp"].server_allowcvar = "scr_allow_enfield";
	level.weapons["enfield_mp"].client_allowcvar = "ui_allow_enfield";
	level.weapons["enfield_mp"].allow_default = 1;

	level.weapons["enfield_scope_mp"] = spawnstruct();
	level.weapons["enfield_scope_mp"].server_allowcvar = "scr_allow_enfieldsniper";
	level.weapons["enfield_scope_mp"].client_allowcvar = "ui_allow_enfieldsniper";
	level.weapons["enfield_scope_mp"].allow_default = 1;

	level.weapons["bren_mp"] = spawnstruct();
	level.weapons["bren_mp"].server_allowcvar = "scr_allow_bren";
	level.weapons["bren_mp"].client_allowcvar = "ui_allow_bren";
	level.weapons["bren_mp"].allow_default = 1;

	level.weapons["PPS42_mp"] = spawnstruct();
	level.weapons["PPS42_mp"].server_allowcvar = "scr_allow_pps42";
	level.weapons["PPS42_mp"].client_allowcvar = "ui_allow_pps42";
	level.weapons["PPS42_mp"].allow_default = 1;

	level.weapons["mosin_nagant_mp"] = spawnstruct();
	level.weapons["mosin_nagant_mp"].server_allowcvar = "scr_allow_nagant";
	level.weapons["mosin_nagant_mp"].client_allowcvar = "ui_allow_nagant";
	level.weapons["mosin_nagant_mp"].allow_default = 1;

	level.weapons["SVT40_mp"] = spawnstruct();
	level.weapons["SVT40_mp"].server_allowcvar = "scr_allow_svt40";
	level.weapons["SVT40_mp"].client_allowcvar = "ui_allow_svt40";
	level.weapons["SVT40_mp"].allow_default = 1;

	level.weapons["mosin_nagant_sniper_mp"] = spawnstruct();
	level.weapons["mosin_nagant_sniper_mp"].server_allowcvar = "scr_allow_nagantsniper";
	level.weapons["mosin_nagant_sniper_mp"].client_allowcvar = "ui_allow_nagantsniper";
	level.weapons["mosin_nagant_sniper_mp"].allow_default = 1;

	level.weapons["ppsh_mp"] = spawnstruct();
	level.weapons["ppsh_mp"].server_allowcvar = "scr_allow_ppsh";
	level.weapons["ppsh_mp"].client_allowcvar = "ui_allow_ppsh";
	level.weapons["ppsh_mp"].allow_default = 1;

	level.weapons["mp40_mp"] = spawnstruct();
	level.weapons["mp40_mp"].server_allowcvar = "scr_allow_mp40";
	level.weapons["mp40_mp"].client_allowcvar = "ui_allow_mp40";
	level.weapons["mp40_mp"].allow_default = 1;

	level.weapons["kar98k_mp"] = spawnstruct();
	level.weapons["kar98k_mp"].server_allowcvar = "scr_allow_kar98k";
	level.weapons["kar98k_mp"].client_allowcvar = "ui_allow_kar98k";
	level.weapons["kar98k_mp"].allow_default = 1;

	level.weapons["g43_mp"] = spawnstruct();
	level.weapons["g43_mp"].server_allowcvar = "scr_allow_g43";
	level.weapons["g43_mp"].client_allowcvar = "ui_allow_g43";
	level.weapons["g43_mp"].allow_default = 1;

	level.weapons["kar98k_sniper_mp"] = spawnstruct();
	level.weapons["kar98k_sniper_mp"].server_allowcvar = "scr_allow_kar98ksniper";
	level.weapons["kar98k_sniper_mp"].client_allowcvar = "ui_allow_kar98ksniper";
	level.weapons["kar98k_sniper_mp"].allow_default = 1;

	level.weapons["mp44_mp"] = spawnstruct();
	level.weapons["mp44_mp"].server_allowcvar = "scr_allow_mp44";
	level.weapons["mp44_mp"].client_allowcvar = "ui_allow_mp44";
	level.weapons["mp44_mp"].allow_default = 1;

	level.weapons["shotgun_mp_allies"] = spawnstruct();
	level.weapons["shotgun_mp_allies"].server_allowcvar = "scr_allow_shotgun_allies";
	level.weapons["shotgun_mp_allies"].client_allowcvar = "ui_allow_shotgun_allies";
	level.weapons["shotgun_mp_allies"].allow_default = 1;

	level.weapons["shotgun_mp_axis"] = spawnstruct();
	level.weapons["shotgun_mp_axis"].server_allowcvar = "scr_allow_shotgun_axis";
	level.weapons["shotgun_mp_axis"].client_allowcvar = "ui_allow_shotgun_axis";
	level.weapons["shotgun_mp_axis"].allow_default = 1;

	level.weapons["fraggrenade"] = spawnstruct();
	level.weapons["fraggrenade"].server_allowcvar = "scr_allow_fraggrenades";
	level.weapons["fraggrenade"].client_allowcvar = "ui_allow_fraggrenades";
	level.weapons["fraggrenade"].allow_default = 1;

	level.weapons["smokegrenade"] = spawnstruct();
	level.weapons["smokegrenade"].server_allowcvar = "scr_allow_smokegrenades";
	level.weapons["smokegrenade"].client_allowcvar = "ui_allow_smokegrenades";
	level.weapons["smokegrenade"].allow_default = 1;

	level.weapons["colt_mp"] = spawnstruct();
	level.weapons["colt_mp"].server_allowcvar = "scr_allow_colt";
	level.weapons["colt_mp"].client_allowcvar = "ui_allow_colt";
	level.weapons["colt_mp"].allow_default = 1;

	level.weapons["webley_mp"] = spawnstruct();
	level.weapons["webley_mp"].server_allowcvar = "scr_allow_webley";
	level.weapons["webley_mp"].client_allowcvar = "ui_allow_webley";
	level.weapons["webley_mp"].allow_default = 1;

	level.weapons["luger_mp"] = spawnstruct();
	level.weapons["luger_mp"].server_allowcvar = "scr_allow_luger";
	level.weapons["luger_mp"].client_allowcvar = "ui_allow_luger";
	level.weapons["luger_mp"].allow_default = 1;

	level.weapons["TT30_mp"] = spawnstruct();
	level.weapons["TT30_mp"].server_allowcvar = "scr_allow_TT30";
	level.weapons["TT30_mp"].client_allowcvar = "ui_allow_TT30";
	level.weapons["TT30_mp"].allow_default = 1;

	// Back2Uo: allow cvars for the optional extra weapons.
	if(game["back2uo_weaponsystem_enable"])
	{
		// Back2Uo: G43 sniper.
		if(level.back2uo_g43sniper_allow)
		{
			level.weapons["g43_sniper_mp"] = spawnstruct();
			level.weapons["g43_sniper_mp"].server_allowcvar = "scr_allow_g43sniper";
			level.weapons["g43_sniper_mp"].client_allowcvar = "ui_allow_g43sniper";
			level.weapons["g43_sniper_mp"].allow_default = 1;
		}

		// Back2Uo: Panzerschreck.
		if(level.back2uo_rocketl_allow)
		{
			level.weapons["panzerschreck_mp"] = spawnstruct();
			level.weapons["panzerschreck_mp"].server_allowcvar = "scr_allow_panzerschreck";
			level.weapons["panzerschreck_mp"].client_allowcvar = "ui_allow_panzerschreck";
			level.weapons["panzerschreck_mp"].allow_default = 1;

			// Disabled: panzerfaust.
			//level.weapons["panzerfaust_mp"] = spawnstruct();
			//level.weapons["panzerfaust_mp"].server_allowcvar = "scr_allow_panzerfaust";
			//level.weapons["panzerfaust_mp"].client_allowcvar = "ui_allow_panzerfaust";
			//level.weapons["panzerfaust_mp"].allow_default = 1;
		}
	}

	// Read each weapon's allow flag from its scr_allow_* cvar; an unset cvar gets the default and is written back.
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// Back2Uo: in class-limit mode the default comes from the weapon class instead of allow_default.
		if(game["back2uo_weaponsystem_enable"] && level.back2uo_weapon_limit != 0)
		{
			if(getCvar(level.weapons[weaponname].server_allowcvar) == "")
			{
				level.weapons[weaponname].allow = back2uo_weapontyp_allow(weaponname);
				setCvar(level.weapons[weaponname].server_allowcvar, level.weapons[weaponname].allow);
			}
			else
				level.weapons[weaponname].allow = getCvarInt(level.weapons[weaponname].server_allowcvar);
		}
		else
		{
			if(getCvar(level.weapons[weaponname].server_allowcvar) == "")
			{
				level.weapons[weaponname].allow = level.weapons[weaponname].allow_default;
				setCvar(level.weapons[weaponname].server_allowcvar, level.weapons[weaponname].allow);
			}
			else
				level.weapons[weaponname].allow = getCvarInt(level.weapons[weaponname].server_allowcvar);
		}
	}

	level thread deleteRestrictedWeapons();
	level thread onPlayerConnect();

	// Poll the allow cvars so admins can change them at runtime.
	for(;;)
	{
		updateAllowed();
		wait 5;
	}
}

/*
=============
back2uo_weapontyp_allow

Back2Uo: decides whether a weapon belongs to the active weapon class (level.back2uo_weapon_limit:
1 = SMG/LMG, 2 = rifles, 3 = snipers, 4 = pistols). Grenades and pistols are allowed in every class.
Rebuilds level.back2uo_weapontyp on every call.
Params: weaponname - weapon name from level.weaponnames
Returns: 1 if allowed, else 0
=============
*/
back2uo_weapontyp_allow(weaponname)
{
	level.back2uo_weapontyp = [];

	if(level.back2uo_weapon_limit == 1) // Only Mg's Weapon
	{
		// Primary Weapon
		level.back2uo_weapontyp["bar_mp"] = 1;
		level.back2uo_weapontyp["bar_mp"] = 1;
		level.back2uo_weapontyp["bren_mp"] = 1;
		level.back2uo_weapontyp["greasegun_mp"] = 1;
		level.back2uo_weapontyp["mp40_mp"] = 1;
		level.back2uo_weapontyp["mp44_mp"] = 1;
		level.back2uo_weapontyp["ppsh_mp"] = 1;
		level.back2uo_weapontyp["PPS42_mp"] = 1;
		level.back2uo_weapontyp["sten_mp"] = 1;
		level.back2uo_weapontyp["thompson_mp"] = 1;

		// Secondary Weapon
		level.back2uo_weapontyp["fraggrenade"] = 1;
		level.back2uo_weapontyp["smokegrenade"] = 1;
		level.back2uo_weapontyp["colt_mp"] = 1;
		level.back2uo_weapontyp["webley_mp"] = 1;
		level.back2uo_weapontyp["TT30_mp"] = 1;
		level.back2uo_weapontyp["luger_mp"] = 1;
	}
	else if(level.back2uo_weapon_limit == 2) // Only Rifle Weapon
	{
		// Primary Weapon
		level.back2uo_weapontyp["enfield_mp"] = 1;
		level.back2uo_weapontyp["g43_mp"] = 1;
		level.back2uo_weapontyp["kar98k_mp"] = 1;
		level.back2uo_weapontyp["m1carbine_mp"] = 1;
		level.back2uo_weapontyp["m1garand_mp"] = 1;
		level.back2uo_weapontyp["mosin_nagant_mp"] = 1;
		level.back2uo_weapontyp["SVT40_mp"] = 1;

		// Secondary Weapon
		level.back2uo_weapontyp["fraggrenade"] = 1;
		level.back2uo_weapontyp["smokegrenade"] = 1;
		level.back2uo_weapontyp["colt_mp"] = 1;
		level.back2uo_weapontyp["webley_mp"] = 1;
		level.back2uo_weapontyp["TT30_mp"] = 1;
		level.back2uo_weapontyp["luger_mp"] = 1;
	}
	else if(level.back2uo_weapon_limit == 3) // Only Sniper Weapon
	{
		// Primary Weapon
		level.back2uo_weapontyp["enfield_scope_mp"] = 1;
		level.back2uo_weapontyp["kar98k_sniper_mp"] = 1;
		level.back2uo_weapontyp["mosin_nagant_sniper_mp"] = 1;
		level.back2uo_weapontyp["springfield_mp"] = 1;
		level.back2uo_weapontyp["g43_sniper_mp"] = 1;

		// Secondary Weapon
		level.back2uo_weapontyp["fraggrenade"] = 1;
		level.back2uo_weapontyp["smokegrenade"] = 1;
		level.back2uo_weapontyp["colt_mp"] = 1;
		level.back2uo_weapontyp["webley_mp"] = 1;
		level.back2uo_weapontyp["TT30_mp"] = 1;
		level.back2uo_weapontyp["luger_mp"] = 1;
	}
	else if(level.back2uo_weapon_limit == 4) // Only Pistol Weapon
	{
		// Primary Weapon
		level.back2uo_weapontyp["colt_mp"] = 1;
		level.back2uo_weapontyp["webley_mp"] = 1;
		level.back2uo_weapontyp["TT30_mp"] = 1;
		level.back2uo_weapontyp["luger_mp"] = 1;

		// Secondary Weapon
		level.back2uo_weapontyp["fraggrenade"] = 1;
		level.back2uo_weapontyp["smokegrenade"] = 1;
	}

	if(isdefined(level.back2uo_weapontyp[weaponname]) && level.back2uo_weapontyp[weaponname] == 1) return 1;
	else return 0;
}

/*
=============
onPlayerConnect

Sends all ui_allow_* cvars to every connecting player and starts the spawn watcher.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player.usedweapons = false;

		player thread updateAllAllowedSingleClient();
		player thread onPlayerSpawned();
	}
}

/*
=============
onPlayerSpawned

Restarts the weapon usage watcher on every spawn.
Called on: player
=============
*/
onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		self thread watchWeaponUsage();
	}
}

/*
=============
deleteRestrictedWeapons

Stock: meant to delete placed map weapons that are restricted (the loop body is disabled).
Back2Uo: removes all mounted MGs (misc_turret, misc_mg42) when back2uo_turret_allow is 0.
Called on: level
=============
*/
deleteRestrictedWeapons()
{
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// Disabled: stock deletion of placed weapon entities for restricted weapons.
		//if(level.weapons[weaponname].allow != 1)
		//deletePlacedEntity(level.weapons[weaponname].radiant_name);
	}

	// Need to not automatically give these to players if I allow restricting them
	// colt_mp
	// webley_mp
	// TT30_mp
	// luger_mp
	// fraggrenade_mp
	// mk1britishfrag_mp
	// rgd-33russianfrag_mp
	// stielhandgranate_mp

	// Back2Uo: turrets not allowed, delete every mounted MG on the map.
	if(game["back2uo_weaponsystem_enable"] && !level.back2uo_turret_allow)
	{
		weapon_turret = getentarray("misc_turret","classname");

		for (t=0; t < weapon_turret.size; t++)
		{
			weapon_turret[t] delete();
		}

		weapon_mg42 = getentarray("misc_mg42","classname");

		for (t=0; t < weapon_mg42.size; t++)
		{
			weapon_mg42[t] delete();
		}
	}
}

/*
=============
givePistol

Puts the team's nation pistol into the empty secondary slot (primaryb) with max ammo,
if that pistol is allowed. Does nothing when the slot is already used.
Called on: player
=============
*/
givePistol()
{
	weapon2 = self getweaponslotweapon("primaryb");
	if(weapon2 == "none")
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
			case "american":
				pistoltype = "colt_mp";
				break;

			case "british":
				pistoltype = "webley_mp";
				break;

			default:
				assert(game["allies"] == "russian");
				pistoltype = "TT30_mp";
				break;
			}
		}
		else
		{
			assert(self.pers["team"] == "axis");
			switch(game["axis"])
			{
			default:
				assert(game["axis"] == "german");
				pistoltype = "luger_mp";
				break;
			}
		}

		self takeWeapon("colt_mp");
		self takeWeapon("webley_mp");
		self takeWeapon("TT30_mp");
		self takeWeapon("luger_mp");

		// Disabled: stock giveWeapon, replaced by setWeaponSlotWeapon below.
		//self giveWeapon(pistoltype);

		if(level.weapons[pistoltype].allow == 1)
		{
			self setWeaponSlotWeapon("primaryb", pistoltype);
			self giveMaxAmmo(pistoltype);
		}
	}
}

/*
=============
giveGrenades

Gives the frag and smoke grenades of the player's nation. The count comes either from the
primary weapon (stock) or from the Back2Uo grenade setup (back2uo_frag_use, back2uo_smoke_use).
Back2Uo: sets level.back2uo_specialgranade / level.back2uo_specialsmoke, the weapon name suffix
("_special1", "_special2" or "") of the special grenade variants, which the count helpers reuse.
Called on: player
=============
*/
giveGrenades()
{
	// Back2Uo: special frag variant ( back2uo_spezial_grenade: 1 = cookable | 2 = cookable + 85% throw range ).
	if(game["back2uo_specialgrenade_enable"])
	{
		level.back2uo_specialgranade = "_special" + game["back2uo_specialgrenade_enable"];
	}
	else
	{
		level.back2uo_specialgranade = "";
	}

	// Back2Uo: special smoke variant ( back2uo_spezial_smoke: 1 = 85% throw range ).
	if(game["back2uo_specialsmoke_enable"])
	{
		level.back2uo_specialsmoke = "_special" + game["back2uo_specialsmoke_enable"];
	}
	else
	{
		level.back2uo_specialsmoke = "";
	}

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			grenadetype = "frag_grenade_american_mp" + level.back2uo_specialgranade;
			smokegrenadetype = "smoke_grenade_american_mp" + level.back2uo_specialsmoke;
			break;

		case "british":
			grenadetype = "frag_grenade_british_mp" + level.back2uo_specialgranade;
			smokegrenadetype = "smoke_grenade_british_mp" + level.back2uo_specialsmoke;
			break;

		default:
			assert(game["allies"] == "russian");
			grenadetype = "frag_grenade_russian_mp" + level.back2uo_specialgranade;
			smokegrenadetype = "smoke_grenade_russian_mp" + level.back2uo_specialsmoke;
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			grenadetype = "frag_grenade_german_mp" + level.back2uo_specialgranade;
			smokegrenadetype = "smoke_grenade_german_mp" + level.back2uo_specialsmoke;
			break;
		}
	}

	// Remove grenades of every nation before handing out the new ones.
	self takeWeapon("frag_grenade_american_mp" + level.back2uo_specialgranade);
	self takeWeapon("frag_grenade_british_mp" + level.back2uo_specialgranade);
	self takeWeapon("frag_grenade_russian_mp" + level.back2uo_specialgranade);
	self takeWeapon("frag_grenade_german_mp" + level.back2uo_specialgranade);
	self takeWeapon("smoke_grenade_american_mp" + level.back2uo_specialsmoke);
	self takeWeapon("smoke_grenade_british_mp" + level.back2uo_specialsmoke);
	self takeWeapon("smoke_grenade_russian_mp" + level.back2uo_specialsmoke);
	self takeWeapon("smoke_grenade_german_mp" + level.back2uo_specialsmoke);

	if(getcvarint("scr_allow_fraggrenades"))
	{
		// Back2Uo: fixed frag count from the grenade setup instead of the per-weapon stock count.
		if(game["back2uo_weaponsystem_enable"] && level.back2uo_smoke_grana_aktiv)
		{
			fraggrenadecount = level.back2uo_granaten_use;
		}
		else
		{
			fraggrenadecount = getWeaponBasedGrenadeCount(self.pers["weapon"]);
		}

		if(fraggrenadecount)
		{
			self giveWeapon(grenadetype);
			self setWeaponClipAmmo(grenadetype, fraggrenadecount);
		}
	}

	if(getcvarint("scr_allow_smokegrenades"))
	{
		// Back2Uo: fixed smoke count from the grenade setup instead of the per-weapon stock count.
		if(game["back2uo_weaponsystem_enable"] && level.back2uo_smoke_grana_aktiv)
		{
			smokegrenadecount = level.back2uo_smoke_use;
		}
		else
		{
			smokegrenadecount = getWeaponBasedSmokeGrenadeCount(self.pers["weapon"]);
		}

		if(smokegrenadecount)
		{
			self giveWeapon(smokegrenadetype);
			self setWeaponClipAmmo(smokegrenadetype, smokegrenadecount);
		}
	}

	self switchtooffhand(grenadetype);
}

/*
=============
giveBinoculars

Only takes the binoculars away; nothing here gives them to the player.
Called on: player
=============
*/
giveBinoculars()
{
	self takeWeapon("binoculars_mp");
}

/*
=============
dropWeapon

Drops the player's current (or the given) weapon if it still has ammo.
Back2Uo: with the sprint system on, the weapon is not dropped by the engine; instead a script_model
is placed on the ground and _back2uo_weaponsystem.gsc handles pickup and cleanup.
Called on: player
Params: current - optional weapon name, defaults to the current weapon
=============
*/
dropWeapon(current)
{
	// Back2Uo: end an active sprint first so the real weapon, not the _sprint variant, is dropped.
	if(game["back2uo_enable"] && !isdefined(self.pers["bots_nosprint"]))
	{
		// pers["sprinting"] only exists while the sprint system is on (back2uo_sprint_aktiv)
		if(isdefined(self.pers["sprinting"]) && self.pers["sprinting"] == true)
		{
			back2uo\_back2uo_sprint::back2uo_sprintsystem_stop();
		}
	}

	if(!isdefined(current)) current = self getcurrentweapon();

	// Back2Uo: drop as a script_model pickup instead of the engine dropItem.
	if(game["back2uo_enable"] && game["back2uo_sprint_enable"])
	{
		weapon_xmodel = "";

		// World model of the dropped weapon; weapons not listed here are not dropped.
		switch(current)
		{
		// Pistols
		case "colt_mp":
			weapon_xmodel = "xmodel/weapon_colt45";
			break;

		case "webley_mp":
			weapon_xmodel = "xmodel/weapon_webley";
			break;

		case "TT30_mp":
			weapon_xmodel = "xmodel/weapon_tt30";
			break;

		case "luger_mp":
			weapon_xmodel = "xmodel/weapon_luger";
			break;

		// SMG / LMG (plus SVT40 and G43)
		case "greasegun_mp":
			weapon_xmodel = "xmodel/weapon_greasegun";
			break;

		case "bar_mp":
			weapon_xmodel = "xmodel/weapon_bar";
			break;

		case "thompson_mp":
			weapon_xmodel = "xmodel/weapon_thompson";
			break;

		case "sten_mp":
			weapon_xmodel = "xmodel/weapon_sten";
			break;

		case "bren_mp":
			weapon_xmodel = "xmodel/weapon_bren";
			break;

		case "SVT40_mp":
			weapon_xmodel = "xmodel/weapon_svt40";
			break;

		case "PPS42_mp":
			weapon_xmodel = "xmodel/weapon_pps43";
			break;

		case "ppsh_mp":
			weapon_xmodel = "xmodel/weapon_ppsh";
			break;

		case "g43_mp":
			weapon_xmodel = "xmodel/weapon_g43";
			break;

		case "mp40_mp":
			weapon_xmodel = "xmodel/weapon_mp40";
			break;

		case "mp44_mp":
			weapon_xmodel = "xmodel/weapon_mp44";
			break;

		// Rifle
		case "m1carbine_mp":
			weapon_xmodel = "xmodel/weapon_m1carbine";
			break;

		case "m1garand_mp":
			weapon_xmodel = "xmodel/weapon_m1garand";
			break;

		case "enfield_mp":
			weapon_xmodel = "xmodel/weapon_enfield";
			break;

		case "mosin_nagant_mp":
			weapon_xmodel = "xmodel/weapon_mosinnagant";
			break;

		case "kar98k_mp":
			weapon_xmodel = "xmodel/weapon_kar98";
			break;

		// Sniper
		case "springfield_mp":
			weapon_xmodel = "xmodel/weapon_springfield";
			break;

		case "enfield_scope_mp":
			weapon_xmodel = "xmodel/weapon_enfield_scope";
			break;

		case "mosin_nagant_sniper_mp":
			weapon_xmodel = "xmodel/weapon_mosinnagantscoped_cloth";
			break;

		case "kar98k_sniper_mp":
			weapon_xmodel = "xmodel/weapon_kar98_scoped";
			break;

		case "g43_sniper_mp":
			weapon_xmodel = "xmodel/weapon_g43_scoped";
			break;

		// Extra
		case "shotgun_mp_axis":
			weapon_xmodel = "xmodel/weapon_trenchgun";
			break;

		case "shotgun_mp_allies":
			weapon_xmodel = "xmodel/weapon_trenchgun";
			break;

		case "panzerschreck_mp":
			weapon_xmodel = "xmodel/weapon_panzerschreck";
			break;

			// Disabled: panzerfaust.
			//case "panzerfaust_mp":
			//weapon_xmodel = "xmodel/weapon_panzerfaust";
			//break;
		}

		if(weapon_xmodel == "") return;

		if(current != "none")
		{
			weapon1 = self getweaponslotweapon("primary");
			weapon2 = self getweaponslotweapon("primaryb");

			if(current == weapon1)
			{
				currentslot = "primary";
				// Back2Uo: slot ammo stored in self.pers, passed on to the pickup logic.
				slotmaxammo = self.pers["back2uo_weaponspawn_prislotammo"];
			}
			else
			{
				assert(current == weapon2);
				currentslot = "primaryb";
				slotmaxammo = self.pers["back2uo_weaponspawn_pribslotammo"];
			}

			clipsize = self getweaponslotclipammo(currentslot);
			reservesize = self getweaponslotammo(currentslot);

			if(clipsize || reservesize)
			{
				// Find the ground: trace down from a random point up to 30 units beside the player, 50 units up.
				trace_posi = self.origin + (randomint(30), randomint(30), 50);
				trace_endposi = trace_posi + (0, 0, -1000);
				trace = bulletTrace(trace_posi, trace_endposi, false, undefined);

				// Spawn hidden, move to the ground point, then show.
				weapon_model = spawn("script_model", (0,0,0));
				weapon_model setModel(weapon_xmodel);
				weapon_model.targetname = "weapon_pickup";
				weapon_model hide();
				weapon_model.origin = trace["position"];
				weapon_model.angles = (0, randomint(360), 90);
				weapon_model show();

				// Back2Uo: pickup logic and timed removal of the dropped model.
				thread back2uo\_back2uo_weaponsystem::back2uo_weaponpickup(current, clipsize, reservesize, weapon_model, weapon_model.origin, slotmaxammo, currentslot);
				weapon_model thread back2uo\_back2uo_weaponsystem::back2uo_weaponclear();
			}
		}
	}
	else
	{
		// Stock: engine drop.
		if(current != "none")
		{
			weapon1 = self getweaponslotweapon("primary");
			weapon2 = self getweaponslotweapon("primaryb");

			if(current == weapon1)
			{
				currentslot = "primary";
			}
			else
			{
				assert(current == weapon2);
				currentslot = "primaryb";
			}

			clipsize = self getweaponslotclipammo(currentslot);
			reservesize = self getweaponslotammo(currentslot);

			if(clipsize || reservesize)
				self dropItem(current);
		}
	}
}

/*
=============
dropOffhand

Drops the player's current offhand grenade if it has ammo.
Back2Uo: places a script_model on the ground instead; objects\_back2uo_grenadepickup.gsc handles pickup and cleanup.
Called on: player
=============
*/
dropOffhand()
{
	current = self getcurrentoffhand();

	// Back2Uo: drop as a script_model pickup instead of the engine dropItem.
	if(game["back2uo_enable"])
	{
		grenade_xmodel = "";
		team = "";
		name = &"WEAPON_M2FRAGGRENADE";

		// World model, owning team and display name per grenade (stock and special variants).
		switch(current)
		{
		case "frag_grenade_american_mp":
		case "frag_grenade_american_mp_special1":
		case "frag_grenade_american_mp_special2":
			grenade_xmodel = "xmodel/weapon_mk2fraggrenade";
			team = "allies";
			name = &"WEAPON_M2FRAGGRENADE";
			break;

		case "frag_grenade_british_mp":
		case "frag_grenade_british_mp_special1":
		case "frag_grenade_british_mp_special2":
			grenade_xmodel = "xmodel/weapon_mk1grenade";
			team = "allies";
			name = &"WEAPON_MK1_FRAG_GRENADE";
			break;

		case "frag_grenade_russian_mp":
		case "frag_grenade_russian_mp_special1":
		case "frag_grenade_russian_mp_special2":
			grenade_xmodel = "xmodel/weapon_russian_handgrenade";
			team = "allies";
			name = &"WEAPON_RUSSIANGRENADE";
			break;

		case "frag_grenade_german_mp":
		case "frag_grenade_german_mp_special1":
		case "frag_grenade_german_mp_special2":
			grenade_xmodel = "xmodel/weapon_nebelhandgrenate";
			team = "axis";
			name = &"WEAPON_GERMANGRENADE";
			break;

		case "smoke_grenade_american_mp":
		case "smoke_grenade_american_mp_special1":
			grenade_xmodel = "xmodel/weapon_us_smoke_grenade";
			team = "allies";
			name = &"WEAPON_ANM8_SMOKE_GRENADE";
			break;

		case "smoke_grenade_british_mp":
		case "smoke_grenade_british_mp_special1":
			grenade_xmodel = "xmodel/weapon_us_smoke_grenade";
			team = "allies";
			name = &"WEAPON_NO77_WP_SMOKE_GRENADE";
			break;

		case "smoke_grenade_russian_mp":
		case "smoke_grenade_russian_mp_special1":
			grenade_xmodel = "xmodel/weapon_us_smoke_grenade";
			team = "allies";
			name = &"WEAPON_RGD1_SMOKE_GRENADE";
			break;

		case "smoke_grenade_german_mp":
		case "smoke_grenade_german_mp_special1":
			grenade_xmodel = "xmodel/weapon_us_smoke_grenade";
			team = "axis";
			name = &"WEAPON_NEBELHANDGRANATE";
			break;
		}

		if(grenade_xmodel == "" || team == "") return;

		if(current != "none")
		{
			ammosize = self getammocount(current);

			if(ammosize)
			{
				// Find the ground: trace down from a random point up to 30 units beside the player, 50 units up.
				trace_posi = self.origin + (randomint(30), randomint(30), 50);
				trace_endposi = trace_posi + (0, 0, -1000);
				trace = bulletTrace(trace_posi, trace_endposi, false, undefined);

				// Spawn hidden, move to the ground point, then show.
				grenade_model = spawn("script_model", (0,0,0));
				grenade_model setModel(grenade_xmodel);
				grenade_model.targetname = "grenade_pickup";
				grenade_model hide();
				grenade_model.origin = trace["position"];
				grenade_model.angles = (0, randomint(360), 90);
				grenade_model show();

				// Back2Uo: pickup logic and timed removal of the dropped model.
				thread back2uo\objects\_back2uo_grenadepickup::back2uo_grenadepickup(current, grenade_model, grenade_model.origin, team, name);
				grenade_model thread back2uo\objects\_back2uo_grenadepickup::back2uo_grenadepickup_clear();
			}
		}
	}
	else
	{
		// Stock: engine drop.
		if(current != "none")
		{
			ammosize = self getammocount(current);

			if(ammosize)
				self dropItem(current);
		}
	}
}

/*
=============
getWeaponBasedGrenadeCount

Stock frag grenade count per primary weapon: bolt-action and snipers 3,
semi-auto and LMG 2, everything else 1.
Params: weapon - primary weapon name
Returns: number of frag grenades
=============
*/
getWeaponBasedGrenadeCount(weapon)
{
	switch(weapon)
	{
	case "springfield_mp":
	case "enfield_scope_mp":
	case "mosin_nagant_sniper_mp":
	case "kar98k_sniper_mp":
	case "enfield_mp":
	case "mosin_nagant_mp":
	case "kar98k_mp":
		return 3;
	case "m1carbine_mp":
	case "m1garand_mp":
	case "SVT40_mp":
	case "g43_mp":
	case "bar_mp":
	case "bren_mp":
	case "mp44_mp":
		return 2;
	default:
	case "thompson_mp":
	case "sten_mp":
	case "ppsh_mp":
	case "mp40_mp":
	case "PPS42_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":
	case "greasegun_mp":

	case "g43_sniper_mp":
	case "panzerschreck_mp":
		// Disabled: panzerfaust.
		//case "panzerfaust_mp":

	case "colt_mp":
	case "webley_mp":
	// Note: lowercase, never matches "TT30_mp" (it still gets 1 via default).
	case "tt30_mp":
	case "luger_mp":

		return 1;
	}
}

/*
=============
getWeaponBasedSmokeGrenadeCount

Stock smoke grenade count per primary weapon: SMGs and shotguns 1, everything else 0.
Params: weapon - primary weapon name
Returns: number of smoke grenades
=============
*/
getWeaponBasedSmokeGrenadeCount(weapon)
{
	switch(weapon)
	{
	case "thompson_mp":
	case "sten_mp":
	case "ppsh_mp":
	case "mp40_mp":
	case "PPS42_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":
	case "greasegun_mp":
		return 1;
	case "m1carbine_mp":
	case "m1garand_mp":
	case "enfield_mp":
	case "mosin_nagant_mp":
	case "SVT40_mp":
	case "kar98k_mp":
	case "g43_mp":
	case "bar_mp":
	case "bren_mp":
	case "mp44_mp":
	case "springfield_mp":
	case "enfield_scope_mp":
	case "mosin_nagant_sniper_mp":
	case "kar98k_sniper_mp":

	case "g43_sniper_mp":
	case "panzerschreck_mp":
		// Disabled: panzerfaust.
		//case "panzerfaust_mp":

	default:
		return 0;
	}
}

/*
=============
getFragGrenadeCount

Returns how many frag grenades the player carries.
Back2Uo: with the grenade setup on, counts the special variant of the given team's nation
(so picked-up enemy grenades can be counted too).
Called on: player
Params: team - optional, "allies" or "axis"; defaults to the player's team
Returns: grenade ammo count
=============
*/
getFragGrenadeCount(team)
{
	// Back2Uo: count the active special variant of the given team's nation.
	if(game["back2uo_enable"] && level.back2uo_smoke_grana_aktiv == 1)
	{
		if(!isdefined(team)) team = self.pers["team"];

		count = 0;

		if(team == "allies")
		{
			grenadetype = "frag_grenade_" + game["allies"] + "_mp" + level.back2uo_specialgranade;
			count = self getammocount(grenadetype);
		}
		else
		{
			grenadetype = "frag_grenade_" + game["axis"] + "_mp" + level.back2uo_specialgranade;
			count = self getammocount(grenadetype);
		}

		return count;
	}
	else
	{
		if(self.pers["team"] == "allies")
			grenadetype = "frag_grenade_" + game["allies"] + "_mp";
		else
		{
			assert(self.pers["team"] == "axis");
			grenadetype = "frag_grenade_" + game["axis"] + "_mp";
		}

		count = self getammocount(grenadetype);
		return count;
	}
}

/*
=============
getSmokeGrenadeCount

Returns how many smoke grenades the player carries.
Back2Uo: with the grenade setup on, counts the special variant of the given team's nation.
Called on: player
Params: team - optional, "allies" or "axis"; defaults to the player's team
Returns: smoke grenade ammo count
=============
*/
getSmokeGrenadeCount(team)
{
	// Back2Uo: count the active special variant of the given team's nation.
	if(game["back2uo_enable"] && level.back2uo_smoke_grana_aktiv == 1)
	{
		if(!isdefined(team)) team = self.pers["team"];

		count = 0;

		if(team == "allies")
		{
			grenadetype = "smoke_grenade_" + game["allies"] + "_mp" + level.back2uo_specialsmoke;
			count = self getammocount(grenadetype);
		}
		else
		{
			grenadetype = "smoke_grenade_" + game["axis"] + "_mp" + level.back2uo_specialsmoke;
			count = self getammocount(grenadetype);
		}

		return count;
	}
	else
	{
		if(self.pers["team"] == "allies")
			grenadetype = "smoke_grenade_" + game["allies"] + "_mp";
		else
		{
			assert(self.pers["team"] == "axis");
			grenadetype = "smoke_grenade_" + game["axis"] + "_mp";
		}

		count = self getammocount(grenadetype);
		return count;
	}
}

/*
=============
isPistol

Params: weapon - weapon name
Returns: true for the four nation pistols
=============
*/
isPistol(weapon)
{
	switch(weapon)
	{
	case "colt_mp":
	case "webley_mp":
	case "luger_mp":
	case "TT30_mp":
		return true;
	default:
		return false;
	}
}

/*
=============
isMainWeapon

Params: weapon - weapon name
Returns: true for weapons that can be picked up as a main weapon (Back2Uo adds G43 sniper,
Panzerschreck and the pistols)
=============
*/
isMainWeapon(weapon)
{
	// Include any main weapons that can be picked up

	switch(weapon)
	{
	case "greasegun_mp":
	case "m1carbine_mp":
	case "m1garand_mp":
	case "thompson_mp":
	case "bar_mp":
	case "springfield_mp":
	case "sten_mp":
	case "enfield_mp":
	case "bren_mp":
	case "enfield_scope_mp":
	case "mosin_nagant_mp":
	case "SVT40_mp":
	case "PPS42_mp":
	case "ppsh_mp":
	case "mosin_nagant_sniper_mp":
	case "kar98k_mp":
	case "g43_mp":
	case "mp40_mp":
	case "mp44_mp":
	case "kar98k_sniper_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":

	case "g43_sniper_mp":
	case "panzerschreck_mp":
		// Disabled: panzerfaust.
		//case "panzerfaust_mp":

	case "colt_mp":
	case "webley_mp":
	// Note: lowercase, never matches "TT30_mp", so the TT30 returns false here.
	case "tt30_mp":
	case "luger_mp":

		return true;
	default:
		return false;
	}
}

/*
=============
restrictWeaponByServerCvars

Checks a weapon menu response against the scr_allow_* server cvars.
The commented iprintln lines are disabled stock "weapon is restricted" messages.
Params: response - weapon name chosen in the weapon menu
Returns: the weapon name, or "restricted" if it is not allowed or unknown
=============
*/
restrictWeaponByServerCvars(response)
{
	switch(response)
	{
	// American
	case "m1carbine_mp":
		if(!getcvarint("scr_allow_m1carbine"))
		{
			//self iprintln(&"MP_M1A1_CARBINE_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "m1garand_mp":
		if(!getcvarint("scr_allow_m1garand"))
		{
			//self iprintln(&"MP_M1_GARAND_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "thompson_mp":
		if(!getcvarint("scr_allow_thompson"))
		{
			//self iprintln(&"MP_THOMPSON_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "bar_mp":
		if(!getcvarint("scr_allow_bar"))
		{
			//self iprintln(&"MP_BAR_IS_A_RESTRICTED_WEAPON");
			response = "restricted";
		}
		break;

	case "springfield_mp":
		if(!getcvarint("scr_allow_springfield"))
		{
			//self iprintln(&"MP_SPRINGFIELD_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "greasegun_mp":
		if(!getcvarint("scr_allow_greasegun"))
		{
			//self iprintln(&"MP_GREASEGUN_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "shotgun_mp_allies":
		if(!getcvarint("scr_allow_shotgun_allies"))
		{
			//self iprintln(&"MP_SHOTGUN_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "shotgun_mp_axis":
		if(!getcvarint("scr_allow_shotgun_axis"))
		{
			//self iprintln(&"MP_SHOTGUN_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	// British
	case "enfield_mp":
		if(!getcvarint("scr_allow_enfield"))
		{
			//self iprintln(&"MP_LEEENFIELD_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "sten_mp":
		if(!getcvarint("scr_allow_sten"))
		{
			//self iprintln(&"MP_STEN_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "bren_mp":
		if(!getcvarint("scr_allow_bren"))
		{
			//self iprintln(&"MP_BREN_LMG_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "enfield_scope_mp":
		if(!getcvarint("scr_allow_enfieldsniper"))
		{
			//self iprintln(&"MP_BREN_LMG_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	// Russian
	case "mosin_nagant_mp":
		if(!getcvarint("scr_allow_nagant"))
		{
			//self iprintln(&"MP_MOSINNAGANT_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "SVT40_mp":
		if(!getcvarint("scr_allow_svt40"))
		{
			//self iprintln(&"MP_MOSINNAGANT_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "PPS42_mp":
		if(!getcvarint("scr_allow_pps42"))
		{
			//self iprintln(&"MP_PPSH_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "ppsh_mp":
		if(!getcvarint("scr_allow_ppsh"))
		{
			//self iprintln(&"MP_PPSH_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "mosin_nagant_sniper_mp":
		if(!getcvarint("scr_allow_nagantsniper"))
		{
			//self iprintln(&"MP_SCOPED_MOSINNAGANT_IS");
			response = "restricted";
		}
		break;

	// German
	case "kar98k_mp":
		if(!getcvarint("scr_allow_kar98k"))
		{
			//self iprintln(&"MP_KAR98K_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "g43_mp":
		if(!getcvarint("scr_allow_g43"))
		{
			//self iprintln(&"MP_KAR98K_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "mp40_mp":
		if(!getcvarint("scr_allow_mp40"))
		{
			//self iprintln(&"MP_MP40_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "mp44_mp":
		if(!getcvarint("scr_allow_mp44"))
		{
			//self iprintln(&"MP_MP44_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "kar98k_sniper_mp":
		if(!getcvarint("scr_allow_kar98ksniper"))
		{
			//self iprintln(&"MP_SCOPED_KAR98K_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "g43_sniper_mp":
		if(!getcvarint("scr_allow_g43sniper"))
		{
			//self iprintln(&"MP_SCOPED_G43_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

	case "panzerschreck_mp":
		if(!getcvarint("scr_allow_panzerschreck"))
		{
			//self iprintln(&"MP_PANZERSCHRECK_IS_A_RESTRICTED");
			response = "restricted";
		}
		break;

		// Disabled: panzerfaust.
		//case "panzerfaust_mp":
		//if(!getcvarint("scr_allow_panzerfaust"))
		//{
		//self iprintln(&"MP_PANZERFAUST_IS_A_RESTRICTED");
		//response = "restricted";
		//}
		//break;

	case "fraggrenade":
		if(!getcvarint("scr_allow_fraggrenades"))
		{
			//self iprintln("Frag grenades are restricted");
			response = "restricted";
		}
		break;

	case "smokegrenade":
		if(!getcvarint("scr_allow_smokegrenades"))
		{
			//self iprintln("Smoke grenades are restricted");
			response = "restricted";
		}
		break;

	case "colt_mp":
		if(!getcvarint("scr_allow_colt"))
		{
			//self iprintln("Colt.45's are restricted");
			response = "restricted";
		}
		break;

	case "webley_mp":
		if(!getcvarint("scr_allow_webley"))
		{
			//self iprintln("Webley's are restricted");
			response = "restricted";
		}
		break;

	// Note: lowercase; a "TT30_mp" response does not match and falls to default (restricted).
	case "tt30_mp":
		if(!getcvarint("scr_allow_TT30"))
		{
			//self iprintln("TT30's are restricted");
			response = "restricted";
		}
		break;

	// Note: response is never set to "restricted" here, so scr_allow_luger has no effect.
	case "luger_mp":
		if(!getcvarint("scr_allow_luger"))
		{
			//self iprintln("Luger's are restricted");
		}
		break;

	default:
		//self iprintln(&"MP_UNKNOWN_WEAPON_SELECTED");
		response = "restricted";
		break;
	}

	// Back2Uo: the response can be sent by hand (/mr), so only accept weapons that are precached.
	if(response != "restricted" && game["back2uo_weaponsystem_enable"])
	{
		// Optional extra weapons (G43 sniper, Panzerschreck) only exist when switched on.
		if(response == "g43_sniper_mp" || response == "panzerschreck_mp")
		{
			if(!isdefined(level.weapons[response])) response = "restricted";
		}

		// Class-limit mode precaches only the active class (pistols only with back2uo_pistel_allow).
		if(response != "restricted" && level.back2uo_weapon_limit != 0)
		{
			if(!back2uo_weapontyp_allow(response))
				response = "restricted";
			else if(isPistol(response) && !level.back2uo_pistel_allow && level.back2uo_weapon_limit != 4)
				response = "restricted";
		}
	}

	// Back2Uo: sniper/shotgun limit reached; players that already have this weapon keep it.
	if(response != "restricted" && back2uo_weaponlimit_full(response))
	{
		if(!isdefined(self.pers["weapon"]) || self.pers["weapon"] != response) response = "restricted";
	}

	return response;
}

/*
=============
watchWeaponUsage

Sets self.usedweapons once the player presses fire after spawning (a fire button held
at spawn is ignored until released). Restarted on every spawn.
TODO (stock): This doesn't handle offhands
Called on: player
=============
*/
watchWeaponUsage()
{
	self endon("spawned_player");
	self endon("disconnect");

	self.usedweapons = false;

	while(self attackButtonPressed())
		wait .05;

	while(!(self attackButtonPressed()))
		wait .05;

	self.usedweapons = true;
}

/*
=============
getWeaponName

Params: weapon - weapon name
Returns: localized weapon name for messages (plain strings for the pistols)
=============
*/
getWeaponName(weapon)
{
	switch(weapon)
	{
	// American
	case "m1carbine_mp":
		weaponname = &"WEAPON_M1A1CARBINE";
		break;

	case "m1garand_mp":
		weaponname = &"WEAPON_M1GARAND";
		break;

	case "thompson_mp":
		weaponname = &"WEAPON_THOMPSON";
		break;

	case "bar_mp":
		weaponname = &"WEAPON_BAR";
		break;

	case "springfield_mp":
		weaponname = &"WEAPON_SPRINGFIELD";
		break;

	case "greasegun_mp":
		weaponname = &"WEAPON_GREASEGUN";
		break;

	case "shotgun_mp_allies":
		weaponname = &"WEAPON_SHOTGUN";
		break;

	case "shotgun_mp_axis":
		weaponname = &"WEAPON_SHOTGUN";
		break;

		// Disabled: unused weapons.
		//	case "30cal_mp":
		//		weaponname = &"PI_WEAPON_MP_30CAL";
		//		break;

		//	case "M9_Bazooka":
		//		weaponname = &"PI_WEAPON_MP_BAZOOKA";
		//		break;

	// British
	case "enfield_mp":
		weaponname = &"WEAPON_LEEENFIELD";
		break;

	case "sten_mp":
		weaponname = &"WEAPON_STEN";
		break;

	case "bren_mp":
		weaponname = &"WEAPON_BREN";
		break;

	case "enfield_scope_mp":
		weaponname = &"WEAPON_SCOPEDLEEENFIELD";
		break;

	// Russian
	case "mosin_nagant_mp":
		weaponname = &"WEAPON_MOSINNAGANT";
		break;

	case "SVT40_mp":
		weaponname = &"WEAPON_SVT40";
		break;

	case "PPS42_mp":
		weaponname = &"WEAPON_PPS42";
		break;

	case "ppsh_mp":
		weaponname = &"WEAPON_PPSH";
		break;

	case "mosin_nagant_sniper_mp":
		weaponname = &"WEAPON_SCOPEDMOSINNAGANT";
		break;

	//German
	case "kar98k_mp":
		weaponname = &"WEAPON_KAR98K";
		break;

	case "g43_mp":
		weaponname = &"WEAPON_G43";
		break;

	case "mp40_mp":
		weaponname = &"WEAPON_MP40";
		break;

	case "mp44_mp":
		weaponname = &"WEAPON_MP44";
		break;

	case "kar98k_sniper_mp":
		weaponname = &"WEAPON_SCOPEDKAR98K";
		break;

	case "g43_sniper_mp":
		weaponname = &"WEAPON_SCOPEDG43";
		break;

	case "panzerschreck_mp":
		weaponname = &"WEAPON_PANZERSCHRECK";
		break;

		// Disabled: panzerfaust.
		//case "panzerfaust_mp":
		//weaponname = &"WEAPON_PANZERFAUST";
		//break;

	case "colt_mp":
		weaponname = "Colt.45";
		break;

	case "webley_mp":
		weaponname = "Webley";
		break;

	// Note: lowercase, never matches "TT30_mp".
	case "tt30_mp":
		weaponname = "TT30";
		break;

	case "luger_mp":
		weaponname = "Luger";
		break;

	default:
		weaponname = &"WEAPON_UNKNOWNWEAPON";
		break;
	}

	return weaponname;
}

/*
=============
useAn

Params: weapon - weapon name
Returns: true if the weapon name needs the article "an" instead of "a" in messages
=============
*/
useAn(weapon)
{
	switch(weapon)
	{
	case "m1carbine_mp":
	case "m1garand_mp":
	case "mp40_mp":
	case "mp44_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":

		result = true;
		break;

	default:
		result = false;
		break;
	}

	return result;
}

/*
=============
updateAllowed

Re-reads every weapon's allow cvar and pushes changed values to all clients.
Called on: level (from init every 5 seconds)
=============
*/
updateAllowed()
{
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// Back2Uo: in class-limit mode an unset cvar means "use the class default".
		if(game["back2uo_weaponsystem_enable"] && level.back2uo_weapon_limit != 0 && getCvar(level.weapons[weaponname].server_allowcvar) == "")
		{
			cvarvalue = back2uo_weapontyp_allow(weaponname);
		}
		else
		{
			cvarvalue = getCvarInt(level.weapons[weaponname].server_allowcvar);
		}

		if(level.weapons[weaponname].allow != cvarvalue)
		{
			level.weapons[weaponname].allow = cvarvalue;

			thread updateAllowedAllClients(weaponname);
		}
	}
}

/*
=============
updateAllowedAllClients

Sends one weapon's ui_allow_* cvar to every player.
Params: weaponname - weapon name from level.weaponnames
=============
*/
updateAllowedAllClients(weaponname)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] updateAllowedSingleClient(weaponname);
}

/*
=============
updateAllowedSingleClient

Sends one weapon's ui_allow_* cvar to this player.
Called on: player
Params: weaponname - weapon name from level.weaponnames
=============
*/
updateAllowedSingleClient(weaponname)
{
	allow = level.weapons[weaponname].allow;

	// Back2Uo: sniper/shotgun limit reached (_back2uo_weaponsystem::back2uo_snipershotgun_limiter).
	if(allow && back2uo_weaponlimit_full(weaponname)) allow = 0;

	self setClientCvar(level.weapons[weaponname].client_allowcvar, allow);
}

/*
=============
back2uo_weaponlimit_full

Back2Uo: true if the sniper/shotgun limit of this weapon is reached
(level.back2uo_weaponlimit_full is set by _back2uo_weaponsystem::back2uo_snipershotgun_limiter).
Params: weaponname - weapon name
=============
*/
back2uo_weaponlimit_full(weaponname)
{
	if(!isdefined(level.back2uo_weaponlimit_full) || !isdefined(level.back2uo_weaponlimit_full[weaponname])) return false;

	return level.back2uo_weaponlimit_full[weaponname];
}

/*
=============
updateAllAllowedSingleClient

Sends all ui_allow_* cvars to this player.
Called on: player
=============
*/
updateAllAllowedSingleClient()
{
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];
		self updateAllowedSingleClient(weaponname);
	}
}
