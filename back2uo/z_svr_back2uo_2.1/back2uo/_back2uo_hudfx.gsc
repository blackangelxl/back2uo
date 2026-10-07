/*
	Back2Uo v2.1 - Player HUD elements

	Creates, updates and destroys the mod's per-player HUD: DM player score, team score
	panel with alive/dead counts, health bar, stance/sprint indicator, blood splatter on
	screen, weather/war FX status icons, rank icon and rank rewards, binocular distance
	display and the weapon pickup hint.
	Every feature has a *_draw (create elements), *_update (looping thread) and *_clear
	(destroy elements) function, called from _back2uo_player.gsc on spawn, damage and death.
	Feature switches are game["back2uo_*_enable"]; tuning comes from level.back2uo_* cvars.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
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

Copies the player's score into the DM score panel every 0.1 seconds.
Called on: self = player
=============
*/
back2uo_playerscore_update()
{
	if(!game["back2uo_playerscore_enable"] || getcvar("g_gametype") != "dm") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Score", "Update");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(isDefined(self.hud_playerscore))
			self.hud_playerscore setValue(self.score);

		wait 0.1;
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

/*
=============
back2uo_healthbar_draw

Creates the health bar at the bottom right: background, colored bar and a red cross icon.
Called on: self = player
=============
*/
back2uo_healthbar_draw()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Run");

	// Full bar width in pixels at 100 health (1.28 px per health point).
	balkenWidth = 128;

	// Screen position of the bar (640x480 virtual screen).
	healthbar_x = 501;
	healthbar_y = 460;

	// Background
	if(!isDefined(self.healthbar_bg))
	{
		self.healthbar_bg = newClientHudElem(self);
		self.healthbar_bg.x = healthbar_x;
		self.healthbar_bg.y = healthbar_y + 1;
		self.healthbar_bg.horzAlign = "left";
		self.healthbar_bg.vertAlign = "top";
		self.healthbar_bg.alpha = 1;
		self.healthbar_bg.sort = 1;
		self.healthbar_bg.archived = true;
		self.healthbar_bg setShader("gfx/hud/hud@health_back.tga", 130, 10);
	}

	// Colored bar: red = 1 - health/100, green = health/100 - 0.4 (green to red).
	if(!isDefined(self.healthbar_gruen))
	{
		self.healthbar_gruen = newClientHudElem(self);
		self.healthbar_gruen.x = healthbar_x + 1;
		self.healthbar_gruen.y = healthbar_y + 2;
		self.healthbar_gruen.horzAlign = "left";
		self.healthbar_gruen.vertAlign = "top";
		self.healthbar_gruen.color = (1.0-(self.health/100.0), (self.health/100.0)-0.4, 0);
		self.healthbar_gruen.alpha = 0.4;
		self.healthbar_gruen.sort = 4;
		self.healthbar_gruen.archived = true;
		self.healthbar_gruen setShader("gfx/hud/hud@health_bar.tga", balkenWidth, 8);
	}

	// Cross icon left of the bar
	if(!isDefined(self.healthbar_kreuz))
	{
		self.healthbar_kreuz = newClientHudElem(self);
		self.healthbar_kreuz.x = healthbar_x - 13;
		self.healthbar_kreuz.y = healthbar_y;
		self.healthbar_kreuz.horzAlign = "left";
		self.healthbar_kreuz.vertAlign = "top";
		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz.sort = 1;
		self.healthbar_kreuz.archived = true;
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
	}
}

/*
=============
back2uo_healthbar_spawn_prot

Colors the health bar cross while spawn protection is active and resets it to
white when protection ends. Called each tick of the spawn protection loop in
_back2uo_antiplay.gsc.
Called on: self = player
Params: time - elapsed spawn protection time (unused)
		wert - if defined, spawn protection has ended and the cross is reset
=============
*/
back2uo_healthbar_spawn_prot(time, wert)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar Spawn Pro", "Run");

	// Spawn protection active: tint the cross cyan and fade it out (blinks once per call).
	if(isdefined(self.healthbar_kreuz))
	{
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
		self.healthbar_kreuz.color = (0, 2, 2);

		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz fadeOverTime(1);
		self.healthbar_kreuz.alpha = 0;
	}

	// Spawn protection ended: show the white cross again.
	if(isdefined(self.healthbar_kreuz) && isdefined(wert))
	{
		self.healthbar_kreuz.alpha = 1;
		self.healthbar_kreuz setShader("gfx/hud/hud@health_cross.tga", 12, 12);
		self.healthbar_kreuz.color = (1, 1, 1);
	}
}

/*
=============
back2uo_healthbar_update

Polls the player's health every 0.05 seconds and rescales and recolors the health
bar when it changed. The bar goes from green (full) to red (low).
Called on: self = player
=============
*/
back2uo_healthbar_update()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	balkenWidth = 128;

	for(;;)
	{
		// Sample health twice, 0.05 s apart, and only redraw on change.
		health_status1 = self.health;
		wait .05;
		health_status2 = self.health;

		if(health_status2 != health_status1)
		{
			balkenWidth = Int(health_status2 * 1.28);

			// Health 0 or less: remove the bar.
			if (balkenWidth == 0 || balkenWidth < 0)
			{
				if(isdefined(self.healthbar_gruen)) self.healthbar_gruen destroy();
			}

			// Rescale and recolor
			if(isdefined(self.healthbar_gruen))
			{
				self.healthbar_gruen.alpha = 0.4;
				self.healthbar_gruen setShader("gfx/hud/hud@health_bar.tga", balkenWidth, 8);
				self.healthbar_gruen.color = (1.0-(self.health/100.0), (self.health/100.0)-0.4, 0);
			}
		}
	}
}

/*
=============
back2uo_healthbar_glow

Makes the health bar blink while health is below 50. Lower health means a faster
fade (fade time = health / 100 seconds). Started on every damage event.
Called on: self = player
=============
*/
back2uo_healthbar_glow()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar Glow", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	while(isdefined(self.health) && self.health < 50)
	{
		blink = self.health / 100;

		if(isdefined(self.healthbar_gruen))
		{
			self.healthbar_gruen.alpha = 0.4;
			self.healthbar_gruen fadeOverTime(blink);
			self.healthbar_gruen.alpha = 0;
		}

		wait 0.45;
	}

	if(isDefined(self.healthbar_gruen)) self.healthbar_gruen.alpha = 0.4;
}

