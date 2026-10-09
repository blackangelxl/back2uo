/*
	Back2Uo v2.1 - Player-called artillery: binocular targeting, shells, damage and shell shock.

	back2uo_artilleryfx_control() is started from the ranking code in hud\_back2uo_ranking.gsc;
	the player then marks a target with the binoculars + Use key.
	Split from the former _back2uo_warfx.gsc. All loops end on level notify "back2uo_killthreads".
*/

/*
=============
back2uo_artilleryfx_control

Grants the player one artillery strike (ranking reward). Marks it in
self.pers["artillery_save"] so it survives a respawn, shows a message, plays the
"artillery ready" voice and starts waiting for binocular use.
Called on: self = player (from hud\_back2uo_ranking.gsc)
=============
*/
back2uo_artilleryfx_control()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Control", "Run");

	self endon("disconnect");
	self endon("killed_player");

	// Persistent flag: the strike is still available after death/respawn
	// (hud\_back2uo_ranking.gsc restarts back2uo_artilleryfx_binowaituse when it is set).
	self.pers["artillery_save"] = true;

	// Only one active artillery grant per player.
	if(!isdefined(self.back2uo_artillery_go)) self.back2uo_artillery_go = false;
	if(self.back2uo_artillery_go) return;

	self.back2uo_artillery_go = true;

	if(self.back2uo_artillery_go)
	{
		self thread back2uo_artilleryfx_binowaituse();

		self iprintlnbold(&"BACK2UOMOD_ARTILLERY_GO");

		// Nation specific "artillery ready" voice, e.g. "artillery_german_ready".
		land = back2uo\_back2uo_tools::back2uo_teams(self);
		sound = "artillery_" + land + "_ready";
		back2uo\_back2uo_sounds::back2uo_soundonplayer(sound, self);
	}
}

/*
=============
back2uo_artilleryfx_binowaituse

Waits for the player to raise the binoculars ("binocular_enter" notify from
hud\_back2uo_ranking.gsc) and then starts the target selection. Ends once the strike
was called in ("end_waitforuse") or the player dies.
Called on: self = player
=============
*/
back2uo_artilleryfx_binowaituse()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Binocular Use", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("end_waitforuse");
	self endon("killed_player");

	for (;;)
	{
		self waittill("binocular_enter");

		self thread back2uo_artilleryfx_binousing();

		wait 0.2;
	}
}

/*
=============
back2uo_artilleryfx_binousing

While the binoculars are up, checks every 0.2 seconds for the Use key. On Use, traces
the view direction for a target; a valid target fires the strike, an invalid one plays
the "target invalid" voice (if level.back2uo_artillery_order is 1).
Called on: self = player
=============
*/
back2uo_artilleryfx_binousing()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Binocular Using", "Run");

	// Kill any older instance of this thread first, then register the endon after the
	// short wait so this thread does not end on its own notify.
	self notify("binocular_exit");
	wait(0.1);
	self endon("binocular_exit");

	self endon("back2uo_killplayerthreads");
	self endon("artillery_fired");
	self endon("killed_player");

	for (;;)
	{
		if(isPlayer(self) && self useButtonPressed())
		{
			// Ground position the player is looking at, undefined if sky/out of range.
			binopositarget = back2uo\_back2uo_cvars::back2uo_getpositarget();

			if(isdefined(binopositarget))
			{
				self thread back2uo_artilleryfx_fire(binopositarget, self.origin[0], self.origin[1]);

				// Stop both the wait-for-use loop and this thread.
				self notify("end_waitforuse");
				self notify ("artillery_fired");
			}
			else
			{
				// "Target invalid" radio voice.
				if(level.back2uo_artillery_order == 1)
				{
					if(self.pers["team"] == "allies")
					{
						back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_allies_targetfalse", self);
					}
					else
					{
						back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_axis_targetfalse", self);
					}
				}
			}
		}

		wait .2;
	}
}

