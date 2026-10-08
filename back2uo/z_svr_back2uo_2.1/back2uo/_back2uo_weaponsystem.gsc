/*
	Back2Uo v2.1 - weapon system

	Weapon availability (scr_allow_* cvars), per-weapon damage scaling
	(level.back2uo_weaponstrength[], read by the gametype damage callbacks), hit
	location / distance messages, unlimited pistol ammo, sniper/shotgun count limits,
	the dropped-weapon pickup system (use key, ammo top-up, HUD icon) and the turret
	proximity check used to block sprinting near MGs.
	Started from _back2uo_player.gsc, maps\mp\gametypes\_weapons.gsc and the gametype
	Callback_PlayerKilled hooks.
*/

/*
=============
back2uo_weapon_limitiert

Writes the scr_allow_* cvars (and marks them serverinfo) for pistols, shotguns,
Panzerschreck, scoped G43 and binoculars from the mod's allow settings.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_weapon_limitiert()
{
	if(!game["back2uo_weaponsystem_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Limit", "Run");

	// Pistols
	if(level.back2uo_pistel_allow)
	{
		setCvar("scr_allow_colt", "1");
		makeCvarServerInfo("scr_allow_colt", "1");
		setCvar("scr_allow_webley", "1");
		makeCvarServerInfo("scr_allow_webley", "1");
		setCvar("scr_allow_luger", "1");
		makeCvarServerInfo("scr_allow_luger", "1");
		setCvar("scr_allow_TT30", "1");
		makeCvarServerInfo("scr_allow_TT30", "1");
	}
	else
	{
		setCvar("scr_allow_colt", "0");
		makeCvarServerInfo("scr_allow_colt", "0");
		setCvar("scr_allow_webley", "0");
		makeCvarServerInfo("scr_allow_webley", "0");
		setCvar("scr_allow_luger", "0");
		makeCvarServerInfo("scr_allow_luger", "0");
		setCvar("scr_allow_TT30", "0");
		makeCvarServerInfo("scr_allow_TT30", "0");
	}

	// Shotguns (both teams)
	if(level.back2uo_shotgunteam_allow)
	{
		setCvar("scr_allow_shotgun_axis", "1");
		makeCvarServerInfo("scr_allow_shotgun_axis", "1");
		setCvar("scr_allow_shotgun_allies", "1");
		makeCvarServerInfo("scr_allow_shotgun_allies", "1");
	}
	else
	{
		setCvar("scr_allow_shotgun_axis", "0");
		makeCvarServerInfo("scr_allow_shotgun_axis", "0");
		setCvar("scr_allow_shotgun_allies", "0");
		makeCvarServerInfo("scr_allow_shotgun_allies", "0");
	}

	// Rocket launcher
	if(level.back2uo_rocketl_allow)
	{
		setCvar("scr_allow_panzerschreck", "1");
		makeCvarServerInfo("scr_allow_panzerschreck", "1");

		// Disabled: Panzerfaust is not used by the mod.
		//setCvar("scr_allow_panzerfaust", "1");
		//makeCvarServerInfo("scr_allow_panzerfaust", "1");
	}
	else
	{
		setCvar("scr_allow_panzerschreck", "0");
		makeCvarServerInfo("scr_allow_panzerschreck", "0");

		// Disabled: Panzerfaust is not used by the mod.
		//setCvar("scr_allow_panzerfaust", "0");
		//makeCvarServerInfo("scr_allow_panzerfaust", "0");
	}

	// Scoped G43
	if(level.back2uo_g43sniper_allow)
	{
		setCvar("scr_allow_g43sniper", "1");
		makeCvarServerInfo("scr_allow_g43sniper", "1");
	}
	else
	{
		setCvar("scr_allow_g43sniper", "0");
		makeCvarServerInfo("scr_allow_g43sniper", "0");
	}

	// Binoculars
	if(level.back2uo_binocular_allow)
	{
		setCvar("scr_allow_binocular", "1");
		makeCvarServerInfo("scr_allow_binocular", "1");
	}
	else
	{
		setCvar("scr_allow_binocular", "0");
		makeCvarServerInfo("scr_allow_binocular", "0");
	}
}

/*
=============
back2uo_weapon_optimizer

Reads the per-weapon damage cvars (back2uo_weaponstr_*, percent 1-100, default 100)
into level.back2uo_weaponstrength[weaponname]. The gametype damage callbacks multiply
damage by value / 100. Also reads level.back2uo_melee_strength.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_weapon_optimizer()
{
	if(!game["back2uo_weaponsystem_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Optimize", "Run");

	// Melee damage scale in percent.
	level.back2uo_melee_strength = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_melee_strength", 100, 1, 100, "int");

	level.back2uo_weaponstrength = [];

	// Mounted MGs: all stances share one value.
	level.back2uo_weaponstrength["mg42_bipod_stand_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mg42", 100, 1, 100, "int");
	level.back2uo_weaponstrength["mg42_bipod_duck_mp"] = level.back2uo_weaponstrength["mg42_bipod_stand_mp"];
	level.back2uo_weaponstrength["mg42_bipod_prone_mp"] = level.back2uo_weaponstrength["mg42_bipod_stand_mp"];
	level.back2uo_weaponstrength["30cal_stand_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mg30cal", 100, 1, 100, "int");
	level.back2uo_weaponstrength["30cal_duck_mp"] = level.back2uo_weaponstrength["30cal_stand_mp"];
	level.back2uo_weaponstrength["30cal_prone_mp"] = level.back2uo_weaponstrength["30cal_stand_mp"];

	// Frag grenades
	level.back2uo_weaponstrength["frag_grenade_american_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_frag_american", 100, 1, 100, "int");
	level.back2uo_weaponstrength["frag_grenade_british_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_frag_british", 100, 1, 100, "int");
	level.back2uo_weaponstrength["frag_grenade_german_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_frag_german", 100, 1, 100, "int");
	level.back2uo_weaponstrength["frag_grenade_russian_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_frag_russian", 100, 1, 100, "int");

	// Back2Uo: the special frag grenade variants (_special1 / _special2) use the same cvars as the normal ones.
	level.back2uo_weaponstrength["frag_grenade_american_mp_special1"] = level.back2uo_weaponstrength["frag_grenade_american_mp"];
	level.back2uo_weaponstrength["frag_grenade_american_mp_special2"] = level.back2uo_weaponstrength["frag_grenade_american_mp"];
	level.back2uo_weaponstrength["frag_grenade_british_mp_special1"] = level.back2uo_weaponstrength["frag_grenade_british_mp"];
	level.back2uo_weaponstrength["frag_grenade_british_mp_special2"] = level.back2uo_weaponstrength["frag_grenade_british_mp"];
	level.back2uo_weaponstrength["frag_grenade_german_mp_special1"] = level.back2uo_weaponstrength["frag_grenade_german_mp"];
	level.back2uo_weaponstrength["frag_grenade_german_mp_special2"] = level.back2uo_weaponstrength["frag_grenade_german_mp"];
	level.back2uo_weaponstrength["frag_grenade_russian_mp_special1"] = level.back2uo_weaponstrength["frag_grenade_russian_mp"];
	level.back2uo_weaponstrength["frag_grenade_russian_mp_special2"] = level.back2uo_weaponstrength["frag_grenade_russian_mp"];

	// Pistols
	level.back2uo_weaponstrength["colt_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_colt", 100, 1, 100, "int");
	level.back2uo_weaponstrength["webley_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_webley", 100, 1, 100, "int");
	level.back2uo_weaponstrength["TT30_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_TT30", 100, 1, 100, "int");
	level.back2uo_weaponstrength["luger_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_luger", 100, 1, 100, "int");

	// Special weapons
	level.back2uo_weaponstrength["g43_sniper_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_g43scoped", 100, 1, 100, "int");
	// Back2Uo: key is the real weapon name (was "rocketlancher_mp").
	level.back2uo_weaponstrength["panzerschreck_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_rocketlancher", 100, 1, 100, "int");

	// Weapons shared by several nations
	level.back2uo_weaponstrength["shotgun_mp_allies"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_shotgun_allies", 100, 1, 100, "int");
	level.back2uo_weaponstrength["shotgun_mp_axis"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_shotgun_axis", 100, 1, 100, "int");
	level.back2uo_weaponstrength["thompson_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_thompson", 100, 1, 100, "int");
	level.back2uo_weaponstrength["m1garand_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_m1garand", 100, 1, 100, "int");

	// German weapons
	level.back2uo_weaponstrength["mp40_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mp40", 100, 1, 100, "int");
	level.back2uo_weaponstrength["kar98k_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_kar98k", 100, 1, 100, "int");
	level.back2uo_weaponstrength["g43_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_g43", 100, 1, 100, "int");
	level.back2uo_weaponstrength["kar98k_sniper_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_kar98k_sniper", 100, 1, 100, "int");
	level.back2uo_weaponstrength["mp44_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mp44", 100, 1, 100, "int");

	// American weapons
	level.back2uo_weaponstrength["greasegun_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_greasegun", 100, 1, 100, "int");
	level.back2uo_weaponstrength["m1carbine_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_m1carbine", 100, 1, 100, "int");
	level.back2uo_weaponstrength["springfield_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_springfield", 100, 1, 100, "int");
	level.back2uo_weaponstrength["bar_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_bar", 100, 1, 100, "int");

	// British weapons
	level.back2uo_weaponstrength["sten_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_sten", 100, 1, 100, "int");
	level.back2uo_weaponstrength["enfield_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_enfield", 100, 1, 100, "int");
	level.back2uo_weaponstrength["enfield_scope_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_enfield_sniper", 100, 1, 100, "int");
	level.back2uo_weaponstrength["bren_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_bren", 100, 1, 100, "int");

	// Russian weapons
	level.back2uo_weaponstrength["PPS42_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_pps42", 100, 1, 100, "int");
	level.back2uo_weaponstrength["mosin_nagant_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mosin_nagant", 100, 1, 100, "int");
	level.back2uo_weaponstrength["SVT40_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_svt40", 100, 1, 100, "int");
	level.back2uo_weaponstrength["mosin_nagant_sniper_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_mosin_nagant_sniper", 100, 1, 100, "int");
	level.back2uo_weaponstrength["ppsh_mp"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_weaponstr_ppsh", 100, 1, 100, "int");
}

/*
=============
back2uo_hit_distance

Tells the attacker where the victim was hit and from how far (in meters). Melee hits
show only the hit location; explosive kills and self kills show nothing.
Called on: victim player (from the gametype Callback_PlayerKilled hooks)
Params: attacker - killing entity
		sMeansOfDeath - MOD_* string
		sWeapon - weapon name
		sHitLoc - hit location name
=============
*/
back2uo_hit_distance(attacker, sMeansOfDeath, sWeapon, sHitLoc)
{
	if(!game["back2uo_hit_distance_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hit Distance", "Run");

	if(isplayer(attacker) && attacker != self && sMeansOfDeath != "MOD_EXPLOSIVE")
	{
		// Disabled: skipped the message for grenade and Panzerschreck kills.
		//if(sWeapon == "frag_grenade_american_mp" || sWeapon == "frag_grenade_german_mp" || sWeapon == "frag_grenade_british_mp" || sWeapon == "frag_grenade_russian_mp") return;
		//if(sWeapon == "frag_grenade_american_mp_special1" || sWeapon == "frag_grenade_german_mp_special1" || sWeapon == "frag_grenade_british_mp_special1" || sWeapon == "frag_grenade_russian_mp_special1") return;
		//if(sWeapon == "frag_grenade_american_mp_special2" || sWeapon == "frag_grenade_german_mp_special2" || sWeapon == "frag_grenade_british_mp_special2" || sWeapon == "frag_grenade_russian_mp_special2") return;
		//if(sWeapon == "panzerschreck_mp") return;

		// Map the hit location to a localized name; "none" (e.g. splash damage) gives distance only.
		hitposi = &"none";

		// Head area
		if(sHitLoc == "helmet") hitposi = &"BACK2UOMOD_HIT_HELMET";
		if(sHitLoc == "head") hitposi = &"BACK2UOMOD_HIT_HEAD";
		if(sHitLoc == "neck") hitposi = &"BACK2UOMOD_HIT_NECK";

		// Torso
		if(sHitLoc == "torso_upper") hitposi = &"BACK2UOMOD_HIT_TORSO_UPPER";
		if(sHitLoc == "torso_lower") hitposi = &"BACK2UOMOD_HIT_TORSO_LOWER";

		// Left arm
		if(sHitLoc == "left_arm_upper") hitposi = &"BACK2UOMOD_HIT_LEFT_ARM_UPPER";
		if(sHitLoc == "left_arm_lower") hitposi = &"BACK2UOMOD_HIT_LEFT_ARM_LOWER";

		// Right arm
		if(sHitLoc == "right_arm_upper") hitposi = &"BACK2UOMOD_HIT_RIGHT_ARM_UPPER";
		if(sHitLoc == "right_arm_lower") hitposi = &"BACK2UOMOD_HIT_RIGHT_ARM_LOWER";

		// Hands
		if(sHitLoc == "left_hand") hitposi = &"BACK2UOMOD_HIT_LEFT_HAND";
		if(sHitLoc == "right_hand") hitposi = &"BACK2UOMOD_HIT_RIGHT_HAND";

		// Left leg
		if(sHitLoc == "left_leg_upper") hitposi = &"BACK2UOMOD_HIT_LEFT_LEG_UPPER";
		if(sHitLoc == "left_leg_lower") hitposi = &"BACK2UOMOD_HIT_LEFT_LEG_LOWER";

		// Right leg
		if(sHitLoc == "right_leg_upper") hitposi = &"BACK2UOMOD_HIT_RIGHT_LEG_UPPER";
		if(sHitLoc == "right_leg_lower") hitposi = &"BACK2UOMOD_HIT_RIGHT_LEG_LOWER";

		// Feet
		if(sHitLoc == "left_foot") hitposi = &"BACK2UOMOD_HIT_LEFT_FOOT";
		if(sHitLoc == "right_foot") hitposi = &"BACK2UOMOD_HIT_RIGHT_FOOT";

		// Game units are inches: * 2.5 (approx. cm per inch) / 100 gives meters.
		distance = distance(attacker.origin , self.origin);
		distance_mr = int(int(distance * 2.5) / 100);

		if(hitposi != &"none")
		{
			if(sMeansOfDeath != "MOD_MELEE")
			{
				attacker iprintln("^7( ^3", distance_mr, &"BACK2UOMOD_HIT_METER", hitposi, " ^7)");
			}
			else
			{
				attacker iprintln("^7( ^3", hitposi, " ^7)");
			}
		}
		else
		{
			attacker iprintln("^7( ^3", distance_mr, &"BACK2UOMOD_HIT_METER2", " ^7)");
		}
	}

	// Debug log for missing callback arguments.
	if(!isdefined(attacker) || !isdefined(sMeansOfDeath) || !isdefined(sWeapon) || !isdefined(sHitLoc))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("Hit Distance", "isdefined Error");
	}
}