/*
=============
back2uo_healthbar_clear

Destroys the health bar elements.
Called on: self = player
=============
*/
back2uo_healthbar_clear()
{
	if(!game["back2uo_healthbar_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthbar", "Clear");

	if(isDefined(self.healthbar_bg))
		self.healthbar_bg destroy();

	if(isDefined(self.healthbar_gruen))
		self.healthbar_gruen destroy();

	if(isDefined(self.healthbar_kreuz))
		self.healthbar_kreuz destroy();
}

/*
=============
back2uo_sprinttast_msg

Tells the player why sprinting is not possible when he holds the use key (sprint key)
while moving with a Panzerschreck, while not standing, while busy (plant/defuse/binoculars)
or right after a weapon pickup. Repeats at most every 5 seconds.
Called on: self = player
=============
*/
back2uo_sprinttast_msg()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	if(level.back2uo_sprint_infomsg != 1) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sprint Info Msg", "Run");

	level endon("back2uo_killthreads");
	level endon("round_ended");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		positype = back2uo\_back2uo_cvars::back2uo_player_stance();

		// Only warn when the sprint key is pressed while moving.
		if(isPlayer(self) && self useButtonPressed() && self.pers["is_moving"])
		{
			// Sprint not possible: wrong weapon, not standing, busy or just picked up a weapon.
			if(self getcurrentweapon() == "panzerschreck_mp" || (positype != "stand" && positype != "sprint") || self.back2uo_playerdo != "none" || self.pers["weapon_pickupsprintwait"] == true)
			{
				// Planting or defusing also uses the use key, so skip the message.
				if(self.back2uo_playerdo == "plant" || self.back2uo_playerdo == "defuse")
				{
					wait 1;
				}
				else
				{
					self iprintln(level.back2uo_nosprint_msg);

					wait 5;
				}
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_draw

Creates the stance icons (stand, crouch, prone, sprint) at the bottom left, all hidden,
and the sprint stamina bar below them.
Called on: self = player
=============
*/
back2uo_playerposition_draw()
{
	if(!game["back2uo_playerposition_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Run");

	// Stance icons share one position; only the active one is made visible.
	if(!isDefined(self.playerposition_crouch))
	{
		self.playerposition_crouch = newClientHudElem(self);
		self.playerposition_crouch.x = 105; // was 108
		self.playerposition_crouch.y = 415; // was 422
		self.playerposition_crouch.horzAlign = "left";
		self.playerposition_crouch.vertAlign = "top";
		self.playerposition_crouch.alpha = 0;
		self.playerposition_crouch.sort = 2;
		self.playerposition_crouch setShader("gfx/custom/back2uo_hud_stance_crouch.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_prone))
	{
		self.playerposition_prone = newClientHudElem(self);
		self.playerposition_prone.x = 105; // was 108
		self.playerposition_prone.y = 415; // was 422
		self.playerposition_prone.horzAlign = "left";
		self.playerposition_prone.vertAlign = "top";
		self.playerposition_prone.alpha = 0;
		self.playerposition_prone.sort = 2;
		self.playerposition_prone setShader("gfx/custom/back2uo_hud_stance_prone.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_stand))
	{
		self.playerposition_stand = newClientHudElem(self);
		self.playerposition_stand.x = 105; // was 108
		self.playerposition_stand.y = 415; // was 422
		self.playerposition_stand.horzAlign = "left";
		self.playerposition_stand.vertAlign = "top";
		self.playerposition_stand.alpha = 0;
		self.playerposition_stand.sort = 2;
		self.playerposition_stand setShader("gfx/custom/back2uo_hud_stance_stand.tga", 45, 45); // was 40, 40
	}

	if(!isDefined(self.playerposition_sprint))
	{
		self.playerposition_sprint = newClientHudElem(self);
		self.playerposition_sprint.x = 105; // was 108
		self.playerposition_sprint.y = 415; // was 422
		self.playerposition_sprint.horzAlign = "left";
		self.playerposition_sprint.vertAlign = "top";
		self.playerposition_sprint.alpha = 0;
		self.playerposition_sprint.sort = 2;
		self.playerposition_sprint setShader("gfx/custom/back2uo_hud_stance_sprint.tga", 45, 45); // was 40, 40
	}

	// Sprint stamina bar (width grows with self.hud_sprint_height)
	if(!isDefined(self.playerposition_sprintcross))
	{
		self.playerposition_sprintcross = newClientHudElem(self);
		self.playerposition_sprintcross.x = 110;
		self.playerposition_sprintcross.y = 450;
		self.playerposition_sprintcross.horzAlign = "left";
		self.playerposition_sprintcross.vertAlign = "top";
		self.playerposition_sprintcross.color = ((1/100)*3, (1/100)*2, 0);
		self.playerposition_sprintcross.alpha = 0.8;
		self.playerposition_sprintcross.sort = 3;
		self.playerposition_sprintcross.archived = true;
		self.playerposition_sprintcross setShader("white", 1, 5);
	}
}

/*
=============
back2uo_playerposition_update

Starts the sprint bar and breathing threads, then every 0.1 seconds shows the icon
of the current stance (from back2uo_player_stance()) and hides the others.
Icons only become visible when level.back2uo_sprint_onhud is set.
Called on: self = player
=============
*/
back2uo_playerposition_update()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self thread back2uo_playerposition_sprint();
	self thread back2uo_playerposition_sprintsound();

	for(;;)
	{
		posi_type = back2uo\_back2uo_cvars::back2uo_player_stance();

		switch(posi_type)
		{
		default:

			if(isdefined(self.playerposition_crouch)) self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_stand) && level.back2uo_sprint_onhud) self.playerposition_stand.alpha = 0.9;

			break;

		case "crouch":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_crouch) && level.back2uo_sprint_onhud)self.playerposition_crouch.alpha = 0.9;

			break;

		case "prone":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_crouch))self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_sprint)) self.playerposition_sprint.alpha = 0;

			if(isdefined(self.playerposition_prone) && level.back2uo_sprint_onhud) self.playerposition_prone.alpha = 0.9;

			break;

		case "sprint":

			if(isdefined(self.playerposition_stand)) self.playerposition_stand.alpha = 0;
			if(isdefined(self.playerposition_crouch))self.playerposition_crouch.alpha = 0;
			if(isdefined(self.playerposition_prone)) self.playerposition_prone.alpha = 0;

			if(isdefined(self.playerposition_sprint) && level.back2uo_sprint_onhud) self.playerposition_sprint.alpha = 0.9;

			break;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_sprint

Drives the sprint stamina bar. While sprinting, self.hud_sprint_height grows from 1 to 36
(the bar width in pixels); when not sprinting it shrinks back. Also controls
self.pers["breathing"], which triggers the heavy breathing sound.
back2uo_sprint_length and back2uo_sprint_rehatime are total seconds; divided by 35 they
become the time per bar step.
Called on: self = player
=============
*/
back2uo_playerposition_sprint()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Postion Sprint", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	breath_timeon = 1;
	breath_timeoff = 1;
	sprint_waiton = 0.2;
	sprint_waitoff = 1;
	sprint_length = level.back2uo_sprint_length / 35;
	sprint_rehatime =  level.back2uo_sprint_rehatime / 35;
	self.hud_sprint_height = 1;
	self.pers["breathing"] = false;
	self.sprint_breathingout = 0;
	self.sprint_stop = undefined;

	for(;;)
	{
		// Slow the loop down at the bar limits (empty while sprinting, full while resting).
		if(self.pers["sprinting"] && self.hud_sprint_height < 2)
		{
			wait sprint_waiton;
		}
		else if(!self.pers["sprinting"] && self.hud_sprint_height > 35)
		{
			wait sprint_waitoff;
		}

		// Bar above 15: start heavy breathing; below 15 keep breathing for another 20 loop passes.
		if(self.hud_sprint_height > 15)
		{
			self.pers["breathing"] = true;
			self.sprint_breathingout = 0;
		}
		else if(self.hud_sprint_height < 15)
		{
			if(self.sprint_breathingout == 20)
			{
				self.pers["breathing"] = false;
				self.sprint_breathingout = 0;
			}
			else
			{
				self.sprint_breathingout++;
			}
		}

		// Sprinting: grow the bar one step per sprint_length seconds up to 36.
		while(self.pers["sprinting"] && self usebuttonpressed())
		{
			self.sprint_stop = undefined;

			if(isdefined(self.playerposition_sprintcross))
			{
				self.playerposition_sprintcross scaleOverTime(breath_timeon, self.hud_sprint_height, 5);
				self.playerposition_sprintcross.color = ((self.hud_sprint_height/100)*3, (self.hud_sprint_height/100)*2, 0);
			}

			if(self.hud_sprint_height < 36) self.hud_sprint_height++;
			else self.pers["breathing"] = true;

			wait sprint_length;
		}

		// Not sprinting: after a short delay shrink the bar one step per sprint_rehatime seconds.
		if(!self.pers["sprinting"] && self.hud_sprint_height >= 2)
		{
			if(!isdefined(self.sprint_stop))
			{
				wait 0.8;

				self.sprint_stop = true;
			}

			// Only regenerate while the sprint key is released or the player stands still.
			if(!self usebuttonpressed() || self.pers["is_moving"] == false)
			{
				if(isdefined(self.playerposition_sprintcross))
				{
					self.playerposition_sprintcross scaleOverTime(breath_timeoff, self.hud_sprint_height, 5);
					self.playerposition_sprintcross.color = ((self.hud_sprint_height/100)*3, (self.hud_sprint_height/100)*2, 0);
				}

				if(self.hud_sprint_height >= 2) self.hud_sprint_height = self.hud_sprint_height - 1;

				wait sprint_rehatime;
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_sprintsound

Plays the sprint breathing sound every 1.4 seconds while self.pers["breathing"] is set.
Called on: self = player
=============
*/
back2uo_playerposition_sprintsound()
{
	if(!game["back2uo_sprint_enable"]) return;

	// Bots never sprint.
	if(isdefined(self.pers["bots_nosprint"])) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position Sprintsound", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		if(self.pers["breathing"])
		{
			self thread back2uo\_back2uo_sounds::back2uo_soundonplayerorigin("sprint_breathing", self);

			wait 1.4;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_playerposition_clear

Destroys the stance icons and the sprint stamina bar.
Called on: self = player
=============
*/
back2uo_playerposition_clear()
{
	if(!game["back2uo_playerposition_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Player Position", "Clear");

	// Stand icon
	if(isDefined(self.playerposition_stand)) self.playerposition_stand destroy();

	// Crouch icon
	if(isDefined(self.playerposition_crouch)) self.playerposition_crouch destroy();

	// Prone icon
	if(isDefined(self.playerposition_prone)) self.playerposition_prone destroy();

	// Sprint icon
	if(isDefined(self.playerposition_sprint)) self.playerposition_sprint destroy();

	// Sprint stamina bar
	if(isDefined(self.playerposition_sprintcross)) self.playerposition_sprintcross destroy();
}

/*
=============
back2uo_view_bloodfx

Shows four blood splatter images at random screen positions when the player is hit,
keeps them for 5 seconds and then fades them out via back2uo_update_bloodfx().
Called on: self = player
=============
*/
back2uo_view_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Run");

	// Remove splatters from a previous hit first.
	back2uo_clear_bloodfx();

	if(!isDefined(self.back2uo_bloodyscreen))
	{
		// Random position (x 0-495, y 0-335) and random size 100-198 px.
		bs1 = randomint(496);
		bs2 = randomint(336);
		bs3 = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen = newClientHudElem(self);
		self.back2uo_bloodyscreen.alignX = "center";
		self.back2uo_bloodyscreen.alignY = "top";
		self.back2uo_bloodyscreen.x = bs1;
		self.back2uo_bloodyscreen.y = bs2;
		self.back2uo_bloodyscreen.color = (1,1,1);
		self.back2uo_bloodyscreen.alpha = 1;
		self.back2uo_bloodyscreen.archived = true;
		self.back2uo_bloodyscreen SetShader("gfx/gore/back2uo_hud_blood_hit1.tga", 100 + bs3 , 100 + bs3);
	}

	if(!isDefined(self.back2uo_bloodyscreen1))
	{
		bs1a = randomint(496);
		bs2a = randomint(336);
		bs3a = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen1 = newClientHudElem(self);
		self.back2uo_bloodyscreen1.alignX = "center";
		self.back2uo_bloodyscreen1.alignY = "top";
		self.back2uo_bloodyscreen1.x = bs1a;
		self.back2uo_bloodyscreen1.y = bs2a;
		self.back2uo_bloodyscreen1.color = (1,1,1);
		self.back2uo_bloodyscreen1.alpha = 1;
		self.back2uo_bloodyscreen1.archived = true;
		self.back2uo_bloodyscreen1 SetShader("gfx/gore/back2uo_hud_blood_hit2.tga", 100 + bs3a , 100 + bs3a);
	}

	if(!isDefined(self.back2uo_bloodyscreen2))
	{
		bs1b = randomint(496);
		bs2b = randomint(336);
		bs3b = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen2 = newClientHudElem(self);
		self.back2uo_bloodyscreen2.alignX = "center";
		self.back2uo_bloodyscreen2.alignY = "top";
		self.back2uo_bloodyscreen2.x = bs1b;
		self.back2uo_bloodyscreen2.y = bs2b;
		self.back2uo_bloodyscreen2.color = (1,1,1);
		self.back2uo_bloodyscreen2.alpha = 1;
		self.back2uo_bloodyscreen2.archived = true;
		self.back2uo_bloodyscreen2 SetShader("gfx/gore/back2uo_hud_blood_hit1.tga", 100 + bs3b , 100 + bs3b);
	}

	if(!isDefined(self.back2uo_bloodyscreen3))
	{
		bs1c = randomint(496);
		bs2c = randomint(336);
		bs3c = int(randomint(50) + randomint(50));
		self.back2uo_bloodyscreen3 = newClientHudElem(self);
		self.back2uo_bloodyscreen3.alignX = "center";
		self.back2uo_bloodyscreen3.alignY = "middle";
		self.back2uo_bloodyscreen3.x = bs1c;
		self.back2uo_bloodyscreen3.y = bs2c;
		self.back2uo_bloodyscreen3.color = (1,1,1);
		self.back2uo_bloodyscreen3.alpha = 1;
		self.back2uo_bloodyscreen3.archived = true;
		self.back2uo_bloodyscreen3 SetShader("gfx/gore/back2uo_hud_blood_hit2.tga", 100 + bs3c , 100 + bs3c);
	}

	wait 5;

	// Start the fade out.
	self back2uo_update_bloodfx();
}

/*
=============
back2uo_update_bloodfx

Fades the screen blood splatters out over 1 to 1.9 seconds and destroys them after 3 seconds.
Called on: self = player
=============
*/
back2uo_update_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Update");

	if(isDefined(self.back2uo_bloodyscreen))
	{
		self.back2uo_bloodyscreen.alpha = 1;
		self.back2uo_bloodyscreen fadeOverTime(1);
		self.back2uo_bloodyscreen.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen1))
	{
		self.back2uo_bloodyscreen1.alpha = 1;
		self.back2uo_bloodyscreen1 fadeOverTime(1.6);
		self.back2uo_bloodyscreen1.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen2))
	{
		self.back2uo_bloodyscreen2.alpha = 1;
		self.back2uo_bloodyscreen2 fadeOverTime(1.3);
		self.back2uo_bloodyscreen2.alpha = 0;
	}

	if(isDefined(self.back2uo_bloodyscreen3))
	{
		self.back2uo_bloodyscreen3.alpha = 1;
		self.back2uo_bloodyscreen3 fadeOverTime(1.9);
		self.back2uo_bloodyscreen3.alpha = 0;
	}

	// Wait until all fades (max 1.9 s) are done.
	wait 3;

	// Remove the elements.
	self back2uo_clear_bloodfx();
}

/*
=============
back2uo_clear_bloodfx

Destroys all screen blood splatter elements.
Called on: self = player
=============
*/
back2uo_clear_bloodfx()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Blood Fx", "Clear");

	if(isDefined(self.back2uo_bloodyscreen))
		self.back2uo_bloodyscreen destroy();

	if(isDefined(self.back2uo_bloodyscreen1))
		self.back2uo_bloodyscreen1 destroy();

	if(isDefined(self.back2uo_bloodyscreen2))
		self.back2uo_bloodyscreen2 destroy();

	if(isDefined(self.back2uo_bloodyscreen3))
		self.back2uo_bloodyscreen3 destroy();
}

/*
=============
back2uo_hudfx_draw

Creates the small FX status icons next to the stance icon: weather (snow, rain,
thunder or none), impact (mortar or none) and air (airplanes, flak or none).
Icons are placed left to right, 15 pixels apart.
Called on: self = player
=============
*/
back2uo_hudfx_draw()
{
	if(!game["back2uo_hudfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Run");

	if(!isdefined(level.back2uo_weather_allow)) level.back2uo_weather_allow = false;

	back2uo_hudfx_clear();

	// Start position of the first icon; each icon moves 15 px to the right.
	level.hudfx_x = 93;
	level.hudfx_y = 465;

	// Weather icon
	if(!isDefined(self.hud_weatherfx))
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_weatherfx = newClientHudElem(self);
		self.hud_weatherfx.x = level.hudfx_x;
		self.hud_weatherfx.y = level.hudfx_y;
		self.hud_weatherfx.horzAlign = "left";
		self.hud_weatherfx.vertAlign = "top";
		self.hud_weatherfx.alpha = 0.6;
		self.hud_weatherfx.sort = 1;
		self.hud_weatherfx.archived = true;

		if(isdefined(game["weather_allow"]) && game["back2uo_weatherfx_enable"])
		{
			// Snow on winter maps, rain without thunder, or thunder.
			if(game["back2uo_snowfx_enable"] && game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_snowfx.tga", 10, 10);
			}
			else if(game["back2uo_rainfx_enable"] && !game["back2uo_thunderfx_enable"] && game["german_soldiertype"] != "winterlight" && game["german_soldiertype"] != "winterdark")
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_rainfx.tga", 10, 10);
			}
			else if(game["back2uo_thunderfx_enable"])
			{
				self.hud_weatherfx setShader("gfx/custom/back2uo_hud_thunderfx.tga", 10, 10);
			}
		}
		else
		{
			self.hud_weatherfx setShader("gfx/custom/back2uo_hud_noweatherfx.tga", 10, 10);
		}
	}

	// Impact icon (mortar), only with war FX enabled
	if(!isDefined(self.hud_impactfx) && game["back2uo_warfx_enable"])
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_impactfx = newClientHudElem(self);
		self.hud_impactfx.x = level.hudfx_x;
		self.hud_impactfx.y = level.hudfx_y;
		self.hud_impactfx.horzAlign = "left";
		self.hud_impactfx.vertAlign = "top";
		self.hud_impactfx.alpha = 0.6;
		self.hud_impactfx.sort = 1;
		self.hud_impactfx.archived = true;

		if(game["back2uo_mortarfx_enable"])
		{
			self.hud_impactfx setShader("gfx/custom/back2uo_hud_mortarfx.tga", 10, 10);
		}
		else
		{
			self.hud_impactfx setShader("gfx/custom/back2uo_hud_nomortarfx.tga", 10, 10);
		}
	}

	// Air icon (airplanes or flak), only with war FX enabled
	if(!isDefined(self.hud_airfx) && game["back2uo_warfx_enable"])
	{
		level.hudfx_x = level.hudfx_x + 15;

		self.hud_airfx = newClientHudElem(self);
		self.hud_airfx.x = level.hudfx_x;
		self.hud_airfx.y = level.hudfx_y;
		self.hud_airfx.horzAlign = "left";
		self.hud_airfx.vertAlign = "top";
		self.hud_airfx.sort = 1;
		self.hud_airfx.alpha = 0.6;
		self.hud_airfx.archived = true;

		if(isdefined(level.back2uo_airplanedimo_allow) && level.back2uo_airplanedimo_allow == 1)
		{
			if(game["back2uo_airplanesfx_enable"] && !game["back2uo_flakfx_enable"])
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_airplanefx.tga", 10, 10);
			}
			else if(game["back2uo_flakfx_enable"])
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_flakfx.tga", 10, 10);
			}
			else
			{
				self.hud_airfx setShader("gfx/custom/back2uo_hud_noplanefx.tga", 10, 10);
			}
		}
		else
		{
			self.hud_airfx setShader("gfx/custom/back2uo_hud_noplanefx.tga", 10, 10);
		}
	}
}

