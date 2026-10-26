/*
	Back2Uo v2.1 - tests for the bot name pool (test build only)

	back2uo\bots\_back2uo_botnames.gsc: pool sizes, name length, suffix, no duplicates and
	the numbered names once a pool is used up. level.back2uo_botnames_used is saved and
	restored, so the names of the running test bots stay reserved.
*/

/*
=============
run

Runs all bot name tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("botnames");

	saved = level.back2uo_botnames_used;

	test_pools();
	test_get();
	test_exhausted();

	level.back2uo_botnames_used = saved;
}

/*
=============
test_pools

Every nationality has names, unknown nationalities get the german pool, and every name
with suffix fits the CoD2 name limit of 31 characters.
=============
*/
test_pools()
{
	nations = [];
	nations[0] = "american";
	nations[1] = "british";
	nations[2] = "russian";
	nations[3] = "german";

	longest = 0;

	for(i = 0; i < nations.size; i++)
	{
		pool = back2uo\bots\_back2uo_botnames::back2uo_botname_pool(nations[i]);
		back2uo\test\_assert::assert_true("pool " + nations[i] + " not empty", pool.size > 0);

		for(j = 0; j < pool.size; j++)
		{
			if(pool[j].size > longest) longest = pool[j].size;
		}
	}

	back2uo\test\_assert::assert_true("longest name fits 31 chars", longest + 8 <= 31);

	german = back2uo\bots\_back2uo_botnames::back2uo_botname_pool("german");
	unknown = back2uo\bots\_back2uo_botnames::back2uo_botname_pool("japanese");
	back2uo\test\_assert::assert_eq("unknown nationality uses german pool", unknown.size, german.size);
}

/*
=============
test_get

back2uo_botname_get() adds the suffix and never hands out the same name twice.
=============
*/
test_get()
{
	level.back2uo_botnames_used = undefined;

	a = back2uo\bots\_back2uo_botnames::back2uo_botname_get("british");
	b = back2uo\bots\_back2uo_botnames::back2uo_botname_get("british");

	back2uo\test\_assert::assert_eq("name has bot suffix", getsubstr(a, a.size - 8, a.size), " ^3[BOT]");
	back2uo\test\_assert::assert_true("two names differ", a != b);
}

/*
=============
test_exhausted

When every name of a pool is taken, a two-digit number is inserted before the suffix.
=============
*/
test_exhausted()
{
	level.back2uo_botnames_used = [];
	pool = back2uo\bots\_back2uo_botnames::back2uo_botname_pool("russian");

	for(i = 0; i < pool.size; i++)
		level.back2uo_botnames_used[pool[i]] = true;

	name = back2uo\bots\_back2uo_botnames::back2uo_botname_get("russian");
	base = getsubstr(name, 0, name.size - 11);

	back2uo\test\_assert::assert_true("exhausted pool name is from pool", isdefined(level.back2uo_botnames_used[base]));
	back2uo\test\_assert::assert_true("exhausted pool name fits 31 chars", name.size <= 31);
}
