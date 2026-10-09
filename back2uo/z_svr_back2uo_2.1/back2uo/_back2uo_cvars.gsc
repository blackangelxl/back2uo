/*
	Back2Uo v2.1 - cvar readers and shared helper functions

	back2uo_setconfig() and back2uo_getcvardef() read the mod cvars (back2uomod.cfg) into
	game[] / level. variables; they are called from _back2uo_main.gsc and _back2uo_cod2set.gsc.
	The rest are small helpers used across the mod: player stance/movement checks, messages
	to all players, aim trace, vector helpers, log output (game["back2uo_logprint_enable"]),
	HUD client cvar resets and the per-player frag/smoke grenade limit checker.
*/

/*
=============
back2uo_favorite_menu

Fills the client's "add to favorites" menu with the server name (sv_hostname) and address
(net_ip), or disables the menu entry when level.favorite_menu is not 1.
Called on: self = player
=============
*/
back2uo_favorite_menu()
{
	if(!game["back2uo_add_favorite_enable"]) return;

	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("favoriten_menu", "self not exist");
		return;
	}

	if(isdefined(level.favorite_menu) && level.favorite_menu == 1)
	{
		server_name = getcvar("sv_hostname");
		server_ip = getcvar("net_ip");

		// Short waits spread the client cvar updates over several server frames
		self setClientCvar("ui_allow_favorite_server", 1);
		wait .05;
		self setClientCvar("ui_favoriteName", server_name);
		wait .05;
		self setClientCvar("ui_favoriteAddress", server_ip);
	}
	else
	{
		self setClientCvar("ui_allow_favorite_server", 0);
	}
}

