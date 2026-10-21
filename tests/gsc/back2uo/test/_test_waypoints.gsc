/*
	Back2Uo v2.1 - tests for back2uo\bots\_back2uo_waypoints.gsc (test build only)

	Only the current map's waypoint script is compiled (see tools/wp2gsc.py), so the tests
	check the waypoints of the map the test server runs. The general tests work on every map
	with waypoints; mp_toujane and mp_dawnville also get checks against values taken from
	their generated scripts:
		python tests/run_tests.py --map mp_toujane
		python tests/run_tests.py --map mp_dawnville
*/

/*
=============
run

Runs all waypoint tests.
=============
*/
run()
{
	back2uo\test\_assert::suite("waypoints");

	back2uo\bots\_back2uo_waypoints::back2uo_waypoints_load();

	if(!level.back2uo_wp_count)
	{
		back2uo\test\_assert::skip("waypoints", "no waypoints for " + getcvar("mapname"));
		return;
	}

	back2uo\test\_assert::out("INFO;waypoints " + getcvar("mapname") + " " + level.back2uo_wp_count + " nodes");

	test_edges();
	test_special_edges();
	test_closest();
	test_paths();

	switch(getcvar("mapname"))
	{
	case "mp_toujane":
		test_toujane();
		break;
	case "mp_dawnville":
		test_dawnville();
		break;
	}
}

/*
=============
test_edges

Every edge points to an existing node other than its own.
=============
*/
test_edges()
{
	bad = 0;

	for(id = 0; id < level.back2uo_wp_count; id++)
	{
		links = level.back2uo_wp_links[id];

		for(i = 0; i < links.size; i++)
		{
			if(links[i] < 0 || links[i] >= level.back2uo_wp_count || links[i] == id) bad++;
		}
	}

	back2uo\test\_assert::assert_eq("all edges point to other nodes", bad, 0);
}

/*
=============
test_special_edges

Every fall node has a fall edge, every mantle node a mantle edge; the edge back from a
mantle edge's target is a fall edge. (A special node can also have plain walk edges,
added for links stored on its neighbours.)
=============
*/
test_special_edges()
{
	nofall = 0;
	nomantle = 0;
	noback = 0;
	falls = 0;
	mantles = 0;

	for(id = 0; id < level.back2uo_wp_count; id++)
	{
		if(back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(id, "fall"))
		{
			falls++;
			if(!isdefined(special_edge(id, "fall"))) nofall++;
		}

		if(back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(id, "mantle"))
		{
			mantles++;
			target = special_edge(id, "mantle");

			if(!isdefined(target))
				nomantle++;
			else
			{
				type = back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(target, id);
				if(!isdefined(type) || !(type & level.back2uo_wpbit["fall"])) noback++;
			}
		}
	}

	back2uo\test\_assert::out("INFO;" + falls + " fall nodes, " + mantles + " mantle nodes");
	back2uo\test\_assert::assert_eq("fall nodes without fall edge", nofall, 0);
	back2uo\test\_assert::assert_eq("mantle nodes without mantle edge", nomantle, 0);
	back2uo\test\_assert::assert_eq("mantle edges without fall edge back", noback, 0);
}

/*
=============
special_edge

Returns the target of the first edge leaving a node that has the given type bit, or undefined.
Params: id - node id
		name - type name, e.g. "fall"
=============
*/
special_edge(id, name)
{
	links = level.back2uo_wp_links[id];

	for(i = 0; i < links.size; i++)
	{
		type = back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(id, links[i]);
		if(type & level.back2uo_wpbit[name]) return links[i];
	}

	return undefined;
}

/*
=============
test_closest

The closest waypoint to a node's own position is at that position.
=============
*/
test_closest()
{
	id = int(level.back2uo_wp_count / 2);
	origin = level.back2uo_wp_origin[id];
	closest = back2uo\bots\_back2uo_waypoints::back2uo_wp_closest(origin);

	back2uo\test\_assert::assert_true("closest to node " + id, isdefined(closest) && level.back2uo_wp_origin[closest] == origin);
}

