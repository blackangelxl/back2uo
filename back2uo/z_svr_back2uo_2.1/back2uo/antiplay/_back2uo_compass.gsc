/*
	Back2Uo v2.1 - Anti-play rules: Enemy firing on the compass (not in use).

	These functions are not called anywhere.
	Split from the former _back2uo_antiplay.gsc.
*/

/*
=============
back2uo_compass_enemyfiring

Not in use. Every second starts back2uo_compass_enemyfiring_show() for each living player,
to show firing players as red dots on the enemy compass.
=============
*/
back2uo_compass_enemyfiring()
{
	if(!game["back2uo_compass_enemyfire"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Enemy Firing", "Run");

	while(1)
	{
		players = getentarray("player", "classname");

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player) && player.sessionstate == "playing")
			{
				player thread back2uo_compass_enemyfiring_show(player.clientid);
			}
		}

		wait 1;
	}
}

/*
=============
back2uo_compass_enemyfiring_show

Not in use. While the player holds the attack button, shows a compass objective at his
position to the enemy team (everyone in DM) for level.back2uo_compass_firefade * 0.3 seconds.
Uses the client id as objective number.
Called on: self = player
Params: player_id - client id of the player (objective number)
=============
*/
back2uo_compass_enemyfiring_show(player_id)
{
	// No trace call here: this function is started every second for every player

	// Already running for this player
	if(isdefined(self.pers["enemyfiring_nr"]) && self.pers["enemyfiring_nr"] == player_id) return;

	if(!isdefined(self.pers["enemyfiring_nr"])) self.pers["enemyfiring_nr"] = player_id;

	// The marker is shown to the opposing team
	if(getcvar("g_gametype") == "dm")
	{
		compass_enemyfiring_team  = "none";
	}
	else
	{
		if(self.pers["team"] == "allies")
		{
			compass_enemyfiring_team  = "axis";
		}
		else
		{
			compass_enemyfiring_team  = "allies";
		}
	}

	self endon("disconnect");
	self endon("killed_player");

	while(isdefined(self.pers["enemyfiring_nr"]))
	{
		if(isdefined(self.pers["enemyfiring_nr"]) && isdefined(self) && self attackButtonPressed())
		{
			objective_add(self.pers["enemyfiring_nr"], "current", self.origin, "gfx/custom/back2uo_compass_enemyfiring.tga");
			objective_team(self.pers["enemyfiring_nr"], compass_enemyfiring_team);

			if(back2uo\_back2uo_cvars::back2uo_logactive())
			{
				weapon = self getCurrentWeapon();
				if(!isdefined(weapon)) weapon = "none";

				back2uo\_back2uo_cvars::back2uo_logevent("compass", "fire_show", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " weapon=" + weapon + " objnum=" + self.pers["enemyfiring_nr"] + " visible_to=" + compass_enemyfiring_team + " fade=" + level.back2uo_compass_firefade + " pos=" + back2uo\_back2uo_cvars::back2uo_logvec(self.origin));
			}

			// Follow the player while the marker is visible
			for(i=0; i < level.back2uo_compass_firefade; i++)
			{
				if(isdefined(self.pers["enemyfiring_nr"])) objective_position(self.pers["enemyfiring_nr"], self.origin);

				wait 0.3;
			}

			if(isdefined(self.pers["enemyfiring_nr"]) && !self attackButtonPressed())
			{
				back2uo\_back2uo_cvars::back2uo_logevent("compass", "fire_hide", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " objnum=" + self.pers["enemyfiring_nr"]);

				objective_delete(self.pers["enemyfiring_nr"]);

				self.pers["enemyfiring_nr"] = undefined;
			}
		}
		else
		{
			// Hide the objective while not firing
			if(isdefined(self.pers["enemyfiring_nr"])) objective_state(self.pers["enemyfiring_nr"], "empty");
		}

		wait 0.1;
	}
}

/*
=============
back2uo_compass_enemyfiring_clear

Not in use. Removes the enemy firing compass objective of the player.
Called on: self = player
=============
*/
back2uo_compass_enemyfiring_clear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Enemy Firing", "Clear");

	if(isDefined(self.pers["enemyfiring_nr"]))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("compass", "fire_clear", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " objnum=" + self.pers["enemyfiring_nr"]);

		objective_delete(self.pers["enemyfiring_nr"]);

		self.pers["enemyfiring_nr"] = undefined;
	}
}
