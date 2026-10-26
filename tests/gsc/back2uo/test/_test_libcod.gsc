/*
	Back2Uo v2.1 - tests for the zk_libcod wrappers (test build only)

	The test server runs zk_libcod with z_svr_back2uo_2.1_libcod.iwd, so the zk_libcod version
	of back2uo\_back2uo_libcod.gsc must be loaded and find the "libcod" dvar. The fallbacks of
	back2uo\_back2uo_libcod_fallback.gsc are called directly, on a struct in place of a player.
*/

/*
=============
run

Runs all libcod wrapper tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("libcod");

	test_active();
	test_fallbacks();
}

/*
=============
test_active

back2uo_libcod_active(): true on the zk_libcod test server (false would mean the release stub
or a missing "libcod" dvar).
=============
*/
test_active()
{
	back2uo\test\_assert::assert_true("libcod version loaded", back2uo\_back2uo_libcod::back2uo_libcod_active());
}

/*
=============
test_fallbacks

Fallback values of the functions that need no real player.
=============
*/
test_fallbacks()
{
	s = spawnstruct();

	back2uo\test\_assert::assert_eq("fallback getspeed is g_speed", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getspeed(), getcvarint("g_speed"));
	back2uo\test\_assert::assert_eq("fallback false", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false(), false);

	back2uo\test\_assert::assert_eq("fallback binoculars unset", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isusingbinoculars(), false);
	s.back2uo_bino_up = true;
	back2uo\test\_assert::assert_eq("fallback binoculars up", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isusingbinoculars(), true);

	back2uo\test\_assert::assert_eq("fallback isbot no pers", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isbot(), false);
	s.pers = [];
	s.pers["bots_nosprint"] = "noallow";
	back2uo\test\_assert::assert_eq("fallback isbot test client", s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isbot(), true);

	back2uo\test\_assert::assert_true("fallback inactivity undefined", !isdefined(s back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getinactivitytime()));

	// g_inactivity 0: the engine does not update the value, the wrapper must not read it
	saved = back2uo\test\_assert::cvar_save("g_inactivity");
	setcvar("g_inactivity", "0");
	back2uo\test\_assert::assert_true("inactivity undefined with g_inactivity 0", !isdefined(s back2uo\_back2uo_libcod::back2uo_libcod_getinactivitytime()));
	back2uo\test\_assert::cvar_restore("g_inactivity", saved);

	// g_bulletDrop 0: the wrapper must not call enableBulletDrop (it would fail on a struct)
	saved = back2uo\test\_assert::cvar_save("g_bulletDrop");
	setcvar("g_bulletDrop", "0");
	s back2uo\_back2uo_libcod::back2uo_libcod_setbulletdrop(true);
	back2uo\test\_assert::assert_true("bulletdrop skipped with g_bulletDrop 0", true);
	back2uo\test\_assert::cvar_restore("g_bulletDrop", saved);
}