/*
=============
back2uo_hudfx_update

Every 0.1 seconds switches the impact icon to the artillery icon while the player
owns an artillery strike (self.pers["artillery_save"]), otherwise back to mortar/none.
Called on: self = player
=============
*/
back2uo_hudfx_update()
{
	if(!game["back2uo_hudfx_enable"]) return;

	if(!game["back2uo_warfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Update");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	for(;;)
	{
		// Artillery strike available: show the artillery icon instead of the mortar icon.
		if(game["back2uo_artilleryfx_enable"] && isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
		{
			if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_artilleryfx.tga", 10, 10);
		}
		else
		{
			if(game["back2uo_mortarfx_enable"])
			{
				if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_mortarfx.tga", 10, 10);
			}
			else
			{
				if(isDefined(self.hud_impactfx)) self.hud_impactfx setShader("gfx/custom/back2uo_hud_nomortarfx.tga", 10, 10);
			}
		}

		wait 0.1;
	}
}

/*
=============
back2uo_hudfx_clear

Destroys the FX status icons.
Called on: self = player
=============
*/
back2uo_hudfx_clear()
{
	if(!game["back2uo_hudfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Fx Icons", "Clear");

	if(isDefined(self.hud_weatherfx))
		self.hud_weatherfx destroy();

	if(isDefined(self.hud_airfx))
		self.hud_airfx destroy();

	if(isDefined(self.hud_impactfx))
		self.hud_impactfx destroy();
}

/*
=============
back2uo_ranking_draw

Creates the rank icon above the stance icons and sets the player's scoreboard status
icon to his current rank picture.
Called on: self = player
=============
*/
back2uo_ranking_draw()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Run");

	if(!isdefined(self.hud_ranking_lv))
	{
		if(level.back2uo_hudrankingdraw != 1) return;

		self.hud_ranking_lv = newClientHudElem(self);
		self.hud_ranking_lv.x = -204;
		self.hud_ranking_lv.y = 390;
		self.hud_ranking_lv.horzAlign = "center";
		self.hud_ranking_lv.vertAlign = "top";
		self.hud_ranking_lv.sort = 1;
		self.hud_ranking_lv.archived = true;
		self.hud_ranking_lv.alpha = 0.6;
	}

	if(!isdefined(self.pers["back2uo_score_ranking_pic"])) self.pers["back2uo_score_ranking_pic"] = "gfx/custom/back2uo_ranking_lv1.tga";
	if(level.back2uo_rankingscorelist == 1) self.statusicon = self.pers["back2uo_score_ranking_pic"];
}

/*
=============
back2uo_ranking_update

Every 0.5 seconds maps the player's score to a rank (1 to 5, plus extra ranks every
level.back2uo_ranking_lvextra points above level 5 when back2uo_rankextra_aktiv is set).
On a rank change it plays a sound, prints a message and pulses the rank icon.
Called on: self = player
=============
*/
back2uo_ranking_update()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Update");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(!isdefined(self.pers["back2uo_ranking"])) self.pers["back2uo_ranking"] = 1;
	// Score needed for the first extra rank above level 5.
	if(!isdefined(self.pers["back2uo_ranking_extra"])) self.pers["back2uo_ranking_extra"] = level.back2uo_ranking_level5 + level.back2uo_ranking_lvextra;
	level.back2uo_ranking_over = level.back2uo_ranking_level5 + level.back2uo_ranking_lvextra;

	self.back2uo_rank_give = undefined;

	// Player still owns an unused artillery strike (from an earlier life): restart the binocular target selection.
	if(game["back2uo_artilleryfx_enable"] && isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
	{
		thread back2uo\_back2uo_warfx::back2uo_artilleryfx_binowaituse();
	}

	for(;;)
	{
		// Remember the previous rank to detect rank changes below.
		player_score = self.score;
		self.pers["back2uo_ranking_new"] = self.pers["back2uo_ranking"];

		if(player_score >= level.back2uo_ranking_level2 && player_score < level.back2uo_ranking_level3)
		{
			back2uo_ranking_level(2);

			self.pers["back2uo_ranking"] = 2;
		}
		else if(player_score >= level.back2uo_ranking_level3 && player_score < level.back2uo_ranking_level4)
		{
			back2uo_ranking_level(3);

			self.pers["back2uo_ranking"] = 3;
		}
		else if(player_score >= level.back2uo_ranking_level4 && player_score < level.back2uo_ranking_level5)
		{
			back2uo_ranking_level(4);

			self.pers["back2uo_ranking"] = 4;
		}
		else if(player_score >= level.back2uo_ranking_level5 && player_score < level.back2uo_ranking_over)
		{
			back2uo_ranking_level(5);

			self.pers["back2uo_ranking"] = 5;
		}
		else if(player_score >= self.pers["back2uo_ranking_extra"] && level.back2uo_rankextra_aktiv == 1)
		{
			// Extra ranks: one rank up every back2uo_ranking_lvextra points above level 5.
			back2uo_ranking_level(self.pers["back2uo_ranking"]);

			self.pers["back2uo_ranking"]++;
			self.pers["back2uo_ranking_extra"] += level.back2uo_ranking_lvextra;
		}
		else
		{
			// Below level 2
			back2uo_ranking_level(1);
		}

		// Teammates see the rank as head icon (team gametypes only).
		if(isdefined(self.headicon) && level.back2uo_teamrankheadicons == 1 && getCvar("g_gametype") != "dm")
		{
			self.headicon = self.pers["back2uo_head_ranking_pic"];
		}

		// Rank changed
		if(self.pers["back2uo_ranking"] != self.pers["back2uo_ranking_new"])
		{
			if(self.pers["back2uo_ranking"] <= 5)
			{
				// Rank up: sound and message; allow the rewards of the next rank.
				if(self.pers["back2uo_ranking"] > self.pers["back2uo_ranking_new"])
				{
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_up", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_UP");

					self.back2uo_rank_give = undefined;
				}
				else
				{
					// Rank down: sound and message only.
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_down", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_DOWN");
				}

				// Pulse the rank icon: grow, shrink, back to normal.
				if(isdefined(self.hud_ranking_lv))
				{
					if(level.back2uo_rankingscorelist == 1) self.statusicon = self.pers["back2uo_score_ranking_pic"];

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = -206;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.2;
					self.hud_ranking_lv.x = -208;
					self.hud_ranking_lv.y = 386;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 32, 32);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = -206;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.1;

					self.hud_ranking_lv.alpha = 0.6;
					self.hud_ranking_lv.x = -204;
					self.hud_ranking_lv.y = 390;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 24, 24);
				}
			}
			else
			{
				self.back2uo_rank_give = undefined;
			}

			self.back2uo_art_rank = undefined;
		}
		else
		{
			if(isdefined(self.hud_ranking_lv))
			{
				self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 24, 24);
			}
		}

		wait 0.5;
	}
}

