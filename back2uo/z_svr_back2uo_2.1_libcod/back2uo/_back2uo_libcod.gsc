/*
	Back2Uo v2.1 - zk_libcod function wrappers, zk_libcod version (z_svr_back2uo_2.1_libcod.iwd).

	Every zk_libcod function the mod uses is called only from here. This file replaces the
	release stub back2uo\_back2uo_libcod.gsc in z_svr_back2uo_2.1.iwd: CoD2 searches .iwd files
	in reverse order of their upper-cased names, so z_svr_back2uo_2.1_libcod.iwd comes first.

	CoD2 resolves builtin functions when the script is compiled, so this file only loads on a
	server with zk_libcod. Without zk_libcod, leave z_svr_back2uo_2.1_libcod.iwd out; the stub
	then runs the fallbacks of back2uo\_back2uo_libcod_fallback.gsc. They are also used here
	when the "libcod" dvar of zk_libcod is missing.

	Some functions come from extra modules compiled into zk_libcod by server/Dockerfile, so this
	file needs that build: setBinocularsBlocked (server/extra/back2uo_binoculars.cpp), and the
	graph* functions and getPlayersByViewOriginInRange of the cod2-server extra module
	(github.com/rutkowski-tomasz/cod2-server, server/extra).
*/

/*
=============
back2uo_libcod_active

Returns true when zk_libcod is loaded. Read once per map from the "libcod" dvar.
=============
*/
back2uo_libcod_active()
{
	if(!isdefined(level.back2uo_libcod))
	{
		level.back2uo_libcod = (getCvar("libcod") != "");

		// The log switch may not be read yet when this runs before back2uo_main.
		if(!level.back2uo_libcod && isdefined(game["back2uo_logprint_enable"])) back2uo\_back2uo_cvars::back2uo_logevent("libcod", "missing", "fallback=on");
	}

	return level.back2uo_libcod;
}

// --- Player movement ---

/*
=============
back2uo_libcod_setspeed

Sets the player's movement speed; 0 returns to g_speed.
Called on: self = player
=============
*/
back2uo_libcod_setspeed(speed)
{
	if(back2uo_libcod_active()) self setSpeed(speed);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setspeed(speed);
}

/*
=============
back2uo_libcod_getspeed

Returns the player's movement speed.
Called on: self = player
=============
*/
back2uo_libcod_getspeed()
{
	if(back2uo_libcod_active()) return self getSpeed();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getspeed();
}

