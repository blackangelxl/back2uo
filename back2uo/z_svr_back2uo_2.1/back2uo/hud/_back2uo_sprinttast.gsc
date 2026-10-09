/*
	Back2Uo v2.1 - Info message when the sprint key is pressed but sprinting is not possible.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_sprinttast_msg

Tells the player why sprinting is not possible when he holds the use key (sprint key)
while moving with a Panzerschreck, while not standing, while busy (plant/defuse/binoculars)
or right after a weapon pickup. Repeats at most every 5 seconds.
Called on: self = player
=============
*/
back2uo_sprinttast_msg()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	if(level.back2uo_sprint_infomsg != 1) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sprint Info Msg", "Run");

	level endon("back2uo_killthreads");
	level endon("round_ended");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		positype = back2uo\_back2uo_cvars::back2uo_player_stance();

		// Only warn when the sprint key is pressed while moving.
		if(isPlayer(self) && self useButtonPressed() && self.pers["is_moving"])
		{
			// Sprint not possible: wrong weapon, not standing, busy or just picked up a weapon.
			if(self getcurrentweapon() == "panzerschreck_mp" || (positype != "stand" && positype != "sprint") || self.back2uo_playerdo != "none" || self.pers["weapon_pickupsprintwait"] == true)
			{
				// Planting or defusing also uses the use key, so skip the message.
				if(self.back2uo_playerdo == "plant" || self.back2uo_playerdo == "defuse")
				{
					wait 1;
				}
				else
				{
					self iprintln(level.back2uo_nosprint_msg);

					wait 5;
				}
			}
		}

		wait 0.1;
	}
}
