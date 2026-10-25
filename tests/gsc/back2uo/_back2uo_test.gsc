/*
	Back2Uo v2.1 - GSC test runner (test build only)

	Replaces the release stub back2uo/_back2uo_test.gsc when the test archive
	z_svr_back2uo_2.1_test.iwd is loaded (python tools/build.py --test).
	Runs only with the cvar back2uo_test 1, once per map. Every result is written as a
	"B2UTEST;..." line to the game log (logprint) and to the console (println, needs
	developer 1). tests/run_tests.py reads these lines and sets the exit code.

	Line format:
		B2UTEST;START;<gametype>;<mapname>
		B2UTEST;SUITE;<suite>
		B2UTEST;PASS;<test>
		B2UTEST;FAIL;<test>;got=<value>;want=<value>
		B2UTEST;XFAIL;<test>;got=<value>;want=<value>		known bug, still present
		B2UTEST;XPASS;<test>							known bug, now fixed
		B2UTEST;SKIP;<test>;<reason>
		B2UTEST;DONE;pass=<n>;fail=<n>;xfail=<n>;xpass=<n>;skip=<n>
*/

/*
=============
run

Runs all test suites and prints the summary.
Called on: level (threaded from _back2uo_main::back2uo_main)
=============
*/
run()
{
	if(getcvarint("back2uo_test") != 1) return;

	// Only once per map, not again after a round restart. A restart while the tests run (sd
	// restarts when both teams have players; the bots end rounds) kills this thread, so the
	// flag is set at the end and an interrupted run starts over in the next round.
	if(isdefined(game["back2uo_test_done"])) return;

	// Let Callback_StartGameType and the mod start code finish first
	wait 1;

	// tools/wpgen.py: generate bot waypoints instead of running the tests
	if(getcvarint("back2uo_wpgen") == 1)
	{
		back2uo\test\_wpgen::run();
		game["back2uo_test_done"] = true;
		return;
	}

	back2uo\test\_assert::init();
	back2uo\test\_assert::out("START;" + getcvar("g_gametype") + ";" + getcvar("mapname"));

	if(!game["back2uo_enable"])
	{
		back2uo\test\_assert::skip("all", "back2uo_status is 0");
	}
	else
	{
		//back2uo\test\_test_cvars::run();
		//back2uo\test\_test_weaponsystem::run();
		back2uo\test\_test_maprotation::run();
		//back2uo\test\_test_waypoints::run();
		//back2uo\test\_test_botai::run();
	}

	game["back2uo_test_done"] = true;
	back2uo\test\_assert::done();
}
