/*
	Back2Uo v2.1 - Bot AI: test bots walk the map along the waypoints and fight like players.

	back2uo_bot_spawned() runs once per life of a bot (started from back2uo_player_spawn). One
	loop per bot, every server frame:
		- look for the nearest visible enemy (4 times a second, field of view 120 degrees,
		  all around within 300 units)
		- enemy seen: turn to it, wait the reaction time, fire with an aim error that shrinks
		  while the bot keeps the enemy in sight; strafe, reload, sniper rifles zoom in;
		  melee an enemy within reach instead of shooting
		- no enemy: follow a waypoint path (back2uo\bots\_back2uo_waypoints.gsc) to a random
		  goal, or to where the last enemy was seen. Jumps, mantles and ladders follow the
		  edge types of the waypoints. A bot that does not move gets unstuck by jumping,
		  strafing, and finally a new route.
		- maps without waypoints: walk straight and turn away from walls
	Bots only use the bot input functions of zk_libcod (setWalkDir, setWalkValues, setBotStance,
	fireWeapon, reloadWeapon, meleeWeapon, setAim, via _back2uo_libcod.gsc) and setPlayerAngles,
	so they move by the same rules as players. Without zk_libcod the AI does not start.

	Skill (cvar back2uo_testbots_skill -> level.back2uo_testbots_skill), see bot_skill():
		1 easy, 2 normal, 3 hard: reaction time, aim error and turn speed.

	State per bot: self.b2ubot (struct), reset on every spawn.
*/

/*
=============
back2uo_bot_spawned

Starts the AI of a bot for this life. Ends when the bot dies, spawns again, goes spectator,
disconnects or the map ends.
Called on: self = bot (threaded from back2uo_player_spawn)
=============
*/
back2uo_bot_spawned()
{
	self endon("disconnect");
	self endon("killed_player");
	self endon("spawned");
	level endon("intermission");

	// Bot input needs zk_libcod; without it the bot just stands at its spawn.
	if(!back2uo\_back2uo_libcod::back2uo_libcod_active()) return;

	bot_init();

	// Spread the bots over several frames, they all spawn at once at round start
	wait(0.1 + randomfloat(0.5));

	for(;;)
	{
		bot_find_enemy();

		if(isdefined(self.b2ubot.enemy))
			bot_combat();
		else
			bot_navigate();

		wait .05;
	}
}

/*
=============
back2uo_bot_killed

Makes a dead bot respawn when scr_forcerespawn is off: the gametype then waits for the use
button, which a bot cannot press, so this sends the "respawn" notify the button would send.
Called on: self = bot (threaded from back2uo_player_killed)
=============
*/
back2uo_bot_killed()
{
	self endon("disconnect");
	self endon("spawned");

	bot_release();

	wait 2;

	for(;;)
	{
		self notify("remove_respawntext");
		self notify("respawn");
		wait 1;
	}
}

/*
=============
bot_init

Resets the bot's input and AI state for a new life.
=============
*/
bot_init()
{
	bot_release();

	self.b2ubot = spawnstruct();
	self.b2ubot.skill = bot_skill(level.back2uo_testbots_skill);

	// Combat
	self.b2ubot.enemy = undefined;
	self.b2ubot.enemysince = 0;
	self.b2ubot.nextscan = 0;
	self.b2ubot.aimerror = (0, 0, 0);
	self.b2ubot.nextaimerror = 0;
	self.b2ubot.firing = false;
	self.b2ubot.nextshot = 0;
	self.b2ubot.shotstart = 0;
	self.b2ubot.reloading = false;
	self.b2ubot.meleeing = false;
	self.b2ubot.meleestart = 0;
	self.b2ubot.nextmelee = 0;
	self.b2ubot.aiming = false;
	self.b2ubot.strafe = 0;
	self.b2ubot.nextstrafe = 0;
	self.b2ubot.lastseenpos = undefined;
	self.b2ubot.lastseentime = 0;

	// Navigation
	self.b2ubot.path = undefined;
	self.b2ubot.pathindex = 0;
	self.b2ubot.planning = false;
	self.b2ubot.jumped = false;
	self.b2ubot.stance = "stand";
	self.b2ubot.walking = false;
	self.b2ubot.stuck = 0;
	self.b2ubot.stuckcheck = gettime() + 1000;
	self.b2ubot.stuckpos = self.origin;
	self.b2ubot.unstuckuntil = 0;
	self.b2ubot.waituntil = 0;
	self.b2ubot.avoid = [];		// node id -> gettime() until which the bot does not start a path there
}

