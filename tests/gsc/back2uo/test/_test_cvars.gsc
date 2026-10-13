/*
	Back2Uo v2.1 - tests for the cvar readers in back2uo\_back2uo_cvars.gsc (test build only)

	Uses scratch cvars named b2utest_*. Every test puts changed cvars and game[] values back.
*/

/*
=============
run

Runs all cvar tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("cvars");

	test_getstatus();
	test_setconfig_enabled();
	test_setconfig_disabled();
	test_getcvardef();
	test_getcvardef_overrides();
	test_sprint_length();
}

/*
=============
test_getstatus

back2uo_getstatus(): empty cvar becomes 1, "0" disables, any other number enables.
=============
*/
test_getstatus()
{
	saved = back2uo\test\_assert::cvar_save("back2uo_status");

	setcvar("back2uo_status", "");
	back2uo\test\_assert::assert_eq("getstatus empty returns 1", back2uo\_back2uo_cvars::back2uo_getstatus(), 1);
	back2uo\test\_assert::assert_eq("getstatus empty sets cvar", getcvar("back2uo_status"), "1");

	setcvar("back2uo_status", "0");
	back2uo\test\_assert::assert_eq("getstatus 0 returns 0", back2uo\_back2uo_cvars::back2uo_getstatus(), 0);

	setcvar("back2uo_status", "2");
	back2uo\test\_assert::assert_eq("getstatus 2 returns 1", back2uo\_back2uo_cvars::back2uo_getstatus(), 1);

	back2uo\test\_assert::cvar_restore("back2uo_status", saved);
}

/*
=============
test_setconfig_enabled

back2uo_setconfig() with the mod on: default for empty cvars, min/max clamp, 0 = no limit.
=============
*/
test_setconfig_enabled()
{
	setcvar("b2utest_a", "");
	back2uo\test\_assert::assert_eq("setconfig empty returns default", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 1, 0, 1), 1);
	back2uo\test\_assert::assert_eq("setconfig empty writes default", getcvar("b2utest_a"), "1");

	setcvar("b2utest_a", "5");
	back2uo\test\_assert::assert_eq("setconfig clamps to max", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 1, 0, 1), 1);

	setcvar("b2utest_a", "0");
	back2uo\test\_assert::assert_eq("setconfig clamps to min", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 3, 2, 4), 2);

	setcvar("b2utest_a", "-3");
	back2uo\test\_assert::assert_eq("setconfig min 0 is no limit", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 1, 0, 1), -3);

	setcvar("b2utest_a", "");
}

/*
=============
test_setconfig_disabled

back2uo_setconfig() with the mod off: returns offvalue (default 0) and leaves the cvar alone.
=============
*/
test_setconfig_disabled()
{
	saved = game["back2uo_enable"];
	game["back2uo_enable"] = 0;

	setcvar("b2utest_a", "5");
	back2uo\test\_assert::assert_eq("setconfig off returns 0", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 1, 0, 1), 0);
	back2uo\test\_assert::assert_eq("setconfig off returns offvalue", back2uo\_back2uo_cvars::back2uo_setconfig("b2utest_a", 1, 0, 1, 1), 1);
	back2uo\test\_assert::assert_eq("setconfig off keeps cvar", getcvar("b2utest_a"), "5");

	game["back2uo_enable"] = saved;
	setcvar("b2utest_a", "");
}

/*
=============
test_getcvardef

back2uo_getcvardef() without overrides: types, default and clamp.
=============
*/
test_getcvardef()
{
	setcvar("b2utest_b", "");
	back2uo\test\_assert::assert_eq("getcvardef empty returns default", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", 3, 1, 10, "int"), 3);

	setcvar("b2utest_b", "7");
	back2uo\test\_assert::assert_eq("getcvardef int", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", 3, 1, 10, "int"), 7);

	setcvar("b2utest_b", "50");
	back2uo\test\_assert::assert_eq("getcvardef clamps to max", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", 3, 1, 10, "int"), 10);

	setcvar("b2utest_b", "2.5");
	back2uo\test\_assert::assert_eq("getcvardef float", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", 1, 0, 0, "float"), 2.5);
	back2uo\test\_assert::assert_eq("getcvardef int truncates", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", 1, 0, 0, "int"), 2);

	setcvar("b2utest_b", "hello");
	back2uo\test\_assert::assert_eq("getcvardef string", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_b", "x", 0, 0, "string"), "hello");

	setcvar("b2utest_b", "");
}

/*
=============
test_getcvardef_overrides

back2uo_getcvardef() override lookup: <name>_<gametype>, <name>_<mapname>, <name>_<gametype>_<mapname>.
=============
*/
test_getcvardef_overrides()
{
	gametype = getcvar("g_gametype");
	mapname = getcvar("mapname");

	gt = "b2utest_c_" + gametype;
	mapvar = "b2utest_c_" + mapname;
	gtmap = "b2utest_c_" + gametype + "_" + mapname;

	setcvar("b2utest_c", "1");

	setcvar(gt, "2");
	back2uo\test\_assert::assert_eq("getcvardef gametype override", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_c", 0, 0, 0, "int"), 2);
	setcvar(gt, "");

	setcvar(mapvar, "3");
	back2uo\test\_assert::assert_eq("getcvardef map override", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_c", 0, 0, 0, "int"), 3);
	setcvar(mapvar, "");

	setcvar(gtmap, "4");
	back2uo\test\_assert::assert_eq("getcvardef gametype+map override", back2uo\_back2uo_cvars::back2uo_getcvardef("b2utest_c", 0, 0, 0, "int"), 4);
	setcvar(gtmap, "");

	setcvar("b2utest_c", "");
}

/*
=============
test_sprint_length

Known bug (docs/code-review-notes.md): back2uo_sprint_length is read as "int" in
_back2uo_main.gsc, so 2.5 becomes 2.
=============
*/
test_sprint_length()
{
	if(getcvarint("back2uo_sprint_length") == getcvarfloat("back2uo_sprint_length"))
	{
		back2uo\test\_assert::skip("sprint_length keeps fraction", "back2uo_sprint_length has no fraction");
		return;
	}

	back2uo\test\_assert::known_bug("sprint_length keeps fraction", level.back2uo_sprint_length, getcvarfloat("back2uo_sprint_length"));
}