/*
=============
back2uo_pistel_unlimtedammo

In pistol-only mode (back2uo_weapons_allow 4) with back2uo_pistolonly_unammo on, records
the spawn reserve ammo of both weapon slots and starts a refill thread for each.
Called on: player (at spawn, from _back2uo_player.gsc)
=============
*/
back2uo_pistel_unlimtedammo()
{
	if(level.back2uo_weapon_limit != 4) return;

	if(level.back2uo_pistel_unammo == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Pistel Unlimited Ammo", "Run");

	self.pers["pri_pistel_ammo_pri"] = self getweaponslotammo("primary");

	thread back2uo_pistel_ammo_slot("primary", self.pers["pri_pistel_ammo_pri"]);

	self.pers["pri_pistel_ammo_prib"] = self getweaponslotammo("primaryb");

	thread back2uo_pistel_ammo_slot("primaryb", self.pers["pri_pistel_ammo_prib"]);
}

/*
=============
back2uo_pistel_ammo_slot

Keeps the reserve ammo of a weapon slot at least at the given value, checked every
0.1 seconds until the player dies or disconnects.
Called on: player
Params: slot - "primary" or "primaryb"
		ammo - reserve ammo amount to maintain
=============
*/
back2uo_pistel_ammo_slot(slot, ammo)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Pistol Ammo in Slot", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		inslot_ammo = self getweaponslotammo(slot);

		if(inslot_ammo < ammo)
		{
			self setweaponslotammo(slot, ammo);
		}

		wait 0.1;
	}
}

