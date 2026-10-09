/*
	Back2Uo v2.1 - Team score panel: team icons, team scores and alive/dead counts per team.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_teamscore_draw

Creates the team score panel for team gametypes: one row per team with flag icon,
team score and the number of alive/dead players ("alive | dead").
The upper row is always allies and the lower row always axis, independent of the player's team.
Called on: self = player
=============
*/
back2uo_teamscore_draw()
{
	if(!game["back2uo_teamscore_enable"] || getcvar("g_gametype") == "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Team Score", "Run");

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

	// Allied flag icon (upper row)
	if(!isdefined(self.hud_teamicon))
	{
		self.hud_teamicon = newClientHudElem(self);
		self.hud_teamicon.horzAlign = "left";
		self.hud_teamicon.vertAlign = "top";
		self.hud_teamicon.x = 12;
		self.hud_teamicon.y = 42;
		self.hud_teamicon.alpha = level.back2uo_hudscore_alpha;
		self.hud_teamicon.archived = true;
		self.hud_teamicon setShader(game["hudicon_allies"], 48, 24);
	}

	// Allied team score
	if(!isdefined(self.hud_teamscore))
	{
		self.hud_teamscore = newClientHudElem(self);
		self.hud_teamscore.horzAlign = "left";
		self.hud_teamscore.vertAlign = "top";
		self.hud_teamscore.x = 65;
		self.hud_teamscore.y = 40;
		self.hud_teamscore.font = "default";
		self.hud_teamscore.fontscale = 2;
		self.hud_teamscore.alpha = level.back2uo_hudscore_alpha;
		self.hud_teamscore.archived = true;
	}

	// Axis flag icon (lower row)
	if(!isdefined(self.hud_enemyicon))
	{
		self.hud_enemyicon = newClientHudElem(self);
		self.hud_enemyicon.horzAlign = "left";
		self.hud_enemyicon.vertAlign = "top";
		self.hud_enemyicon.x = 12;
		self.hud_enemyicon.y = 75;
		self.hud_enemyicon.alpha = level.back2uo_hudscore_alpha;
		self.hud_enemyicon.archived = true;
		self.hud_enemyicon setShader(game["hudicon_axis"], 48, 24);
	}

	// Axis team score
	if(!isdefined(self.hud_enemyscore))
	{
		self.hud_enemyscore = newClientHudElem(self);
		self.hud_enemyscore.horzAlign = "left";
		self.hud_enemyscore.vertAlign = "top";
		self.hud_enemyscore.x = 65;
		self.hud_enemyscore.y = 73;
		self.hud_enemyscore.font = "default";
		self.hud_enemyscore.fontscale = 2;
		self.hud_enemyscore.alpha = level.back2uo_hudscore_alpha;
		self.hud_enemyscore.archived = true;
	}

	// Column header icons: alive and dead
	if(!isDefined(self.hud_lifeicon))
	{
		self.hud_lifeicon = newClientHudElem(self);
		self.hud_lifeicon.horzAlign = "left";
		self.hud_lifeicon.vertAlign = "top";
		self.hud_lifeicon.x = 10;
		self.hud_lifeicon.y = 21;
		self.hud_lifeicon.archived = true;
		self.hud_lifeicon.alpha = level.back2uo_hudscore_alpha;
		self.hud_lifeicon setShader("gfx/custom/back2uo_liveicon.tga", 26, 24);
	}

	if(!isDefined(self.hud_deathicon))
	{
		self.hud_deathicon = newClientHudElem(self);
		self.hud_deathicon.horzAlign = "left";
		self.hud_deathicon.vertAlign = "top";
		self.hud_deathicon.x = 35;
		self.hud_deathicon.y = 21;
		self.hud_deathicon.archived = true;
		self.hud_deathicon.alpha = level.back2uo_hudscore_alpha;
		self.hud_deathicon setShader("gfx/custom/back2uo_deadicon.tga", 26, 24);
	}

	// Separator characters between the alive and dead counts
	if(!isDefined(self.hud_teamcuticon))
	{
		self.hud_teamcuticon = newClientHudElem(self);
		self.hud_teamcuticon.horzAlign = "left";
		self.hud_teamcuticon.vertAlign = "top";
		self.hud_teamcuticon.x = 34;
		self.hud_teamcuticon.y = 62;
		self.hud_teamcuticon.font = "default";
		self.hud_teamcuticon.fontscale = 1;
		self.hud_teamcuticon.archived = true;
		self.hud_teamcuticon.alpha = level.back2uo_hudscore_alpha;
		self.hud_teamcuticon setText(level.cuticon);
	}

	if(!isDefined(self.hud_enemycuticon))
	{
		self.hud_enemycuticon = newClientHudElem(self);
		self.hud_enemycuticon.horzAlign = "left";
		self.hud_enemycuticon.vertAlign = "top";
		self.hud_enemycuticon.x = 34;
		self.hud_enemycuticon.y = 95;
		self.hud_enemycuticon.font = "default";
		self.hud_enemycuticon.fontscale = 1;
		self.hud_enemycuticon.archived = true;
		self.hud_enemycuticon.alpha = level.back2uo_hudscore_alpha;
		self.hud_enemycuticon setText(level.cuticon);
	}

	// Allies alive count
	if(!isDefined(self.hud_teamlife))
	{
		self.hud_teamlife = newClientHudElem(self);
		self.hud_teamlife.horzAlign = "left";
		self.hud_teamlife.vertAlign = "top";
		self.hud_teamlife.x = 19;
		self.hud_teamlife.y = 62;
		self.hud_teamlife.font = "default";
		self.hud_teamlife.fontscale = 1;
		self.hud_teamlife.archived = true;
		self.hud_teamlife.alpha = level.back2uo_hudscore_alpha;
		self.hud_teamlife setValue(0);
	}

	// Allies dead count
	if(!isDefined(self.hud_teamdeath))
	{
		self.hud_teamdeath = newClientHudElem(self);
		self.hud_teamdeath.horzAlign = "left";
		self.hud_teamdeath.vertAlign = "top";
		self.hud_teamdeath.x = 45;
		self.hud_teamdeath.y = 62;
		self.hud_teamdeath.font = "default";
		self.hud_teamdeath.fontscale = 1;
		self.hud_teamdeath.archived = true;
		self.hud_teamdeath.alpha = level.back2uo_hudscore_alpha;
		self.hud_teamdeath setValue(0);
	}

	// Axis alive count
	if(!isDefined(self.hud_enemylife))
	{
		self.hud_enemylife = newClientHudElem(self);
		self.hud_enemylife.horzAlign = "left";
		self.hud_enemylife.vertAlign = "top";
		self.hud_enemylife.x = 19;
		self.hud_enemylife.y = 95;
		self.hud_enemylife.font = "default";
		self.hud_enemylife.fontscale = 1;
		self.hud_enemylife.archived = true;
		self.hud_enemylife.alpha = level.back2uo_hudscore_alpha;
		self.hud_enemylife setValue(0);
	}

	// Axis dead count
	if(!isDefined(self.hud_enemydeath))
	{
		self.hud_enemydeath = newClientHudElem(self);
		self.hud_enemydeath.horzAlign = "left";
		self.hud_enemydeath.vertAlign = "top";
		self.hud_enemydeath.x = 45;
		self.hud_enemydeath.y = 95;
		self.hud_enemydeath.font = "default";
		self.hud_enemydeath.fontscale = 1;
		self.hud_enemydeath.archived = true;
		self.hud_enemydeath.alpha = level.back2uo_hudscore_alpha;
		self.hud_enemydeath setValue(0);
	}
}

