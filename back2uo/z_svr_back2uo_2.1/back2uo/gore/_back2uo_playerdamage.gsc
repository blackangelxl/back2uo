/*
	Back2Uo v2.1 - Blood and gore: Blood splatter on the hit body part when a player takes damage.

	back2uo_playerdamage_blood() is called from _back2uo_player.gsc::back2uo_player_damage().
	Uses level.back2uo_effect["body_bloodsplatter"] and the back2uo_blood_spatter cvar.
	Split from the former _back2uo_gore.gsc.
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