/*
=============
back2uo_snipershotgun_limiter

With back2uo_weaponlimit_enable on, polls every 0.1 seconds how many players carry each
sniper rifle / shotgun and toggles the matching scr_allow_* and ui_allow_* cvars when a
limit (level.back2uo_*_limit) is exceeded or freed again. With the limit off, all of
these weapons are allowed once.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_snipershotgun_limiter()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Sniper & Shotgun Limit", "Run");

	level endon("back2uo_killthreads");

	// Current counts and allow state (1 = allowed) per limited weapon.
	level.weapon_enfieldsniper_count = 0;
	level.weapon_enfieldsniper_allow = 1;
	level.weapon_nagantsniper_count = 0;
	level.weapon_nagantsniper_allow = 1;
	level.weapon_springfield_count = 0;
	level.weapon_springfield_allow = 1;
	level.weapon_kar98ksniper_count = 0;
	level.weapon_kar98ksniper_allow = 1;
	level.weapon_shotgun_allies_count = 0;
	level.weapon_shotgun_allies_allow = 1;
	level.weapon_shotgun_axis_count = 0;
	level.weapon_shotgun_axis_allow = 1;

	if(game["back2uo_weaponlimit_enable"])
	{
		for(;;)
		{
			players = getentarray("player", "classname");

			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				// Note: the counters are reset for every player inside the loop, so the
				// limit checks below only ever see the current player's weapon (count 0 or 1).
				level.weapon_enfieldsniper_count = 0;
				level.weapon_nagantsniper_count = 0;
				level.weapon_springfield_count = 0;
				level.weapon_kar98ksniper_count = 0;
				level.weapon_shotgun_allies_count = 0;
				level.weapon_shotgun_axis_count = 0;

				if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
				{
					if(player.pers["team"] == "allies")
					{
						if(isdefined(player.pers["weapon"]))
						{
							switch(player.pers["weapon"])
							{
							case "springfield_mp":
								level.weapon_springfield_count++;
								break;

							case "mosin_nagant_sniper_mp":
								level.weapon_nagantsniper_count++;
								break;

							case "enfield_scope_mp":
								level.weapon_enfieldsniper_count++;
								break;

							case "shotgun_mp_allies":
								level.weapon_shotgun_allies_count++;
								break;
							}
						}
					}
					else
					{
						if(isdefined(player.pers["weapon"]))
						{
							switch(player.pers["weapon"])
							{
							case "kar98k_sniper_mp":
								level.weapon_kar98ksniper_count++;
								break;

							case "shotgun_mp_axis":
								level.weapon_shotgun_axis_count++;
								break;
							}
						}
					}
				}

				// Each weapon: disable above the limit, re-enable below it. The *_allow flag
				// prevents setting the cvars again every tick.

				// Springfield
				if(level.weapon_springfield_count > level.back2uo_springfield_limit && level.weapon_springfield_allow != 0)
				{
					setcvar("scr_allow_springfield", "0");
					setcvar("ui_allow_springfield", "0");
					level.weapon_springfield_allow = 0;
				}

				if(level.weapon_springfield_count < level.back2uo_springfield_limit && level.weapon_springfield_allow != 1)
				{
					setcvar("scr_allow_springfield", "1");
					setcvar("ui_allow_springfield", "1");
					level.weapon_springfield_allow = 1;
				}

				// Mosin-Nagant sniper
				if(level.weapon_nagantsniper_count > level.back2uo_nagantsniper_limit && level.weapon_nagantsniper_allow != 0)
				{
					setcvar("scr_allow_nagantsniper", "0");
					setcvar("ui_allow_nagantsniper", "0");
					level.weapon_nagantsniper_allow = 0;
				}

				if(level.weapon_nagantsniper_count < level.back2uo_nagantsniper_limit && level.weapon_nagantsniper_allow != 1)
				{
					setcvar("scr_allow_nagantsniper", "1");
					setcvar("ui_allow_nagantsniper", "1");
					level.weapon_nagantsniper_allow = 1;
				}

				// Scoped Enfield
				if(level.weapon_enfieldsniper_count > level.back2uo_enfieldsniper_limit && level.weapon_enfieldsniper_allow != 0)
				{
					setcvar("scr_allow_enfieldsniper", "0");
					setcvar("ui_allow_enfieldsniper", "0");
					level.weapon_enfieldsniper_allow = 0;
				}

				if(level.weapon_enfieldsniper_count < level.back2uo_enfieldsniper_limit && level.weapon_enfieldsniper_allow != 1)
				{
					setcvar("scr_allow_enfieldsniper", "1");
					setcvar("ui_allow_enfieldsniper", "1");
					level.weapon_enfieldsniper_allow = 1;
				}

				// Scoped Kar98k
				if(level.weapon_kar98ksniper_count > level.back2uo_kar98sniper_limit && level.weapon_kar98ksniper_allow != 0)
				{
					setcvar("scr_allow_kar98ksniper", "0");
					setcvar("ui_allow_kar98ksniper", "0");
					level.weapon_kar98ksniper_allow = 0;
				}

				if(level.weapon_kar98ksniper_count < level.back2uo_kar98sniper_limit && level.weapon_kar98ksniper_allow != 1)
				{
					setcvar("scr_allow_kar98ksniper", "1");
					setcvar("ui_allow_kar98ksniper", "1");
					level.weapon_kar98ksniper_allow = 1;
				}

				// Axis shotgun
				if(level.weapon_shotgun_axis_count > level.back2uo_shotgun_axis_limit && level.weapon_shotgun_axis_allow != 0)
				{
					setcvar("scr_allow_shotgun_axis", "0");
					setcvar("ui_allow_shotgun_axis", "0");
					level.weapon_shotgun_axis_allow = 0;
				}

				if(level.weapon_shotgun_axis_count < level.back2uo_shotgun_axis_limit && level.weapon_shotgun_axis_allow != 1)
				{
					setcvar("scr_allow_shotgun_axis", "1");
					setcvar("ui_allow_shotgun_axis", "1");
					level.weapon_shotgun_axis_allow = 1;
				}

				// Allied shotgun
				if(level.weapon_shotgun_allies_count > level.back2uo_shotgun_allies_limit && level.weapon_shotgun_allies_allow != 0)
				{
					setcvar("scr_allow_shotgun_allies", "0");
					setcvar("ui_allow_shotgun_allies", "0");
					level.weapon_shotgun_allies_allow = 0;
				}

				// Note: this re-enable branch writes "0" and allow = 0 (copy/paste error), so
				// once disabled the allied shotgun never becomes available again.
				if(level.weapon_shotgun_allies_count < level.back2uo_shotgun_allies_limit && level.weapon_shotgun_allies_allow != 1)
				{
					setcvar("scr_allow_shotgun_allies", "0");
					setcvar("ui_allow_shotgun_allies", "0");
					level.weapon_shotgun_allies_allow = 0;
				}
			}

			wait 0.1;
		}
	}
	else
	{
		// No limit: allow all sniper rifles and shotguns.
		setcvar("scr_allow_springfield", "1");
		setcvar("ui_allow_springfield", "1");

		setcvar("scr_allow_nagantsniper", "1");
		setcvar("ui_allow_nagantsniper", "1");

		setcvar("scr_allow_enfieldsniper", "1");
		setcvar("ui_allow_enfieldsniper", "1");

		setcvar("scr_allow_kar98ksniper", "1");
		setcvar("ui_allow_kar98ksniper", "1");

		setcvar("scr_allow_shotgun_axis", "1");
		setcvar("ui_allow_shotgun_axis", "1");

		setcvar("scr_allow_shotgun_allies", "1");
		setcvar("ui_allow_shotgun_allies", "1");
	}
}

/*
=============
back2uo_weaponpickup

Handles one dropped weapon. A 100 unit trigger_radius waits for players; within 60 units
a player who does not carry this weapon sees the pickup icon (client cvar
back2uo_ui_weaponpickup_object) and can swap it in with the use key. A player who already
holds the same weapon gets its ammo added instead. Ends when the weapon model is deleted
(picked up or removed by back2uo_weaponclear). Only active with the sprint system enabled.
Called on: the dropping player (from _weapons.gsc dropWeapon hook)
Params: weapon - weapon name
		clipammo - ammo in the clip
		slotammo - reserve ammo
		object - the dropped script_model
		origin - position of the dropped weapon
		slotmaxammo - spawn reserve ammo of the weapon, used as ammo top-up cap
		currentslot - slot the weapon was dropped from ("primary" / "primaryb")
=============
*/
back2uo_weaponpickup(weapon, clipammo, slotammo, object, origin, slotmaxammo, currentslot)
{
	if(!game["back2uo_sprint_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Pickup", "Run");

	// [1] = HUD icon index, [2] = display name
	weaponinfo = back2uo_weaponpickup_icon(weapon);

	// trigger_radius: spawnflags 0, radius 100, height 100.
	trigger = spawn("trigger_radius", origin, 0, 100, 100);
	other = "";

	while(isdefined(object))
	{
		wait 0.1;

		// Blocks until a player touches the trigger; other = that player.
		trigger waittill("trigger", other);

		other.pers["weapon_exist"] = false;

		// Initialize the per-player pickup state on first contact.
		if(!isdefined(other.pers["weapon_pickupwait"])) other.pers["weapon_pickupwait"] = false;
		if(!isdefined(other.pers["weapon_dopple"])) other.pers["weapon_dopple"] = false;
		if(!isdefined(other.pers["usebutton_holdpress"])) other.pers["usebutton_holdpress"] = false;
		if(!isdefined(other.pers["weaponpickup_msg"])) other.pers["weaponpickup_msg"] = false;
		if(!isdefined(other.back2uo_playerdo)) other.back2uo_playerdo = "none";

		if(other.sessionstate == "playing")
		{
			// With several weapons in range, only the one the player is already
			// targeting (other.weapon_origin) is handled.
			if(isdefined(other.weapon_origin))
			{
				if(other.weapon_origin != origin) continue;
			}

			// Short cooldown after the player just picked up a weapon.
			if(other.pers["weapon_pickupwait"] == true)
			{
				wait 1;

				other.pers["weapon_pickupwait"] = false;
			}

			// "dopple" (double): the player's other slot already holds this weapon (both
			// shotgun variants count as the same). The pickup would replace the current slot.
			if(other getWeaponSlotWeapon("primary") == other getcurrentweapon())
			{
				other.pers["weapon_dopple"] = false;
				other.pers["weaponpickup_slot"] = "primary";

				if(other getWeaponSlotWeapon("primaryb") == weapon) other.pers["weapon_dopple"] = true;

				if(other getWeaponSlotWeapon("primaryb") == "shotgun_mp_allies" && weapon == "shotgun_mp_axis") other.pers["weapon_dopple"] = true;
				if(other getWeaponSlotWeapon("primaryb") == "shotgun_mp_axis" && weapon == "shotgun_mp_allies") other.pers["weapon_dopple"] = true;
			}
			else
			{
				other.pers["weapon_dopple"] = false;
				other.pers["weaponpickup_slot"] = "primaryb";

				if(other getWeaponSlotWeapon("primary") == weapon) other.pers["weapon_dopple"] = true;

				if(other getWeaponSlotWeapon("primary") == "shotgun_mp_allies" && weapon == "shotgun_mp_axis") other.pers["weapon_dopple"] = true;
				if(other getWeaponSlotWeapon("primary") == "shotgun_mp_axis" && weapon == "shotgun_mp_allies") other.pers["weapon_dopple"] = true;
			}

			// "exist": the weapon in hand is the same weapon -> ammo pickup instead of swap.
			if(other getcurrentweapon() != weapon)
			{
				other.pers["weapon_exist"] = false;

				if(other getcurrentweapon() == "shotgun_mp_allies" && weapon == "shotgun_mp_axis") other.pers["weapon_exist"] = true;
				if(other getcurrentweapon() == "shotgun_mp_axis" && weapon == "shotgun_mp_allies") other.pers["weapon_exist"] = true;
			}
			else
			{
				other.pers["weapon_exist"] = true;
			}

			// Show the pickup icon when the weapon can be swapped in.
			if(other.pers["weapon_exist"] == false && other.pers["weapon_dopple"] == false && distance(other.origin, origin) < 60)
			{
				// Not while sprinting or busy (planting, defusing, on a turret).
				if(isdefined(other.pers["sprinting"]) && other.pers["sprinting"] == false && other.back2uo_playerdo == "none")
				{
					if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0.8;
					other setClientCvar("back2uo_ui_weaponpickup_object", weaponinfo[1]);

					// Lock this weapon as the player's pickup target.
					other.weapon_origin = origin;
				}
				else
				{
					if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
					other setClientCvar("back2uo_ui_weaponpickup_object", 0);
				}
			}
			else
			{
				if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
				other setClientCvar("back2uo_ui_weaponpickup_object", 0);

				other.weapon_origin = undefined;
			}

			// Require the use key to be released between actions, and treat it as held
			// while planting/defusing so the bomb use press does not pick up a weapon.
			if(!other usebuttonpressed() && other.pers["usebutton_holdpress"] == true)
			{
				other.pers["usebutton_holdpress"] = false;
			}
			else if(other.back2uo_playerdo == "plant" || other.back2uo_playerdo == "defuse")
			{
				other.pers["usebutton_holdpress"] = true;
			}

			// Swap: fresh use key press near the weapon.
			if(other.pers["weapon_exist"] == false && other.pers["weapon_dopple"] == false && distance(other.origin, origin) < 60 && other usebuttonpressed() && other.pers["usebutton_holdpress"] == false && other.back2uo_playerdo == "none")
			{
				// Note: checks self (the player who dropped the weapon), not other.
				if(!isdefined(self.planting) && !isdefined(self.defuse))
				{
					if(isdefined(other.pers["sprinting"]) && other.pers["sprinting"] == false)
					{
						if(!isDefined(object)) break;

						other.pers["usebutton_holdpress"] = true;

						// Drop the current weapon first (spawns its own pickup), then put the
						// new weapon into the freed slot.
						other maps\mp\gametypes\_weapons::dropWeapon();

						if(other.pers["weaponpickup_slot"] == "primary")
						{
							other setweaponslotweapon("primary", weapon);
							other setweaponslotammo("primary", slotammo);
							other setweaponslotclipammo("primary", clipammo);
						}
						else
						{
							other setweaponslotweapon("primaryb", weapon);
							other setweaponslotammo("primaryb", slotammo);
							other setweaponslotclipammo("primaryb", clipammo);
						}

						other switchToWeapon(weapon);

						other playSound("weap_pickup");

						if(isDefined(object)) object delete();

						other.weapon_origin = undefined;
						if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
						other setClientCvar("back2uo_ui_weaponpickup_object", 0);

						// Remember the max reserve ammo for later ammo top-ups of this slot.
						if(other.pers["weaponpickup_slot"] == "primary")
						{
							other.pers["back2uo_weaponspawn_prislotammo"] = slotmaxammo;
						}
						else
						{
							other.pers["back2uo_weaponspawn_pribslotammo"] = slotmaxammo;
						}

						other.pers["weapon_pickupwait"] = true;
						other.pers["weapon_pickupsprintwait"] = true;

						if(isdefined(trigger)) trigger delete();

						return;
					}
				}
			}

			// Ammo pickup: the player holds the same weapon; add its ammo if below the cap.
			if(other.pers["weapon_exist"] == true && distance(other.origin, origin) < 60)
			{
				if(!isDefined(object)) break;

				if(other.pers["weaponpickup_slot"] == "primary")
				{
					// Ammo cap: spawn reserve of the slot the weapon was dropped from.
					if(isdefined(currentslot) && currentslot == "primary")
						weapon_maxslotammo = other.pers["back2uo_weaponspawn_prislotammo"];
					else
						weapon_maxslotammo = other.pers["back2uo_weaponspawn_pribslotammo"];

					// Primary slot
					if(other getweaponslotammo("primary") < weapon_maxslotammo)
					{
						other.pers["weaponpickup_ammo"] = other getweaponslotammo("primary");
						other.pers["weaponpickup_clipammo"] = other getweaponslotclipammo("primary");

						other setweaponslotammo("primary", other.pers["weaponpickup_ammo"] + slotammo);
						other setweaponslotclipammo("primary", other.pers["weaponpickup_clipammo"] + clipammo);

						other playSound("weap_ammo_pickup");

						other iprintln(&"GAME_PICKUP_AMMO", weaponinfo[2]);

						other.weapon_origin = undefined;
						if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
						other setClientCvar("back2uo_ui_weaponpickup_object", 0);

						if(isDefined(object)) object delete();

						if(isdefined(trigger)) trigger delete();

						return;
					}
				}
				else if(other.pers["weaponpickup_slot"] == "primaryb")
				{
					if(isdefined(currentslot) && currentslot == "primary")
						weapon_maxslotammo = other.pers["back2uo_weaponspawn_prislotammo"];
					else
						weapon_maxslotammo = other.pers["back2uo_weaponspawn_pribslotammo"];

					// Secondary slot (primaryb)
					if(other getweaponslotammo("primaryb") < weapon_maxslotammo)
					{
						// Note: reads the clip ammo of "primary", not "primaryb".
						other.pers["weaponpickup_ammo"] = other getweaponslotammo("primaryb");
						other.pers["weaponpickup_clipammo"] = other getweaponslotclipammo("primary");

						other setweaponslotammo("primaryb", other.pers["weaponpickup_ammo"] + slotammo);
						other setweaponslotclipammo("primaryb", other.pers["weaponpickup_clipammo"] + clipammo);

						other playSound("weap_ammo_pickup");

						other iprintln(&"GAME_PICKUP_AMMO", weaponinfo[2]);

						other.weapon_origin = undefined;
						if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
						other setClientCvar("back2uo_ui_weaponpickup_object", 0);

						if(isDefined(object)) object delete();

						if(isdefined(trigger)) trigger delete();

						return;
					}
				}
			}

		}
		else
		{
			// Not playing (dead / spectating): hide the icon.
			other.weapon_origin = undefined;
			if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
			other setClientCvar("back2uo_ui_weaponpickup_object", 0);
		}
	}

	// Weapon is gone: clear the icon of the last player and remove the trigger.
	if(isdefined(other))
	{
		other.weapon_origin = undefined;
		if(isdefined(other.back2uo_weaponpickup)) other.back2uo_weaponpickup.alpha = 0;
		other setClientCvar("back2uo_ui_weaponpickup_object", 0);
	}

	if(isdefined(trigger))trigger delete();
}

/*
=============
back2uo_weaponclear

Deletes a dropped weapon model after 40 seconds; this also ends its
back2uo_weaponpickup thread.
Called on: the dropped weapon script_model
=============
*/
back2uo_weaponclear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Pickup Weapon", "Clear");

	if(!isDefined(self)) return;

	wait 40;

	if(isDefined(self)) self delete();
}

