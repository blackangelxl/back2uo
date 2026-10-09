/*
	Back2Uo v2.1 - Messages: Repeating clan messages.

	back2uo_clan_messages_draw() is threaded once from _back2uo_player.gsc.
	Uses game["back2uo_clanmsg"].
	Split from the former _back2uo_messages.gsc.
*/

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
