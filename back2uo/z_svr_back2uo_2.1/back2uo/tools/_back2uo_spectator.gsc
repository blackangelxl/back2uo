/*
	Back2Uo v2.1 - Spectator spawn helper.
*/

/*
=============
back2uo_spawn_Spectator

Puts the player into spectator mode, optionally at a given position; otherwise at a
random mp_global_intermission spawnpoint. Clears shellshock and rumble first.
Called on: player
Params: origin - optional spawn position
		angles - optional view angles (both must be given to be used)
=============
*/
back2uo_spawn_Spectator(origin, angles)
{
	level endon("back2uo_killthreads");

	resettimeout();

	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator") self.statusicon = "";

	maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
}
