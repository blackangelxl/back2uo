/*
	Back2Uo v2.1 - Blood and gore effects

	Plays blood splatter on the hit body part when a player takes damage, and blood
	splatter plus a blood pool on the corpse when a player dies.
	back2uo_playerdamage_blood() is called from _back2uo_player.gsc::back2uo_player_damage(),
	back2uo_killedplayer_blood() from the gametype Callback_PlayerKilled handlers.
	Uses level.back2uo_effect[] (body_bloodsplatter, body_bloodpool, body_gore) and the
	back2uo_blood_spatter / back2uo_blood_pools cvars.
*/

/*
=============
back2uo_playerdamage_blood

Plays blood splatter on the bone that matches the hit location. More damage
plays the effect more often (1x up to 45, 2x up to 90, 3x above).
Called on: self = damaged player
Params: sHitLoc - engine hit location string (e.g. "head", "left_arm_lower")
		iDamage - damage dealt (defaults to 40)
		attacker - attacking entity, only used for the development debug print
=============
*/
back2uo_playerdamage_blood(sHitLoc, iDamage, attacker)
{
	if(level.back2uo_blood_spatter == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Damage Blood", "Run");

	if(!isdefined(self)) return;

	// Fallback bone when the hit location is unknown or not listed below.
	hitposi = "pelvis";

	// Map the engine hit location to the bone tag the effect is played on.
	if(isdefined(sHitLoc))
	{
		// Hands
		if(sHitLoc == "left_hand")
		{
			hitposi = "j_wrist_le";
		}

		if(sHitLoc == "right_hand")
		{
			hitposi = "j_wrist_ri";
		}

		// Lower arms (elbow joints)
		if(sHitLoc == "left_arm_lower")
		{
			hitposi = "j_elbow_le";
		}

		if(sHitLoc == "right_arm_lower")
		{
			hitposi = "j_elbow_ri";
		}

		// Lower legs (knee joints)
		if(sHitLoc == "left_leg_lower")
		{
			hitposi = "j_knee_le";
		}

		if(sHitLoc == "right_leg_lower")
		{
			hitposi = "j_knee_ri";
		}

		// Upper legs (hip joints)
		if(sHitLoc == "left_leg_upper")
		{
			hitposi = "j_hip_le";
		}

		if(sHitLoc == "right_leg_upper")
		{
			hitposi = "j_hip_ri";
		}

		// Upper arms (shoulder joints)
		if(sHitLoc == "left_arm_upper")
		{
			hitposi = "j_shoulder_le";
		}

		if(sHitLoc == "right_arm_upper")
		{
			hitposi = "j_shoulder_ri";
		}

		// Head
		if(sHitLoc == "head")
		{
			hitposi = "J_Head";
		}

		// Neck
		if(sHitLoc == "neck")
		{
			hitposi = "J_Neck";
		}

		// Upper and lower torso both use the pelvis bone
		if(sHitLoc == "torso_upper")
		{
			hitposi = "pelvis";
		}

		if(sHitLoc == "torso_lower")
		{
			hitposi = "pelvis";
		}
	}

	if(!isdefined(iDamage)) iDamage = 40;

	// No blood for spectators.
	if(self.pers["team"] == "spectator" || self.sessionstate == "spectator") return;

	if(iDamage <= 45)
	{
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
	}
	else if(iDamage > 45 && iDamage <= 90)
	{
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
	}
	else if(iDamage > 90)
	{
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
	}
	else
	{
		playfxontag(level.back2uo_effect["body_bloodsplatter"], self, hitposi);
	}

	// Development mode: print the bone that was hit to the attacker.
	if(game["back2uo_development_enable"]) attacker iprintln(hitposi);
}

/*
=============
back2uo_killedplayer_blood

Turns the cloned corpse into a tagged "deadplayer" entity and plays a short
burst of blood splatter on it, followed by a blood pool under the pelvis.
Called on: self = killed player
Params: body - corpse entity returned by ClonePlayer()
		selfteam - team of the killed player
		attackerteam - team of the attacker (unused)
=============
*/
back2uo_killedplayer_blood(body, selfteam, attackerteam)
{
	if(level.back2uo_blood_pools == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Blood Pool", "Run");

	if(!isdefined(body)) return;

	// time = number of splatter bursts (0.1 s apart), w = delay before the blood pool.
	time = 6;
	w = 0.8;

	// Give the corpse the player's model and tag it so back2uo_deadbody_gore() can find it.
	body setmodel (self.model);
	body.targetname = "deadplayer";

	if(isdefined(selfteam) && selfteam == "spectator") return;

	for(x=0; x < time; x++)
	{
		playfxontag(level.back2uo_effect["body_bloodsplatter"], body, "pelvis");

		wait 0.10;
	}

	wait w;

	playfxontag(level.back2uo_effect["body_bloodpool"], body, "pelvis");
}

/*
=============
back2uo_deadbody_gore

Unused. Endless level loop that plays a gore effect on a corpse ("deadplayer")
when a living player within 300 units aims at it (dot product >= 0.97, i.e. about
14 degrees) and fires a weapon that still has ammo.
Called on: self = level
=============
*/
back2uo_deadbody_gore()
{
	if(!game["back2uo_bloodsplater_enable"]) return;

	while(1)
	{
		players = getentarray("player", "classname");

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player) && player.sessionstate == "playing")
			{
				dead_user = getentarray("deadplayer","targetname");

				for(j=0; j < dead_user.size; j++)
				{
					if(!isdefined(player))break;
					if(!isdefined(dead_user[j]))break;

					if(distance(player.origin, dead_user[j].origin) < 300)
					{
						// Line of sight between corpse and player.
						trace = bullettrace(dead_user[j].origin, player.origin, false, undefined);

						if(trace["fraction"]==1)
						{
							// Negated dot product of the view direction and the direction eye->corpse; 1.0 = looking straight at it.
							trace_radius = vectordot(anglestoforward(player getplayerangles()),anglestoforward(vectortoangles(vectornormalize((player getEye() + (0, 0, 18)) - dead_user[j].origin)))) * -1;

							if(trace_radius >= 0.97 && isdefined(player) && player attackButtonPressed())
							{
								user_weapon = player getcurrentweapon();

								if(user_weapon != "none")
								{
									prim_weapon = player getweaponslotweapon("primary");
									sec_weapon = player getweaponslotweapon("primaryb");

									if(user_weapon == prim_weapon)
									{
										weapon_slot = "primary";
									}
									else
									{
										weapon_slot = "primaryb";
									}

									weapon_clipammo = player getweaponslotclipammo(weapon_slot);
									weapon_ammosize = player getammocount(user_weapon);

									if(weapon_clipammo != 0 || weapon_ammosize != 0)
									{
										if(!isdefined(dead_user[j])) break;

										playfx (level.back2uo_effect["body_gore"], dead_user[j].origin);
									}
								}
							}
						}
					}
				}
			}
		}

		wait 0.1;
	}
}