/*
=============
back2uo_ranking_level

Sets the rank icons (HUD, scoreboard, head icon) for the given rank and hands out the
rank rewards once per rank (self.back2uo_rank_give). Ranks above 5 use the level 5 icons
and rewards.
Called on: self = player
Params: ranking_lv - rank number used for the icon file names
=============
*/
back2uo_ranking_level(ranking_lv)
{
	// Icons only exist up to level 5.
	if(self.pers["back2uo_ranking"] >= 5) ranking_lv = 5;

	self.back2uo_ranking_pic = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_score_ranking_pic"] = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_head_lv" + ranking_lv + ".tga";

	// Hand out rank rewards once per rank (reset on rank up in back2uo_ranking_update).
	if(self.pers["back2uo_ranking"] == 1)
	{
		self.pers["back2uo_artillery_go"] = false;
	}
	else if(self.pers["back2uo_ranking"] == 2)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(2, level.back2uo_rang2_getsekammo,level.back2uo_rang2_getpriammo,level.back2uo_rang2_getgranade,level.back2uo_rang2_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 3)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(3, level.back2uo_rang3_getsekammo,level.back2uo_rang3_getpriammo,level.back2uo_rang3_getgranade,level.back2uo_rang3_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 4)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(4, level.back2uo_rang4_getsekammo,level.back2uo_rang4_getpriammo,level.back2uo_rang4_getgranade,level.back2uo_rang4_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 5)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(5, level.back2uo_rang5_getsekammo,level.back2uo_rang5_getpriammo,level.back2uo_rang5_getgranade,level.back2uo_rang5_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] >= 6)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(self.pers["back2uo_ranking"], level.back2uo_rang5_getsekammo,level.back2uo_rang5_getpriammo,level.back2uo_rang5_getgranade,level.back2uo_rang5_getsmoke);
	}
}

