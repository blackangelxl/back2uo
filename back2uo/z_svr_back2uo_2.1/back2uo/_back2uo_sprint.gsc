/*
	Back2Uo v2.1 - Sprint system.

	Players sprint by holding the Use key while running. Sprinting swaps the current primary
	weapon for its "<weapon>_sprint" variant (a sprint-pose weapon) and restores the original
	weapon with its ammo when the sprint ends. Stamina is tracked as self.hud_sprint_height
	(fatigue bar drawn and recovered in hud\_back2uo_playerposition.gsc); sprinting is blocked above 34/35.
	Entry point: back2uo_sprintsystem_main(), threaded per player from
	_back2uo_player::back2uo_player_spawn. Switch: game["back2uo_sprint_enable"].
	Player state: self.pers["sprinting"], ["is_moving"], ["sprint_slot"], ["pri_*"] / ["pri_b_*"] saved
	weapon and ammo, ["weapon_pickupsprintwait"] (set by weapon pickup in _back2uo_weaponsystem.gsc).
*/

/*
=============
back2uo_sprintsystem_main

Per-player sprint loop. Every frame checks whether the player may start a sprint
(Use held, moving, standing, not exhausted, no binoculars, no other action like
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
	self.sprint_none = false;

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
		if(self usebuttonpressed() && self.pers["is_moving"] && (positype == "stand" || positype == "sprint") && self.hud_sprint_height < 34 && !self.pers["bino_inuse"] && self.pers["weapon_pickupsprintwait"] == false && self.back2uo_playerdo == "none")
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

Runs one sprint while Use is held. On the first pass it saves the current weapon's ammo
and switches the weapon slot to the "_sprint" variant. The loop ends when the player
crouches/prones, is exhausted, uses binoculars, plants/defuses, stops moving, picks up a
weapon or has no weapon (ladder, turret, climbing). Afterwards the saved ammo is updated
and the original weapon restored.
Called on: self = player
=============
*/
back2uo_sprintsystem_run()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Sprint Run", "Start");

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(self.pers["sprinting"] == true) return;

	// "_sprint" once the weapon swap has been done for this sprint.
	sprint_string = "";
	// Consecutive passes with weapon "none".
	sprint_none = 0;

	while(isalive(self) && self useButtonPressed() && !self.pers["bino_inuse"])
	{
		positype = back2uo\_back2uo_cvars::back2uo_player_stance();

		if(positype == "crouch" || positype == "prone") break;

		// Exhausted. Disabled extra condition: || self.pers["breathing"]
		if(self.hud_sprint_height > 35) break;

		if(self.pers["bino_inuse"]) break;

		// Bomb plant / defuse in SD.
		if(isdefined(self.planting) && self.planting) break;

		if(isdefined(self.defuse) && self.defuse) break;

		if(!self.pers["is_moving"]) break;

		if(self.pers["weapon_pickupsprintwait"] == true) break;

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

		if(self.sprint_none) break;

		// First pass: swap to the sprint weapon.
		if(self.pers["sprinting"] != true && sprint_string == "" && normal_weapon != "none")
		{
			// Save weapon and ammo of the slot holding the current weapon.
			self back2uo_sprintsystem_inslot(self getcurrentweapon());

			sprint_string = "_sprint";
			sprint_weapon = self getcurrentweapon() + sprint_string;

			// The Panzerschreck has no sprint variant.
			if(sprint_weapon == "panzerschreck_mp_sprint") return;

			if(self getWeaponSlotWeapon("primary") == self getcurrentweapon())
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
		}

		self.pers["sprinting"] = true;

		wait 0.1;
	}

	// Sprint ended: save the sprint weapon's ammo and restore the original weapon.
	if(isalive(self))
	{
		sprint_string = "";

		self back2uo_sprintsystem_inslot2(self.pers["sprint_slot"]);

		self back2uo_sprintsystem_stop();
	}
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

Ends the sprint state and puts the saved original weapon with its ammo back into the
sprint slot, then switches to it. Does nothing if the player is not sprinting.
Called on: self = player
=============
*/
back2uo_sprintsystem_stop()
{
	if(self.pers["sprinting"] == false) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sprint Stop", "Run");

	self.pers["sprinting"] = false;

	if(isdefined(self.pers["sprint_slot"]))
	{
		if(self.pers["sprint_slot"] == "primary")
		{
			self setWeaponSlotWeapon("primary", self.pers["pri_weapon"]);
			self setweaponslotammo("primary", self.pers["pri_ammo"]);
			self setweaponslotclipammo("primary", self.pers["pri_clipammo"]);
			self switchToWeapon(self.pers["pri_weapon"]);
		}
		else
		{
			self setWeaponSlotWeapon("primaryb", self.pers["pri_b_weapon"]);
			self setweaponslotammo("primaryb", self.pers["pri_b_ammo"]);
			self setweaponslotclipammo("primaryb", self.pers["pri_b_clipammo"]);
			self switchToWeapon(self.pers["pri_b_weapon"]);
		}
	}
}
