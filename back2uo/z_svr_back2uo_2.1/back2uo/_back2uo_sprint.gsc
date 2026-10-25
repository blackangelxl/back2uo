/*
	Back2Uo v2.1 - Sprint system.

	Players sprint by holding the Use key while running. Two sprint modes (back2uo_sprint_mode):
	- "speed" (primary): raises the player's speed with zk_libcod setSpeed and holds the weapon
	  down (setHoldingWeaponDown), so it cannot fire while sprinting.
	- "weapon" (fallback): swaps the current primary weapon for its "<weapon>_sprint" variant
	  (a sprint-pose weapon) and restores the original weapon with its ammo when the sprint ends.
	  Used when back2uo_sprint_mode is 0, or for the rest of the map once the engine did not
	  apply the speed (level.back2uo_sprint_speedfail).
	Stamina is tracked as self.hud_sprint_height
	(fatigue bar drawn and recovered in hud\_back2uo_playerposition.gsc); sprinting is blocked above 34/35.
	Entry point: back2uo_sprintsystem_main(), threaded per player from
	_back2uo_player::back2uo_player_spawn. Switch: game["back2uo_sprint_enable"].
	Player state: self.pers["sprinting"], ["sprint_mode"], ["is_moving"], ["sprint_slot"], ["pri_*"] / ["pri_b_*"] saved
	weapon and ammo, ["weapon_pickupsprintwait"] (set by weapon pickup in _back2uo_weaponsystem.gsc).
*/

