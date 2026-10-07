/*
	Back2Uo v2.1 - world pickup objects: dropped health packs, grenade pickups, popping helmets

	back2uo_dropHealthPacks() and back2uo_helmpopping() are threaded from _back2uo_player.gsc
	(damage/death), back2uo_grenadepickup() from maps\mp\gametypes\_weapons.gsc when a dead
	player's grenades are dropped.
	Uses game["back2uo_medipacks_enable"], game["back2uo_helmpoppping_enable"],
	level.back2uo_medipacks_health1/2/3, level.back2uo_medipacks_hide (lifetime in seconds),
	level.back2uo_medipacks_pickup (0 = auto, 1 = use key) and the client cvar back2uo_ui_medicicon.
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

/*
=============
back2uo_helmpopping_off

Resets the helmet state on spawn: the helmet is on again and the one-time
helmet save (self.pers["back2uo_helmsave"], used by the gametype damage callbacks) is available.
Called on: self = player
=============
*/
back2uo_helmpopping_off()
{
	if(!game["back2uo_helmpoppping_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Helm Popping", "Undefined");

	self.back2uo_helmpopped = undefined;
	self.pers["back2uo_helmsave"] = undefined;
}

/*
=============
back2uo_helmpopping

On a head or neck hit, detaches the helmet model and spawns it as a flying script_model
at head height for the current stance.
Called on: self = hit player
Params: damageDir - damage direction vector (flight direction)
		idamage - damage (unused)
		hitloc - hit location
		attacker - attacker (unused)
=============
*/
back2uo_helmpopping(damageDir, idamage, hitloc, attacker)
{
	if(!game["back2uo_helmpoppping_enable"]) return;

	// Helmet already gone
	if(isdefined(self.back2uo_helmpopped)) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Helm Popping", "Run");

	if(!isdefined(self.hatModel) || !isdefined(hitloc)) return;

	if(hitloc == "head" || hitloc == "neck")
	{
		self.back2uo_helmpopped = true;

		self detach(self.hatModel, "");

		// Spawn height of the helmet above the player origin, by stance
		if(isPlayer(self))
		{
			positype = back2uo\_back2uo_cvars::back2uo_player_stance();

			switch(positype)
			{
			case "prone":
				helmposi = (0,0,15);
				break;

			case "crouch":
				helmposi = (0,0,44);
				break;

			// Stand
			default:
				helmposi = (0,0,64);
				break;
			}
		}
		else
		{
			helmposi = (0,0,15);
		}

		helm = spawn("script_model", self.origin + helmposi);
		helm setmodel(self.hatModel);
		helm.targetname = "Helm Popping";
		helm.angles = self.angles;
		helm back2uo_helmmove(damageDir);
	}
}

/*
=============
back2uo_helmmove

Throws the helmet along the damage direction with gravity and spin, then deletes it after 20 seconds.
Called on: self = helmet script_model
Params: damageDir - damage direction vector
=============
*/
back2uo_helmmove(damageDir)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Helm Popping", "Move");

	// Horizontal speed 150..349 along the damage direction, upward speed 100..299
	temp_vec = damageDir;
	temp_vec = maps\mp\_utility::vectorScale (temp_vec, 150 + randomint (200));

	x = temp_vec[0];
	y = temp_vec[1];
	z = 100 + randomint (200);

	// Spin about 4000 degrees over 5 seconds; direction depends on the flight side
	if (y > 0)
		self rotatepitch((4000 + randomfloat (500)) * -1, 5, 0, 0);
	else
		self rotatepitch(4000 + randomfloat (500), 5, 0, 0);

	// Ballistic flight with the given initial velocity for 15 seconds
	self moveGravity((x, y, z), 15);

	wait (20);

	if(isdefined(self)) self delete();
}

/*
=============
back2uo_helmpopping_deadbodys

Not in use. Spawns the helmet of a dead body as a model that a player can kick away
with the melee button.
Called on: self = dead body / player entity
=============
*/
back2uo_helmpopping_deadbodys()
{
	if(!game["back2uo_helmpoppping_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Helm popping Death Bodys", "Run");

	level endon("back2uo_killthreads");

	self detach(self.hatModel, "");

	helm2 = spawn("script_model", self.origin);
	helm2 setmodel(self.hatModel);
	helm2.targetname = "Helm Popping";
	helm2.angles = self.angles;

	trigger = spawn("trigger_radius", self.origin, 0, 80, 70);
	other = "";

	while(isdefined(self))
	{
		wait 0.1;

		trigger waittill("trigger", other);

		if(other.sessionstate == "playing")
		{
			if(distance(other.origin, self.origin) < 60)
			{
				if(other meleebuttonpressed())
				{
					other iprintln("Helm Popping");

					self.back2uo_helmpopped = true;

					// Passes a number instead of a direction vector (temp_vec[0] would fail)
					helm2 back2uo_helmmove(60);
				}
			}
		}
	}
}
