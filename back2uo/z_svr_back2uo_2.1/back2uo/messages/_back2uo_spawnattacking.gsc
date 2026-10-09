/*
	Back2Uo v2.1 - Messages: Spawn protection warning for attackers.

	back2uo_spawn_attacking() is called from the gametype Callback_PlayerDamage handlers.
	Split from the former _back2uo_messages.gsc.
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