/*
=============
back2uo_teamscore_update

Every 0.1 seconds recounts alive and dead players per team and refreshes the
team score panel. Team scores are written to every player's panel, the alive/dead
counts only to this player's panel.
Called on: self = player
=============
*/
back2uo_teamscore_update()
{
	if(!game["back2uo_teamscore_enable"] || getcvar("g_gametype") == "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Team Score", "Update");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(game["back2uo_teamscore_enable"] && getcvar("g_gametype") != "dm")
		{
			level.players = getentarray("player", "classname");
			alliedlife = [];
			allieddeath = [];
			axislife = [];
			axisdeath = [];

			alliedscore = getTeamScore("allies");
			axisscore = getTeamScore("axis");

			for(i = 0; i < level.players.size; i++)
			{
				player = level.players[i];

				if(isdefined(player.hud_teamscore) && isdefined(player.hud_enemyscore))
				{
					player.hud_teamscore setValue(alliedscore);
					player.hud_enemyscore setValue(axisscore);
				}

				// Count players per team: playing = alive, any other session state = dead.
				if(isdefined(player.pers["team"]) && player.pers["team"] == "allies" && player.pers["team"] != "spectator")
				{
					if(player.sessionstate == "playing")
					{
						alliedlife[alliedlife.size] = player;
					}
					else if(player.sessionstate != "playing")
					{
						allieddeath[allieddeath.size] = player;
					}
				}
				else if(isdefined(player.pers["team"]) && player.pers["team"] == "axis" && player.pers["team"] != "spectator")
				{
					if(player.sessionstate == "playing")
					{
						axislife[axislife.size] = player;
					}
					else if(player.sessionstate != "playing")
					{
						axisdeath[axisdeath.size] = player;
					}
				}

				if(isdefined(self.hud_teamlife) && isdefined(self.hud_enemylife))
				{
					// Allies
					self.hud_teamlife setValue(alliedlife.size);
					self.hud_teamdeath setValue(allieddeath.size);

					// Axis
					self.hud_enemylife setValue(axislife.size);
					self.hud_enemydeath setValue(axisdeath.size);
				}
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_teamscore_clear

Destroys all team score panel elements.
Called on: self = player
=============
*/
back2uo_teamscore_clear()
{
	if(!game["back2uo_teamscore_enable"] || getcvar("g_gametype") == "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Team Score", "Clear");

	if(isDefined(self.hud_lifeicon))
		self.hud_lifeicon destroy();
	if(isDefined(self.hud_deathicon))
		self.hud_deathicon destroy();
	if(isDefined(self.hud_teamcuticon))
		self.hud_teamcuticon destroy();
	if(isDefined(self.hud_enemycuticon))
		self.hud_enemycuticon destroy();

	// Allies
	if(isDefined(self.hud_teamicon))
		self.hud_teamicon destroy();
	if(isDefined(self.hud_teamscore))
		self.hud_teamscore destroy();

	if(isDefined(self.hud_teamlife))
		self.hud_teamlife destroy();
	if(isDefined(self.hud_teamdeath))
		self.hud_teamdeath destroy();

	// Axis
	if(isDefined(self.hud_enemyicon))
		self.hud_enemyicon destroy();
	if(isDefined(self.hud_enemyscore))
		self.hud_enemyscore destroy();

	if(isDefined(self.hud_enemylife))
		self.hud_enemylife destroy();
	if(isDefined(self.hud_enemydeath))
		self.hud_enemydeath destroy();
}
