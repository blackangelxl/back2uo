/*
	Back2Uo v2.1 - World objects: Grenade pickups dropped by dead players.

	back2uo_grenadepickup() and back2uo_grenadepickup_clear() are threaded from
	maps\mp\gametypes\_weapons.gsc when a dead player's grenades are dropped.
	Split from the former _back2uo_objects.gsc.
*/

/*
=============
back2uo_grenadepickup

Pickup logic for a dropped grenade. When a playing player within 60 units has fewer grenades
of that type than his per-team limit, one grenade is added and the model is removed.
Params: grenadetype - grenade weapon name
		object - the dropped grenade model
		origin - position of the model
		team - team of the grenade type ("allies" or "axis"), selects the limit
		name - display name for the pickup message
=============
*/
back2uo_grenadepickup(grenadetype, object, origin, team, name)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Grenade can pickup", "Run");

	trigger = spawn("trigger_radius", origin, 0, 100, 100);
	other = "";

	while(isdefined(object))
	{
		wait 0.1;

		// Blocks until any entity touches the trigger
		trigger waittill("trigger", other);

		if(other.sessionstate == "playing")
		{
			grenade_count = other getammocount(grenadetype);

			// Per-player grenade limit for this team's grenade type
			if(team == "allies")
			{
				grenade_countmax = other.back2uo_granaten_allow_allies;
			}
			else
			{
				grenade_countmax = other.back2uo_granaten_allow_axis;
			}

			if(distance(other.origin, origin) < 60 && grenade_count < grenade_countmax)
			{
				if(!isDefined(object)) break;

				other giveWeapon(grenadetype);

				grenade_count = grenade_count + 1;
				other setWeaponClipAmmo(grenadetype, grenade_count);

				other playSound("weap_ammo_pickup");

				// Pickup message
				other iprintln(&"GAME_PICKUP_CLIPONLY_AMMO", name);

				if(isDefined(object)) object delete();

				if(isdefined(trigger)) trigger delete();

				return;
			}
		}
	}

	if(isdefined(trigger)) trigger delete();
}

/*
=============
back2uo_grenadepickup_clear

Deletes a dropped grenade model after 40 seconds.
Called on: self = grenade model
=============
*/
back2uo_grenadepickup_clear()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Grenade Pickup", "Clear");

	if(!isDefined(self)) return;

	wait 40;

	if(isDefined(self)) self delete();
}
