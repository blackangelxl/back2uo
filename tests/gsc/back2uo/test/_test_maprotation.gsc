/*
	Back2Uo v2.1 - tests for back2uo\tools\_back2uo_maprotation.gsc (test build only)

	Sets sv_maprotation / sv_maprotationcurrent, parses them and checks the map entries.
	The real rotation cvars are put back at the end of run().
*/

/*
=============
run

Runs all map rotation tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("maprotation");

	saved_rot = back2uo\test\_assert::cvar_save("sv_maprotation");
	saved_cur = back2uo\test\_assert::cvar_save("sv_maprotationcurrent");
	saved_random = back2uo\test\_assert::cvar_save("back2uo_random_maprotation");
	saved_enable = game["back2uo_mapsystem_enable"];

	test_isgametype();
	test_isconfig();
	test_parse_plain();
	test_parse_number();
	test_parse_current();
	test_parse_empty();
	test_parse_guess();
	test_parse_random();
	test_parse_random_default_gametype();
	test_serialize();
	test_serialize_limit();

	game["back2uo_mapsystem_enable"] = saved_enable;
	back2uo\test\_assert::cvar_restore("back2uo_random_maprotation", saved_random);
	back2uo\test\_assert::cvar_restore("sv_maprotationcurrent", saved_cur);
	back2uo\test\_assert::cvar_restore("sv_maprotation", saved_rot);
}

/*
=============
parse

Sets the rotation cvars and parses them.
Params: rotation - value for sv_maprotation
		current - value for sv_maprotationcurrent
		random, readcurrent, number - passed to back2uo_getmaprotation()
=============
*/
parse(rotation, current, random, readcurrent, number)
{
	setcvar("sv_maprotation", rotation);
	setcvar("sv_maprotationcurrent", current);

	return back2uo\tools\_back2uo_maprotation::back2uo_getmaprotation(random, readcurrent, number);
}

/*
=============
test_isgametype

Only the stock gametypes count.
=============
*/
test_isgametype()
{
	back2uo\test\_assert::assert_eq("isGametype tdm", back2uo\tools\_back2uo_maprotation::isGametype("tdm"), true);
	back2uo\test\_assert::assert_eq("isGametype ctf", back2uo\tools\_back2uo_maprotation::isGametype("ctf"), true);
	back2uo\test\_assert::assert_eq("isGametype mp_toujane", back2uo\tools\_back2uo_maprotation::isGametype("mp_toujane"), false);
}

/*
=============
test_isconfig

"name.cfg" is a config, anything else is not.
=============
*/
test_isconfig()
{
	back2uo\test\_assert::assert_eq("isConfig server.cfg", back2uo\tools\_back2uo_maprotation::isConfig("server.cfg"), true);
	back2uo\test\_assert::assert_eq("isConfig mp_toujane", back2uo\tools\_back2uo_maprotation::isConfig("mp_toujane"), false);
	back2uo\test\_assert::assert_eq("isConfig a.b.cfg", back2uo\tools\_back2uo_maprotation::isConfig("a.b.cfg"), false);
}

/*
=============
test_parse_plain

Plain rotation: keywords apply to the next map only, repeated spaces are ignored.
=============
*/
test_parse_plain()
{
	x = parse("gametype tdm map mp_a  map mp_b exec x.cfg allow_jeeps 1 gametype sd map mp_c", "", false, false, undefined);

	back2uo\test\_assert::assert_eq("plain map count", x.maps.size, 3);
	back2uo\test\_assert::assert_eq("plain map 0 name", x.maps[0]["map"], "mp_a");
	back2uo\test\_assert::assert_eq("plain map 0 gametype", x.maps[0]["gametype"], "tdm");
	back2uo\test\_assert::assert_eq("plain map 1 name", x.maps[1]["map"], "mp_b");
	back2uo\test\_assert::assert_true("plain map 1 gametype reset", !isdefined(x.maps[1]["gametype"]));
	back2uo\test\_assert::assert_eq("plain map 2 name", x.maps[2]["map"], "mp_c");
	back2uo\test\_assert::assert_eq("plain map 2 exec", x.maps[2]["exec"], "x.cfg");
	back2uo\test\_assert::assert_eq("plain map 2 jeep", x.maps[2]["jeep"], "1");
	back2uo\test\_assert::assert_eq("plain map 2 gametype", x.maps[2]["gametype"], "sd");
}

/*
=============
test_parse_number

number stops parsing after that many maps.
=============
*/
test_parse_number()
{
	x = parse("map mp_a map mp_b map mp_c", "", false, false, 1);

	back2uo\test\_assert::assert_eq("number 1 map count", x.maps.size, 1);
	back2uo\test\_assert::assert_eq("number 1 map name", x.maps[0]["map"], "mp_a");
}