/*
=============
bot_release

Lets go of every button and stops moving.
=============
*/
bot_release()
{
	self back2uo\_back2uo_libcod::back2uo_libcod_fireweapon(false);
	self back2uo\_back2uo_libcod::back2uo_libcod_reloadweapon(false);
	self back2uo\_back2uo_libcod::back2uo_libcod_meleeweapon(false);
	self back2uo\_back2uo_libcod::back2uo_libcod_setaim(false);
	self back2uo\_back2uo_libcod::back2uo_libcod_setlean("none");
	self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("none");
	self back2uo\_back2uo_libcod::back2uo_libcod_setbotstance("stand");
}

/*
=============
bot_skill

Returns the skill settings for a skill level.
Params: level - 1 easy, 2 normal, 3 hard
=============
*/
bot_skill(skilllevel)
{
	skill = spawnstruct();

	switch(skilllevel)
	{
	case 1:
		skill.reaction = 900;		// ms between seeing an enemy and the first shot
		skill.aimerror = 90;		// aim error in units at 1000 units distance, before it shrinks
		skill.turnspeed = 12;		// degrees per server frame in combat
		break;
	case 3:
		skill.reaction = 250;
		skill.aimerror = 30;
		skill.turnspeed = 35;
		break;
	default:
		skill.reaction = 500;
		skill.aimerror = 55;
		skill.turnspeed = 20;
		break;
	}

	return skill;
}

/*
=============
bot_find_enemy

Every 250 ms: picks the nearest living enemy the bot can see. The current enemy stays
selected while it is visible, even outside the field of view. When the enemy is lost, its
last position is kept as the next goal.
=============
*/
bot_find_enemy()
{
	if(gettime() < self.b2ubot.nextscan) return;
	self.b2ubot.nextscan = gettime() + 250;

	eye = self back2uo\_back2uo_libcod::back2uo_libcod_getvieworigin();
	forward = anglestoforward(self getPlayerAngles());
	teambased = getcvar("g_gametype") != "dm";

	best = undefined;
	bestdist = 4000 * 4000;

	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player == self || !isdefined(player.sessionstate) || player.sessionstate != "playing") continue;
		if(teambased && isdefined(player.pers["team"]) && player.pers["team"] == self.pers["team"]) continue;

		target = bot_aimpoint(player);
		dist = distancesquared(eye, target);

		if(dist > bestdist) continue;

		// Field of view: 120 degrees, but notice anyone very close and keep the current enemy
		if(dist > 300 * 300 && (!isdefined(self.b2ubot.enemy) || player != self.b2ubot.enemy))
		{
			if(vectordot(vectornormalize(target - eye), forward) < 0.5) continue;
		}

		if(!sighttracepassed(eye, target, false, self)) continue;

		best = player;
		bestdist = dist;
	}

	if(isdefined(best))
	{
		if(!isdefined(self.b2ubot.enemy) || best != self.b2ubot.enemy)
		{
			self.b2ubot.enemy = best;
			self.b2ubot.enemysince = gettime();
			self.b2ubot.nextaimerror = 0;
			self.b2ubot.path = undefined;
		}
		return;
	}

	if(isdefined(self.b2ubot.enemy))
	{
		// Lost sight: go and look where the enemy was
		self.b2ubot.lastseenpos = self.b2ubot.enemy.origin;
		self.b2ubot.lastseentime = gettime();
		self.b2ubot.enemy = undefined;
		self.b2ubot.path = undefined;

		bot_fire(false);
		bot_melee(false);
		bot_zoom(false);
		self back2uo\_back2uo_libcod::back2uo_libcod_setwalkvalues(0, 0);
	}
}

