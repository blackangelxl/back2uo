/*
	Back2Uo v2.1 - admin commands from the player console.

	rcon cannot tell which player sent a command, so the admin commands are typed in the
	admin's own client console and checked against a password (cvar back2uo_admin_password,
	empty = commands disabled). After 3 wrong passwords the player is locked out:
		/openscriptmenu -1 b2u_artillery:<password>
			grants one artillery strike to the player who typed it
		/openscriptmenu -1 b2u_airplanes:<count>:<password>
			starts one airplane fly-over with 1-6 planes (0 = count from back2uo_airplanes_max_count)
		/openscriptmenu -1 b2u_mortar:<password>
			starts one mortar barrage
		/openscriptmenu -1 b2u_ambtracer:<password>
			starts one wave of ambient anti-air tracers
		/openscriptmenu -1 b2u_thunderfx:<password>
			plays one lightning flash with thunder
		/openscriptmenu -1 b2u_rainfx:<password>, b2u_snowfx:<password>
			turns rain / snow on or off for the current round (replaces the other weather)
	Handled by back2uo_admin_menuresponse() from maps\mp\gametypes\_menus::onMenuResponse.
	Results are written to the server log as "B2U;admin;..." (back2uo_logprint 1).
*/

/*
=============
back2uo_admin_menuresponse

Handles the admin console commands sent with /openscriptmenu. Wrong passwords are counted
per player (self.pers, so it holds over respawns); from 3 on every command is refused.
Called on: self = player (from maps\mp\gametypes\_menus::onMenuResponse)
Params: response - menu response, e.g. "b2u_artillery:secret"
Returns: true if the response was an admin command (the menu code then ignores it)
=============
*/
back2uo_admin_menuresponse(response)
{
	command = back2uo_admin_command(response);
	if(!isdefined(command)) return false;

	if(!isdefined(self.pers["back2uo_admin_fails"])) self.pers["back2uo_admin_fails"] = 0;

	if(self.pers["back2uo_admin_fails"] >= 3)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "command", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " cmd=" + command["name"] + " result=locked");
		self iprintln("Back2Uo: admin commands locked (too many wrong passwords)");
		return true;
	}

	if(!back2uo_admin_password_ok(command["password"]))
	{
		self.pers["back2uo_admin_fails"]++;
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "command", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " cmd=" + command["name"] + " result=badpassword fails=" + self.pers["back2uo_admin_fails"]);
		self iprintln("Back2Uo: wrong admin password");
		return true;
	}

	self.pers["back2uo_admin_fails"] = 0;

	switch(command["name"])
	{
	case "b2u_artillery": self back2uo_admin_artillery(); break;
	case "b2u_airplanes": self back2uo_admin_airplanes(command["value"]); break;
	case "b2u_mortar": self back2uo_admin_mortar(); break;
	case "b2u_ambtracer": self back2uo_admin_ambtracer(); break;
	case "b2u_thunderfx": self back2uo_admin_thunder(); break;
	case "b2u_rainfx": self back2uo_admin_weather("rain"); break;
	case "b2u_snowfx": self back2uo_admin_weather("snow"); break;
	}

	return true;
}

/*
=============
back2uo_admin_command

Splits an admin command at ":": "<name>:<password>" or "b2u_airplanes:<count>:<password>".
The password is the rest of the line, so it may contain ":" itself.
Params: response - menu response
Returns: array ["name"], ["value"] ("" except for b2u_airplanes), ["password"];
		undefined if it is no admin command
=============
*/
back2uo_admin_command(response)
{
	if(!isdefined(response)) return;

	name = "";
	for(i = 0; i < response.size; i++)
	{
		if(response[i] == ":") break;
		name += response[i];
	}

	switch(name)
	{
	case "b2u_artillery":
	case "b2u_airplanes":
	case "b2u_mortar":
	case "b2u_ambtracer":
	case "b2u_thunderfx":
	case "b2u_rainfx":
	case "b2u_snowfx":
		break;

	default:
		return;
	}

	// Skip the ":" after the name.
	i++;

	value = "";
	if(name == "b2u_airplanes")
	{
		for(; i < response.size; i++)
		{
			if(response[i] == ":") break;
			value += response[i];
		}

		i++;
	}

	password = "";
	for(; i < response.size; i++)
		password += response[i];

	command["name"] = name;
	command["value"] = value;
	command["password"] = password;

	return command;
}

/*
=============
back2uo_admin_password_ok

Params: password - password sent by the player
Returns: true if it matches back2uo_admin_password; always false while that cvar is empty
=============
*/
back2uo_admin_password_ok(password)
{
	admin_password = getcvar("back2uo_admin_password");

	if(admin_password == "") return false;

	return (password == admin_password);
}

