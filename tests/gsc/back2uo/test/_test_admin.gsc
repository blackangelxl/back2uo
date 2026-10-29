/*
	Back2Uo v2.1 - tests for the admin command parsing in back2uo\_back2uo_admin.gsc (test build only)

	Only parsing and the password check are tested: granting artillery and starting airplanes
	need players and effects.
*/

/*
=============
run

Runs all admin command tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("admin");

	test_toint();
	test_airplanes_count();
	test_admin_command();
	test_admin_password();
	test_admin_weather();
}

/*
=============
test_admin_weather

back2uo_admin_weather(): the same type toggles on/off, the other type replaces the running one.
Runs on a test bot (the command prints a message to the calling player).
=============
*/
test_admin_weather()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_rainfx_enable"] || !game["back2uo_snowfx_enable"])
	{
		back2uo\test\_assert::skip("admin weather", "weather, rain or snow disabled");
		return;
	}

	players = getentarray("player", "classname");
	if(players.size == 0)
	{
		back2uo\test\_assert::skip("admin weather", "no player");
		return;
	}
	player = players[0];

	saved = level.back2uo_weatherart;

	level.back2uo_weatherart = undefined;
	player back2uo\_back2uo_admin::back2uo_admin_weather("rain");
	back2uo\test\_assert::assert_eq("weather rain on", level.back2uo_weatherart, "rain");

	player back2uo\_back2uo_admin::back2uo_admin_weather("snow");
	back2uo\test\_assert::assert_eq("weather snow replaces rain", level.back2uo_weatherart, "snow");

	player back2uo\_back2uo_admin::back2uo_admin_weather("snow");
	back2uo\test\_assert::assert_true("weather snow off", !isdefined(level.back2uo_weatherart));

	// Put the map's own weather back.
	level.back2uo_weatherart = saved;
	if(isdefined(saved)) level thread back2uo\weatherfx\_back2uo_weather::back2uo_weatherdraw(true);
}

/*
=============
test_toint

back2uo_admin_toint(): digits only, max 4 characters, otherwise undefined.
=============
*/
test_toint()
{
	back2uo\test\_assert::assert_eq("toint 0", back2uo\_back2uo_admin::back2uo_admin_toint("0"), 0);
	back2uo\test\_assert::assert_eq("toint 7", back2uo\_back2uo_admin::back2uo_admin_toint("7"), 7);
	back2uo\test\_assert::assert_eq("toint 42", back2uo\_back2uo_admin::back2uo_admin_toint("42"), 42);
	back2uo\test\_assert::assert_true("toint empty is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_toint("")));
	back2uo\test\_assert::assert_true("toint text is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_toint("all")));
	back2uo\test\_assert::assert_true("toint negative is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_toint("-1")));
	back2uo\test\_assert::assert_true("toint mixed is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_toint("4a")));
	back2uo\test\_assert::assert_true("toint too long is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_toint("12345")));
}

/*
=============
test_airplanes_count

back2uo_admin_airplanes_count(): 0 stays 0 (config count), 1-6 as given, above 6 clamps to 6.
=============
*/
test_airplanes_count()
{
	back2uo\test\_assert::assert_eq("airplanes 0 uses config", back2uo\_back2uo_admin::back2uo_admin_airplanes_count("0"), 0);
	back2uo\test\_assert::assert_eq("airplanes 1", back2uo\_back2uo_admin::back2uo_admin_airplanes_count("1"), 1);
	back2uo\test\_assert::assert_eq("airplanes 6", back2uo\_back2uo_admin::back2uo_admin_airplanes_count("6"), 6);
	back2uo\test\_assert::assert_eq("airplanes 9 clamps to 6", back2uo\_back2uo_admin::back2uo_admin_airplanes_count("9"), 6);
	back2uo\test\_assert::assert_true("airplanes text is undefined", !isdefined(back2uo\_back2uo_admin::back2uo_admin_airplanes_count("many")));
}

/*
=============
test_admin_command

back2uo_admin_command(): "b2u_artillery:<password>" and "b2u_airplanes:<count>:<password>";
the password is the rest of the line, other responses are no command.
=============
*/
test_admin_command()
{
	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_artillery:secret");
	back2uo\test\_assert::assert_eq("artillery name", command["name"], "b2u_artillery");
	back2uo\test\_assert::assert_eq("artillery value", command["value"], "");
	back2uo\test\_assert::assert_eq("artillery password", command["password"], "secret");

	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_artillery:a:b");
	back2uo\test\_assert::assert_eq("artillery password keeps later colons", command["password"], "a:b");

	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_artillery");
	back2uo\test\_assert::assert_eq("artillery without password", command["password"], "");

	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_airplanes:4:secret");
	back2uo\test\_assert::assert_eq("airplanes name", command["name"], "b2u_airplanes");
	back2uo\test\_assert::assert_eq("airplanes value", command["value"], "4");
	back2uo\test\_assert::assert_eq("airplanes password", command["password"], "secret");

	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_airplanes:4:a:b");
	back2uo\test\_assert::assert_eq("airplanes password keeps later colons", command["password"], "a:b");

	command = back2uo\_back2uo_admin::back2uo_admin_command("b2u_airplanes:secret");
	back2uo\test\_assert::assert_eq("airplanes without count reads password as count", command["value"], "secret");
	back2uo\test\_assert::assert_eq("airplanes without count has no password", command["password"], "");

	names[0] = "b2u_mortar";
	names[1] = "b2u_ambtracer";
	names[2] = "b2u_thunderfx";
	names[3] = "b2u_rainfx";
	names[4] = "b2u_snowfx";
	for(i = 0; i < names.size; i++)
	{
		command = back2uo\_back2uo_admin::back2uo_admin_command(names[i] + ":secret");
		back2uo\test\_assert::assert_true(names[i] + " is a command", isdefined(command));
		back2uo\test\_assert::assert_eq(names[i] + " password", command["password"], "secret");
	}

	back2uo\test\_assert::assert_true("menu response is no command", !isdefined(back2uo\_back2uo_admin::back2uo_admin_command("changeteam")));
	back2uo\test\_assert::assert_true("unknown command is no command", !isdefined(back2uo\_back2uo_admin::back2uo_admin_command("b2u_nuke:secret")));
}

/*
=============
test_admin_password

back2uo_admin_password_ok(): only the exact password, never while back2uo_admin_password is empty.
=============
*/
test_admin_password()
{
	saved = back2uo\test\_assert::cvar_save("back2uo_admin_password");

	setcvar("back2uo_admin_password", "");
	back2uo\test\_assert::assert_eq("empty admin password refuses empty", back2uo\_back2uo_admin::back2uo_admin_password_ok(""), false);

	setcvar("back2uo_admin_password", "secret");
	back2uo\test\_assert::assert_eq("right password", back2uo\_back2uo_admin::back2uo_admin_password_ok("secret"), true);
	back2uo\test\_assert::assert_eq("wrong password", back2uo\_back2uo_admin::back2uo_admin_password_ok("Secret"), false);
	back2uo\test\_assert::assert_eq("empty password", back2uo\_back2uo_admin::back2uo_admin_password_ok(""), false);

	back2uo\test\_assert::cvar_restore("back2uo_admin_password", saved);
}