/*
=============
test_parse_current

current = true reads sv_maprotationcurrent first and falls back to sv_maprotation.
=============
*/
test_parse_current()
{
	x = parse("map mp_rot", "map mp_cur", false, true, undefined);
	back2uo\test\_assert::assert_eq("current reads sv_maprotationcurrent", x.maps[0]["map"], "mp_cur");

	x = parse("map mp_rot", "", false, true, undefined);
	back2uo\test\_assert::assert_eq("current falls back to sv_maprotation", x.maps[0]["map"], "mp_rot");

	x = parse("map mp_rot", "map mp_cur", false, false, undefined);
	back2uo\test\_assert::assert_eq("current false ignores sv_maprotationcurrent", x.maps[0]["map"], "mp_rot");
}

/*
=============
test_parse_empty

No rotation set: returns undefined.
=============
*/
test_parse_empty()
{
	x = parse("", "", false, true, undefined);

	back2uo\test\_assert::assert_true("empty rotation returns undefined", !isdefined(x));
}

/*
=============
test_parse_guess

Tokens without keyword: gametype and .cfg are recognised, the rest is a map name.
=============
*/
test_parse_guess()
{
	x = parse("sd x.cfg mp_a", "", false, false, undefined);

	back2uo\test\_assert::assert_eq("guess map count", x.maps.size, 1);
	back2uo\test\_assert::assert_eq("guess map name", x.maps[0]["map"], "mp_a");
	back2uo\test\_assert::assert_eq("guess gametype", x.maps[0]["gametype"], "sd");
	back2uo\test\_assert::assert_eq("guess exec", x.maps[0]["exec"], "x.cfg");
}

/*
=============
test_parse_random

Shuffled rotation: settings stay with every later map, no map is lost or doubled.
=============
*/
test_parse_random()
{
	x = parse("gametype sd map mp_a map mp_b map mp_c", "", true, false, undefined);

	back2uo\test\_assert::assert_eq("random map count", x.maps.size, 3);

	found_a = 0;
	found_b = 0;
	found_c = 0;
	sticky = true;
	for(i = 0; i < x.maps.size; i++)
	{
		if(x.maps[i]["map"] == "mp_a") found_a++;
		if(x.maps[i]["map"] == "mp_b") found_b++;
		if(x.maps[i]["map"] == "mp_c") found_c++;
		if(!isdefined(x.maps[i]["gametype"]) || x.maps[i]["gametype"] != "sd") sticky = false;
	}

	back2uo\test\_assert::assert_true("random keeps every map once", found_a == 1 && found_b == 1 && found_c == 1);
	back2uo\test\_assert::assert_true("random keeps gametype on every map", sticky);
}

/*
=============
test_parse_random_default_gametype

Known bug: maps before the first "gametype" token should get the current gametype.
back2uo_getmaprotation() starts with level.back2uo_gametype, which is never set. After the
shuffle such a map can follow an "sd" map and is then played as sd.
=============
*/
test_parse_random_default_gametype()
{
	x = parse("map mp_a gametype sd map mp_b", "", true, false, undefined);

	gametype = undefined;
	for(i = 0; i < x.maps.size; i++)
	{
		if(x.maps[i]["map"] == "mp_a") gametype = x.maps[i]["gametype"];
	}

	back2uo\test\_assert::known_bug("random map without gametype gets current gametype", gametype, getcvar("g_gametype"));
}

/*
=============
entry

Adds one map entry to a rotation struct, like back2uo_getmaprotation() builds it.
=============
*/
entry(x, mapname, gametype, exec)
{
	i = x.maps.size;
	x.maps[i]["map"] = mapname;
	x.maps[i]["gametype"] = gametype;
	x.maps[i]["exec"] = exec;
}

/*
=============
test_serialize

back2uo_randommap_rotation() writes the entries back and skips repeated tokens.
=============
*/
test_serialize()
{
	game["back2uo_mapsystem_enable"] = 1;

	x = spawnstruct();
	x.maps = [];
	entry(x, "mp_a", "tdm", undefined);
	entry(x, "mp_b", "tdm", undefined);
	entry(x, "mp_c", "sd", "x.cfg");

	back2uo\tools\_back2uo_maprotation::back2uo_randommap_rotation(x);

	back2uo\test\_assert::assert_eq("serialize skips repeated tokens", getcvar("sv_maprotationcurrent"),
		" gametype tdm map mp_a map mp_b exec x.cfg gametype sd map mp_c");
	back2uo\test\_assert::assert_eq("serialize sets back2uo_random_maprotation", getcvar("back2uo_random_maprotation"), "2");
}

/*
=============
test_serialize_limit

Long rotations are cut before 975 characters (cvar strings near 1024 crash the server).
The entries are built directly, so no oversized cvar is ever set.
=============
*/
test_serialize_limit()
{
	game["back2uo_mapsystem_enable"] = 1;

	x = spawnstruct();
	x.maps = [];
	for(i = 0; i < 100; i++)
		entry(x, "mp_longmapname_" + i, "tdm", undefined);

	back2uo\tools\_back2uo_maprotation::back2uo_randommap_rotation(x);

	result = getcvar("sv_maprotationcurrent");
	back2uo\test\_assert::assert_true("serialize limit 975 chars (got " + result.size + ")", result.size > 0 && result.size <= 975);
}
