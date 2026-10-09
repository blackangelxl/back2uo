/*
	Back2Uo v2.1 - Messages: Welcome messages on spawn.

	back2uo_wellc_messages_draw() is threaded from _back2uo_player.gsc on spawn.
	Uses game["back2uo_wellmsg"].
	Split from the former _back2uo_messages.gsc.
*/

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