/*
=============
back2uo_artilleryfx_fire

Confirms the target, warns the player if the target is closer than
level.back2uo_artillery_danger, removes the artillery HUD icon, starts the strike and
consumes the player's artillery grant.
Called on: self = player
Params: binopositarget - target position
		selftarget_x, selftarget_y - player x/y; shells are launched from above this point
=============
*/
back2uo_artilleryfx_fire(binopositarget, selftarget_x, selftarget_y)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Fire", "Run");

	if(isdefined(binopositarget))
	{
		// "Target confirmed" radio voice.
		if(level.back2uo_artillery_order == 1)
		{
			if(self.pers["team"] == "allies")
			{
				back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_allies_targettrue", self);
			}
			else
			{
				back2uo\_back2uo_sounds::back2uo_soundonplayer("artillery_axis_targettrue", self);
			}
		}

		dangerdist = distance( self.origin, binopositarget );

		// Danger-close warning (0 disables it).
		if(isdefined(level.back2uo_artillery_danger) && level.back2uo_artillery_danger != 0 && dangerdist < level.back2uo_artillery_danger)
		{
			self iprintlnbold(&"BACK2UOMOD_ARTILLERY_DANGER");
		}

		if(isdefined(self.back2uo_artuseing)) self.back2uo_artuseing destroy();

		// Hide the artillery icon in the client UI.
		self setClientCvar("back2uo_ui_artillery_icon", 0);

		// The caller's team at fire time decides friendly fire (not the team at impact)
		thread back2uo_artilleryfx_play(binopositarget, selftarget_x, selftarget_y, self.pers["team"]);

		self iprintlnbold(&"BACK2UOMOD_ARTILLERY_FIRING");

		// Strike used up.
		self.pers["artillery_save"] = undefined;
		self.back2uo_artillery_go = false;

		return;
	}

	return;
}

/*
=============
back2uo_artilleryfx_play

Runs the artillery strike: incoming voice alert, a launch sound after 4-5 seconds, then
three salvos 3 seconds apart. Salvo 2 and 3 are shifted around the target to spread the
impacts. Shells per salvo is level.back2uo_artillery_count, or 4-7 if that is 0.
Called on: self = player who called the strike
Params: binopositarget - target position
		selftarget_x, selftarget_y - launch x/y (player position when firing)
		callerteam - team of the caller when the strike was fired
=============
*/
back2uo_artilleryfx_play(binopositarget, selftarget_x, selftarget_y, callerteam)
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Play", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	thread back2uo_artillery_sound();

	// Salvo counter.
	art_wait = 0;

	// Random launch sound.
	soundfx_artlaun[0] = "artillery_launch1";
	soundfx_artlaun[1] = "artillery_launch2";
	soundfx_artlaun[2] = "artillery_launch3";

	artlaun_efx = randomInt(soundfx_artlaun.size);

	wait (4 + randomint(2));

	self thread back2uo\_back2uo_sounds::back2uo_soundonplayers(soundfx_artlaun[artlaun_efx]);

	// Shell flight time before the first impacts.
	wait 4 + randomint(4);

	while(art_wait < 3)
	{
		// Shift the aim point for salvo 2 (+0..99) and salvo 3 (-100..-199 from that).
		if(art_wait == 1) binopositarget = binopositarget + (randomint(100), randomint(100), 0);
		else if(art_wait == 2) binopositarget = binopositarget - (int(100 + randomint(100)), int(100 + randomint(100)), 0);

		artillerycount = 0;

		// 0 = random shell count.
		if(level.back2uo_artillery_count == 0)
		{
			level.back2uo_artillery_count2 = int(4 + randomint(4));
		}
		else
		{
			level.back2uo_artillery_count2 = level.back2uo_artillery_count;
		}

		while(artillerycount < level.back2uo_artillery_count2)
		{
			thread back2uo_artillery_draw(binopositarget, selftarget_x, selftarget_y, callerteam);

			artillerycount++;

			wait 0.6;
		}

		art_wait++;

		wait 3;
	}
}

