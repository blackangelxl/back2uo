/*
	Back2Uo v2.1 - Messages: "Next map" announcement.

	back2uo_nextmap_messages_draw() is threaded from _back2uo_tools.gsc.
	Uses the back2uo_mapmsg_* cvars.
	Split from the former _back2uo_messages.gsc.
*/

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
