/*
	Back2Uo v2.1 - Player and server text messages

	Prints the mod's chat/center-screen messages: spawn protection warning for attackers,
	welcome messages, repeating clan messages and the "next map" announcement.
	Called from _back2uo_player.gsc (welcome, clan), _back2uo_tools.gsc (next map) and the
	gametype Callback_PlayerDamage handlers (spawn attack warning).
	Uses game["back2uo_wellmsg"], game["back2uo_clanmsg"] and the back2uo_mapmsg_* cvars.
*/

/*
=============
back2uo_spawn_attacking

Tells an attacker that the player he shot is still spawn protected.
The message is throttled to once every 2 seconds per attacker.
Called on: self = attacking player
=============
*/
back2uo_spawn_attacking()
{
	if(level.back2uo_antiplay_sp_msg == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Spawn Attacking Msg", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	if(isDefined(self.back2uo_spawn_att)) return;
	self.back2uo_spawn_att = true;

	if(isPlayer(self))
	{
		self iprintln(&"BACK2UOMOD_SPAWN_PLAYER_ATTACKE");
	}

	wait 2;

	self.back2uo_spawn_att = undefined;
}

/*
=============
back2uo_wellc_messages_draw

Shows the configured welcome messages (game["back2uo_wellmsg"]) to the player
as bold center-screen text, 3 seconds apart. Only runs once per player per map.
Called on: self = player
=============
*/
back2uo_wellc_messages_draw()
{
	if(!game["back2uo_wellm_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Wellcome Msg", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	if(isdefined(self.pers["wellcome_msg"])) return;
	self.pers["wellcome_msg"] = true;

	msg_count_welc = 0;

	while(isdefined(game["back2uo_wellmsg"]) && msg_count_welc < game["back2uo_wellmsg"].size)
	{
		welmsg = game["back2uo_wellmsg"][msg_count_welc];

		if(isdefined(welmsg))
		{
			self iprintlnbold(welmsg);

			wait 3;
		}

		msg_count_welc++;

		if(msg_count_welc == game["back2uo_wellmsg"].size) break;

		wait 0.05;
	}
}

/*
=============
back2uo_clan_messages_draw

Broadcasts the clan messages (game["back2uo_clanmsg"]) to all players in an
endless loop, waiting level.back2uo_clanmrepeatwait seconds between passes.
game["clanout"] marks that the first pass already happened, so later calls wait first.
Called on: self = level (started once from back2uo_start_gametype)
=============
*/
back2uo_clan_messages_draw()
{
	if(!game["back2uo_clanm_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Clan Msg", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	for(;;)
	{
		// First pass runs immediately; every later pass waits for the repeat delay.
		if(isdefined(game["clanout"])) wait level.back2uo_clanmrepeatwait;
		game["clanout"] = true;

		msg_count_clan = 0;

		while(isdefined(game["back2uo_clanmsg"]) && msg_count_clan < game["back2uo_clanmsg"].size)
		{
			clanmsg = game["back2uo_clanmsg"][msg_count_clan];

			if(isdefined(clanmsg))
			{
				back2uo\_back2uo_cvars::back2uo_player_message("",clanmsg);

				wait 3;
			}

			msg_count_clan++;

			if(msg_count_clan == game["back2uo_clanmsg"].size) break;

			wait 0.05;
		}
	}
}

/*
=============
back2uo_nextmap_messages_draw

Periodically broadcasts the next map (and optionally gametype) to all players.
Repeats every level.back2uo_mapmsg_delay seconds; with back2uo_mapmsg_loop != 1 it is shown only once
per map (game["mapmsg_loop"]).
Called on: self = level (via back2uo_getmaprotation_control)
Params: x - map rotation struct from back2uo_getmaprotation(); x.maps[0] is the next entry
=============
*/
back2uo_nextmap_messages_draw(x)
{
	if(!game["back2uo_mapmsg_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Next Map Msg", "Run");

	if(!isdefined(x)) return;

	level endon("back2uo_killthreads");
	level endon("kill_endround");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	maps = undefined;

	if(isdefined(x.maps)) maps = x.maps;

	for(;;)
	{
		if(isdefined(game["mapmsg_loop"])) return;
		if(level.back2uo_mapmsg_loop != 1) game["mapmsg_loop"] = true;

		// Delay between announcements, from the back2uo_mapmsg_delay cvar.
		wait level.back2uo_mapmsg_delay;

		if(isdefined(maps))
		{
			level.back2uo_nextmap = maps[0]["map"];

			if(isdefined(maps[0]["gametype"]))
			{
				level.back2uo_nextgt = maps[0]["gametype"];
			}
			else
			{
				level.back2uo_nextgt = getcvar("g_gametype");
			}
		}

		// Type 1: map name only.
		if(level.back2uo_mapmsg_maptype == 1)
		{
			if(isdefined(level.back2uo_nextmap))
			{
				lstr = &"BACK2UOMOD_NEXT_MAP";

				wert_map = back2uo\_back2uo_tools::back2uo_get_mapname(level.back2uo_nextmap);

				back2uo\_back2uo_cvars::back2uo_player_message(lstr, wert_map, " ^7)");
			}
		}

		// Type 2: map name and gametype name.
		if(level.back2uo_mapmsg_maptype == 2)
		{
			if(isdefined(level.back2uo_nextmap) && isdefined(level.back2uo_nextgt))
			{
				lstr = &"BACK2UOMOD_NEXT_MAP";

				wert_map = back2uo\_back2uo_tools::back2uo_get_mapname(level.back2uo_nextmap);
				wert_gt = back2uo\_back2uo_tools::back2uo_get_gametypename(level.back2uo_nextgt);

				back2uo\_back2uo_cvars::back2uo_player_message(lstr, wert_map, " ^7-^2 ", wert_gt, " ^7)");
			}
		}

		wait 0.1;
	}
}