/*
=============
back2uo_weaponpickup_icon

Looks up the HUD pickup icon index (matched by the client hud.menu via the
back2uo_ui_weaponpickup_object cvar) and the display name of a weapon.
Params: weapon - weapon name
Returns: array [1] = icon index (0 = none), [2] = display name; 0 if weapon is undefined
=============
*/
back2uo_weaponpickup_icon(weapon)
{
	if(!isdefined(weapon)) return 0;

	weaponinfo = [];

	switch(weapon)
	{
	default:
		weaponinfo[1] = 0;
		weaponinfo[2] = "Unknow";
		break;

	case "TT30_mp":
		weaponinfo[1] = 1;
		weaponinfo[2] = "TT30";
		break;

	case "luger_mp":
		weaponinfo[1] = 2;
		weaponinfo[2] = "Luger";
		break;

	case "colt_mp":
		weaponinfo[1] = 3;
		weaponinfo[2] = "Colt.45";
		break;

	case "webley_mp":
		weaponinfo[1] = 4;
		weaponinfo[2] = "Webley";
		break;

	case "bar_mp":
		weaponinfo[1] = 5;
		weaponinfo[2] = &"WEAPON_BAR";
		break;

	case "bren_mp":
		weaponinfo[1] = 6;
		weaponinfo[2] = &"WEAPON_BREN";
		break;

	case "enfield_mp":
		weaponinfo[1] = 7;
		weaponinfo[2] = &"WEAPON_LEEENFIELD";
		break;

	case "enfield_scope_mp":
		weaponinfo[1] = 8;
		weaponinfo[2] = &"WEAPON_SCOPEDLEEENFIELD";
		break;

	case "g43_mp":
		weaponinfo[1] = 9;
		weaponinfo[2] = &"WEAPON_G43";
		break;

	case "g43_sniper_mp":
		weaponinfo[1] = 10;
		weaponinfo[2] = &"WEAPON_SCOPEDG43";
		break;

	case "greasegun_mp":
		weaponinfo[1] = 11;
		weaponinfo[2] = &"WEAPON_GREASEGUN";
		break;

	case "kar98k_mp":
		weaponinfo[1] = 12;
		weaponinfo[2] = &"WEAPON_KAR98K";
		break;

	case "m1carbine_mp":
		weaponinfo[1] = 13;
		weaponinfo[2] = &"WEAPON_M1A1CARBINE";
		break;

	case "m1garand_mp":
		weaponinfo[1] = 14;
		weaponinfo[2] = &"WEAPON_M1GARAND";
		break;

	case "mp40_mp":
		weaponinfo[1] = 15;
		weaponinfo[2] = &"WEAPON_MP40";
		break;

	case "mp44_mp":
		weaponinfo[1] = 16;
		weaponinfo[2] = &"WEAPON_MP44";
		break;

	case "PPS42_mp":
		weaponinfo[1] = 17;
		weaponinfo[2] = &"WEAPON_PPS42";
		break;

	case "ppsh_mp":
		weaponinfo[1] = 18;
		weaponinfo[2] = &"WEAPON_PPSH";
		break;

	case "kar98k_sniper_mp":
		weaponinfo[1] = 19;
		weaponinfo[2] = &"WEAPON_SCOPEDKAR98K";
		break;

	case "springfield_mp":
		weaponinfo[1] = 20;
		weaponinfo[2] = &"WEAPON_SPRINGFIELD";
		break;

	case "shotgun_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":
		weaponinfo[1] = 21;
		weaponinfo[2] = &"WEAPON_SHOTGUN";
		break;

	case "sten_mp":
		weaponinfo[1] = 22;
		weaponinfo[2] = &"WEAPON_STEN";
		break;

	case "SVT40_mp":
		weaponinfo[1] = 23;
		weaponinfo[2] = &"WEAPON_SVT40";
		break;

	case "thompson_mp":
		weaponinfo[1] = 24;
		weaponinfo[2] = &"WEAPON_THOMPSON";
		break;

	case "mosin_nagant_mp":
		weaponinfo[1] = 25;
		weaponinfo[2] = &"WEAPON_MOSINNAGANT";
		break;

	case "mosin_nagant_sniper_mp":
		weaponinfo[1] = 26;
		weaponinfo[2] = &"WEAPON_SCOPEDMOSINNAGANT";
		break;

	case "panzerschreck_mp":
		weaponinfo[1] = 27;
		weaponinfo[2] = &"WEAPON_PANZERSCHRECK";
		break;

		// Disabled: Panzerfaust is not used by the mod.
		//case "panzerfaust_mp":
		//weaponinfo[1] = 28;
		//weaponinfo[2] = &"WEAPON_PANZERFAUST";
		//break;
	}

	return weaponinfo;
}