/*
=============
bot_aimpoint

Returns the point a bot aims at: a bit below the eyes of the player (upper chest).
Params: player - target player
=============
*/
bot_aimpoint(player)
{
	return player back2uo\_back2uo_libcod::back2uo_libcod_getvieworigin() - (0, 0, 10);
}

/*
=============
bot_combat

Fights the current enemy: aim with the skill's turn speed and aim error, fire after the
reaction time, reload when the clip is empty, melee an enemy within reach, strafe.
=============
*/
bot_combat()
{
	enemy = self.b2ubot.enemy;

	if(!isdefined(enemy) || !isdefined(enemy.sessionstate) || enemy.sessionstate != "playing")
	{
		self.b2ubot.enemy = undefined;
		bot_fire(false);
		bot_melee(false);
		bot_zoom(false);
		self back2uo\_back2uo_libcod::back2uo_libcod_setwalkvalues(0, 0);
		return;
	}

	skill = self.b2ubot.skill;
	eye = self back2uo\_back2uo_libcod::back2uo_libcod_getvieworigin();
	target = bot_aimpoint(enemy);
	dist = distance(eye, target);
	seen = gettime() - self.b2ubot.enemysince;

	// New random aim error twice a second; it shrinks to a third over 2 seconds on target
	if(gettime() >= self.b2ubot.nextaimerror)
	{
		self.b2ubot.nextaimerror = gettime() + 500;

		scale = skill.aimerror * dist / 1000;
		if(seen < 2000) scale = scale * (1 - seen / 3000.0);
		else scale = scale / 3;

		// CoD2 cannot multiply a vector by a number directly
		self.b2ubot.aimerror = maps\mp\_utility::vectorScale((randomfloat(2) - 1, randomfloat(2) - 1, randomfloat(2) - 1), scale);
	}

	offaim = bot_turn(vectortoangles(target + self.b2ubot.aimerror - eye), skill.turnspeed);

	weapon = self getCurrentWeapon();
	kind = bot_weaponkind(weapon);

	// Snipers zoom in, rifles only at range
	bot_zoom(kind == "sniper" || (kind != "auto" && kind != "shotgun" && dist > 1200));

	// Melee an enemy within reach instead of shooting or reloading
	melee = bot_inmeleerange(dist, offaim);
	bot_melee(melee);

	if(melee)
	{
		bot_fire(false);

		if(self.b2ubot.reloading)
		{
			self back2uo\_back2uo_libcod::back2uo_libcod_reloadweapon(false);
			self.b2ubot.reloading = false;
		}
	}
	// Reload an empty clip; wait for the reload to finish
	else if(self back2uo\_back2uo_libcod::back2uo_libcod_getcurrentweaponclipammo() == 0 && !self back2uo\_back2uo_libcod::back2uo_libcod_isonladder())
	{
		bot_fire(false);

		if(!self.b2ubot.reloading)
		{
			self back2uo\_back2uo_libcod::back2uo_libcod_reloadweapon(true);
			self.b2ubot.reloading = true;
		}
		else if(!self back2uo\_back2uo_libcod::back2uo_libcod_isreloading())
		{
			self back2uo\_back2uo_libcod::back2uo_libcod_reloadweapon(false);
			self.b2ubot.reloading = false;
		}
	}
	else
	{
		if(self.b2ubot.reloading)
		{
			self back2uo\_back2uo_libcod::back2uo_libcod_reloadweapon(false);
			self.b2ubot.reloading = false;
		}

		// Fire once the reaction time is over and the aim is close enough (wider when close).
		// Rockets only from a safe distance, the splash would hit the bot itself.
		bot_fire(seen >= skill.reaction && offaim < 3 + 300 / (dist + 1) && (kind != "rocket" || dist > 400));
	}

	// Strafe left / right / stand, change every 0.6 to 1.5 seconds; shotguns close in
	if(gettime() >= self.b2ubot.nextstrafe)
	{
		self.b2ubot.nextstrafe = gettime() + 600 + randomint(900);
		self.b2ubot.strafe = (randomint(3) - 1) * 127;
	}

	forwardmove = 0;
	if(kind == "shotgun" && dist > 250) forwardmove = 127;
	if(kind == "sniper") self.b2ubot.strafe = 0;

	self back2uo\_back2uo_libcod::back2uo_libcod_setwalkvalues(forwardmove, self.b2ubot.strafe);
}

