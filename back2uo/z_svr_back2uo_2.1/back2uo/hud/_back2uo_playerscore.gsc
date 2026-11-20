/*
	Back2Uo v2.1 - DM player score panel (top left): life icon, team flag and the player's score.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	The update thread ends on player "disconnect" or "back2uo_life_end".
*/

/*
=============
back2uo_playerscore_draw

Creates the DM score panel in the top left corner: life icon, team flag icon and
the player's score. Only active in DM with game["back2uo_playerscore_enable"].
Called on: self = player
=============
*/
back2uo_playerscore_draw()
{
	if(!game["back2uo_playerscore_enable"] || getcvar("g_gametype") != "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Score", "Run");

	// Pick the flag icon for the allied nationality of this map.
	switch(game["allies"])
	{
	case "american":
		game["hudicon_allies"] = "gfx/custom/back2uo_flag_ammis.tga";
		break;

	case "british":
		game["hudicon_allies"] = "gfx/custom/back2uo_flag_british.tga";
		break;

	case "russian":
		game["hudicon_allies"] = "gfx/custom/back2uo_flag_russian.tga";
		break;
	}

	assert(game["axis"] == "german");
	game["hudicon_axis"] = "gfx/custom/back2uo_flag_german.tga";

	// Life icon
	if(!isDefined(self.hud_lifeicon))
	{
		self.hud_lifeicon = newClientHudElem(self);
		self.hud_lifeicon.horzAlign = "left";
		self.hud_lifeicon.vertAlign = "top";
		self.hud_lifeicon.x = 6;
		self.hud_lifeicon.y = 28;
		self.hud_lifeicon.archived = true;
		self.hud_lifeicon.alpha = level.back2uo_hudscore_alpha;
		self.hud_lifeicon setShader("gfx/custom/back2uo_liveicon.tga", 26, 24);
	}

	// Team flag icon (shader set below by team)
	if(!isdefined(self.hud_playericon))
	{
		self.hud_playericon = newClientHudElem(self);
		self.hud_playericon.horzAlign = "left";
		self.hud_playericon.vertAlign = "top";
		self.hud_playericon.x = 6;
		self.hud_playericon.y = 54;
		self.hud_playericon.alpha = level.back2uo_hudscore_alpha;
		self.hud_playericon.archived = true;
	}

	// Score value
	if(!isdefined(self.hud_playerscore))
	{
		self.hud_playerscore = newClientHudElem(self);
		self.hud_playerscore.horzAlign = "left";
		self.hud_playerscore.vertAlign = "top";
		self.hud_playerscore.x = 36;
		self.hud_playerscore.y = 26;
		self.hud_playerscore.alpha = level.back2uo_hudscore_alpha;
		self.hud_playerscore.font = "default";
		self.hud_playerscore.fontscale = 2;
		self.hud_playerscore.archived = true;
	}

	assert(self.pers["team"] == "allies" || self.pers["team"] == "axis");

	if(self.pers["team"] == "allies")
		self.hud_playericon setShader(game["hudicon_allies"], 48, 24);
	else
		self.hud_playericon setShader(game["hudicon_axis"], 48, 24);
}

/*
=============
back2uo_playerscore_update

Copies the player's score into the DM score panel on spawn and on every
"update_playerhud_score" (sent by dm.gsc and tools\_back2uo_points.gsc after a score change).
Called on: self = player
=============
*/
back2uo_playerscore_update()
{
	if(!game["back2uo_playerscore_enable"] || getcvar("g_gametype") != "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Score", "Update");

	self endon("disconnect");
	self endon("back2uo_life_end");

	for(;;)
	{
		if(isDefined(self.hud_playerscore))
			self.hud_playerscore setValue(self.score);

		self waittill("update_playerhud_score");

		// A notify can come before the last score change of the frame (suicide: the
		// back2uo_losepoints_ofplayer notify comes before the "score--" in dm.gsc).
		waittillframeend;
	}
}

/*
=============
back2uo_playerscore_clear

Destroys the DM score panel elements.
Called on: self = player
=============
*/
back2uo_playerscore_clear()
{
	if(!game["back2uo_playerscore_enable"] || getcvar("g_gametype") != "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Score", "Clear");

	if(isDefined(self.hud_lifeicon))
		self.hud_lifeicon destroy();

	if(isDefined(self.hud_playericon))
		self.hud_playericon destroy();

	if(isDefined(self.hud_playerscore))
		self.hud_playerscore destroy();
}