/*
=============
back2uo_libcod_setholdingweapondown

Holds the weapon down (no firing, no weapon switch) or raises it again.
Called on: self = player
=============
*/
back2uo_libcod_setholdingweapondown(on)
{
	if(back2uo_libcod_active()) self setHoldingWeaponDown(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setholdingweapondown(on);
}

// --- Player state ---

/*
=============
back2uo_libcod_aimbuttonpressed

Returns true while the player holds the zoom (ADS) key. zk_libcod reads the key itself, so
this also works while the weapon is held down.
Called on: self = player
=============
*/
back2uo_libcod_aimbuttonpressed()
{
	if(back2uo_libcod_active()) return self aimButtonPressed();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_aimbuttonpressed();
}

/*
=============
back2uo_libcod_forwardbuttonpressed

Returns true while the player holds the forward key.
Called on: self = player
=============
*/
back2uo_libcod_forwardbuttonpressed()
{
	if(back2uo_libcod_active()) return self forwardButtonPressed();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_forwardbuttonpressed();
}

/*
=============
back2uo_libcod_isusingbinoculars

Returns true while the player looks through the binoculars.
Called on: self = player
=============
*/
back2uo_libcod_isusingbinoculars()
{
	if(back2uo_libcod_active()) return self isUsingBinoculars();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isusingbinoculars();
}

/*
=============
back2uo_libcod_isbot

Returns true for test clients.
Called on: self = player or client entity
=============
*/
back2uo_libcod_isbot()
{
	if(back2uo_libcod_active()) return self isBot();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_isbot();
}

/*
=============
back2uo_libcod_renameclient

Changes the client's name (bot names from bots\_back2uo_botnames.gsc).
Called on: self = player or bot
=============
*/
back2uo_libcod_renameclient(name)
{
	if(back2uo_libcod_active()) self renameClient(name);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_renameclient(name);
}

/*
=============
back2uo_libcod_getvieworigin

Returns the player's eye position.
Called on: self = player
=============
*/
back2uo_libcod_getvieworigin()
{
	if(back2uo_libcod_active()) return self getViewOrigin();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getvieworigin();
}

/*
=============
back2uo_libcod_getcurrentweaponclipammo

Returns the clip ammo of the current weapon.
Called on: self = player
=============
*/
back2uo_libcod_getcurrentweaponclipammo()
{
	if(back2uo_libcod_active()) return self getCurrentWeaponClipAmmo();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getcurrentweaponclipammo();
}

/*
=============
back2uo_libcod_isreloading

Returns true while the player reloads.
Called on: self = player
=============
*/
back2uo_libcod_isreloading()
{
	if(back2uo_libcod_active()) return self isReloading();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_isonladder

Returns true while the player is on a ladder.
Called on: self = player
=============
*/
back2uo_libcod_isonladder()
{
	if(back2uo_libcod_active()) return self isOnLadder();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_getvelocity

Returns the player's velocity vector in units per second, or undefined without zk_libcod.
Called on: self = player
=============
*/
back2uo_libcod_getvelocity()
{
	if(back2uo_libcod_active()) return self getVelocity();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getvelocity();
}

/*
=============
back2uo_libcod_getstance

Returns the player's stance: "stand", "crouch" or "prone". Replaces two bulletTrace calls of
the fallback; called every frame by the sprint system and the stance HUD.
Called on: self = player
=============
*/
back2uo_libcod_getstance()
{
	if(back2uo_libcod_active()) return self getStance();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getstance();
}

/*
=============
back2uo_libcod_canmantle

Returns true when the player can mantle over the obstacle in front.
Called on: self = player
=============
*/
back2uo_libcod_canmantle()
{
	if(back2uo_libcod_active()) return self canMantle();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_ismantling

Returns true while the player mantles.
Called on: self = player
=============
*/
back2uo_libcod_ismantling()
{
	if(back2uo_libcod_active()) return self isMantling();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_false();
}

/*
=============
back2uo_libcod_getinactivitytime

Returns the engine's inactivity timestamp (client->inactivityTime). It changes only when the
player moves or presses one of a few buttons, so a changed value means activity. The engine
updates it only with g_inactivity != 0 and not for spectators; with g_inactivity 0 this
returns undefined (as the fallback does).
Called on: self = player
=============
*/
back2uo_libcod_getinactivitytime()
{
	if(back2uo_libcod_active() && getcvarint("g_inactivity") != 0) return self getInactivityTime();

	return self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getinactivitytime();
}

// --- Bullets ---

/*
=============
back2uo_libcod_setbulletdrop

Turns bullet gravity on or off for the player's shots. The engine's bullet gravity system only
runs with g_bulletDrop 1 (zk_libcod.cfg, travel time limit g_bulletDropMaxTime); with
g_bulletDrop 0 nothing is called (as the fallback does).
Called on: self = player
=============
*/
back2uo_libcod_setbulletdrop(on)
{
	if(back2uo_libcod_active() && getcvarint("g_bulletDrop") != 0)
	{
		if(on) self enableBulletDrop();
		else self disableBulletDrop();
	}
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_setbulletdrop(on);
}

// --- Bot input ---

/*
=============
back2uo_libcod_setwalkdir

Bot walk direction: "none", "forward", "back", "left" or "right".
Called on: self = bot
=============
*/
back2uo_libcod_setwalkdir(dir)
{
	if(back2uo_libcod_active()) self setWalkDir(dir);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setwalkvalues

Bot forward and right move values (-128 to 127).
Called on: self = bot
=============
*/
back2uo_libcod_setwalkvalues(forward, right)
{
	if(back2uo_libcod_active()) self setWalkValues(forward, right);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setbotstance

Bot stance: "stand", "crouch", "prone" or "jump".
Called on: self = bot
=============
*/
back2uo_libcod_setbotstance(stance)
{
	if(back2uo_libcod_active()) self setBotStance(stance);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setlean

Bot lean: "none", "left" or "right".
Called on: self = bot
=============
*/
back2uo_libcod_setlean(lean)
{
	if(back2uo_libcod_active()) self setLean(lean);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_setaim

Bot zoom (ADS) on or off.
Called on: self = bot
=============
*/
back2uo_libcod_setaim(on)
{
	if(back2uo_libcod_active()) self setAim(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_fireweapon

Bot holds or releases the fire button.
Called on: self = bot
=============
*/
back2uo_libcod_fireweapon(on)
{
	if(back2uo_libcod_active()) self fireWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_reloadweapon

Bot holds or releases the reload button.
Called on: self = bot
=============
*/
back2uo_libcod_reloadweapon(on)
{
	if(back2uo_libcod_active()) self reloadWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

/*
=============
back2uo_libcod_meleeweapon

Bot holds or releases the melee button.
Called on: self = bot
=============
*/
back2uo_libcod_meleeweapon(on)
{
	if(back2uo_libcod_active()) self meleeWeapon(on);
	else self back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_botinput();
}

// --- Binoculars ---

/*
=============
back2uo_libcod_setbinocularsblocked

Blocks (true) or allows (false) the binocular key of the player. Needs the Back2Uo extra
module of zk_libcod (server/extra/back2uo_binoculars.cpp); while blocked the engine never
sees the key and the player gets the notify "binoculars_blocked" once per key press.
Without zk_libcod nothing happens (takeWeapon does not affect the binocular key in CoD2).
Called on: self = player
=============
*/
back2uo_libcod_setbinocularsblocked(on)
{
	if(back2uo_libcod_active()) self setBinocularsBlocked(on);
}

// --- Buttons ---

/*
=============
back2uo_libcod_holdbreathbuttonpressed

Returns true while the player holds the "Hold Breath" key (+holdbreath); false without zk_libcod.
Called on: self = player
=============
*/
back2uo_libcod_holdbreathbuttonpressed()
{
	if(back2uo_libcod_active()) return self holdBreathButtonPressed();

	return false;
}

// --- Time ---

/*
=============
back2uo_libcod_getmicroseconds

Returns the real (wall clock) time in microseconds, masked to 31 bits by zk_libcod (wraps
about every 35 minutes; add 2^31 to a negative difference). Unlike gettime(), which is
game time, it also advances while a server frame takes longer than planned.
=============
*/
back2uo_libcod_getmicroseconds()
{
	if(back2uo_libcod_active()) return getMicroseconds();

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getmicroseconds();
}

// --- Players in range ---

/*
=============
back2uo_libcod_teamid

Returns the engine's team number of a team name (0 free, 1 axis, 2 allies, 3 spectator),
as back2uo_libcod_getplayersbyvieworigininrange expects it.
Params: name - "axis", "allies", "spectator" or "none"
=============
*/
back2uo_libcod_teamid(name)
{
	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_teamid(name);
}

/*
=============
back2uo_libcod_getplayersbyvieworigininrange

Returns the living players in play whose view origin is within sqrt(maxdistsq) of origin,
in no particular order. Needs the cod2-server extra module (getPlayersByViewOriginInRange,
filters in C++); without zk_libcod a script loop does the same.
Params: origin - world position
		maxdistsq - squared distance; undefined = no limit
		team - team number (back2uo_libcod_teamid); undefined = every team
Returns: array of players
=============
*/
back2uo_libcod_getplayersbyvieworigininrange(origin, maxdistsq, team)
{
	if(back2uo_libcod_active()) return getPlayersByViewOriginInRange(origin, maxdistsq, team);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_getplayersbyvieworigininrange(origin, maxdistsq, team);
}

// --- Path finding graph ---
//
// A* graph of the cod2-server extra module (server/extra/gsc_graph.cpp). Graphs live in the
// server, not in the script: graphCreate(false, ...) graphs are deleted on the next map load,
// but survive a round restart (map_restart), so graphcreate removes all graphs first.
// The other functions must only be called with a graph id from back2uo_libcod_graphcreate and
// valid node ids: on bad arguments zk_libcod raises a script error.

/*
=============
back2uo_libcod_graphcreate

Removes all graphs of the server and creates an empty one for this map. Back2Uo is the only
user of the graph functions.
Params: nodecount - expected number of nodes (memory reserve, not a limit)
Returns: graph id, or undefined without zk_libcod (callers then use their script fallback)
=============
*/
back2uo_libcod_graphcreate(nodecount)
{
	if(!back2uo_libcod_active()) return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graphcreate();

	graphRemoveAll();

	return graphCreate(false, nodecount);
}

/*
=============
back2uo_libcod_graphaddnode

Adds a node with a given id.
Params: graph - graph id
		id - node id (must be new)
		origin - position
		type - type bits
Returns: node id
=============
*/
back2uo_libcod_graphaddnode(graph, id, origin, type)
{
	if(back2uo_libcod_active()) return graphAddNode(graph, origin, type, id);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graph();
}

/*
=============
back2uo_libcod_graphaddedge

Adds a directed edge; its cost is the 3D distance between the two nodes.
Params: graph - graph id
		from, to - node ids (must exist, differ, and have no edge yet)
		type - type bits
Returns: true
=============
*/
back2uo_libcod_graphaddedge(graph, from, to, type)
{
	if(back2uo_libcod_active()) return graphAddEdge(graph, from, to, type);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graph();
}

/*
=============
back2uo_libcod_graphfindpath

A* search in C++ (cost = sum of the edge lengths, estimate = 3D distance to the goal).
Params: graph - graph id with at least two nodes
		start, goal - node ids
Returns: node ids from start to goal (both included; start == goal gives [start]),
		or undefined if the goal cannot be reached
=============
*/
back2uo_libcod_graphfindpath(graph, start, goal)
{
	if(back2uo_libcod_active()) return graphFindPath(graph, start, goal);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graph();
}

/*
=============
back2uo_libcod_graphclosestnode

Returns the id of the node nearest to a position (the lowest id on a tie).
Params: graph - graph id with at least one node
		origin - world position
=============
*/
back2uo_libcod_graphclosestnode(graph, origin)
{
	if(back2uo_libcod_active()) return graphFindClosestNode(graph, origin);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graph();
}

/*
=============
back2uo_libcod_graphnodesinrange

Returns the ids of the nodes within sqrt(maxdistsq) of a position, in id order.
Params: graph - graph id
		origin - world position
		maxdistsq - squared distance
=============
*/
back2uo_libcod_graphnodesinrange(graph, origin, maxdistsq)
{
	if(back2uo_libcod_active()) return graphGetAllNodes(graph, origin, maxdistsq);

	return back2uo\_back2uo_libcod_fallback::back2uo_libcod_fallback_graph();
}