/*
=============
bot_fire

Presses or releases fire. Automatic weapons hold the button; other weapons press it for
one shot and wait their fire interval before the next.
Params: on - true to shoot
=============
*/
bot_fire(on)
{
	if(!on)
	{
		if(self.b2ubot.firing) self back2uo\_back2uo_libcod::back2uo_libcod_fireweapon(false);
		self.b2ubot.firing = false;
		return;
	}

	kind = bot_weaponkind(self getCurrentWeapon());

	if(kind == "auto")
	{
		if(!self.b2ubot.firing) self back2uo\_back2uo_libcod::back2uo_libcod_fireweapon(true);
		self.b2ubot.firing = true;
		return;
	}

	// Single shots: press for 100 ms, then release until the weapon is ready again
	if(self.b2ubot.firing)
	{
		if(gettime() - self.b2ubot.shotstart >= 100)
		{
			self back2uo\_back2uo_libcod::back2uo_libcod_fireweapon(false);
			self.b2ubot.firing = false;
			self.b2ubot.nextshot = gettime() + bot_weaponinterval(kind);
		}
	}
	else if(gettime() >= self.b2ubot.nextshot)
	{
		self back2uo\_back2uo_libcod::back2uo_libcod_fireweapon(true);
		self.b2ubot.firing = true;
		self.b2ubot.shotstart = gettime();
	}
}

/*
=============
bot_inmeleerange

Returns true when the enemy is within melee reach (player_meleeRange is 64 units) and the
bot faces it.
Params: dist - distance from the bot's eye to the aim point
        offaim - degrees between the view and the aim point
=============
*/
bot_inmeleerange(dist, offaim)
{
	return dist < 64 && offaim < 30;
}

/*
=============
bot_melee

Presses melee for 100 ms, then releases it until the swing is over (one swing per second).
Releasing takes effect at once.
Params: on - true to melee
=============
*/
bot_melee(on)
{
	if(self.b2ubot.meleeing)
	{
		if(on && gettime() - self.b2ubot.meleestart < 100) return;

		self back2uo\_back2uo_libcod::back2uo_libcod_meleeweapon(false);
		self.b2ubot.meleeing = false;
		self.b2ubot.nextmelee = self.b2ubot.meleestart + 1000;
	}
	else if(on && gettime() >= self.b2ubot.nextmelee)
	{
		self back2uo\_back2uo_libcod::back2uo_libcod_meleeweapon(true);
		self.b2ubot.meleeing = true;
		self.b2ubot.meleestart = gettime();
	}
}

/*
=============
bot_zoom

Aims down the sights (right mouse button) or stops aiming.
Params: on - true to zoom in
=============
*/
bot_zoom(on)
{
	if(self.b2ubot.aiming == on) return;

	self back2uo\_back2uo_libcod::back2uo_libcod_setaim(on);
	self.b2ubot.aiming = on;
}

