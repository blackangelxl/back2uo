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

	// Only one update loop per player; spectators get no "killed_player", so every switch
	// to spectator would otherwise start one more loop.
	self notify("back2uo_teamscore_update");
	self endon("back2uo_teamscore_update");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(game["back2uo_teamscore_enable"] && getcvar("g_gametype") != "dm")
		{
			// Count once per server frame for all player loops; walking every player from
			// every player's loop is O(n^2) and trips the "potential infinite loop" limit.
			if(!isdefined(level.back2uo_teamscore_time) || level.back2uo_teamscore_time != gettime())
			{
				back2uo_teamscore_count();
			}

			alliedscore = level.back2uo_teamscore_allies;
			axisscore = level.back2uo_teamscore_axis;

			if(isdefined(self.hud_teamscore) && isdefined(self.hud_enemyscore))
			{
				self back2uo_teamscore_setvalue(self.hud_teamscore, alliedscore);
				self back2uo_teamscore_setvalue(self.hud_enemyscore, axisscore);
			}

			if(isdefined(self.hud_teamlife) && isdefined(self.hud_enemylife))
			{
				// Allies
				self back2uo_teamscore_setvalue(self.hud_teamlife, level.back2uo_teamscore_allies_alive);
				self back2uo_teamscore_setvalue(self.hud_teamdeath, level.back2uo_teamscore_allies_dead);

				// Axis
				self back2uo_teamscore_setvalue(self.hud_enemylife, level.back2uo_teamscore_axis_alive);
				self back2uo_teamscore_setvalue(self.hud_enemydeath, level.back2uo_teamscore_axis_dead);
			}

			// Log team score changes once per level (all player loops see the same values).
			if(back2uo\_back2uo_cvars::back2uo_logactive())
			{
				if(!isdefined(level.back2uo_log_teamscore_allies) || level.back2uo_log_teamscore_allies != alliedscore || level.back2uo_log_teamscore_axis != axisscore)
				{
					level.back2uo_log_teamscore_allies = alliedscore;
					level.back2uo_log_teamscore_axis = axisscore;

					leader = "tie";
					if(alliedscore > axisscore) leader = "allies";
					else if(axisscore > alliedscore) leader = "axis";

					back2uo\_back2uo_cvars::back2uo_logevent("teamscore", "score", "allies=" + alliedscore + " axis=" + axisscore + " leader=" + leader + " allies_alive=" + level.back2uo_teamscore_allies_alive + " allies_dead=" + level.back2uo_teamscore_allies_dead + " axis_alive=" + level.back2uo_teamscore_axis_alive + " axis_dead=" + level.back2uo_teamscore_axis_dead);

					// Leading team switched (a tie in between does not count as a switch).
					if(leader != "tie")
					{
						if(isdefined(level.back2uo_log_teamscore_leader) && level.back2uo_log_teamscore_leader != leader)
						{
							back2uo\_back2uo_cvars::back2uo_logevent("teamscore", "leadchange", "leader=" + leader + " allies=" + alliedscore + " axis=" + axisscore);
						}

						level.back2uo_log_teamscore_leader = leader;
					}
				}
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_teamscore_count

Counts alive and dead players per team and caches them together with the team
scores on level for the current server frame.
Called on: level
=============
*/
back2uo_teamscore_count()
{
	level.back2uo_teamscore_time = gettime();
	level.back2uo_teamscore_allies = getTeamScore("allies");
	level.back2uo_teamscore_axis = getTeamScore("axis");

	alliesalive = 0;
	alliesdead = 0;
	axisalive = 0;
	axisdead = 0;

	// Playing = alive, any other session state = dead.
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isdefined(player.pers["team"])) continue;

		if(player.pers["team"] == "allies")
		{
			if(player.sessionstate == "playing") alliesalive++;
			else alliesdead++;
		}
		else if(player.pers["team"] == "axis")
		{
			if(player.sessionstate == "playing") axisalive++;
			else axisdead++;
		}
	}

	level.back2uo_teamscore_allies_alive = alliesalive;
	level.back2uo_teamscore_allies_dead = alliesdead;
	level.back2uo_teamscore_axis_alive = axisalive;
	level.back2uo_teamscore_axis_dead = axisdead;
}

/*
=============
back2uo_teamscore_setvalue

Sets a hud element value only when it changed, to avoid resending unchanged
values every tick.
Called on: self = player
=============
*/
back2uo_teamscore_setvalue(hud, value)
{
	if(isdefined(hud.back2uo_value) && hud.back2uo_value == value) return;

	hud.back2uo_value = value;
	hud setValue(value);
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
