/*
	Back2Uo v2.1 - World objects: Popping helmets on head hits and helmet save reset.

	back2uo_helmpopping() is threaded from _back2uo_player.gsc on damage and death,
	back2uo_helmpopping_off() on spawn (also clears self.pers["back2uo_helmsave"]).
	Uses game["back2uo_helmpoppping_enable"].
	Split from the former _back2uo_objects.gsc.
*/

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
