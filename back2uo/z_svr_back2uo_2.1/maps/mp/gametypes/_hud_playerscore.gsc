/*
	Back2Uo v2.1 - stock player score HUD (top left icon, score / scorelimit)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from dm.gsc. dm.gsc notifies "update_playerhud_score" on a player and
	"update_allhud_score" on level to refresh the display.
	Back2Uo: with game["back2uo_playerscore_enable"] (cvar back2uo_playerscore, default 1) this stock
	HUD is skipped completely and back2uo\hud\_back2uo_playerscore.gsc draws the mod's own score display.
*/

/*
=============
init

Picks the allied/axis hud icons for the current map factions, precaches them and starts
the connect and refresh watchers.
Back2Uo: returns at once when the mod's own score HUD is enabled.
=============
*/
init()
{
	// Back2Uo: mod score HUD replaces this stock HUD ( 0 = stock | 1 = mod, default 1 ).
	if(game["back2uo_playerscore_enable"]) return;

	switch(game["allies"])
	{
	case "american":
		game["hudicon_allies"] = "hudicon_american";
		break;

	case "british":
		game["hudicon_allies"] = "hudicon_british";
		break;

	case "russian":
		game["hudicon_allies"] = "hudicon_russian";
		break;
	}

	// Axis is always german in CoD2.
	assert(game["axis"] == "german");
	game["hudicon_axis"] = "hudicon_german";

	precacheShader(game["hudicon_allies"]);
	precacheShader(game["hudicon_axis"]);
	precacheString(&"MP_SLASH");

	level thread onPlayerConnect();
	level thread onUpdateAllHUD();
}

/*
=============
onPlayerConnect

Creates the hidden icon, score and "/ scorelimit" hud elements (top left) for every connecting
player and starts the per-player refresh watchers.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		// Team icon, top left; archived = false keeps it out of killcam replays.
		player.hud_playericon = newClientHudElem(player);
		player.hud_playericon.horzAlign = "left";
		player.hud_playericon.vertAlign = "top";
		player.hud_playericon.x = 6;
		player.hud_playericon.y = 28;
		player.hud_playericon.archived = false;
		player.hud_playericon.alpha = 0;

		// Score value, right of the icon.
		player.hud_playerscore = newClientHudElem(player);
		player.hud_playerscore.horzAlign = "left";
		player.hud_playerscore.vertAlign = "top";
		player.hud_playerscore.x = 36;
		player.hud_playerscore.y = 26;
		player.hud_playerscore.font = "default";
		player.hud_playerscore.fontscale = 2;
		player.hud_playerscore.archived = false;
		player.hud_playerscore.alpha = 0;

		// "/ scorelimit"; x is moved by getScoreLimitPosition() to follow the score width.
		player.hud_playerscorelimit = newClientHudElem(player);
		player.hud_playerscorelimit.horzAlign = "left";
		player.hud_playerscorelimit.vertAlign = "top";
		player.hud_playerscorelimit.x = 49;
		player.hud_playerscorelimit.y = 26;
		player.hud_playerscorelimit.font = "default";
		player.hud_playerscorelimit.fontscale = 2;
		player.hud_playerscorelimit.archived = false;
		player.hud_playerscorelimit.label = (&"MP_SLASH");
		player.hud_playerscorelimit.alpha = 0;

		player.hidescore = true;

		player thread onJoinedTeam();
		player thread onJoinedSpectators();
		player thread onUpdatePlayerHUD();
	}
}

/*
=============
onJoinedTeam

Refreshes the score HUD when the player joins a team.
Called on: player
=============
*/
onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");

		self thread updatePlayerHUD();
	}
}

/*
=============
onJoinedSpectators

Refreshes (hides) the score HUD when the player goes to spectator.
Called on: player
=============
*/
onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");

		self thread updatePlayerHUD();
	}
}

/*
=============
onUpdatePlayerHUD

Refreshes this player's score HUD whenever "update_playerhud_score" is notified on the player.
Called on: player
=============
*/
onUpdatePlayerHUD()
{
	for(;;)
	{
		self waittill("update_playerhud_score");

		self thread updatePlayerHUD();
	}
}

/*
=============
onUpdateAllHUD

Refreshes the score HUD of all players whenever "update_allhud_score" is notified on level.
Called on: level
=============
*/
onUpdateAllHUD()
{
	for(;;)
	{
		self waittill("update_allhud_score");

		level thread updateAllHUD();
	}
}

/*
=============
updatePlayerHUD

Shows team icon, score and scorelimit for players in a team, hides everything for spectators.
The scorelimit part is only shown when level.scorelimit > 0.
Called on: player
=============
*/
updatePlayerHUD()
{
	if(isdefined(self.pers["team"]))
	{
		hudicon["allies"] = game["hudicon_allies"];
		hudicon["axis"] = game["hudicon_axis"];

		if(self.pers["team"] == "allies" || self.pers["team"] == "axis")
		{
			self.hud_playericon setShader(hudicon[self.pers["team"]], 24, 24);
			self.hud_playericon.alpha = 1;
			self.hud_playerscore setValue(self.score);
			self.hud_playerscore.alpha = 1;

			if(level.scorelimit > 0)
			{
				self.hud_playerscorelimit setValue(level.scorelimit);
				self.hud_playerscorelimit.x = getScoreLimitPosition(self.score);
				self.hud_playerscorelimit.alpha = 1;
			}
			else
				self.hud_playerscorelimit.alpha = 0;
		}
		else if(self.pers["team"] == "spectator")
		{
			self.hud_playericon.alpha = 0;
			self.hud_playerscore.alpha = 0;
			self.hud_playerscorelimit.alpha = 0;
		}
	}
}

/*
=============
updateAllHUD

Refreshes the score HUD of every connected player.
=============
*/
updateAllHUD()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] thread updatePlayerHUD();
}

/*
=============
getScoreLimitPosition

Computes the x position of the "/ scorelimit" text so it sits right of the score digits:
12 units per extra digit, plus 7 for a minus sign.
Params: score - the score shown in front of the limit
Returns: x offset in hud units (49 for a one-digit positive score)
=============
*/
getScoreLimitPosition(score)
{
	offset = 0;

	if(score < 0)
	{
		score = score * -1;
		offset = 7;
	}

	if(score >= 10000)
		offset += 48;
	else if(score >= 1000)
		offset += 36;
	else if(score >= 100)
		offset += 24;
	else if(score >= 10)
		offset += 12;

	return 49 + offset;
}