/*
=============
back2uo_artillery_draw

Drops a single artillery shell: a shell model falls from the map ceiling above the
caller toward a random point around the target, then plays a surface dependent impact
effect, explosion sound, screen shake and radius damage credited to the caller.
Called on: self = player who called the strike (damage attacker)
Params: binopositarget - target position
		selftarget_x, selftarget_y - x/y of the shell start point
		callerteam - team of the caller when the strike was fired
=============
*/
back2uo_artillery_draw(binopositarget, selftarget_x, selftarget_y, callerteam)
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Draw", "Run");

	// No player endon here: a running shell must always reach its delete() below,
	// even if the caller disconnects.

	artillery_zmax = level.back2uo_mapdimo_zMax;

	// Start high above the caller's position.
	startposition = (selftarget_x, selftarget_y, artillery_zmax);

	// Ground point scattered randomly around the target.
	endposition = back2uo\_back2uo_tools::back2uo_calcshellpos(binopositarget);

	// Shell model, nose pointing along the flight path, hidden until the whistle has started.
	artillery = spawn("script_model", startposition);
	artillery setModel("xmodel/vehicle_halftrack_rockets_shell_d");
	artillery.origin = startposition;
	artillery.angles = vectortoangles(vectornormalize((endposition) - startposition));;
	artillery hide();

	// Trace along the flight path to get the impact point and surface type.
	trace = bulletTrace( startposition, endposition, false, undefined );

	// Map the hit surface to one of the level.back2uo_effect["artillery_*"] impact effects.
	artilleryfx = "dirt";

	switch(trace["surfacetype"])
	{
	case "beach":
	case "sand":
	case "mud":
		artilleryfx = "beach";
		break;

	case "asphalt":
	case "metal":
		artilleryfx = "concrete";
		break;

	case "snow":
		artilleryfx = "snow";
		break;

	case "wood":
	case "grass":
	case "dirt":
		artilleryfx = "wood";
		break;

	case "water":
		artilleryfx = "water";
		break;
	}

	wait 0.05;

	// Random incoming whistle.
	soundfx_artincom[0] = "artillery_fallincome1";
	soundfx_artincom[1] = "artillery_fallincome2";
	soundfx_artincom[2] = "artillery_fallincome3";

	artincom_efx = randomInt(soundfx_artincom.size);

	artillery playsound(soundfx_artincom[artincom_efx]);

	wait 0.3;

	artillery show();

	// Fall time scales with the flight distance.
	fall_distance = distance(startposition, trace["position"]);
	fall_time = (fall_distance / 1000) / 4;

	// moveto() needs a time above 0 (start point close to or on the ground)
	if(fall_time < 0.1) fall_time = 0.1;

	artillery moveto(trace["position"], fall_time);

	wait fall_time;

	// Impact effect for the surface type.
	playfx(level.back2uo_effect["artillery_" + artilleryfx], trace["position"]);

	// Random explosion sound.
	soundfx_artexplo[0] = "artillery_explod1";
	soundfx_artexplo[1] = "artillery_explod2";
	soundfx_artexplo[2] = "artillery_explod3";

	artexplo_efx = randomInt(soundfx_artexplo.size);

	artillery playsound(soundfx_artexplo[artexplo_efx]);

	artillery hide();

	thread back2uo_artillery_damage(trace["position"], self, callerteam);

	// Strong screen shake (scale 0.8, radius 3000). randomint(1) is always 0, so length is 0.5.
	length = 0.5 + randomint(1);
	earthquake(0.8, length, trace["position"], 3000);

	artillery delete();
}

