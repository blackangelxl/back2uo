/*
	Back2Uo v2.1 - Anti-play rules: Spawn protection.

	back2uo_antiplay_spawn_start() is threaded from _back2uo_player.gsc on spawn.
	Cvars (back2uomod.cfg): back2uo_antiplay_sp_*.
	Split from the former _back2uo_antiplay.gsc.
*/

/*
=============
back2uo_antiplay_spawn_start

Spawn protection. Runs one iteration per second (back2uo_player_origin waits 1 second) for
level.back2uo_antiplay_sp_time seconds and updates the spawn protection bar. While
self.back2uo_antiplay_sp_run is true the gametype damage callbacks ignore damage from
other players, and the artillery (warfx\_back2uo_artillery) skips this player.
With back2uo_antiplay_sp_move 1 the protection ends early when the player moves more than
50 units in a second or presses attack, melee or use.
Called on: self = player (threaded on spawn)
=============
*/
back2uo_antiplay_spawn_start()
{
	if(!game["back2uo_antiplay_sp_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Spawn Save", "Run");

	level endon("back2uo_killthreads");
	self endon("disconnect");

	// One protection thread per life: a thread of the last life must not end the
	// protection of the new one.
	self notify("back2uo_spawnprotection_start");
	self endon("back2uo_spawnprotection_start");
	self endon("killed_player");

	self.back2uo_spawntime = 0;
	// Allowed movement per second in units
	radius = 50;

	self iprintln(&"BACK2UOMOD_SPAWN_ENABLE_MSG");

	self.back2uo_antiplay_sp_run = true;

	// One iteration per second (the wait is inside back2uo_player_origin)
	for(self.back2uo_spawntime=0; self.back2uo_spawntime < level.back2uo_antiplay_sp_time; self.back2uo_spawntime++)
	{
		self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

		self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime);

		// Protection is waived on movement or action
		if(level.back2uo_antiplay_sp_move == 1)
		{
			if(isdefined(self_org) && self_org > radius || self attackButtonPressed() || self meleeButtonPressed() || self useButtonPressed())
			{
				// "1" = end of spawn protection, resets the bar
				self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime, "1");

				self iprintln(&"BACK2UOMOD_SPAWN_DISABLED_MSG");

				self.back2uo_antiplay_sp_run = false;

				return;
			}
		}
	}

	// Protection time is over
	self back2uo\hud\_back2uo_healthbar::back2uo_healthbar_spawn_prot(self.back2uo_spawntime, "1");

	self iprintln(&"BACK2UOMOD_SPAWN_DISABLED_MSG");

	self.back2uo_antiplay_sp_run = false;
}
