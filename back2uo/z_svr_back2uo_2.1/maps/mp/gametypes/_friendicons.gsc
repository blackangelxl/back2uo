/*
	Back2Uo v2.1 - Friendly head icons above team mates

	Shows a head icon above every living team player that only the own team can see.
	init() is threaded by the team gametypes (tdm, sd, ctf, hq). Back2Uo replaces the stock
	scr_drawfriend switch with game["back2uo_friendicon_enable"] (cvar back2uo_friendicon) and,
	when the ranking system is on (game["back2uo_ranking_enable"] and back2uo_teamrankheadicons),
	shows the player's ranking icon self.pers["back2uo_head_ranking_pic"] instead of the national icon.
	The per-player ranking icon is set in back2uo\hud\_back2uo_ranking.gsc.
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
init

Chooses the head icons per team, starts the spawn / death watchers and then checks
the friend icon cvar every 5 seconds.
Called on: level
=============
*/
init()
{
	// Back2Uo: with team ranking head icons both teams start with the level 1 ranking icon
	// (stored on level.pers here; each player's own icon is set later by the ranking code).
	if(game["back2uo_ranking_enable"] && level.back2uo_teamrankheadicons == 1)
	{
		switch(game["allies"])
		{
		case "american":
			self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_lv1.tga";
			game["headicon_allies"] = self.pers["back2uo_head_ranking_pic"];
			break;

		case "british":
			self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_lv1.tga";
			game["headicon_allies"] = self.pers["back2uo_head_ranking_pic"];
			break;

		case "russian":
			self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_lv1.tga";
			game["headicon_allies"] = self.pers["back2uo_head_ranking_pic"];
			break;
		}

		assert(game["axis"] == "german");
		self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_lv1.tga";
		game["headicon_axis"] = self.pers["back2uo_head_ranking_pic"];
	}
	else
	{
		// Stock national head icons
		switch(game["allies"])
		{
		case "american":
			game["headicon_allies"] = "headicon_american";
			precacheHeadIcon(game["headicon_allies"]);
			break;

		case "british":
			game["headicon_allies"] = "headicon_british";
			precacheHeadIcon(game["headicon_allies"]);
			break;

		case "russian":
			game["headicon_allies"] = "headicon_russian";
			precacheHeadIcon(game["headicon_allies"]);
			break;
		}

		assert(game["axis"] == "german");
		game["headicon_axis"] = "headicon_german";
		precacheHeadIcon(game["headicon_axis"]);
	}

	level thread onPlayerConnect();

	for(;;)
	{
		updateFriendIconSettings();
		wait 5;
	}
}

/*
=============
onPlayerConnect

Starts the spawn and death watchers for every connecting player.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player thread onPlayerSpawned();
		player thread onPlayerKilled();
	}
}

/*
=============
onPlayerSpawned

Shows the friend icon each time the player spawns.
Called on: player
=============
*/
onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		self thread showFriendIcon();
	}
}

/*
=============
onPlayerKilled

Removes the head icon when the player dies.
Called on: player
=============
*/
onPlayerKilled()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("killed_player");
		self.headicon = "";
	}
}

/*
=============
showFriendIcon

Sets the player's head icon and restricts its visibility to the own team
(headiconteam). Does nothing when back2uo_friendicon is off.
Called on: player
=============
*/
showFriendIcon()
{
	// Back2Uo: replaces the stock level.drawfriend check
	if(game["back2uo_friendicon_enable"])
	{
		// Back2Uo: ranking head icon instead of the national icon
		if(game["back2uo_ranking_enable"] && level.back2uo_teamrankheadicons)
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = self.pers["back2uo_head_ranking_pic"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = self.pers["back2uo_head_ranking_pic"];
				self.headiconteam = "axis";
			}
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
	}
}

/*
=============
updateFriendIconSettings

Back2Uo: reads the back2uo_friendicon cvar and refreshes all head icons when it differs
from game["back2uo_friendicon_enable"]. Note that game["back2uo_friendicon_enable"] itself
is not updated here, only level.drawfriend.
=============
*/
updateFriendIconSettings()
{

	drawfriend = getCvarFloat("back2uo_friendicon");
	if(game["back2uo_friendicon_enable"] != drawfriend)
	{
		level.drawfriend = drawfriend;

		updateFriendIcons();
	}
}

/*
=============
updateFriendIcons

Re-applies (or removes) the head icon of every living team player according to
game["back2uo_friendicon_enable"] and the ranking icon setting.
=============
*/
updateFriendIcons()
{

	// For all living players, show the appropriate headicon
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
		{
			if(game["back2uo_friendicon_enable"])
			{
				// Back2Uo: ranking head icon instead of the national icon.
				// Note: reads self.pers (the caller), not player.pers.
				if(game["back2uo_ranking_enable"] && level.back2uo_teamrankheadicons)
				{
					if(player.pers["team"] == "allies")
					{
						player.headicon = self.pers["back2uo_head_ranking_pic"];
						player.headiconteam = "allies";
					}
					else
					{
						player.headicon = self.pers["back2uo_head_ranking_pic"];
						player.headiconteam = "axis";
					}
				}
				else
				{
					if(player.pers["team"] == "allies")
					{
						player.headicon = game["headicon_allies"];
						player.headiconteam = "allies";
					}
					else
					{
						player.headicon = game["headicon_axis"];
						player.headiconteam = "axis";
					}
				}
			}
			else
			{
				// Icons disabled: clear them for all living players.
				// Note: reuses i and players of the outer loop.
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];

					if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
						player.headicon = "";
				}
			}
		}
	}
}
