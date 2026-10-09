/*
	Back2Uo v2.1 - Blood and gore: Gore effect when shooting at a corpse (not in use).

	back2uo_deadbody_gore() is not called anywhere. It finds corpses tagged "deadplayer"
	by back2uo_killedplayer_blood() in gore\_back2uo_killedplayer.gsc.
	Uses level.back2uo_effect["body_gore"].
	Split from the former _back2uo_gore.gsc.
*/

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