/*
=============
back2uo_sprintsystem_main

Per-player sprint loop. Every frame checks whether the player may start a sprint
(Use held, moving, standing, not exhausted, no binoculars, no weapon zoom, no other action like
planting/turret use, no recent weapon pickup) and starts back2uo_sprintsystem_run.
Bots (self.pers["bots_nosprint"]) never sprint.
Called on: self = player
=============
*/
back2uo_sprintsystem_main()
{
	if(!game["back2uo_sprint_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sprint System", "Run");

	if(isdefined(self.pers["bots_nosprint"])) return;

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self.pers["sprinting"] = false;
	self.pers["sprint_mode"] = "";
	self.sprint_none = false;

	// zk_libcod keeps the per-player speed over death and reconnects; clear a speed left
	// over from a sprint thread that ended without back2uo_sprintsystem_stop.
	self back2uo\_back2uo_libcod::back2uo_libcod_setspeed(0);

	if(!isdefined(self.pers["weapon_pickupsprintwait"])) self.pers["weapon_pickupsprintwait"] = false;

	self thread back2uo_sprintsystem_ismoving();

	for(;;)
	{
		positype = back2uo\_back2uo_cvars::back2uo_player_stance();

		// After a weapon pickup (Use key) block sprinting for 1 second, so the
		// same key press does not also start a sprint.
		if(self.pers["weapon_pickupsprintwait"] == true)
		{
			wait 1;

			self.pers["weapon_pickupsprintwait"] = false;
		}

		// Disabled condition: && !self.pers["breathing"]
		if(self usebuttonpressed() && self.pers["is_moving"] && (positype == "stand" || positype == "sprint") && self.hud_sprint_height < 34 && !self back2uo\_back2uo_libcod::back2uo_libcod_isusingbinoculars() && !self back2uo\_back2uo_libcod::back2uo_libcod_aimbuttonpressed() && self.pers["weapon_pickupsprintwait"] == false && self.back2uo_playerdo == "none")
		{
			// Returns at once if a sprint is already running.
			self thread back2uo_sprintsystem_run();
		}

		wait 0.05;
	}
}

/*
=============
back2uo_sprintsystem_run

Runs one sprint while Use is held. On the first pass it starts the sprint in speed mode
(setSpeed, weapon held down) or, as fallback, saves the current weapon's ammo and switches
the weapon slot to the "_sprint" variant. On the second pass speed mode checks that the
engine applied the speed; if not, it switches to the weapon swap. The loop ends when the player
crouches/prones, is exhausted, uses binoculars or the weapon zoom, plants/defuses, stops moving, picks up a
weapon or has no weapon (ladder, turret, climbing). Afterwards the speed is reset or, after
a weapon swap, the saved ammo is updated and the original weapon restored.
Called on: self = player
=============
*/
back2uo_sprintsystem_run()
{
	// No trace call here: this is threaded every frame while Use is held

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(self.pers["sprinting"] == true) return;

	// Speed set in speed mode, and whether the engine applied it was checked.
	sprint_speed = 0;
	speed_checked = false;
	// Consecutive passes with weapon "none".
	sprint_none = 0;
	// Log values: why the sprint ended, start time
	stop_reason = "release";
	sprint_start = undefined;

	while(isalive(self) && self useButtonPressed() && !self back2uo\_back2uo_libcod::back2uo_libcod_isusingbinoculars())
	{
		positype = back2uo\_back2uo_cvars::back2uo_player_stance();

		if(positype == "crouch" || positype == "prone")
		{
			stop_reason = positype;
			break;
		}

		// Exhausted. Disabled extra condition: || self.pers["breathing"]
		if(self.hud_sprint_height > 35)
		{
			stop_reason = "exhausted";
			break;
		}

		if(self back2uo\_back2uo_libcod::back2uo_libcod_isusingbinoculars())
		{
			stop_reason = "bino";
			break;
		}

		// Weapon zoom (ADS). zk_libcod aimButtonPressed reads the key itself, because in
		// speed mode the held-down weapon cannot go into ADS.
		if(self back2uo\_back2uo_libcod::back2uo_libcod_aimbuttonpressed())
		{
			stop_reason = "ads";
			break;
		}

		// Bomb plant / defuse in SD.
		if(isdefined(self.planting) && self.planting)
		{
			stop_reason = "planting";
			break;
		}

		if(isdefined(self.defuse) && self.defuse)
		{
			stop_reason = "defuse";
			break;
		}

		if(!self.pers["is_moving"])
		{
			stop_reason = "notmoving";
			break;
		}

		if(self.pers["weapon_pickupsprintwait"] == true)
		{
			stop_reason = "weaponpickup";
			break;
		}

		// Tells the weapon pickup code that Use is held for sprinting, not for a pickup.
		self.pers["usebutton_holdpress"] = true;

		normal_weapon = self getcurrentweapon();

		// Weapon "none" for more than 3 passes (0.3 seconds) means the player is on a
		// ladder, a turret or climbing; a brief "none" during the weapon swap is ignored.
		if(normal_weapon == "none")
		{
			sprint_none++;

			if(sprint_none > 3) self.sprint_none = true;
		}
		else
		{
			self.sprint_none = false;
		}

		if(self.sprint_none)
		{
			stop_reason = "noweapon";
			break;
		}

		// No sprint with the rocket launcher, also when switched to it during a sprint
		// (possible in weapon mode, the weapon is not held down there).
		if(normal_weapon == "panzerschreck_mp" && self.pers["sprint_mode"] != "")
		{
			stop_reason = "panzerschreck";
			break;
		}

		// Second pass in speed mode: getSpeed returns the engine's speed, which only differs
		// from g_speed if the per-player speed works. If not, use the weapon swap for this map.
		if(self.pers["sprint_mode"] == "speed" && !speed_checked)
		{
			speed_checked = true;

			if(self back2uo\_back2uo_libcod::back2uo_libcod_getspeed() != sprint_speed)
			{
				level.back2uo_sprint_speedfail = true;
				back2uo\_back2uo_cvars::back2uo_logevent("sprint", "fallback", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " speed=" + self back2uo\_back2uo_libcod::back2uo_libcod_getspeed() + " expected=" + sprint_speed);

				self back2uo_sprintsystem_speedstop();
				self.pers["sprint_mode"] = "";
			}
		}

		// First pass: start the sprint (also after a fallback from speed mode).
		if(self.pers["sprint_mode"] == "" && normal_weapon != "none")
		{
			// Only weapons in a primary slot have a "_sprint" variant (not binoculars, grenades
			// or turrets); the Panzerschreck has none either.
			if(normal_weapon != self getWeaponSlotWeapon("primary") && normal_weapon != self getWeaponSlotWeapon("primaryb"))
			{
				self back2uo_sprintsystem_logskip("nosprintweapon", normal_weapon);
				return;
			}
			if(normal_weapon == "panzerschreck_mp")
			{
				self back2uo_sprintsystem_logskip("panzerschreck", normal_weapon);
				return;
			}

			// Speed mode needs zk_libcod setSpeed, otherwise the weapon swap is used.
			if(level.back2uo_sprint_mode == 1 && !isdefined(level.back2uo_sprint_speedfail) && back2uo\_back2uo_libcod::back2uo_libcod_active())
			{
				// Speed mode: faster player, weapon held down (no firing, no weapon switch).
				sprint_speed = int(getcvarint("g_speed") * level.back2uo_sprint_speedscale);

				self back2uo\_back2uo_libcod::back2uo_libcod_setspeed(sprint_speed);
				self back2uo\_back2uo_libcod::back2uo_libcod_setholdingweapondown(true);

				self.pers["sprint_mode"] = "speed";
			}
			else
			{
				// Weapon mode: save weapon and ammo of the slot holding the current weapon.
				self back2uo_sprintsystem_inslot(normal_weapon);

				sprint_weapon = normal_weapon + "_sprint";

				if(self getWeaponSlotWeapon("primary") == normal_weapon)
					self.pers["sprint_slot"] = "primary";
				else
					self.pers["sprint_slot"] = "primaryb";

				// Put the sprint variant in the same slot and carry the ammo over.
				self setweaponslotweapon(self.pers["sprint_slot"], sprint_weapon);

				if(self.pers["sprint_slot"] == "primary")
				{
					self setweaponslotammo("primary", self.pers["pri_ammo"]);
					self setweaponslotclipammo("primary", self.pers["pri_clipammo"]);
				}
				else
				{
					self setweaponslotammo("primaryb", self.pers["pri_b_ammo"]);
					self setweaponslotclipammo("primaryb", self.pers["pri_b_clipammo"]);
				}

				self switchToWeapon(sprint_weapon);

				self.pers["sprint_mode"] = "weapon";
			}

			// Logged once per sprint; a fallback to weapon mode is logged separately.
			if(!isdefined(sprint_start))
			{
				sprint_start = getTime();
				self.back2uo_sprint_lastskip = undefined;
				back2uo\_back2uo_cvars::back2uo_logevent("sprint", "start", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " mode=" + self.pers["sprint_mode"] + " weapon=" + normal_weapon + " stamina=" + self.hud_sprint_height + " pos=" + back2uo\_back2uo_cvars::back2uo_logvec(self.origin));
			}
		}

		self.pers["sprinting"] = true;

		wait 0.1;
	}

	// Sprint ended: reset the speed, or save the sprint weapon's ammo and restore the original weapon.
	if(isalive(self))
	{
		if(self.pers["sprint_mode"] == "weapon") self back2uo_sprintsystem_inslot2(self.pers["sprint_slot"]);

		self back2uo_sprintsystem_stop();

		if(isdefined(sprint_start))
		{
			// Loop condition ended the sprint: Use released or binoculars
			if(stop_reason == "release" && self back2uo\_back2uo_libcod::back2uo_libcod_isusingbinoculars()) stop_reason = "bino";

			back2uo\_back2uo_cvars::back2uo_logevent("sprint", "stop", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " reason=" + stop_reason + " duration=" + ((getTime() - sprint_start) / 1000) + " stamina=" + self.hud_sprint_height + " pos=" + back2uo\_back2uo_cvars::back2uo_logvec(self.origin));
		}
	}
}

/*
=============
back2uo_sprintsystem_logskip

Logs why a sprint was not started, only when the reason or weapon changed
(back2uo_sprintsystem_run is threaded every frame while Use is held).
Called on: self = player
Params: reason - skip reason
		weapon - current weapon
=============
*/
back2uo_sprintsystem_logskip(reason, weapon)
{
	if(!back2uo\_back2uo_cvars::back2uo_logactive()) return;

	key = reason + " " + weapon;
	if(isdefined(self.back2uo_sprint_lastskip) && self.back2uo_sprint_lastskip == key) return;
	self.back2uo_sprint_lastskip = key;

	back2uo\_back2uo_cvars::back2uo_logevent("sprint", "skip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " reason=" + reason + " weapon=" + weapon);
}

/*
=============
back2uo_sprintsystem_ismoving

Sets self.pers["is_moving"] every 0.1 seconds. It becomes true when Use is held and the
player moved more than 10 units in the last 0.1 seconds, and false when Use is released.
While Use stays held, the last value is kept.
Called on: self = player
=============
*/
back2uo_sprintsystem_ismoving()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Sprint is Moving", "Run");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self.pers["is_moving"] = false;

	for(;;)
	{
		if(isPlayer(self))
		{
			firstpos = self.origin;

			wait 0.1;

			if(isPlayer(self))
			{
				// Units moved in 0.1 seconds.
				playerspeed = distance(firstpos, self.origin);

				if(self useButtonPressed() && playerspeed > 10)
				{
					self.pers["is_moving"] = true;
				}
				else if(!self useButtonPressed())
				{
					self.pers["is_moving"] = false;
				}
			}
		}
		else
		{
			wait 0.1;
		}
	}
}

/*
=============
back2uo_sprintsystem_inslot

Saves weapon name, reserve ammo and clip ammo of the slot holding usedweapon into
self.pers["pri_*"] (slot "primary") or self.pers["pri_b_*"] (slot "primaryb").
Called on: self = player
Params: usedweapon - the weapon the player currently holds
=============
*/
back2uo_sprintsystem_inslot(usedweapon)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Sprint in Slot", "Run");

	if(self getWeaponSlotWeapon("primary") == usedweapon)
	{
		if(self getweaponslotweapon("primary") != "none")
		{
			self.pers["pri_weapon"] = self getweaponslotweapon("primary");
			self.pers["pri_ammo"] = self getweaponslotammo("primary");
			self.pers["pri_clipammo"] = self getweaponslotclipammo("primary");
		}
	}
	else
	{
		if(self getweaponslotweapon("primaryb") != "none")
		{
			self.pers["pri_b_weapon"] = self getweaponslotweapon("primaryb");
			self.pers["pri_b_ammo"] = self getweaponslotammo("primaryb");
			self.pers["pri_b_clipammo"] = self getweaponslotclipammo("primaryb");
		}
	}
}

