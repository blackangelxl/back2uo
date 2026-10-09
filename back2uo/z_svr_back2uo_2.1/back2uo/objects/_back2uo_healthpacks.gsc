/*
	Back2Uo v2.1 - World objects: Dropped health packs: drop, pickup (auto or use key) and cleanup.

	back2uo_dropHealthPacks() is threaded from _back2uo_player.gsc on death.
	Uses game["back2uo_medipacks_enable"], level.back2uo_medipacks_health1/2/3,
	level.back2uo_medipacks_hide (lifetime in seconds), level.back2uo_medipacks_pickup
	(0 = auto, 1 = use key) and the client cvar back2uo_ui_medicicon.
	Split from the former _back2uo_objects.gsc.
*/

/*
=============
back2uo_dropHealthPacks

Drops a health pack near the player, placed on the ground via a downward bullet trace.
The size (small/medium/large) and the amount it heals depend on the damage of the last hit.
Called on: self = player (usually the killed player)
Params: iDamage - damage of the hit (defaults to 45)
=============
*/
back2uo_dropHealthPacks(iDamage)
{
	if(!game["back2uo_medipacks_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthpack Drop", "Run");

	if(!isdefined(iDamage)) iDamage = 45;

	// Random offset up to 30 units, then trace 1000 units down to find the floor
	trace_posi = self.origin + (randomint(30), randomint(30), 50);
	trace_endposi = trace_posi + (0, 0, -1000);
	trace = bulletTrace(trace_posi , trace_endposi, false, undefined);

	medipack_model = "xmodel/health_medium";
	medihealth_vol = level.back2uo_medipacks_health1;

	// Pack size by damage: <= 45 small, 46..90 medium, > 90 large
	if(iDamage <= 45) medi_case = 1;
	else if(iDamage > 45 && iDamage <= 90)  medi_case = 2;
	else if(iDamage > 90)  medi_case = 3;
	else  medi_case = 1;

	switch(medi_case)
	{
	// Small
	case 1:

		medipack_model = "xmodel/health_small";
		medihealth_vol = level.back2uo_medipacks_health1;

		break;

	// Medium
	case 2:

		medipack_model = "xmodel/health_medium";
		medihealth_vol = level.back2uo_medipacks_health2;

		break;

	// Large
	case 3:

		medipack_model = "xmodel/health_large";
		medihealth_vol = level.back2uo_medipacks_health3;

		break;
	}

	// Spawn hidden at the world origin, move into place, then show (avoids a visible jump)
	item_health = spawn("script_model", (0,0,0));
	item_health setModel(medipack_model);
	item_health.targetname = "item_healths";
	item_health hide();
	item_health.origin = trace["position"];
	item_health.angles = (0, randomint(360), 0);
	item_health show();

	// Pickup logic and timed removal
	thread back2uo_healththink(medihealth_vol, medi_case, item_health, item_health.origin);
	item_health thread back2uo_healthclear();
}

/*
=============
back2uo_healththink

Pickup logic for one health pack. A trigger_radius (radius 100, height 100) wakes the loop
when a player touches it; within 60 units the player sees the medic icon (client cvar
back2uo_ui_medicicon) and can take the pack if hurt. The player stores the pack origin in
medi_origin so the icon of another nearby pack does not flicker.
Params: medihealth_vol - health added on pickup
		meditype - 1 small, 2 medium, 3 large (sound and pickup message)
		object - the health pack script_model
		origin - position of the pack
=============
*/
back2uo_healththink(medihealth_vol, meditype, object, origin)
{
	if(!game["back2uo_medipacks_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Healthpacks Health Think", "Run");

	// trigger_radius: origin, spawnflags, radius, height
	trigger = spawn("trigger_radius", origin, 0, 100, 100);
	other = "";
	x = 0;
	name = "Medium";

	// Runs until the pack is picked up or removed by back2uo_healthclear()
	while(isdefined(object))
	{
		wait 0.1;

		// Blocks until any entity touches the trigger; 'other' receives that entity
		trigger waittill("trigger", other);

		if(other.sessionstate == "playing")
		{
			// Player is already near a different pack: ignore this one
			if(isdefined(other.medi_origin))
			{
				if(other.medi_origin != origin) continue;
			}

			// Show the medic icon only within 60 units
			if(distance(other.origin, origin) < 60 )
			{
				other setClientCvar("back2uo_ui_medicicon", 1);

				other.medi_origin = origin;
			}
			else
			{
				other setClientCvar("back2uo_ui_medicicon", 0);

				other.medi_origin = undefined;
			}

			// Pick up: close enough, hurt, and pickup condition met (use key or auto)
			if(distance(other.origin, origin) < 60 && other.health < other.maxhealth && other back2uo_health_buttonpress())
			{
				if(!isDefined(object)) break;

				other.health += 1 * medihealth_vol;

				if(other.health > other.maxhealth) other.health = other.maxhealth;

				// Small pack sound is local to the player, larger ones are heard by others too
				if(meditype == 1)
				{
					other playLocalSound("health_pickup_small");
					name = &"BACK2UOMOD_HEALTHPACK_SMALL";
				}
				else if(meditype == 2)
				{
					other playSound("health_pickup_medium");
					name = &"BACK2UOMOD_HEALTHPACK_MEDIUM";
				}
				else
				{
					other playSound("health_pickup_large");
					name = &"BACK2UOMOD_HEALTHPACK_LARGE";
				}

				// Pickup message
				other iprintln(&"GAME_PICKUP_HEALTH", name);

				other setClientCvar("back2uo_ui_medicicon", 0);

				other.medi_origin = undefined;

				if(isDefined(object)) object delete();

				if(isdefined(trigger)) trigger delete();

				return;
			}
		}
		else
		{
			other setClientCvar("back2uo_ui_medicicon", 0);

			other.medi_origin = undefined;
		}
	}

	// Pack is gone: clear the icon of the last toucher and remove the trigger
	if(isdefined(other))
	{
		other setClientCvar("back2uo_ui_medicicon", 0);
		other.medi_origin = undefined;
	}

	if(isdefined(trigger)) trigger delete();
}

/*
=============
back2uo_health_buttonpress

Checks the pickup condition for health packs.
Called on: self = player
Returns: true if the use key is pressed (back2uo_medipacks_pickup 1),
		 otherwise true while the player is playing (auto pickup)
=============
*/
back2uo_health_buttonpress()
{
	if(level.back2uo_medipacks_pickup == 1)
	{
		buttoninfo = self usebuttonpressed();
	}
	else
	{
		buttoninfo = self.sessionstate == "playing";
	}

	return buttoninfo;
}

/*
=============
back2uo_healthclear

Deletes the health pack after level.back2uo_medipacks_hide seconds.
A value of 0 keeps the pack until it is picked up.
Called on: self = health pack script_model
=============
*/
back2uo_healthclear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Healthpacks", "Clear");

	if(!isDefined(self)) return;

	// Parsed as (!hide) < 1, which is true for any hide value other than 0
	if(!level.back2uo_medipacks_hide < 1)
	{
		wait level.back2uo_medipacks_hide;

		if(isDefined(self)) self delete();
	}
}
