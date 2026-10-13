/*
	Back2Uo v2.1 - tests for the weapon damage scaling in back2uo\_back2uo_weaponsystem.gsc
	(test build only)

	Sets back2uo_weaponstr_* cvars, runs back2uo_weapon_optimizer() again and checks
	level.back2uo_weaponstrength[]. Puts the cvars back and runs the optimizer once more.
*/

/*
=============
run

Runs all weapon system tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("weaponsystem");

	if(!game["back2uo_weaponsystem_enable"])
	{
		back2uo\test\_assert::skip("weaponsystem", "back2uo_weaponsetup_aktiv is 0");
		return;
	}

	test_weaponstrength_cvars();
	test_weaponstrength_clamp();
	test_weaponstrength_range();
}

/*
=============
test_weaponstrength_cvars

Each damage cvar reaches its weapon. Covers the former cvar typo (kar98k sniper) and
weapon name bugs (panzerschreck, TT30) from docs/code-review-notes.md.
=============
*/
test_weaponstrength_cvars()
{
	cvars = [];
	cvars[0] = "back2uo_weaponstr_kar98k_sniper";
	cvars[1] = "back2uo_weaponstr_rocketlancher";
	cvars[2] = "back2uo_weaponstr_TT30";
	cvars[3] = "back2uo_weaponstr_mp44";
	weapons = [];
	weapons[0] = "kar98k_sniper_mp";
	weapons[1] = "panzerschreck_mp";
	weapons[2] = "TT30_mp";
	weapons[3] = "mp44_mp";

	saved = [];
	for(i = 0; i < cvars.size; i++)
	{
		saved[i] = back2uo\test\_assert::cvar_save(cvars[i]);
		setcvar(cvars[i], 40 + i);
	}

	back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();

	for(i = 0; i < cvars.size; i++)
		back2uo\test\_assert::assert_eq("weaponstr " + cvars[i] + " -> " + weapons[i], level.back2uo_weaponstrength[weapons[i]], 40 + i);

	for(i = 0; i < cvars.size; i++)
		back2uo\test\_assert::cvar_restore(cvars[i], saved[i]);

	back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();
}

/*
=============
test_weaponstrength_clamp

Damage values are clamped to 1..100 percent.
=============
*/
test_weaponstrength_clamp()
{
	saved = back2uo\test\_assert::cvar_save("back2uo_weaponstr_mp40");

	setcvar("back2uo_weaponstr_mp40", "500");
	back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();
	back2uo\test\_assert::assert_eq("weaponstr clamps to 100", level.back2uo_weaponstrength["mp40_mp"], 100);

	setcvar("back2uo_weaponstr_mp40", "0");
	back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();
	back2uo\test\_assert::assert_eq("weaponstr clamps to 1", level.back2uo_weaponstrength["mp40_mp"], 1);

	back2uo\test\_assert::cvar_restore("back2uo_weaponstr_mp40", saved);
	back2uo\_back2uo_weaponsystem::back2uo_weapon_optimizer();
}

/*
=============
test_weaponstrength_range

With the current config every weapon has a damage value of 1..100.
=============
*/
test_weaponstrength_range()
{
	keys = getarraykeys(level.back2uo_weaponstrength);
	back2uo\test\_assert::assert_true("weaponstrength has entries", keys.size > 0);

	for(i = 0; i < keys.size; i++)
	{
		value = level.back2uo_weaponstrength[keys[i]];
		back2uo\test\_assert::assert_true("weaponstrength " + keys[i] + " in 1..100", isdefined(value) && value >= 1 && value <= 100);
	}
}
