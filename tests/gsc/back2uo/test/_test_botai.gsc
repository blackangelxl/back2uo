/*
	Back2Uo v2.1 - tests for back2uo\bots\_back2uo_botai.gsc (test build only)

	Needs the test bots (back2uo_testbots_aktiv 1 in back2uomod.cfg). Checks the helper
	functions, then watches the bots on the running map: they must walk away from where they
	are and, within 90 seconds, kill each other. Prints INFO lines with what the bots did.
*/

/*
=============
run

Runs all bot AI tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("botai");

	test_helpers();

	if(!game["back2uo_testbots_enable"])
	{
		back2uo\test\_assert::skip("bots", "back2uo_testbots_aktiv is 0");
		return;
	}

	// Wait up to 20 seconds for at least two bots in play
	for(i = 0; i < 40 && playing_bots().size < 2; i++)
		wait .5;

	bots = playing_bots();
	back2uo\test\_assert::out("INFO;" + bots.size + " bots playing on " + getcvar("mapname"));

	if(bots.size < 2)
	{
		back2uo\test\_assert::assert_true("at least two bots playing", false);
		return;
	}

	test_moving();
	test_fighting();
}

/*
=============
test_helpers

Angle, clamp and weapon helpers.
=============
*/
test_helpers()
{
	back2uo\test\_assert::assert_eq("anglediff 350 - 10", back2uo\bots\_back2uo_botai::bot_anglediff(350, 10), -20);
	back2uo\test\_assert::assert_eq("anglediff 10 - 350", back2uo\bots\_back2uo_botai::bot_anglediff(10, 350), 20);
	back2uo\test\_assert::assert_eq("anglediff -170 - 170", back2uo\bots\_back2uo_botai::bot_anglediff(-170, 170), 20);
	back2uo\test\_assert::assert_eq("clamp 50 to 30", back2uo\bots\_back2uo_botai::bot_clamp(50, 30), 30);
	back2uo\test\_assert::assert_eq("clamp -50 to 30", back2uo\bots\_back2uo_botai::bot_clamp(-50, 30), -30);
	back2uo\test\_assert::assert_eq("clamp 10 to 30", back2uo\bots\_back2uo_botai::bot_clamp(10, 30), 10);
	back2uo\test\_assert::assert_eq("abs -7", back2uo\bots\_back2uo_botai::bot_abs(-7), 7);
	back2uo\test\_assert::assert_eq("mp44 is auto", back2uo\bots\_back2uo_botai::bot_weaponkind("mp44_mp"), "auto");
	back2uo\test\_assert::assert_eq("kar98k is bolt", back2uo\bots\_back2uo_botai::bot_weaponkind("kar98k_mp"), "bolt");
	back2uo\test\_assert::assert_eq("springfield is sniper", back2uo\bots\_back2uo_botai::bot_weaponkind("springfield_mp"), "sniper");
	back2uo\test\_assert::assert_eq("allied shotgun is shotgun", back2uo\bots\_back2uo_botai::bot_weaponkind("shotgun_mp_allies"), "shotgun");
	back2uo\test\_assert::assert_eq("axis shotgun is shotgun", back2uo\bots\_back2uo_botai::bot_weaponkind("shotgun_mp_axis"), "shotgun");
	back2uo\test\_assert::assert_eq("unknown weapon is semi", back2uo\bots\_back2uo_botai::bot_weaponkind("b2utest_mp"), "semi");
	back2uo\test\_assert::assert_eq("bolt interval", back2uo\bots\_back2uo_botai::bot_weaponinterval("bolt"), 1300);
}

/*
=============
test_moving

Over 8 seconds at least half of the bots that stay alive move 150 units or more.
=============
*/
test_moving()
{
	bots = playing_bots();
	start = [];

	for(i = 0; i < bots.size; i++)
		start[i] = bots[i].origin;

	wait 8;

	alive = 0;
	moved = 0;
	withpath = 0;

	for(i = 0; i < bots.size; i++)
	{
		// Died or respawned in between: position says nothing
		if(!isdefined(bots[i]) || bots[i].sessionstate != "playing" || !isdefined(bots[i].b2ubot)) continue;

		alive++;
		if(distance(start[i], bots[i].origin) >= 150) moved++;
		if(isdefined(bots[i].b2ubot.path)) withpath++;
	}

	back2uo\test\_assert::out("INFO;" + moved + " of " + alive + " bots moved 150+ units in 8 s, " + withpath + " follow a path");
	back2uo\test\_assert::assert_true("bots move", alive > 0 && moved * 2 >= alive);
}

/*
=============
test_fighting

Within 90 seconds at least one bot dies (the bots fight each other).
=============
*/
test_fighting()
{
	before = total_deaths();
	start = gettime();

	for(i = 0; i < 180 && total_deaths() == before; i++)
		wait .5;

	back2uo\test\_assert::out("INFO;deaths " + (total_deaths() - before) + " after " + int((gettime() - start) / 1000) + " s");
	back2uo\test\_assert::assert_true("bots kill each other", total_deaths() > before);
}

/*
=============
playing_bots

Returns the bots that are alive and in play.
=============
*/
playing_bots()
{
	bots = [];
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		if(players[i] back2uo\_back2uo_libcod::back2uo_libcod_isbot() && isdefined(players[i].sessionstate) && players[i].sessionstate == "playing")
			bots[bots.size] = players[i];
	}

	return bots;
}

/*
=============
total_deaths

Returns the sum of the deaths of all players.
=============
*/
total_deaths()
{
	total = 0;
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].deaths)) total += players[i].deaths;
	}

	return total;
}
