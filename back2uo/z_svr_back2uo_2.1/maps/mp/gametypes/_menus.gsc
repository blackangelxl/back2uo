/*
	Back2Uo v2.1 - menu registration and menu response dispatcher

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called once per map from the gametype scripts; it picks the menu names into
	game["menu_*"], precaches them and starts onPlayerConnect(). Every player then runs
	onMenuResponse(), which routes "menuresponse" notifies to the gametype callbacks
	level.allies / level.axis / level.autoassign / level.spectator / level.weapon.
	Uses game["back2uo_enable"], game["back2uo_weaponsystem_enable"], game["back2uo_serverinfo_join"]
	and level.back2uo_weapon_limit (cvar back2uo_weapons_allow).
*/

/*
=============
init

Selects and precaches all menus for this gametype and map. With the Back2Uo weapon
system enabled, the stock weapon menus are replaced by the mod's menus, optionally
limited to one weapon class.
Called on: level
=============
*/
init()
{
	game["menu_ingame"] = "ingame";
	game["menu_team"] = "team_" + game["allies"] + game["axis"];
	game["menu_weapon_allies"] = "weapon_" + game["allies"];
	game["menu_weapon_axis"] = "weapon_" + game["axis"];

	// Back2Uo: replace the stock weapon menus with the mod's weapon menus.
	if(game["back2uo_enable"] && game["back2uo_weaponsystem_enable"])
	{
		// level.back2uo_weapon_limit (cvar back2uo_weapons_allow) picks the allowed weapon class.
		// Limited modes use one shared menu for both teams.
		if(level.back2uo_weapon_limit == 0) // All weapons, per-nation menu
		{
			game["menu_weapon_allies"] = "weapons_" + game["allies"];
			game["menu_weapon_axis"] = "weapons_" + game["axis"];
		}
		else if(level.back2uo_weapon_limit == 1) // Machine guns only
		{
			game["menu_weapon_allies"] = "weapons_only_mg";
			game["menu_weapon_axis"] = "weapons_only_mg";
		}
		else if(level.back2uo_weapon_limit == 2) // Rifles only
		{
			game["menu_weapon_allies"] = "weapons_only_rifle";
			game["menu_weapon_axis"] = "weapons_only_rifle";
		}
		else if(level.back2uo_weapon_limit == 3) // Sniper rifles only
		{
			game["menu_weapon_allies"] = "weapons_only_sniper";
			game["menu_weapon_axis"] = "weapons_only_sniper";
		}
		else if(level.back2uo_weapon_limit == 4) // Pistols only
		{
			game["menu_weapon_allies"] = "weapons_only_pistol";
			game["menu_weapon_axis"] = "weapons_only_pistol";
		}
	}

	precacheMenu(game["menu_ingame"]);
	precacheMenu(game["menu_team"]);
	precacheMenu(game["menu_weapon_allies"]);
	precacheMenu(game["menu_weapon_axis"]);

	if(!level.xenon)
	{
		// Back2Uo: server info menus.
		if(game["back2uo_enable"])
		{
			// Mod info menu, opened from the ingame menu ("serverinfos" response).
			game["menu_serverinfos"] = "serverinfos_mod_" + getCvar("g_gametype");
			precacheMenu(game["menu_serverinfos"]);

			// Info menu shown on join: stock one, or the mod's version if back2uo_serverinfo_aktiv is set.
			game["menu_serverinfo"] = "serverinfo_" + getCvar("g_gametype");

			if(game["back2uo_serverinfo_join"])
			{
				game["menu_serverinfo"] = "serverinfo_mod_" + getCvar("g_gametype");
			}
		}
		else
		{
			game["menu_serverinfo"] = "serverinfo_" + getCvar("g_gametype");
		}

		game["menu_callvote"] = "callvote";
		game["menu_muteplayer"] = "muteplayer";

		precacheMenu(game["menu_serverinfo"]);
		precacheMenu(game["menu_callvote"]);
		precacheMenu(game["menu_muteplayer"]);
	}
	else
	{
		// Console (Xbox 360) build only: splitscreen menu variants.
		level.splitscreen = isSplitScreen();
		if(level.splitscreen)
		{
			game["menu_team"] += "_splitscreen";
			game["menu_weapon_allies"] += "_splitscreen";
			game["menu_weapon_axis"] += "_splitscreen";
			game["menu_ingame_onteam"] = "ingame_onteam_splitscreen";
			game["menu_ingame_spectator"] = "ingame_spectator_splitscreen";

			precacheMenu(game["menu_team"]);
			precacheMenu(game["menu_weapon_allies"]);
			precacheMenu(game["menu_weapon_axis"]);
			precacheMenu(game["menu_ingame_onteam"]);
			precacheMenu(game["menu_ingame_spectator"]);
		}
	}

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Starts the menu response handler for every connecting player.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player thread onMenuResponse();
	}
}