/*
=============
back2uo_ranking_give

Gives the rewards for reaching a rank: extra primary/secondary ammo, frag and smoke
grenades (up to the grenade limits), removes the binoculars at the configured rank and
grants an artillery strike from back2uo_artillery_onrank on.
Called on: self = player
Params: ranking_lv - reached rank
		sek_ammo - extra secondary (pistol) ammo
		pri_ammo - extra primary ammo
		granat - extra frag grenades
		smoke - extra smoke grenades
=============
*/
back2uo_ranking_give(ranking_lv, sek_ammo,pri_ammo,granat,smoke)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Give");

	rank_extras_a = 0;
	rank_extras_b = 0;

	// Primary weapon ammo
	if(pri_ammo > 0)
	{
		mgammo = self getWeaponSlotClipAmmo("primary");
		mgresammo = self getWeaponSlotAmmo("primary");
		mgend_ammo = mgammo + mgresammo + pri_ammo;
		self setWeaponSlotAmmo("primary", mgend_ammo);

		mg_maxammo = self getWeaponSlotAmmo("primary");

		if(mgend_ammo >= mg_maxammo) rank_extras_a++;
	}

	// Secondary (pistol) ammo
	if(sek_ammo > 0)
	{
		pistelammo = self getWeaponSlotClipAmmo("primaryb");
		pistelresammo = self getWeaponSlotAmmo("primaryb");
		pistelend_ammo = pistelammo + pistelresammo + sek_ammo;
		self setWeaponSlotAmmo("primaryb", pistelend_ammo);

		pistel_maxammo = self getWeaponSlotAmmo("primaryb");

		if(pistelend_ammo >= pistel_maxammo) rank_extras_a++;
	}

	// Message if any ammo was given (rank_extras_a is 1 or 2).
	if(level.back2uo_rankingmsg == 1 && (rank_extras_a == 1 || rank_extras_a == 2)) self iprintln(&"BACK2UOMOD_RANKING_MUN");

	// Frag grenades, only up to the level.back2uo_granaten_allow limit.
	if(granat > 0)
	{
		// Count grenades of both nationalities (the player may carry either type).
		grenadetype1 = "frag_grenade_" + game["allies"] + "_mp" + level.back2uo_specialgranade;
		grenadetype2 = "frag_grenade_" + game["axis"] + "_mp" + level.back2uo_specialgranade;
		count1 = self getammocount(grenadetype1);
		count2 = self getammocount(grenadetype2);

		granadecount = count1 + count2;
		granadeend_count = granadecount + granat;

		if(granadeend_count <= level.back2uo_granaten_allow)
		{
			granadetype = self back2uo\_back2uo_tools::back2uo_getgranade_type("granade");

			self giveWeapon(granadetype);
			self setWeaponClipAmmo(granadetype, granadeend_count);
			rank_extras_b++;
		}
	}

	// Smoke grenades, only up to the level.back2uo_smoke_allow limit.
	if(smoke > 0)
	{
		grenadetype1 = "smoke_grenade_" + game["allies"] + "_mp" + level.back2uo_specialsmoke;
		grenadetype2 = "smoke_grenade_" + game["axis"] + "_mp" + level.back2uo_specialsmoke;
		count1 = self getammocount(grenadetype1);
		count2 = self getammocount(grenadetype2);

		smokecount = count1 + count2;
		smokeend_count = smokecount + smoke;

		if(smokeend_count <= level.back2uo_smoke_allow)
		{
			smokegrenadetype = self back2uo\_back2uo_tools::back2uo_getgranade_type("smoke");

			self giveWeapon(smokegrenadetype);
			self setWeaponClipAmmo(smokegrenadetype, smokeend_count);
			rank_extras_b++;
		}
	}

	// Message if any grenade was given.
	if(level.back2uo_rankingmsg == 1 && (rank_extras_b == 1 || rank_extras_b == 2)) self iprintln(&"BACK2UOMOD_RANKING_GRA");

	// Binoculars are taken away from the configured rank on.
	if(level.back2uo_binocular_allow)
	{
		if(level.back2uo_binocular_onrank <= ranking_lv)
		{
			self takeWeapon("binoculars_mp");
		}
	}

	// Artillery strike from the configured rank on, once per rank.
	if(game["back2uo_artilleryfx_enable"])
	{
		if(level.back2uo_artillery_onrank <= ranking_lv)
		{
			art_rank_check = thread back2uo_ranking_artillery_check(ranking_lv);

			// Note: a function called with 'thread' does not return a value, so art_rank_check is undefined here.
			if(art_rank_check == 1) return;

			if(isdefined(self.back2uo_art_rank)) return;
			self.back2uo_art_rank = true;

			// Player still has an unused strike.
			if(isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true) return;

			thread back2uo\_back2uo_warfx::back2uo_artilleryfx_control();
		}
	}
}

