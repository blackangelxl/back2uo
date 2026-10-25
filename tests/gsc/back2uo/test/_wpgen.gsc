/*
	Back2Uo v2.1 - bot waypoint generator (test build only)

	Builds walk waypoints for maps without MeatBot waypoints. Starts at every spawnpoint
	and floods the map on a grid of level.wpgen_grid units. Two neighbour points are linked
	when a player can walk between them in both directions, checked with physicstrace()
	(the player collision, so playerclip counts). Falls, jumps, ladders and crouch spots are
	not detected. The result goes to the game log:
		WPGEN;N;<id>;<x>;<y>;<z>
		WPGEN;E;<id>;<id>
		WPGEN;F;<id>;<x>;<y>;<z>;<reason>	neighbour with floor but no link (see wpgen_walkable)
		WPGEN;DONE;<nodes>;<edges>
	tools/wpgen.py starts the test server with back2uo_wpgen 1 and turns the lines into a
	MeatBot .wp file for tools/wp2gsc.py.
*/

/*
=============
run

Generates the waypoints of the current map and writes them to the game log.
Called on: level (from _back2uo_test::run with back2uo_wpgen 1)
=============
*/
run()
{
	level.wpgen_grid = getcvarint("back2uo_wpgen_grid");
	if(level.wpgen_grid < 32) level.wpgen_grid = 128;

	level.wpgen_origin = [];
	level.wpgen_cell = [];
	level.wpgen_done = [];
	level.wpgen_count = 0;
	level.wpgen_edges = 0;

	logPrint("WPGEN;START;" + getcvar("mapname") + ";grid=" + level.wpgen_grid + "\n");

	classes = [];
	classes[classes.size] = "mp_dm_spawn";
	classes[classes.size] = "mp_tdm_spawn";
	classes[classes.size] = "mp_ctf_spawn_allied";
	classes[classes.size] = "mp_ctf_spawn_axis";
	classes[classes.size] = "mp_sd_spawn_attacker";
	classes[classes.size] = "mp_sd_spawn_defender";

	for(c = 0; c < classes.size; c++)
	{
		spawnpoints = getentarray(classes[c], "classname");
		for(i = 0; i < spawnpoints.size; i++)
			wpgen_seed(spawnpoints[i].origin);
		wait .05;
	}

	// Breadth-first flood fill; the queue is the node list itself
	for(id = 0; id < level.wpgen_count; id++)
	{
		wpgen_expand(id);
		if(id % 2 == 1) wait .05;
	}

	logPrint("WPGEN;DONE;" + level.wpgen_count + ";" + level.wpgen_edges + "\n");
}

/*
=============
wpgen_seed

Adds the grid point next to a spawnpoint, if a player can walk there from the spawnpoint.
Params: origin - spawnpoint origin
=============
*/
wpgen_seed(origin)
{
	start = wpgen_ground(origin[0], origin[1], origin[2] + 32, origin[2] - 64);
	if(!isdefined(start)) return;

	x = wpgen_snap(start[0]);
	y = wpgen_snap(start[1]);

	pos = wpgen_ground(x, y, start[2] + 56, start[2] - 64);
	if(!isdefined(pos)) return;
	if(isdefined(wpgen_find(pos))) return;
	if(wpgen_walkable(start, pos) != "") return;

	wpgen_add(pos);
}

/*
=============
wpgen_expand

Checks the 8 grid neighbours of a node, adds the reachable ones and logs the edges. A pair
is checked only once: from the node that is expanded first.
Params: id - node id
=============
*/
wpgen_expand(id)
{
	p = level.wpgen_origin[id];
	g = level.wpgen_grid;

	for(dx = -1; dx <= 1; dx++)
	{
		for(dy = -1; dy <= 1; dy++)
		{
			if(!dx && !dy) continue;

			pos = wpgen_ground(p[0] + dx * g, p[1] + dy * g, p[2] + 56, p[2] - 64);
			if(!isdefined(pos)) continue;

			other = wpgen_find(pos);
			if(isdefined(other))
			{
				if(isdefined(level.wpgen_done[other])) continue;
				pos = level.wpgen_origin[other];
			}

			fail = wpgen_walkable(p, pos);
			if(fail == "") fail = wpgen_walkable(pos, p);
			if(fail != "")
			{
				logPrint("WPGEN;F;" + id + ";" + int(pos[0]) + ";" + int(pos[1]) + ";" + int(pos[2]) + ";" + fail + "\n");
				continue;
			}

			if(!isdefined(other)) other = wpgen_add(pos);

			logPrint("WPGEN;E;" + id + ";" + other + "\n");
			level.wpgen_edges++;
		}
	}

	level.wpgen_done[id] = true;
}

