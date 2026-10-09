/*
	Back2Uo v2.1 - stock team score HUD (allied and axis icon, score / scorelimit, leader on top)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from the team gametypes (tdm, ctf, hq, sd, ...). The gametypes notify
	"update_allhud_score" on level to refresh the display for everyone.
	Back2Uo: with game["back2uo_teamscore_enable"] (cvar back2uo_teamscore, default 1) this stock
	HUD is skipped completely and back2uo\hud\_back2uo_teamscore.gsc draws the mod's own score display.
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
	if(game["back2uo_teamscore_enable"]) return;

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

Creates the allied and axis icon, score and "/ scorelimit" hud elements (top left, two rows)
for every connecting player and starts the refresh watcher.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		// Top row allies, bottom row axis; updatePlayerHUD() swaps rows so the leader is on top.
		// archived = false keeps these out of killcam replays.
		player.hud_alliedicon = newClientHudElem(player);
		player.hud_alliedicon.horzAlign = "left";
		player.hud_alliedicon.vertAlign = "top";
		player.hud_alliedicon.x = 6;
		player.hud_alliedicon.y = 28;
		player.hud_alliedicon.archived = false;

		player.hud_axisicon = newClientHudElem(player);
		player.hud_axisicon.horzAlign = "left";
		player.hud_axisicon.vertAlign = "top";
		player.hud_axisicon.x = 6;
		player.hud_axisicon.y = 50;
		player.hud_axisicon.archived = false;

		player.hud_alliedscore = newClientHudElem(player);
		player.hud_alliedscore.horzAlign = "left";
		player.hud_alliedscore.vertAlign = "top";
		player.hud_alliedscore.x = 36;
		player.hud_alliedscore.y = 26;
		player.hud_alliedscore.font = "default";
		player.hud_alliedscore.fontscale = 2;
		player.hud_alliedscore.archived = false;

		player.hud_axisscore = newClientHudElem(player);
		player.hud_axisscore.horzAlign = "left";
		player.hud_axisscore.vertAlign = "top";
		player.hud_axisscore.x = 36;
		player.hud_axisscore.y = 48;
		player.hud_axisscore.font = "default";
		player.hud_axisscore.fontscale = 2;
		player.hud_axisscore.archived = false;

		// "/ scorelimit"; x is moved by getScoreLimitPosition() to follow the score width.
		player.hud_alliedscorelimit = newClientHudElem(player);
		player.hud_alliedscorelimit.horzAlign = "left";
		player.hud_alliedscorelimit.vertAlign = "top";
		player.hud_alliedscorelimit.x = 49;
		player.hud_alliedscorelimit.y = 26;
		player.hud_alliedscorelimit.font = "default";
		player.hud_alliedscorelimit.fontscale = 2;
		player.hud_alliedscorelimit.archived = false;
		player.hud_alliedscorelimit.label = (&"MP_SLASH");

		player.hud_axisscorelimit = newClientHudElem(player);
		player.hud_axisscorelimit.horzAlign = "left";
		player.hud_axisscorelimit.vertAlign = "top";
		player.hud_axisscorelimit.x = 49;
		player.hud_axisscorelimit.y = 48;
		player.hud_axisscorelimit.font = "default";
		player.hud_axisscorelimit.fontscale = 2;
		player.hud_axisscorelimit.archived = false;
		player.hud_axisscorelimit.label = (&"MP_SLASH");

		player.hud_alliedicon setShader(game["hudicon_allies"], 24, 24);
		player.hud_axisicon setShader(game["hudicon_axis"], 24, 24);

		player thread updatePlayerHUD();
		player thread onUpdatePlayerHUD();
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

Puts the leading team in the top row (y 26/28) and the other in the bottom row (y 48/50);
on a tie the rows stay as they are. Updates both scores and shows the scorelimit when level.scorelimit > 0.
Only changes y when it differs, to avoid needless hud updates.
Called on: player
=============
*/
updatePlayerHUD()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore > axisscore)
		winningteam = "allies";
	else if(axisscore > alliedscore)
		winningteam = "axis";
	else
		winningteam = "tied";

	if(winningteam == "allies")
	{
		if(self.hud_alliedicon.y != 28)
			self.hud_alliedicon.y = 28;
		if(self.hud_alliedscore.y != 26)
			self.hud_alliedscore.y = 26;
		if(self.hud_alliedscorelimit.y != 26)
			self.hud_alliedscorelimit.y = 26;
		if(self.hud_axisicon.y != 50)
			self.hud_axisicon.y = 50;
		if(self.hud_axisscore.y != 48)
			self.hud_axisscore.y = 48;
		if(self.hud_axisscorelimit.y != 48)
			self.hud_axisscorelimit.y = 48;
	}
	else if(winningteam == "axis")
	{
		if(self.hud_axisicon.y != 28)
			self.hud_axisicon.y = 28;
		if(self.hud_axisscore.y != 26)
			self.hud_axisscore.y = 26;
		if(self.hud_axisscorelimit.y != 26)
			self.hud_axisscorelimit.y = 26;
		if(self.hud_alliedicon.y != 50)
			self.hud_alliedicon.y = 50;
		if(self.hud_alliedscore.y != 48)
			self.hud_alliedscore.y = 48;
		if(self.hud_alliedscorelimit.y != 48)
			self.hud_alliedscorelimit.y = 48;
	}

	alliedposition = getScoreLimitPosition(alliedscore);
	axisposition = getScoreLimitPosition(axisscore);

	self.hud_alliedscore setValue(alliedscore);
	self.hud_axisscore setValue(axisscore);

	if(level.scorelimit > 0)
	{
		self.hud_alliedscorelimit.x = alliedposition;
		self.hud_axisscorelimit.x = axisposition;
		self.hud_alliedscorelimit setValue(level.scorelimit);
		self.hud_axisscorelimit setValue(level.scorelimit);
		self.hud_alliedscorelimit.alpha = 1;
		self.hud_axisscorelimit.alpha = 1;
	}
	else
	{
		self.hud_alliedscorelimit.alpha = 0;
		self.hud_axisscorelimit.alpha = 0;
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