/*
=============
back2uo_ranking_artillery_check

Remembers in self.pers that the artillery reward for this rank was handed out.
Called on: self = player
Params: ranking_lv - rank to check
Returns: 1 if the reward was already given for this rank, else 0
=============
*/
back2uo_ranking_artillery_check(ranking_lv)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking Artillery Check", "Run");

	ausgabe = 0;

	if(isdefined(self.pers["art_rang_" + ranking_lv])) ausgabe = 1;
	self.pers["art_rang_" + ranking_lv] = true;

	return ausgabe;
}

/*
=============
back2uo_ranking_clear

Destroys the rank icon and resets the scoreboard status icon to the dead icon.
Called on: self = player
=============
*/
back2uo_ranking_clear()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Clear");

	if(isDefined(self.hud_ranking_lv))
		self.hud_ranking_lv destroy();

	if(level.back2uo_rankingscorelist == 1) self.statusicon = "hud_status_dead";
}

/*
=============
back2uo_binocular_control

Waits for the player to raise the binoculars and starts the distance display and
its cleanup thread. If the player was sprinting, binocular use is flagged and the
display is cleared again after 1 second.
Called on: self = player
=============
*/
back2uo_binocular_control()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Control", "Run");

	// The thread can start after the player has already left.
	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("bino_control", "self not exist");
		return;
	}

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	self.pers["bino_inuse"] = false;

	for (;;)
	{
		// Notified by the engine when the player raises the binoculars.
		self waittill("binocular_enter");

		// Short delay before the display starts.
		wait (0.3);

		self thread back2uo_binocular_distance_clear();

		self thread back2uo_binocular_distance_draw();

		wait 0.2;

		// Sprinting with binoculars: flag binocular use (stops sprinting) and clear the display again.
		if(isdefined(self.pers["sprinting"]) && self.pers["sprinting"] == true)
		{
			self.pers["bino_inuse"] = true;

			wait 1;

			self thread back2uo_binocular_distance_clear2();
		}
	}
}

