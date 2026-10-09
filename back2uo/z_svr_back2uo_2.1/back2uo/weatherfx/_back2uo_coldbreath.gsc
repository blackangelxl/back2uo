/*
	Back2Uo v2.1 - Cold breath effect in front of the player on winter maps.

	Player entry point (from back2uo_player_spawn): back2uo_coldbreath_draw.
	Split from the former _back2uo_weatherfx.gsc.
	Cvars/flags: game["back2uo_weatherfx_enable"], game["back2uo_rainfx_enable"], game["back2uo_snowfx_enable"],
	game["back2uo_thunderfx_enable"], game["back2uo_coldbreath_enable"], level.back2uo_weatherfx_strength.
*/

/*
=============
back2uo_coldbreath_draw

Winter maps only: shows a cold breath puff at the player's eyes every 2.5-4.5 seconds
while the player stands (nearly) still. back2uo_player_origin waits 1 second and returns
the distance moved, so "< 15" means almost no movement.
Note: self_org is only refreshed in the outer loop, so once breathing starts it continues
until the player dies or leaves the "playing" state, even if the player starts moving.
Called on: self = player
=============
*/
back2uo_coldbreath_draw()
{
	if(!game["back2uo_weatherfx_enable"] || !game["back2uo_coldbreath_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Cold Breath Draw", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
	{
		for(;;)
		{
			// Distance moved during the last second (blocks for 1 second).
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			while(isdefined(self) && self_org < 15 && isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
			{
				// Effect is attached to the eye tag so it follows the head.
				playfxontag (level.back2uo_breathfx, self, "TAG_EYE");

				wait randomfloatrange(2.5,4.5);
			}

			wait 0.1;
		}
	}
}