/*
=============
bot_weaponkind

Returns how a weapon is fired: "auto", "semi", "bolt", "sniper", "shotgun" or "pistol".
Params: weapon - weapon name
=============
*/
bot_weaponkind(weapon)
{
	if(!isdefined(weapon)) return "semi";

	switch(weapon)
	{
	case "thompson_mp":
	case "greasegun_mp":
	case "sten_mp":
	case "bren_mp":
	case "bar_mp":
	case "ppsh_mp":
	case "PPS42_mp":
	case "mp40_mp":
	case "mp44_mp":
	case "dp28_mp":
		return "auto";
	case "m1carbine_mp":
	case "m1garand_mp":
	case "SVT40_mp":
	case "g43_mp":
		return "semi";
	case "enfield_mp":
	case "kar98k_mp":
	case "mosin_nagant_mp":
		return "bolt";
	case "springfield_mp":
	case "enfield_scope_mp":
	case "kar98k_sniper_mp":
	case "mosin_nagant_sniper_mp":
	case "g43_sniper_mp":
		return "sniper";
	case "shotgun_mp":
	case "shotgun_mp_allies":
	case "shotgun_mp_axis":
		return "shotgun";
	case "colt_mp":
	case "webley_mp":
	case "luger_mp":
	case "TT30_mp":
	case "tt30_mp":
		return "pistol";
	case "panzerschreck_mp":
	case "panzerfaust_mp":
		return "rocket";
	}

	return "semi";
}

/*
=============
bot_weaponinterval

Returns the time in ms between two shots of a weapon kind that fires single shots.
Params: kind - see bot_weaponkind()
=============
*/
bot_weaponinterval(kind)
{
	switch(kind)
	{
	case "bolt":
	case "sniper":
		return 1300;
	case "shotgun":
		return 1000;
	case "pistol":
		return 350;
	case "rocket":
		return 2000;
	}

	return 300;
}

/*
=============
bot_navigate

Walks along the current waypoint path; plans a new one when there is none. Without
waypoints on this map the bot roams.
=============
*/
bot_navigate()
{
	if(!isdefined(level.back2uo_wp_count) || !level.back2uo_wp_count)
	{
		bot_roam();
		return;
	}

	// Short pause at a goal: stand and look around
	if(gettime() < self.b2ubot.waituntil)
	{
		bot_walk(false);
		return;
	}

	if(!isdefined(self.b2ubot.path))
	{
		bot_walk(false);
		if(!self.b2ubot.planning) self thread bot_plan();
		return;
	}

	path = self.b2ubot.path;
	index = self.b2ubot.pathindex;
	node = path[index];
	nodepos = level.back2uo_wp_origin[node];

	// Edge from the previous node to this one: how to get there
	edgetype = 0;
	if(index > 0)
	{
		edgetype = back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(path[index - 1], node);
		if(!isdefined(edgetype)) edgetype = 0;
	}

	delta = nodepos - self.origin;
	flatdist = length((delta[0], delta[1], 0));
	onladder = self back2uo\_back2uo_libcod::back2uo_libcod_isonladder();

	// Reached: close enough on the ground plane and roughly at the same height (ladders: by height)
	reached = flatdist < 24 && bot_abs(delta[2]) < 72;
	if(onladder && edgetype & level.back2uo_wpbit["ladder"]) reached = bot_abs(delta[2]) < 24;

	if(reached)
	{
		self.b2ubot.pathindex++;
		self.b2ubot.jumped = false;

		if(self.b2ubot.pathindex >= path.size)
		{
			// Goal reached
			self.b2ubot.path = undefined;
			self.b2ubot.lastseenpos = undefined;
			self.b2ubot.waituntil = gettime() + randomint(1500);
			bot_set_stance("stand");
		}
		return;
	}

	// Look at the node; on ladders also up or down, else level
	angles = vectortoangles(delta);
	if(edgetype & level.back2uo_wpbit["ladder"] || onladder)
	{
		if(delta[2] > 0) angles = (-70, angles[1], 0);
		else angles = (70, angles[1], 0);
	}
	else
		angles = (0, angles[1], 0);

	offaim = bot_turn(angles, 30);

	// Turn on the spot first if the node is far to the side, else walk
	bot_walk(offaim < 60 || onladder);

	// Jump edges: jump once right after leaving the previous node. Mantle edges: jump
	// whenever the game shows the mantle hint.
	if(edgetype & level.back2uo_wpbit["jump"] && !self.b2ubot.jumped && offaim < 30)
	{
		self.b2ubot.jumped = true;
		self thread bot_jump();
	}
	else if(edgetype & level.back2uo_wpbit["mantle"] && self back2uo\_back2uo_libcod::back2uo_libcod_canmantle() && !self back2uo\_back2uo_libcod::back2uo_libcod_ismantling())
	{
		self thread bot_jump();
	}

	// Stance of the node when near it
	if(isdefined(level.back2uo_wp_stance[node]) && flatdist < 96)
		bot_set_stance(level.back2uo_wp_stance[node]);
	else if(!isdefined(level.back2uo_wp_stance[node]))
		bot_set_stance("stand");

	bot_check_stuck();
}