/*
=============
test_paths

A* from node 0 to the last node a breadth-first walk from node 0 reaches: a valid path must
exist. A node the walk does not reach (fragmented maps) must give no path.
=============
*/
test_paths()
{
	// Breadth-first walk along the directed edges
	seen = [];
	queue = [];
	seen[0] = true;
	queue[0] = 0;

	for(head = 0; head < queue.size; head++)
	{
		links = level.back2uo_wp_links[queue[head]];

		for(i = 0; i < links.size; i++)
		{
			if(isdefined(seen[links[i]])) continue;

			seen[links[i]] = true;
			queue[queue.size] = links[i];
		}
	}

	far = queue[queue.size - 1];
	back2uo\test\_assert::out("INFO;" + queue.size + " of " + level.back2uo_wp_count + " nodes reachable from node 0");

	start = gettime();
	path = back2uo\bots\_back2uo_waypoints::back2uo_wp_path(0, far);
	back2uo\test\_assert::out("INFO;path 0 -> " + far + " took " + (gettime() - start) + " ms");
	back2uo\test\_assert::assert_true("path 0 -> " + far, isdefined(path) && path[0] == 0 && path[path.size - 1] == far);
	back2uo\test\_assert::assert_true("path 0 -> " + far + " follows edges", path_valid(path));

	path = back2uo\bots\_back2uo_waypoints::back2uo_wp_path(far, far);
	back2uo\test\_assert::assert_true("path to itself", isdefined(path) && path.size == 1 && path[0] == far);

	unreached = undefined;
	for(id = 0; id < level.back2uo_wp_count && !isdefined(unreached); id++)
	{
		if(!isdefined(seen[id])) unreached = id;
	}

	if(isdefined(unreached))
	{
		path = back2uo\bots\_back2uo_waypoints::back2uo_wp_path(0, unreached);
		back2uo\test\_assert::assert_true("no path 0 -> unreachable " + unreached, !isdefined(path));
	}
	else
		back2uo\test\_assert::skip("no path to unreachable node", "every node is reachable from node 0");
}

/*
=============
test_toujane

mp_toujane: values from back2uo\bots\waypoints\_wp_mp_toujane.gsc.
=============
*/
test_toujane()
{
	back2uo\test\_assert::assert_eq("toujane count", level.back2uo_wp_count, 1099);

	// Node 0: n(2546, 2261, 72, ...) with edges to 353 and 870
	back2uo\test\_assert::assert_eq("toujane node 0 origin", level.back2uo_wp_origin[0], (2546, 2261, 72));
	back2uo\test\_assert::assert_eq("toujane closest to node 0", back2uo\bots\_back2uo_waypoints::back2uo_wp_closest((2546, 2261, 80)), 0);

	// Stored once in the .wp file, generated both ways by the converter
	back2uo\test\_assert::assert_eq("toujane edge 0 -> 870", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(0, 870), 0);
	back2uo\test\_assert::assert_eq("toujane edge 870 -> 0", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(870, 0), 0);
	back2uo\test\_assert::assert_true("toujane no edge 0 -> 1", !isdefined(back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(0, 1)));

	// Node 631 is a mantle linking 632: up is a mantle edge, down a fall edge
	back2uo\test\_assert::assert_true("toujane 631 is mantle", back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(631, "mantle"));
	back2uo\test\_assert::assert_true("toujane 632 is not mantle", !back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(632, "mantle"));
	back2uo\test\_assert::assert_eq("toujane edge 631 -> 632 is mantle", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(631, 632), level.back2uo_wpbit["mantle"]);
	back2uo\test\_assert::assert_eq("toujane edge 632 -> 631 is fall", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(632, 631), level.back2uo_wpbit["fall"]);

	// Node 176 is a grenade spot with angles -23, -173; the grenade bit stays off the edge
	back2uo\test\_assert::assert_true("toujane 176 is grenade", back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(176, "grenade"));
	back2uo\test\_assert::assert_eq("toujane 176 angles", level.back2uo_wp_angles[176], (-23, -173, 0));
	back2uo\test\_assert::assert_eq("toujane edge 176 -> 177 is walk", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(176, 177), 0);

	// The toujane waypoints are fully connected
	path = back2uo\bots\_back2uo_waypoints::back2uo_wp_path(1098, 0);
	back2uo\test\_assert::assert_true("toujane path 1098 -> 0", isdefined(path) && path[0] == 1098 && path[path.size - 1] == 0 && path_valid(path));
}

/*
=============
test_dawnville

mp_dawnville: values from back2uo\bots\waypoints\_wp_mp_dawnville.gsc.
=============
*/
test_dawnville()
{
	back2uo\test\_assert::assert_eq("dawnville count", level.back2uo_wp_count, 1876);

	// Node 142 is a fall node linking 145; nothing links 145 back to 142
	back2uo\test\_assert::assert_eq("dawnville edge 142 -> 145 is fall", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(142, 145), level.back2uo_wpbit["fall"]);
	back2uo\test\_assert::assert_true("dawnville no edge 145 -> 142", !isdefined(back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(145, 142)));

	// Node 1852 is a crouched ladder node linking 1853
	back2uo\test\_assert::assert_true("dawnville 1852 is ladder", back2uo\bots\_back2uo_waypoints::back2uo_wp_istype(1852, "ladder"));
	back2uo\test\_assert::assert_eq("dawnville 1852 stance", level.back2uo_wp_stance[1852], "crouch");
	back2uo\test\_assert::assert_eq("dawnville edge 1853 -> 1852 is ladder", back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(1853, 1852), level.back2uo_wpbit["ladder"]);
}

/*
=============
path_valid

True if every step of a path is an edge of the waypoint graph.
Params: path - array of node ids
=============
*/
path_valid(path)
{
	if(!isdefined(path)) return false;

	for(i = 1; i < path.size; i++)
	{
		if(!isdefined(back2uo\bots\_back2uo_waypoints::back2uo_wp_edgetype(path[i - 1], path[i]))) return false;
	}

	return true;
}