/*
=============
back2uo_sprintsystem_inslot2

At sprint end, copies the current ammo of the sprint weapon's slot back into the saved
values, so the restored weapon keeps the ammo state of the sprint weapon.
Called on: self = player
Params: sprintslot - "primary" or "primaryb" (self.pers["sprint_slot"])
=============
*/
back2uo_sprintsystem_inslot2(sprintslot)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Sprint in Slot 2", "Run");

	if(sprintslot == "primary")
	{
		// Note: && binds tighter than ||, so the isdefined() guard only covers the first comparison.
		if(isdefined(self.pers["pri_ammo"]) && self.pers["pri_ammo"] != self getweaponslotammo("primary") || self.pers["pri_clipammo"] != self getweaponslotclipammo("primary"))
		{
			self.pers["pri_ammo"] = self getweaponslotammo("primary");
			self.pers["pri_clipammo"] = self getweaponslotclipammo("primary");
		}
	}
	else
	{
		if(isdefined(self.pers["pri_b_ammo"]) && self.pers["pri_b_ammo"] != self getweaponslotammo("primaryb") || self.pers["pri_b_clipammo"] != self getweaponslotclipammo("primaryb"))
		{
			self.pers["pri_b_ammo"] = self getweaponslotammo("primaryb");
			self.pers["pri_b_clipammo"] = self getweaponslotclipammo("primaryb");
		}
	}
}

