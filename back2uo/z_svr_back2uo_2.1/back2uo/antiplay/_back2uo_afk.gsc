/*
	Back2Uo v2.1 - Anti-play rules: AFK monitor and move to spectator.

	back2uo_antiplay_afk() is threaded from _back2uo_player.gsc on connect, back2uo_switchspec()
	once on the level at init. AFK players are moved to spectator via the cvar g_switchspec
	(entity number of the player).
	Cvars (back2uomod.cfg): back2uo_antiplay_afk_*.
	Split from the former _back2uo_antiplay.gsc.
*/

/*
=============
back2uo_antiplay_afk

AFK monitor. Counts about one tick per second while a living player moves less than 20 units,
stands upright and presses no attack/melee/use button. At level.back2uo_antiplay_afk_limit
the player gets a warning, 10 ticks later he is moved to spectator by writing his entity
number to g_switchspec (handled by back2uo_switchspec).
Called on: self = player (threaded on connect)
=============
*/
back2uo_antiplay_afk()
{
	if(!game["back2uo_antiplay_afk_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("AFK Monitor", "Run");

	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("afk_monitor", "self not exist");
		return;
	}

	level endon("intermission");
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Movement per second (units) below which the player counts as AFK
	radius = 20;
	self.back2uo_afk_time = 0;

	for(;;)
	{
		if(isdefined(self) && isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator")
		{
			// Disabled: debug output of the AFK counter
			//self iprintln(&"BACK2UOMOD_AFK_TIME", self.back2uo_afk_time);

			posi_type = back2uo\_back2uo_cvars::back2uo_player_stance();
			// Blocks for 1 second
			self_org = back2uo\_back2uo_cvars::back2uo_player_origin();

			// Movement, crouch/prone or a button press resets the counter
			if(self_org > radius || posi_type == "crouch" || posi_type == "prone" || self attackButtonPressed() || self meleeButtonPressed() || self useButtonPressed())
			{
				self.back2uo_afk_time = 0;
			}
			else if(self_org < radius)
			{
				self.back2uo_afk_time++;
			}

			if (self.back2uo_afk_time == level.back2uo_antiplay_afk_limit)
			{
				self iprintlnbold(&"BACK2UOMOD_AFK_WARNING_MSG");
			}
			else if(self.back2uo_afk_time >= level.back2uo_antiplay_afk_limit + 10)
			{
				// Request the move to spectator; back2uo_switchspec() polls this cvar
				thisPlayerNum = self getEntityNumber();
				setcvar("g_switchspec", thisPlayerNum);
				self iprintlnbold(&"BACK2UOMOD_AFK_SWICHTING_MSG");
				self.back2uo_afk_time = 0;
			}
		}
		else
		{
			self.back2uo_afk_time = 0;
		}

		wait 0.1;
	}
}

/*
=============
back2uo_switchspec

Polls the cvar g_switchspec every server frame. When it holds an entity number, that player
is killed (if alive) and moved to spectator through the gametype's spawnSpectator().
The cvar is set by back2uo_antiplay_afk() and can also be set by an admin via rcon.
Called on: self = level (threaded once at init)
=============
*/
back2uo_switchspec()
{
	back2uo\_back2uo_cvars::back2uo_logprint("AFK", "Run");

	level endon("boot");
	self endon("disconnect");

	setcvar("g_switchspec", "");

	while(1)
	{
		if(getcvar("g_switchspec") != "")
		{
			movePlayerNum = getcvarint("g_switchspec");
			players = getentarray("player", "classname");

			for(i = 0; i < players.size; i++)
			{
				thisPlayerNum = players[i] getEntityNumber();

				if(thisPlayerNum == movePlayerNum)
				{
					player = players[i];

					// switching_teams: the gametype's killed callback does not count this suicide as a death
					if(isAlive(player))
					{
						player.switching_teams = true;
						player suicide();
					}

					player.pers["team"] = "spectator";
					player.pers["weapon"] = undefined;
					player.pers["savedmodel"] = undefined;
					player.sessionteam = "spectator";
					player setClientCvar("ui_allow_weaponchange", "0");

					level.back2uo_playername = player.name;

					// Each gametype has its own spawnSpectator()
					if(getcvar("g_gametype") == "dm")
					{
						player thread maps\mp\gametypes\dm::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "tdm")
					{
						player thread maps\mp\gametypes\tdm::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "sd")
					{
						player thread maps\mp\gametypes\sd::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "hq")
					{
						player thread maps\mp\gametypes\hq::spawnSpectator();
					}
					else if(getcvar("g_gametype") == "ctf")
					{
						player thread maps\mp\gametypes\ctf::spawnSpectator();
					}

					// Note: self is the level here, not the moved player
					self notify("joined_spectators");
				}
			}

			// Announce the move to all players
			thread back2uo\_back2uo_cvars::back2uo_playeraction_msg(&"BACK2UOMOD_PLAYER_SPECTATOR", self);

			setcvar("g_switchspec", "");
		}

		wait 0.05;
	}
}