/*
=============
back2uo_turret_inradius

Starts back2uo_turret_trigger on every misc_turret and misc_mg42 entity. Consecutive
entities at the same origin are skipped so a turret is only handled once.
Called on: level (from _back2uo_player.gsc)
=============
*/
back2uo_turret_inradius()
{
	if(!game["back2uo_sprint_enable"]) return;

	if(level.back2uo_turret_allow != 1) return;

	weapon_turret = getentarray("misc_turret", "classname");
	level.back2uo_misc_turret_origin = (0,0,0);

	for (t=0; t < weapon_turret.size; t++)
	{
		if(weapon_turret[t].origin != level.back2uo_misc_turret_origin)
		{
			level.back2uo_misc_turret_origin = weapon_turret[t].origin;

			weapon_turret[t] thread back2uo_turret_trigger();
		}
	}

	weapon_mg42 = getentarray("misc_mg42", "classname");
	level.back2uo_misc_mg42_origin = (0,0,0);

	for (t=0; t < weapon_mg42.size; t++)
	{
		if(weapon_mg42[t].origin != level.back2uo_misc_mg42_origin)
		{
			level.back2uo_misc_mg42_origin = weapon_mg42[t].origin;

			weapon_mg42[t] thread back2uo_turret_trigger();
		}
	}
}