/*
=============
onMenuResponse

Endless loop that handles the player's menu responses ("menuresponse" notify from
scriptMenuResponse in the .menu files) and opens the next menu or calls the
gametype's team/weapon callbacks.
Called on: player
=============
*/
onMenuResponse()
{
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		// Disabled: debug print of every menu response.
		//iprintln("^6", response);

		// "back" steps one menu back: team menu -> ingame menu, weapon menu -> team menu.
		if(response == "back")
		{
			self closeMenu();
			self closeInGameMenu();

			if(menu == game["menu_team"])
			{
				if(level.splitscreen)
				{
					if(self.pers["team"] == "spectator")
						self openMenu(game["menu_ingame_spectator"]);
					else
						self openMenu(game["menu_ingame_onteam"]);
				}
				else
					self openMenu(game["menu_ingame"]);
			}
			else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
				self openMenu(game["menu_team"]);

			continue;
		}

		// "endgame" only has an effect on console builds (splitscreen / Xbox Live party).
		if(response == "endgame")
		{
			if(level.splitscreen)
			{
				level thread [[level.endgameconfirmed]]();
			}
			else if (level.xenon)
			{
				endparty();
				level thread [[level.endgameconfirmed]]();
			}

			continue;
		}

		// Back2Uo: like "endgame" only on console builds; on PC any client could end the map with /mr.
		if(response == "endround")
		{
			if(level.splitscreen || level.xenon)
				level thread [[level.endgameconfirmed]]();

			continue;
		}

		if(menu == game["menu_ingame"] || (level.splitscreen && (menu == game["menu_ingame_onteam"] || menu == game["menu_ingame_spectator"])))
		{
			switch(response)
			{
			// Back2Uo: open the mod's server info menu (only exists while the mod is enabled).
			case "serverinfos":
				if(isdefined(game["menu_serverinfos"]))
				{
					self closeMenu();
					self closeInGameMenu();
					self openMenu(game["menu_serverinfos"]);
				}
				break;

			case "changeweapon":
				self closeMenu();
				self closeInGameMenu();
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;

			case "changeteam":
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_team"]);
				break;

			case "muteplayer":
				if(!level.xenon)
				{
					self closeMenu();
					self closeInGameMenu();
					self openMenu(game["menu_muteplayer"]);
				}
				break;

			case "callvote":
				if(!level.xenon)
				{
					self closeMenu();
					self closeInGameMenu();
					self openMenu(game["menu_callvote"]);
				}
				break;
			}
		}
		else if(menu == game["menu_team"])
		{
			// Back2Uo: "auto team only" (back2uo_autoteam_change) is also enforced here, the team
			// menu only hides the buttons and a client can still send allies/axis with /mr.
			if(game["back2uo_enable"] && game["back2uo_autoteam_changeallow_enable"])
			{
				if(response == "allies" || response == "axis") response = "autoassign";
			}

			// Team selection: hand over to the gametype's team callbacks.
			switch(response)
			{
			case "allies":
				self closeMenu();
				self closeInGameMenu();
				self [[level.allies]]();
				break;

			case "axis":
				self closeMenu();
				self closeInGameMenu();
				self [[level.axis]]();
				break;

			case "autoassign":
				self closeMenu();
				self closeInGameMenu();
				self [[level.autoassign]]();
				break;

			case "spectator":
				self closeMenu();
				self closeInGameMenu();
				self [[level.spectator]]();
				break;
			}
		}
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			// The response is the chosen weapon name; level.weapon validates and assigns it.
			self closeMenu();
			self closeInGameMenu();
			self [[level.weapon]](response);
		}
		else if(!level.xenon)
		{
			// Quick chat menus (game["menu_quick*"] are set in _quickmessages.gsc).
			if(menu == game["menu_quickcommands"])
				maps\mp\gametypes\_quickmessages::quickcommands(response);
			else if(menu == game["menu_quickstatements"])
				maps\mp\gametypes\_quickmessages::quickstatements(response);
			else if(menu == game["menu_quickresponses"])
				maps\mp\gametypes\_quickmessages::quickresponses(response);
			else if(menu == game["menu_quicktaunts"])
				maps\mp\gametypes\_quickmessages::quicktaunts(response);
			else if(menu == game["menu_serverinfo"] && response == "close")
			{
				// Closing the join info menu leads to team selection; self.pers["skipserverinfo"] stops it from being shown again.
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_team"]);
				self.pers["skipserverinfo"] = true;
			}
		}
	}
}