/*
=============
back2uo_artillery_damage

Applies artillery damage to all living players within 600 units of the impact. Damage falls off
quadratically with distance (max 300) and is reduced to 2 percent if the line from the
impact to the player's chest is blocked. Players under spawn protection are skipped.
Teammates of the caller follow scr_friendlyfire like normal weapons: 0 = no damage,
1 = damage, 2 = half the damage goes to the caller instead, 3 = caller and teammate take half each.
Params: endposition - impact position
		attacker - player who called the strike
		callerteam - team of the caller when the strike was fired
=============
*/
back2uo_artillery_damage(endposition, attacker, callerteam)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Damage", "Run");

	// Caller left the server or changed the team since firing: the strike does no damage.
	if(!isdefined(attacker) || !isPlayer(attacker)) return;
	if(isdefined(callerteam) && attacker.pers["team"] != callerteam) return;

	teambased = (getcvar("g_gametype") != "dm");

	damage_radius = 600;
	damage_strength = 300;

	players = getEntArray("player", "classname");

	for(i=0; i < players.size; i++)
	{
		player = players[i];

		// Only living players (no spectators, no dead players waiting for respawn)
		if(player.sessionstate != "playing" || !isAlive(player)) continue;

		// back2uo_antiplay_sp_run = spawn protection active (back2uo\antiplay\_back2uo_spawnprotection.gsc).
		if(isdefined(player.back2uo_antiplay_sp_run) && player.back2uo_antiplay_sp_run) continue;

		dist = distance(player.origin, endposition);
		if(dist > damage_radius) continue;

		// Quadratic falloff: full damage at the impact, 0 at the radius edge.
		damage_percent = (damage_radius - dist) / damage_radius;
		iDamage = (damage_strength * damage_percent) * damage_percent;

		// Cover check from the impact to the player's chest (40 units up).
		trace = bulletTrace(endposition, player.origin + (0,0,40), false, undefined);
		if(trace["fraction"] != 1) iDamage = iDamage * 0.02;

		victims = [];
		victims[0] = player;

		// Friendly fire on a teammate of the caller
		if(teambased && player != attacker && isdefined(player.pers["team"]) && player.pers["team"] == attacker.pers["team"])
		{
			if(level.friendlyfire == "0")
			{
				continue;
			}
			else if(level.friendlyfire == "2")
			{
				// Reflect: the caller takes half of the damage instead of the teammate
				iDamage = iDamage * 0.5;
				victims[0] = attacker;
			}
			else if(level.friendlyfire == "3")
			{
				// Shared: teammate and caller take half each
				iDamage = iDamage * 0.5;
				if(isAlive(attacker) && attacker.sessionstate == "playing") victims[1] = attacker;
			}
		}

		for(v = 0; v < victims.size; v++)
		{
			victim = victims[v];

			if(!isAlive(victim) || victim.sessionstate != "playing") continue;

			// Direct damage call, bypassing the gametype Callback_PlayerDamage.
			victim finishPlayerDamage(victim, attacker, int(iDamage), 1, "MOD_EXPLOSIVE", "artillery_mp", undefined, undefined, "none", victim.psOffsetTime);
			victim thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
			victim thread back2uo_artillery_shellshockOnDamage(iDamage);
			victim playrumble("damage_heavy");
		}
	}
}

/*
=============
back2uo_artillery_shellshockOnDamage

Applies the "default" shellshock with a duration based on the damage taken
(>10: 1s, >=25: 2s, >=50: 3s, >=90: 4s).
Called on: self = player
Params: damage - damage dealt by the artillery hit
=============
*/
back2uo_artillery_shellshockOnDamage(damage)
{
	time = 0;

	if(damage >= 90)
		time = 4;
	else if(damage >= 50)
		time = 3;
	else if(damage >= 25)
		time = 2;
	else if(damage > 10)
		time = 1;

	if(time) self shellshock("default", time);
}

/*
=============
back2uo_artillery_sound

Plays a random "incoming artillery" voice line to all players if level.back2uo_artillery_alert
is set. All nationalities map to the "GE_" voice set.
Called on: self = player who called the strike
=============
*/
back2uo_artillery_sound()
{
	if(!game["back2uo_artilleryfx_enable"]) return;

	if(!level.back2uo_artillery_alert) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Artillery Fx Sound", "Run");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");

	// Sound alias nationality prefix (only the German voice set is used).
	nat="";

	if(isdefined(self.origin) && self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			nat = "GE_";
			break;

		case "british":
			nat = "GE_";
			break;

		case "russian":
			nat = "GE_";
			break;
		}
	}
	else if(isdefined(self.origin) && self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
		case "german":
			nat = "GE_";
			break;
		}
	}
	else
	{
		nat = "GE_";
	}

	// Pick voice variant 0-3.
	num = randomInt(4);

	// Alias e.g. "GE_1_inform_incoming_artillery".
	alias = nat + num + "_inform_incoming_artillery";

	thread back2uo\_back2uo_sounds::back2uo_soundonplayers(alias);
}