/*
=============
back2uo_binocular_distance_draw

While looking through the binoculars, shows the distance in meters to the aimed point
(via mod UI cvars) and the "use artillery" hint when an artillery strike is ready.
Ends on "binocular_exit".
Called on: self = player
=============
*/
back2uo_binocular_distance_draw()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");

	self endon("disconnect");
	self endon("killed_player");

	self endon("binocular_exit");

	// Blocks other player actions (sprint message, pickups) while the binoculars are up.
	self.back2uo_playerdo = "binocularuse";

	if(game["back2uo_binocularhud_enable"])
	{
		if(!isdefined(self.back2uo_artlength))
		{
			self.back2uo_artlength = newClientHudElem( self );
			self.back2uo_artlength.alignX = "right";
			self.back2uo_artlength.alignY = "top";
			self.back2uo_artlength.fontScale = 1;
			self.back2uo_artlength.x = 340;
			self.back2uo_artlength.y = 380;
			self.back2uo_artlength.sort = 5;
			self.back2uo_artlength.alpha = 0.7;
		}
	}

	if(!isdefined(self.back2uo_artuseing))
	{
		self.back2uo_artuseing = newClientHudElem( self );
		self.back2uo_artuseing.alignX = "center";
		self.back2uo_artuseing.alignY = "top";
		self.back2uo_artuseing.fontScale = 0.8;
		self.back2uo_artuseing.x = 320;
		self.back2uo_artuseing.y = 305;
		self.back2uo_artuseing.sort = 5;
		self.back2uo_artuseing.alpha = 0;
		self.back2uo_artuseing.label = (&"BACK2UOMOD_ARTILLERY_USE");
	}

	for(;;)
	{
		if(game["back2uo_binocularhud_enable"])
		{
			binopositarget = back2uo\_back2uo_cvars::back2uo_getpositarget();

			// Show the name/meters/unknown labels of the mod's binocular UI.
			self setClientCvar("back2uo_ui_artillery_name", 1);

			if(isdefined(binopositarget))
			{
				// Units to meters: 1 unit = 2.5 cm.
				dangerzonegitter = distance( self.origin, binopositarget );
				dangerzonemeter = int(int(dangerzonegitter * 2.5) / 100);

				if(isdefined(self.back2uo_artlength))
				{
					self.back2uo_artlength.alpha = 0.7;
					self.back2uo_artlength setValue(dangerzonemeter);
				}

				self setClientCvar("back2uo_ui_artillery_meters", 1);
				self setClientCvar("back2uo_ui_artillery_unknown", 0);
			}
			else
			{
				if(isdefined(self.back2uo_artlength))
				{
					self.back2uo_artlength.alpha = 0;
				}

				self setClientCvar("back2uo_ui_artillery_meters", 0);
				self setClientCvar("back2uo_ui_artillery_unknown", 1);
			}
		}

		// Artillery strike ready: show the 'use artillery' hint and icon.
		if(isdefined(self.back2uo_artillery_go) && self.back2uo_artillery_go == true)
		{
			if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing.alpha = 1;

			self setClientCvar("back2uo_ui_artillery_icon", 1);
		}

		wait (0.1);
	}
}

