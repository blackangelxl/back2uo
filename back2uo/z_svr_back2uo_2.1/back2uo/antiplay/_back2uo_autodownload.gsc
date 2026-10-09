/*
	Back2Uo v2.1 - Anti-play rules: Client autodownload notice.

	back2uo_client_autodownload_init() is threaded from _back2uo_player.gsc on connect.
	Cvar (back2uomod.cfg): back2uo_autodownload.
	Split from the former _back2uo_antiplay.gsc.
*/

/*
=============
back2uo_client_autodownload_init

Shows the "client autodownload disabled" notice to the player every 12 seconds.
The loop has no end condition other than the player entity going away.
Called on: self = player (threaded on connect)
=============
*/
back2uo_client_autodownload_init()
{
	if(!game["back2uo_autodownload_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Client Autodownload", "Run");

	for(;;)
	{
		if(isdefined(self)) self iprintlnbold(&"EXE_AUTODL_CLIENTDISABLED");

		wait 12;
	}
}