/*
=============
bot_plan

Plans a path from the nearest visible waypoint to a goal: the last seen enemy position
(within 10 seconds), else a random waypoint. Tries 5 goals, as some maps have waypoints
that cannot reach each other.
Called on: self = bot (threaded)
=============
*/
bot_plan()
{
	self endon("disconnect");
	self endon("killed_player");
	self endon("spawned");
	level endon("intermission");

	self.b2ubot.planning = true;

	start = bot_start_node();
	path = undefined;

	for(attempt = 0; attempt < 5 && !isdefined(path); attempt++)
	{
		if(attempt == 0 &&isdefined(self.b2ubot.lastseenpos) && gettime() - self.b2ubot.lastseentime < 10000)
			goal = back2uo\bots\_back2uo_waypoints::back2uo_wp_closest(self.b2ubot.lastseenpos);
		else
			goal = randomint(level.back2uo_wp_count);

		if(goal == start) continue;

		path = back2uo\bots\_back2uo_waypoints::back2uo_wp_path(start, goal);
	}

	self.b2ubot.path = path;
	self.b2ubot.pathindex = 0;
	self.b2ubot.jumped = false;
	self.b2ubot.planning = false;
}

/*
=============
bot_start_node

Returns the nearest waypoint the bot can see at knee height (within 1000 units) and has not
got stuck at lately, else the nearest one.
=============
*/
bot_start_node()
{
	// Knee height: a higher trace looks over fences and low walls the bot cannot walk through
	knee = self.origin + (0, 0, 24);
	best = undefined;
	bestdist = 1000 * 1000;

	for(i = 0; i < level.back2uo_wp_count; i++)
	{
		dist = distancesquared(self.origin, level.back2uo_wp_origin[i]);

		if(dist >= bestdist) continue;
		if(isdefined(self.b2ubot.avoid[i]) && gettime() < self.b2ubot.avoid[i]) continue;

		// Only nodes that beat the current best need the (expensive) sight trace
		if(!sighttracepassed(knee, level.back2uo_wp_origin[i] + (0, 0, 24), false, self)) continue;

		best = i;
		bestdist = dist;
	}

	if(!isdefined(best)) best = back2uo\bots\_back2uo_waypoints::back2uo_wp_closest(self.origin);

	return best;
}

/*
=============
bot_check_stuck

Once a second while walking: a bot that moved less than 16 units is stuck. First it jumps,
then strafes for a moment, then plans a new path from where it is.
=============
*/
bot_check_stuck()
{
	if(gettime() < self.b2ubot.stuckcheck) return;
	self.b2ubot.stuckcheck = gettime() + 1000;

	moved = distance(self.origin, self.b2ubot.stuckpos);
	self.b2ubot.stuckpos = self.origin;

	if(!self.b2ubot.walking || moved >= 16)
	{
		self.b2ubot.stuck = 0;
		return;
	}

	self.b2ubot.stuck++;

	switch(self.b2ubot.stuck)
	{
	case 1:
		self thread bot_jump();
		break;
	case 2:
		self thread bot_sidestep();
		break;
	default:
		// New route from here, not via the node the bot could not reach
		if(isdefined(self.b2ubot.path))
			self.b2ubot.avoid[self.b2ubot.path[self.b2ubot.pathindex]] = gettime() + 15000;

		self.b2ubot.stuck = 0;
		self.b2ubot.path = undefined;
		break;
	}
}