/*
=============
back2uo_binocular_distance_clear

Waits for "binocular_exit", then resets the binocular state and removes the distance
and artillery hint display.
Called on: self = player
=============
*/
back2uo_binocular_distance_clear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Clear");

	// Notified by the engine when the player lowers the binoculars.
	self waittill("binocular_exit");

	self.pers["bino_inuse"] = false;
	self.back2uo_playerdo = "none";

	if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

	self setClientCvar("back2uo_ui_artillery_icon", 0);

	if(!game["back2uo_binocularhud_enable"]) return;

	self setClientCvar("back2uo_ui_artillery_name", 0);
	self setClientCvar("back2uo_ui_artillery_meters", 0);
	self setClientCvar("back2uo_ui_artillery_unknown", 0);

	if(isdefined(self.back2uo_artlength)) self.back2uo_artlength destroy();
}

/*
=============
back2uo_binocular_distance_clear2

Immediately resets the binocular state and removes the distance and artillery hint
display (same as back2uo_binocular_distance_clear without waiting).
Called on: self = player
=============
*/
back2uo_binocular_distance_clear2()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Binocular Distance", "Clear 2");

	self.pers["bino_inuse"] = false;
	self.back2uo_playerdo = "none";

	if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

	self setClientCvar("back2uo_ui_artillery_icon", 0);

	if(!game["back2uo_binocularhud_enable"]) return;

	self setClientCvar("back2uo_ui_artillery_name", 0);
	self setClientCvar("back2uo_ui_artillery_meters", 0);
	self setClientCvar("back2uo_ui_artillery_unknown", 0);

	if(isdefined(self.back2uo_artlength)) self.back2uo_artlength destroy();
}

/*
=============
back2uo_weaponpickup_hud_draw

Creates the hidden "swap weapons" hint text shown when the player stands on a pickup
weapon (made visible by _back2uo_weaponsystem.gsc).
Called on: self = player
=============
*/
back2uo_weaponpickup_hud_draw()
{
	if(!game["back2uo_sprint_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Pickup Hud Draw", "Run");

	if(!isdefined(self.back2uo_weaponpickup))
	{
		self.back2uo_weaponpickup = newClientHudElem(self);
		self.back2uo_weaponpickup.alignX = "right";
		self.back2uo_weaponpickup.alignY = "top";
		self.back2uo_weaponpickup.fontScale = 0.9;
		self.back2uo_weaponpickup.x = 375;
		self.back2uo_weaponpickup.y = 345;
		self.back2uo_weaponpickup.alpha = 0;
		self.back2uo_weaponpickup setText(level.back2uo_weaponpickup);
	}
}
