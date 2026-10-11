/*
	Back2Uo v2.1 - The mod's bonus/penalty score system. Called from the hooks in
	maps\mp\gametypes\*.gsc.
*/

/*
=============
back2uo_playerpoints_waitdefending

Waits for "bomb_exploded" on the player and awards the bomb defense bonus once
(the notify "give_defendingpoint" ends this thread via its own endon).
Called on: player
=============
*/
back2uo_playerpoints_waitdefending()
{
	level endon("back2uo_killthreads");
	level endon("round_ended");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	// Ensures the bonus is given only once.
	self endon("give_defendingpoint");

	for (;;)
	{
		self waittill("bomb_exploded");

		// Note: back2uo_playerpoints_system has no "bomb_defense" case, so the bonus is 0.
		self back2uo_playerpoints_system("bomb_defense");

		self notify("give_defendingpoint");
	}
}

/*
=============
back2uo_playerpoints_system

Adds the mod's objective bonus points to the player's score and prints a message.
Bonus values come from level.back2uo_sd_plant_points, level.back2uo_sd_defuse_points,
level.back2uo_captureflag and level.back2uo_defendsflag.
Called on: player (from the sd.gsc / ctf.gsc hooks)
Params: wert - event: "bomb_planted", "bomb_defused", "flag_capture", "flag_defending"
=============
*/
back2uo_playerpoints_system(wert)
{
	if(!game["back2uo_enable"]) return;

	if(!game["back2uo_playerpoints_enable"]) return;

	if(!isdefined(wert)) return;

	bonus = 0;
	text = "";
	msg = "";

	switch(wert)
	{
	case "bomb_planted":
		bonus = level.back2uo_sd_plant_points;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_PLANT";
		break;

	case "bomb_defused":
		bonus = level.back2uo_sd_defuse_points;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_DEFUSE";
		break;

	case "flag_capture":
		bonus = level.back2uo_captureflag;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_CAPTURE";
		break;

	case "flag_defending":
		bonus = level.back2uo_defendsflag;
		msg = &"BACK2UOMOD_RANKINGPOINTS_FOR_DEFENDING";
		break;
	}

	// pers["score"] survives rounds; score is the scoreboard value.
	self.pers["score"] = self.pers["score"] + bonus;
	self.score = self.pers["score"];

	if(bonus != 0)
	{
		self iprintln(&"BACK2UOMOD_RANKINGPOINTS_ADD", msg);
	}
}

/*
=============
back2uo_givepoints_toplayer

Gives survival bonus points to every living player of a team.
Params: team - "allies" or "axis"
		points - points to add
=============
*/
back2uo_givepoints_toplayer(team, points)
{
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isAlive(player) && player.pers["team"] == team)
		{
			player.pers["score"] = player.pers["score"] + points;
			player.score = player.pers["score"];

			if(points != 0)
			{
				player iprintln(&"BACK2UOMOD_RANKINGPOINTS_ADD", &"BACK2UOMOD_RANKINGPOINTS_FOR_SURVIVE");
			}
		}
	}
}

/*
=============
back2uo_losepoints_ofplayer

Subtracts penalty points from the player (suicide / teamkill, called from the
gametype Callback_PlayerKilled hooks) and prints a message.
Called on: player
Params: points - points to subtract
=============
*/
back2uo_losepoints_ofplayer(points)
{
	if(!isdefined(points)) return;

	if(isdefined(self))
	{
		if(isdefined(self.pers["score"]))
		{
			self.pers["score"] = self.pers["score"] - points;
			self.score = self.pers["score"];
		}
		else
		{
			self.score = self.score - points;
		}

		// Note: the message always says "suicide", also for teamkills.
		if(points != 0)
		{
			self iprintln(&"BACK2UOMOD_RANKINGPOINTS_SUB", &"BACK2UOMOD_RANKINGPOINTS_FOR_SUICIDE");
		}
	}
}