/*
=============
back2uo_sprintsystem_stop

Ends the sprint state. Speed mode: resets speed and weapon. Weapon mode: puts the saved
original weapon with its ammo back into the sprint slot, then switches to it.
Does nothing if the player is not sprinting.
Called on: self = player
=============
*/
back2uo_sprintsystem_stop()
{
	if(self.pers["sprinting"] == false) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sprint Stop", "Run");

	self.pers["sprinting"] = false;

	sprint_mode = self.pers["sprint_mode"];
	self.pers["sprint_mode"] = "";

	if(sprint_mode == "speed")
	{
		self back2uo_sprintsystem_speedstop();
	}
	else if(sprint_mode == "weapon" && isdefined(self.pers["sprint_slot"]))
	{
		// Switch back only while the sprint weapon is in hand, not after a switch to the
		// other slot (e.g. the Panzerschreck).
		current = self getcurrentweapon();
		switch_back = (current == "none" || current == self getWeaponSlotWeapon(self.pers["sprint_slot"]));

		if(self.pers["sprint_slot"] == "primary")
		{
			self setWeaponSlotWeapon("primary", self.pers["pri_weapon"]);
			self setweaponslotammo("primary", self.pers["pri_ammo"]);
			self setweaponslotclipammo("primary", self.pers["pri_clipammo"]);
			if(switch_back) self switchToWeapon(self.pers["pri_weapon"]);
		}
		else
		{
			self setWeaponSlotWeapon("primaryb", self.pers["pri_b_weapon"]);
			self setweaponslotammo("primaryb", self.pers["pri_b_ammo"]);
			self setweaponslotclipammo("primaryb", self.pers["pri_b_clipammo"]);
			if(switch_back) self switchToWeapon(self.pers["pri_b_weapon"]);
		}
	}
}

/*
=============
back2uo_sprintsystem_speedstop

Ends a speed-mode sprint: setSpeed(0) returns to g_speed and the weapon is raised again.
Called on: self = player
=============
*/
back2uo_sprintsystem_speedstop()
{
	self back2uo\_back2uo_libcod::back2uo_libcod_setspeed(0);
	self back2uo\_back2uo_libcod::back2uo_libcod_setholdingweapondown(false);
}