/*
=============
back2uo_turret_trigger

Spawns a trigger_radius (radius 200, height 100) around a turret and marks players
standing in its use position with back2uo_playerdo = "turret_use" (blocks sprinting and
weapon pickup). Reset to "none" when they leave that position.
Called on: turret entity
=============
*/
back2uo_turret_trigger()
{
	trigger = spawn("trigger_radius", self.origin, 0, 200, 100);
	other = "";

	back2uo\_back2uo_cvars::back2uo_logprint("Turret Trigger", "Spawn");

	while(isdefined(self))
	{
		wait 0.1;

		trigger waittill("trigger", other);

		if(isdefined(other) && isAlive(other) && other.sessionstate == "playing")
		{
			// Dot product of the turret facing and the turret-to-player direction:
			// negative = player is behind the gun, where the operator stands.
			dotforward = anglestoforward(self.angles);
			angles = vectortoangles(other.origin - self.origin);
			forward = anglestoforward(angles);

			playerdistance = distance(other.origin, self.origin);
			playerangles = vectordot(dotforward,forward);

			// The .30 cal needs the player more directly behind it.
			if(self.weaponinfo == "30cal_prone_mp" || self.weaponinfo == "30cal_stand_mp") playerangles_max = -0.75;
			else playerangles_max = -0.55;

			// Behind the gun at 47-130 units, or very close (35-46 units) from any side.
			if(playerdistance < 131 && playerdistance > 46 && playerangles < playerangles_max)
			{
				other.back2uo_playerdo = "turret_use";
			}
			else if(playerdistance < 47 && playerdistance > 34)
			{
				other.back2uo_playerdo = "turret_use";
			}
			else
			{
				if(other.back2uo_playerdo == "turret_use") other.back2uo_playerdo = "none";
			}
		}
	}
}

/*
=============
back2uo_create_turret

Not in use (its only call in _back2uo_cvars.gsc is commented out). Spawns an MG42
turret at self's origin and angles.
Called on: entity providing origin and angles
=============
*/
back2uo_create_turret()
{
	turret = spawnTurret ("misc_turret", self.origin, "mg42_bipod_stand_mp");
	turret setmodel("xmodel/weapon_mg42");
	turret.name = "MG";
	turret.angles = self.angles;
	turret show();

	// Disabled: limits for the turret's firing arc in degrees.
	//turret SetTopArc(40);
	//turret SetBottomArc(30);
	//turret SetLeftArc(45);
	//turret SetRightArc(45);
}