/*
=============
bot_roam

Maps without waypoints: walk forward, turn away from walls in front.
=============
*/
bot_roam()
{
	angles = self getPlayerAngles();
	start = self.origin + (0, 0, 32);
	end = start + maps\mp\_utility::vectorScale(anglestoforward((0, angles[1], 0)), 64);

	if(!sighttracepassed(start, end, false, self))
		self setPlayerAngles((0, angles[1] + 90 + randomint(180), 0));

	bot_walk(true);
	bot_check_stuck();
}

/*
=============
bot_turn

Turns the bot towards the given view angles by at most maxturn degrees per axis.
Params: want - wanted view angles
		maxturn - degrees per call
Returns: the larger of the remaining yaw and pitch difference before the turn, in degrees
=============
*/
bot_turn(want, maxturn)
{
	current = self getPlayerAngles();

	pitchdiff = bot_anglediff(want[0], current[0]);
	yawdiff = bot_anglediff(want[1], current[1]);

	pitch = bot_anglediff(current[0] + bot_clamp(pitchdiff, maxturn), 0);
	if(pitch > 85) pitch = 85;
	if(pitch < -85) pitch = -85;

	self setPlayerAngles((pitch, current[1] + bot_clamp(yawdiff, maxturn), 0));

	if(bot_abs(pitchdiff) > bot_abs(yawdiff)) return bot_abs(pitchdiff);
	return bot_abs(yawdiff);
}

/*
=============
bot_walk

Walks forward or stops. Only sends the input when it changes.
Params: on - true to walk
=============
*/
bot_walk(on)
{
	if(gettime() < self.b2ubot.unstuckuntil) return;

	if(on) self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("forward");
	else self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("none");

	self.b2ubot.walking = on;
}

/*
=============
bot_jump

Presses jump for a moment.
Called on: self = bot (threaded)
=============
*/
bot_jump()
{
	self endon("disconnect");

	self back2uo\_back2uo_libcod::back2uo_libcod_setbotstance("jump");
	wait .1;
	self back2uo\_back2uo_libcod::back2uo_libcod_setbotstance(self.b2ubot.stance);
}

/*
=============
bot_sidestep

Strafes to a random side for half a second to get around an obstacle.
Called on: self = bot (threaded)
=============
*/
bot_sidestep()
{
	self endon("disconnect");
	self endon("killed_player");

	self.b2ubot.unstuckuntil = gettime() + 500;

	if(randomint(2)) self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("left");
	else self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("right");

	wait .5;

	self back2uo\_back2uo_libcod::back2uo_libcod_setwalkdir("none");
}

/*
=============
bot_set_stance

Sets the stance ("stand", "crouch" or "prone") if it differs from the current one.
Params: stance - wanted stance
=============
*/
bot_set_stance(stance)
{
	if(self.b2ubot.stance == stance) return;

	self back2uo\_back2uo_libcod::back2uo_libcod_setbotstance(stance);
	self.b2ubot.stance = stance;
}

/*
=============
bot_anglediff

Returns a - b in degrees, wrapped to -180 .. 180.
Params: a, b - angles in degrees
=============
*/
bot_anglediff(a, b)
{
	diff = a - b;

	while(diff > 180) diff -= 360;
	while(diff < -180) diff += 360;

	return diff;
}

/*
=============
bot_clamp

Returns value limited to -limit .. limit.
Params: value, limit - numbers, limit >= 0
=============
*/
bot_clamp(value, limit)
{
	if(value > limit) return limit;
	if(value < 0 - limit) return 0 - limit;

	return value;
}

/*
=============
bot_abs

Returns the absolute value of a number.
Params: value - number
=============
*/
bot_abs(value)
{
	if(value < 0) return 0 - value;

	return value;
}