/*
=============
back2uo_admin_artillery

Grants one artillery strike to the admin (binoculars + Use key, like the ranking reward).
Only while alive in a team.
Called on: self = player
=============
*/
back2uo_admin_artillery()
{
	if(!game["back2uo_artilleryfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "artillery", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=disabled");
		self iprintln("Back2Uo: artillery is disabled");
		return;
	}

	if(self.sessionstate != "playing" || !isdefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "artillery", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=notplaying");
		self iprintln("Back2Uo: artillery only while alive in a team");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "artillery", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=granted");
	self iprintln("Back2Uo: artillery strike granted (binoculars + Use)");

	self thread back2uo\warfx\_back2uo_artillery::back2uo_artilleryfx_control();
}

/*
=============
back2uo_admin_airplanes

Starts one airplane fly-over. Uses the same checks as the random fly-overs (airplanes
enabled, map large enough, no other fly-over running), see back2uo_airplanefx_play.
Called on: self = player (gets the messages)
Params: value - plane count as string
=============
*/
back2uo_admin_airplanes(value)
{
	count = back2uo_admin_airplanes_count(value);

	if(!isdefined(count))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "airplanes", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " value=" + value + " result=invalid");
		self iprintln("Back2Uo: airplane count must be 0-6");
		return;
	}

	if(!game["back2uo_airplanesfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "airplanes", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=disabled");
		self iprintln("Back2Uo: airplanes are disabled");
		return;
	}

	if(level.back2uo_airplanedimo_allow == 0)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "airplanes", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=mapsize");
		self iprintln("Back2Uo: map is too small for airplanes");
		return;
	}

	if(isdefined(level.back2uo_airplanefx_running) && level.back2uo_airplanefx_running)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "airplanes", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=running");
		self iprintln("Back2Uo: an airplane fly-over is already running");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "airplanes", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " count=" + count);

	if(count == 0) self iprintln("Back2Uo: airplane fly-over started");
	else self iprintln("Back2Uo: airplane fly-over started (" + count + " planes)");

	if(count == 0) level thread back2uo\warfx\_back2uo_airplane::back2uo_airplanefx_play();
	else level thread back2uo\warfx\_back2uo_airplane::back2uo_airplanefx_play(count);
}

/*
=============
back2uo_admin_mortar

Starts one mortar barrage (same as the random barrages, shell count from back2uo_mortar_max_count).
Called on: self = player (gets the messages)
=============
*/
back2uo_admin_mortar()
{
	if(!game["back2uo_mortarfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "mortar", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=disabled");
		self iprintln("Back2Uo: mortar is disabled");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "mortar", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=started");
	self iprintln("Back2Uo: mortar barrage started");

	level thread back2uo\warfx\_back2uo_mortar::back2uo_mortarfx_play();
}

/*
=============
back2uo_admin_ambtracer

Starts one wave of ambient anti-air tracers (count from back2uo_ambtracer_max_count).
Called on: self = player (gets the messages)
=============
*/
back2uo_admin_ambtracer()
{
	if(!game["back2uo_ambtracerfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "ambtracer", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=disabled");
		self iprintln("Back2Uo: ambient tracers are disabled");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "ambtracer", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=started");
	self iprintln("Back2Uo: ambient tracers started");

	level thread back2uo\warfx\_back2uo_ambtracer::back2uo_ambtracerfx_play();
}

/*
=============
back2uo_admin_thunder

Plays one lightning flash with thunder, also on maps without weather and on winter maps.
Called on: self = player (gets the messages)
=============
*/
back2uo_admin_thunder()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_thunderfx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "thunder", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=disabled");
		self iprintln("Back2Uo: thunder is disabled");
		return;
	}

	if(!isdefined(level.back2uo_playerdimo_xMin) || !isdefined(level.back2uo_playerdimo_yMin) || !isdefined(level.back2uo_mapdimo_zMax))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "thunder", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=nodimension");
		self iprintln("Back2Uo: thunder not possible, map dimension unknown");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "thunder", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " result=started");
	self iprintln("Back2Uo: lightning flash started");

	level thread back2uo\weatherfx\_back2uo_thunder::back2uo_lightningflash();
}

/*
=============
back2uo_admin_weather

Turns rain or snow on or off. If this weather is running it is stopped, otherwise the running
weather (if any) is stopped and this one started, also on maps that did not roll weather.
Lasts until the round ends; the next round uses the normal per-map weather again.
Called on: self = player (gets the messages)
Params: type - "rain" or "snow"
=============
*/
back2uo_admin_weather(type)
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_" + type + "fx_enable"])
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "weather", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " type=" + type + " result=disabled");
		self iprintln("Back2Uo: " + type + " is disabled");
		return;
	}

	running = false;
	if(isdefined(level.back2uo_weatherart) && level.back2uo_weatherart == type) running = true;

	// Stop the running weather loop; also ends the sd spawn weather (back2uo_weather_startup).
	level notify("back2uo_weather_stop");
	level.back2uo_weatherart = undefined;
	level.rain_startup = false;

	if(running)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("admin", "weather", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " type=" + type + " result=off");
		self iprintln("Back2Uo: " + type + " off");
		return;
	}

	level.back2uo_weatherart = type;

	back2uo\_back2uo_cvars::back2uo_logevent("admin", "weather", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " type=" + type + " result=on");
	self iprintln("Back2Uo: " + type + " on");

	level thread back2uo\weatherfx\_back2uo_weather::back2uo_weatherdraw(true);
}

/*
=============
back2uo_admin_airplanes_count

Params: value - plane count as string
Returns: count clamped to 1-6 (the formation has 6 slots), 0 for "0", undefined if not a number
=============
*/
back2uo_admin_airplanes_count(value)
{
	count = back2uo_admin_toint(value);
	if(!isdefined(count)) return;

	if(count > 6) count = 6;

	return count;
}

/*
=============
back2uo_admin_toint

Params: value - string
Returns: the value as int if it has only digits (max 4), otherwise undefined
=============
*/
back2uo_admin_toint(value)
{
	if(!isdefined(value) || value.size == 0 || value.size > 4) return;

	digits = "0123456789";
	num = 0;

	for(i = 0; i < value.size; i++)
	{
		digit = undefined;

		for(d = 0; d < digits.size; d++)
		{
			if(value[i] == digits[d])
			{
				digit = d;
				break;
			}
		}

		if(!isdefined(digit)) return;

		num = num * 10 + digit;
	}

	return num;
}