/*
=============
back2uo_grana_smoke_checker

Enforces the frag and smoke grenade limits (level.back2uo_granaten_allow, level.back2uo_smoke_allow)
every 0.1 seconds. Allied and axis grenade types share one limit: grenades of one nation
reduce the allowance for the other (picked-up enemy grenades). If a count is above its
allowance, the clip is set back to the allowance.
The per-player allowances (self.back2uo_granaten_allow_*) are also used by
objects\_back2uo_grenadepickup::back2uo_grenadepickup().
Called on: self = player (threaded on spawn)
=============
*/
back2uo_grana_smoke_checker()
{
	if(!level.back2uo_smoke_grana_aktiv) return;

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self.back2uo_granaten_allow_allies = level.back2uo_granaten_allow;
	self.back2uo_granaten_allow_axis = level.back2uo_granaten_allow;
	self.back2uo_smoke_allow_allies = level.back2uo_smoke_allow;
	self.back2uo_smoke_allow_axis = level.back2uo_smoke_allow;

	for(;;)
	{
		// Frag grenades

		// Allied frags: clamp to allowance, otherwise reduce the axis allowance by this count
		granade_count_allies = maps\mp\gametypes\_weapons::getFragGrenadeCount("allies");
		if(granade_count_allies > self.back2uo_granaten_allow_allies)
		{
			granadetype = "frag_grenade_" + game["allies"] + "_mp" + level.back2uo_specialgranade;
			self giveWeapon(granadetype);
			self setWeaponClipAmmo(granadetype, self.back2uo_granaten_allow_allies);
		}
		else
		{
			self.back2uo_granaten_allow_axis = level.back2uo_granaten_allow;
			self.back2uo_granaten_allow_axis = self.back2uo_granaten_allow_axis - granade_count_allies;
		}

		// Axis frags: clamp to allowance, otherwise reduce the allied allowance by this count
		granade_count_axis = maps\mp\gametypes\_weapons::getFragGrenadeCount("axis");
		if(granade_count_axis > self.back2uo_granaten_allow_axis)
		{
			granadetype = "frag_grenade_" + game["axis"] + "_mp" + level.back2uo_specialgranade;
			self giveWeapon(granadetype);
			self setWeaponClipAmmo(granadetype, self.back2uo_granaten_allow_axis);
		}
		else
		{
			self.back2uo_granaten_allow_allies = level.back2uo_granaten_allow;
			self.back2uo_granaten_allow_allies = self.back2uo_granaten_allow_allies - granade_count_axis;
		}

		// Smoke grenades (same scheme as frags)

		smoke_count_allies = maps\mp\gametypes\_weapons::getSmokeGrenadeCount("allies");
		if(smoke_count_allies > self.back2uo_smoke_allow_allies)
		{
			smokegrenadetype = "smoke_grenade_" + game["allies"] + "_mp" + level.back2uo_specialsmoke;
			self giveWeapon(smokegrenadetype);
			self setWeaponClipAmmo(smokegrenadetype, self.back2uo_smoke_allow_allies);
		}
		else
		{
			self.back2uo_smoke_allow_axis = level.back2uo_smoke_allow;
			self.back2uo_smoke_allow_axis = self.back2uo_smoke_allow_axis - smoke_count_allies;
		}

		smoke_count_axis = maps\mp\gametypes\_weapons::getSmokeGrenadeCount("axis");
		if(smoke_count_axis > self.back2uo_smoke_allow_axis)
		{
			smokegrenadetype = "smoke_grenade_" + game["axis"] + "_mp" + level.back2uo_specialsmoke;
			self giveWeapon(smokegrenadetype);
			self setWeaponClipAmmo(smokegrenadetype, self.back2uo_smoke_allow_axis);
		}
		else
		{
			self.back2uo_smoke_allow_allies = level.back2uo_smoke_allow;
			self.back2uo_smoke_allow_allies = self.back2uo_smoke_allow_allies - smoke_count_axis;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_player_stance

Estimates the player's stance with two short horizontal traces through the player model
(at 60 and 40 units height). If the trace at a height hits nothing, the body is lower than
that height. CoD2 has no script function to read the stance directly.
Called on: self = player
Returns: "stand", "sprint" (self.pers["sprinting"]), "crouch" or "prone"
=============
*/
back2uo_player_stance()
{
	pos_type = "stand";

	if(isdefined(self.pers["sprinting"]) && self.pers["sprinting"] == true)
	{
		pos_type = "sprint";
	}

	if(isdefined(self.origin))
	{
		// 20 unit traces across the player, character hits enabled
		pose_crouch = bulletTrace( self.origin + ( 10, 0, 60 ), self.origin + ( -10, 0, 60 ), true, undefined );
		pose_prone = bulletTrace( self.origin + ( 10, 0, 40 ), self.origin + ( -10, 0, 40 ), true, undefined );

		// fraction 1 = trace hit nothing
		if(pose_crouch["fraction"] == 1) pos_type = "crouch";
		if(pose_prone["fraction"] == 1) pos_type = "prone";
	}

	return pos_type;
}

/*
=============
back2uo_player_moving

Compares the player's position over one server frame (0.05 seconds).
Called on: self = player
Returns: true if the player moved, false otherwise
=============
*/
back2uo_player_moving()
{
	user_move = true;

	self.old_posi = self.origin;

	// One server frame
	wait 0.05;

	if(self.old_posi == self.origin) user_move = false;

	return user_move;
}

/*
=============
back2uo_player_origin

Measures how far the player moved within one second (used by the anti-camping checks).
Called on: self = player
Returns: distance in units, or undefined if the player has no origin
=============
*/
back2uo_player_origin()
{
	if(!isdefined(self.origin)) return;

	firstorigin = self.origin;
	wait 1;
	secorigin = self.origin;

	player_origin = distance(firstorigin,secorigin);

	return player_origin;
}

/*
=============
back2uo_playeraction_msg

Prints a message with up to two parts in the message area of every player.
Params: text1 - localized string or text
		text2 - argument for text1 (e.g. a player entity for the name)
=============
*/
back2uo_playeraction_msg(text1, text2)
{
	if(!isdefined(text1)) text1 = "";
	if(!isdefined(text2)) text2 = "";

	players = getentarray("player", "classname");

	for(p = 0; p < players.size; p++)
	{
		user = players[p];

		user iprintln(text1, text2);
	}
}

/*
=============
back2uo_player_message

Prints a message with up to five parts in the message area of every player.
Params: text1..text5 - message parts (undefined parts become "")
=============
*/
back2uo_player_message(text1, text2, text3, text4, text5)
{
	if(!isdefined(text1)) text1 = "";
	if(!isdefined(text2)) text2 = "";
	if(!isdefined(text3)) text3 = "";
	if(!isdefined(text4)) text4 = "";
	if(!isdefined(text5)) text5 = "";

	players = getentarray("player", "classname");

	for(p = 0; p < players.size; p++)
	{
		user = players[p];

		user iprintln(text1, text2, text3, text4, text5);
	}
}

/*
=============
back2uo_player_messagebold

Prints a bold message in the center of the screen of every player.
Params: lstr - localized string
		wert - value inserted into lstr
=============
*/
back2uo_player_messagebold(lstr, wert)
{
	if(!isdefined(lstr)) lstr = "";
	if(!isdefined(wert)) wert = "";

	players = getentarray("player", "classname");

	for(p = 0; p < players.size; p++)
	{
		user = players[p];

		user iprintlnbold(lstr, wert);
	}
}

/*
=============
back2uo_setconfig

Reads a numeric server cvar, clamped to min/max. An unset cvar is created with the default.
While the mod is disabled (game["back2uo_enable"] 0) the cvar is reset to its default.
Params: wert - cvar name
		wertdefault - default value
		min - lower limit (0 = no limit)
		max - upper limit (0 = no limit)
		ui - unused
Returns: the cvar value (int when just created, otherwise float)
=============
*/
back2uo_setconfig(wert, wertdefault, min, max, ui)
{
	wert2 = wertdefault;
	if(!isDefined(game["back2uo_enable"])) game["back2uo_enable"] = 1;

	if(getcvar(wert) == "")
	{
		setCvar(wert, wertdefault);
		wert2 = getCvarInt(wert);
	}
	else
	{
		if(!(game["back2uo_enable"]))
		{
			setCvar(wert, wertdefault);
			wert2 = getCvarInt(wert);
		}else{
			wert2 = getcvarfloat(wert);
		}
	}

	if(min != 0 && wert2 < min)
		wert2 = min;

	if(max != 0 && wert2 > max)
		wert2 = max;

	return wert2;
}

/*
=============
back2uo_setui_var

Sets a cvar and marks it as serverinfo so clients can read it in the UI.
Only writes when the value changed or the cvar is empty.
Params: name - cvar name
		wert - value
=============
*/
back2uo_setui_var(name, wert)
{
	if(!isDefined(name) || !isDefined(wert)) return;

	if(getCvarInt(name) != wert || getCvar(name) == "")
	{
		makeCvarServerInfo(name, wert);
		setCvar(name, wert);
	}
}

/*
=============
back2uo_getcvardef

Reads a mod cvar with optional per-gametype and per-map overrides, IW style.
Lookup order: <name>_<gametype>, then <name>_<mapname>, then <name>_<gametype>_<mapname>;
each found override replaces the name, so later checks append to the already overridden name.
Numeric values are clamped to min/max (0 = no limit).
Params: varname - base cvar name
		vardefault - value used when the cvar is empty
		min, max - limits for "int"/"float"
		type - "int", "float" or "string"
Returns: the cvar value
=============
*/
back2uo_getcvardef(varname, vardefault, min, max, type)
{
	mapname = getcvar("mapname");		// "mp_dawnville", "mp_rocket", etc.
	gametype = getcvar("g_gametype");	// "tdm", "bel", etc.
	multigtmap = gametype + "_" + mapname;

	tempvar = varname + "_" + gametype;	// i.e., scr_teambalance becomes scr_teambalance_tdm
	if(getcvar(tempvar) != "") 		// if the gametype override is being used
		varname = tempvar; 		// use the gametype override instead of the standard variable

	tempvar = varname + "_" + mapname;	// i.e., scr_teambalance becomes scr_teambalance_mp_dawnville
	if(getcvar(tempvar) != "")		// if the map override is being used
		varname = tempvar;		// use the map override instead of the standard variable

	tempvar = varname + "_" + multigtmap;	// i.e., scr_teambalance becomes scr_teambalance_tdm_mp_dawnville
	if(getcvar(tempvar) != "")		// if the gametype+map override is being used
		varname = tempvar;		// use it instead of the standard variable

	switch(type)
	{
	case "int":
		if(getcvar(varname) == "")
			definition = vardefault;
		else
			definition = getcvarint(varname);
		break;

	case "float":
		if(getcvar(varname) == "")
			definition = vardefault;	// set the default
		else
			definition = getcvarfloat(varname);
		break;

	case "string":
	default:
		if(getcvar(varname) == "")
			definition = vardefault;
		else
			definition = getcvar(varname);
		break;
	}

	if((type == "int" || type == "float") && min != 0 && definition < min)
		definition = min;

	if((type == "int" || type == "float") && max != 0 && definition > max)
		definition = max;

	return definition;
}

/*
=============
back2uo_getarray

Reads a numbered cvar list <name>_0, <name>_1, ... until the first empty entry.
Params: name - cvar name prefix
Returns: array of cvar strings, or undefined if <name>_0 is empty
=============
*/
back2uo_getarray(name)
{
	nr = 0;
	msg = name + "_"  + nr;

	if(getcvar(msg) != "")
	{
		wert[nr] = getcvar(msg);
	}
	else
	{
		return;
	}

	while(1)
	{
		nr++;
		msg = name + "_" + nr;

		if(getcvar(msg) != "")
		{
			wert[nr] = getcvar(msg);
		}
		else
		{
			break;
		}
	}

	return wert;
}

/*
=============
back2uo_getpositarget

Traces from the player's eye along the view direction (100000 units) to find the aimed-at
point; used by the binocular distance HUD. The eye height is corrected by stance.
Called on: self = player
Returns: hit position, or undefined if nothing was hit or the surface is "default" (sky)
=============
*/
back2uo_getpositarget()
{
	geteyeextra = back2uo_geteyeoffset();
	startOrigin = self getEye() + geteyeextra;
	forward = anglesToForward( self getplayerangles() );
	forward = back2uo_vecscale( forward, 100000 );
	endOrigin = startOrigin + forward;

	// Ignore the player himself
	trace = bulletTrace( startOrigin, endOrigin, false, self );

	if (trace["fraction"] == 1 || trace["surfacetype"] == "default")
		return ( undefined );
	else
		return ( trace["position"] );
}

/*
=============
back2uo_vectorcheck

Params: vector - value to test
Returns: true if all three vector components are defined
=============
*/
back2uo_vectorcheck(vector)
{
	if(isdefined(vector[0]) && isdefined(vector[1]) && isdefined(vector[2]))
	{
		return true;
	}
	else
	{
		return false;
	}
}

/*
=============
back2uo_geteyeoffset

Offset added to getEye() so the result matches the real eye height for the current stance.
Called on: self = player
Returns: offset vector (stand 18, crouch 2, prone -27 units)
=============
*/
back2uo_geteyeoffset()
{
	offset = (0,0,18);

	player_stance = back2uo_player_stance();

	if(player_stance == "crouch") offset = (0,0,2);
	if(player_stance == "prone") offset = (0,0,-27);

	return offset;
}

/*
=============
back2uo_vecscale

Params: vec - vector
		scale - factor
Returns: vec multiplied by scale
=============
*/
back2uo_vecscale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);

	return vec;
}

/*
=============
back2uo_logprint

Writes "<name> <prob>" to the server log (games_mp.log) when game["back2uo_logprint_enable"] is set.
Used as debug trace throughout the mod.
Params: name - function or feature name
		prob - state text, e.g. "Run"
=============
*/
back2uo_logprint(name, prob)
{
	if(!game["back2uo_logprint_enable"]) return;

	logPrint(name, " ", prob, "\n");
}

/*
=============
back2uo_clear_triggerhud_elements

Hides the context icons that pickup and artillery triggers show on the client
(medic icon, weapon pickup, artillery target info).
Called on: self = player
=============
*/
back2uo_clear_triggerhud_elements()
{
	self setClientCvar("back2uo_ui_medicicon", 0);
	if(isdefined(self.back2uo_weaponpickup)) self.back2uo_weaponpickup.alpha = 0;
	self setClientCvar("back2uo_ui_weaponpickup_object", 0);

	self setClientCvar("back2uo_ui_artillery_name", 0);
	self setClientCvar("back2uo_ui_artillery_meters", 0);
	self setClientCvar("back2uo_ui_artillery_unknown", 0);
}

/*
=============
back2uo_hud_elements_draw

Shows the compass needle in the client UI (client cvar back2uo_ui_compasszeiger).
Called on: self = player
=============
*/
back2uo_hud_elements_draw()
{
	self setClientCvar("back2uo_ui_compasszeiger", 1);
}

/*
=============
back2uo_hud_elements_clear

Hides the compass needle in the client UI.
Called on: self = player
=============
*/
back2uo_hud_elements_clear()
{
	self setClientCvar("back2uo_ui_compasszeiger", 0);
}

/*
=============
back2uo_fx_run

Not in use. Development test hook (game["back2uo_development_enable"]): a double tap of the
melee button while on the ground starts the artillery effect, to test effects in game.
Called on: self = player
=============
*/
back2uo_fx_run()
{
	if(!game["back2uo_development_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Melee Button press", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(self meleeButtonPressed())
		{
			// Set once the button was released; a second press then counts as double tap
			catch_next = false;

			// Double tap window: about 11 iterations (each wait is at least one server frame)
			for(i=0; i<=0.10; i+=0.01)
			{
				if(catch_next && self meleeButtonPressed())
				{
					wait 0.1;

					if(self isOnground())
					{
						// Disabled: other test actions (drop weapon, health pack, turret, mortar)
						//self maps\mp\gametypes\_weapons::dropWeapon("mp40_mp");
						//self back2uo\objects\_back2uo_healthpacks::back2uo_dropHealthPacks();
						//back2uo\_back2uo_weaponsystem::back2uo_create_turret();
						//back2uo\warfx\_back2uo_mortar::back2uo_mortar_draw(self);
						thread back2uo\warfx\_back2uo_artillery::back2uo_artilleryfx_control();

						wait 1;

						break;
					}
					else if (!(self isOnGround()) && self meleeButtonPressed())
					{
						wait 1;
					}
				}
				else if(!(self meleeButtonPressed()))

					// Button released
					catch_next = true;

				wait 0.01;
			}
		}

		wait 0.05;
	}
}