/*
=============
wpgen_walkable

Whether a standing player can walk in a straight line from a to b. Follows the floor in 8
parts of 16 (diagonal 23) units: each part may climb at most a step (18 units, also a 45
degree slope), drop at most 32 units, and needs room at knee, chest and head height (chest
also 14 units to each side). The walk has to end on b's floor.
Params: a, b - ground positions
Returns: "" if walkable, else what blocks: "gap", "step", "wall", "head", "side", "floor"
=============
*/
wpgen_walkable(a, b)
{
	dir = vectornormalize((b[0] - a[0], b[1] - a[1], 0));
	left = (dir[1] * -14, dir[0] * 14, 44);
	right = (dir[1] * 14, dir[0] * -14, 44);

	cur = a;
	for(i = 1; i <= 8; i++)
	{
		t = i * .125;
		next = wpgen_ground(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, cur[2] + 40, cur[2] - 32);
		if(!isdefined(next)) return "gap";

		if(next[2] - cur[2] > 18) return "step";

		if(!wpgen_clear(cur + (0, 0, 24), next + (0, 0, 24))) return "wall";
		if(!wpgen_clear(cur + (0, 0, 44), next + (0, 0, 44))) return "wall";
		if(!wpgen_clear(cur + (0, 0, 66), next + (0, 0, 66))) return "head";
		if(!wpgen_clear(cur + left, next + left)) return "side";
		if(!wpgen_clear(cur + right, next + right)) return "side";

		cur = next;
	}

	if(cur[2] - b[2] > 8 || cur[2] - b[2] < -8) return "floor";

	return "";
}

/*
=============
wpgen_clear

Params: from, to - trace points
Returns: true if nothing solid is between them
=============
*/
wpgen_clear(from, to)
{
	return distancesquared(physicstrace(from, to), to) < 1;
}

/*
=============
wpgen_ground

Finds the floor below a point.
Params: x, y - position
		top, bottom - height range to search, from top down
Returns: floor position, undefined if there is none in the range or top is inside a wall
=============
*/
wpgen_ground(x, y, top, bottom)
{
	pos = physicstrace((x, y, top), (x, y, bottom));

	if(pos[2] > top - 1) return undefined;
	if(pos[2] < bottom + 1) return undefined;

	return pos;
}

/*
=============
wpgen_add

Adds a node and logs it.
Params: pos - ground position
Returns: node id
=============
*/
wpgen_add(pos)
{
	id = level.wpgen_count;
	level.wpgen_count++;

	level.wpgen_origin[id] = pos;

	key = wpgen_cellkey(pos);
	if(!isdefined(level.wpgen_cell[key])) level.wpgen_cell[key] = [];
	level.wpgen_cell[key][level.wpgen_cell[key].size] = id;

	logPrint("WPGEN;N;" + id + ";" + int(pos[0]) + ";" + int(pos[1]) + ";" + int(pos[2]) + "\n");
	return id;
}

/*
=============
wpgen_find

Params: pos - ground position on the grid
Returns: id of the node in the same grid cell less than 40 units higher or lower, or
		undefined (a cell holds one node per floor)
=============
*/
wpgen_find(pos)
{
	key = wpgen_cellkey(pos);
	if(!isdefined(level.wpgen_cell[key])) return undefined;

	ids = level.wpgen_cell[key];
	for(i = 0; i < ids.size; i++)
	{
		dz = level.wpgen_origin[ids[i]][2] - pos[2];
		if(dz < 40 && dz > -40) return ids[i];
	}
	return undefined;
}

/*
=============
wpgen_cellkey

Params: pos - position
Returns: "<x index> <y index>" of the grid cell
=============
*/
wpgen_cellkey(pos)
{
	return wpgen_index(pos[0]) + " " + wpgen_index(pos[1]);
}

/*
=============
wpgen_index

Params: v - coordinate
Returns: index of the nearest grid line; the offset keeps the value positive, as int()
		rounds toward zero
=============
*/
wpgen_index(v)
{
	return int((v + 65536) / level.wpgen_grid + .5);
}

/*
=============
wpgen_snap

Params: v - coordinate
Returns: the nearest grid line
=============
*/
wpgen_snap(v)
{
	return wpgen_index(v) * level.wpgen_grid - 65536;
}
