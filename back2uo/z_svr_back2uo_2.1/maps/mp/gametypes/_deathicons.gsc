/*
	Back2Uo v2.1 - death icons (skull waypoints over dead teammates)

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from the gametype scripts; addDeathIcon() is called from the gametype
	Callback_PlayerKilled with the player's body. Icons are team hud elements stored per team in
	level.deathicons[team].array and removed on respawn, disconnect or after a timeout.
	Back2Uo: everything is gated by game["back2uo_deathicon_enable"] (cvar back2uo_deathicon, default 0).
*/

/*
=============
init

Precaches the skull shader, creates the per-team icon lists and starts the connect watcher.
Back2Uo: does nothing when death icons are disabled.
=============
*/
init()
{
	// Back2Uo: death icons ( 0 = off | 1 = on, default 0 ).
	if(!(game["back2uo_deathicon_enable"])) return;

	precacheShader("headicon_dead");

	level.deathicons["allies"] = spawnstruct();
	level.deathicons["allies"].array = [];
	level.deathicons["axis"] = spawnstruct();
	level.deathicons["axis"].array = [];
	level.deathicons["spectator"] = spawnstruct();
	level.deathicons["spectator"].array = [];

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Starts the spawn and disconnect watchers for every connecting player.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player thread onPlayerSpawned();
		player thread onPlayerDisconnect();
	}
}

/*
=============
onPlayerSpawned

Removes the player's death icon every time the player respawns.
Called on: player
=============
*/
onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		removeDeathIcon(self.clientid);
	}
}

/*
=============
onPlayerDisconnect

Removes the player's death icon when the player leaves.
Called on: player
=============
*/
onPlayerDisconnect()
{
	self waittill("disconnect");

	removeDeathIcon(self.clientid);
}

/*
=============
addDeathIcon

Places a skull waypoint above the given entity, visible to the dead player's team and to
spectators. With a timeout the icons are removed again after that many seconds.
Params: entity - usually the player's body (clone); its origin is used
		id - owner id (player clientid), used by removeDeathIcon
		team - "allies" or "axis"
		timeout - optional, seconds until the icons are removed
=============
*/
addDeathIcon(entity, id, team, timeout)
{

	// Back2Uo: death icons ( 0 = off | 1 = on, default 0 ).
	if(game["back2uo_deathicon_enable"] == 1)
	{
		assert(team == "allies" || team == "axis");

		// Icon for the dead player's team; z + 54 places it roughly above the head.
		newdeathicon = newTeamHudElem(team);
		newdeathicon.id = id;
		newdeathicon.x = entity.origin[0];
		newdeathicon.y = entity.origin[1];
		newdeathicon.z = entity.origin[2] + 54;
		newdeathicon.alpha = .61;
		newdeathicon.archived = true;
		newdeathicon setShader("headicon_dead", 7, 7); // 56.8% of on screen headicons size
		newdeathicon setwaypoint(true); // world-positioned, scales with distance
		level.deathicons[team].array[level.deathicons[team].array.size] = newdeathicon;

		// Same icon again for spectators.
		newdeathicon = newTeamHudElem("spectator");
		newdeathicon.id = id;
		newdeathicon.x = entity.origin[0];
		newdeathicon.y = entity.origin[1];
		newdeathicon.z = entity.origin[2] + 54;
		newdeathicon.alpha = .61;
		newdeathicon.archived = true;
		newdeathicon setShader("headicon_dead", 7, 7); // 56.8% of on screen headicons size
		newdeathicon setwaypoint(true);
		level.deathicons["spectator"].array[level.deathicons["spectator"].array.size] = newdeathicon;

		// Disabled: debug output.
		//	println("ADDED ID: ", id, " to ", team, " array");
		//	println("ADDED ID: ", id, " to spectator array");

		if(isdefined(timeout))
		{
			wait timeout;
			removeDeathIcon(id);
		}
	}
	else return;
}

/*
=============
removeDeathIcon

Destroys the icon with the given id in each of the three team lists (allies, axis, spectator).
The removed slot is filled with the last element so the arrays stay packed.
Params: id - owner id passed to addDeathIcon
=============
*/
removeDeathIcon(id)
{
	for(i = 0; i < 3; i++)
	{
		if(i == 0)
			team = "allies";
		else if(i == 1)
			team = "axis";
		else
			team = "spectator";

		removeElement = undefined;

		for(j = 0; j < level.deathicons[team].array.size; j++)
		{
			if(level.deathicons[team].array[j].id != id)
				continue;

			removeElement = level.deathicons[team].array[j];
			break;
		}

		if(isdefined(removeElement))
		{
			lastElement = level.deathicons[team].array.size - 1;

			// Swap-remove: move the last element into the freed slot, then drop the last slot.
			for(j = 0; j < level.deathicons[team].array.size; j++)
			{
				if(level.deathicons[team].array[j] != removeElement)
					continue;

				level.deathicons[team].array[j] = level.deathicons[team].array[lastElement];
				level.deathicons[team].array[lastElement] = undefined;
				break;
			}

			removeElement destroy();

			// Disabled: debug output.
			//			println("REMOVED ID: ", id, " from ", team, " array");
		}
	}
}
