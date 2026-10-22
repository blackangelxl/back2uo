/*
	Back2Uo v2.1 - Blood and gore: Blood splatter and blood pool on the corpse when a player dies.

	back2uo_killedplayer_blood() is called from the gametype Callback_PlayerKilled handlers.
	Uses level.back2uo_effect[] (body_bloodsplatter, body_bloodpool) and the back2uo_blood_pools cvar.
	Split from the former _back2uo_gore.gsc.
*/

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

	if(!isdefined(body))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("killed", "skip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " reason=no_body");
		return;
	}

	// time = number of splatter bursts (0.1 s apart), w = delay before the blood pool.
	time = 6;
	w = 0.8;

	// Give the corpse the player's model and tag it so back2uo_deadbody_gore() can find it.
	// setmodel rebuilds the skeleton only on the next frame: a playfxontag in the same frame
	// fails the tag lookup ("no model.") and crashes the server while formatting the error,
	// so the effects below wait one frame first.
	if(isdefined(self.model) && self.model != "") body setmodel(self.model);
	body.targetname = "deadplayer";

	if(isdefined(selfteam) && selfteam == "spectator")
	{
		back2uo\_back2uo_cvars::back2uo_logevent("killed", "skip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " reason=spectator");
		return;
	}

	if(back2uo\_back2uo_cvars::back2uo_logactive())
	{
		victimteam = "none";
		if(isdefined(selfteam)) victimteam = selfteam;
		attteam = "none";
		if(isdefined(attackerteam)) attteam = attackerteam;

		back2uo\_back2uo_cvars::back2uo_logevent("killed", "blood", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " victimteam=" + victimteam + " attackerteam=" + attteam + " splatter=" + time + " pool_delay=" + w + " pos=" + back2uo\_back2uo_cvars::back2uo_logvec(body.origin));
	}

	// Let the corpse skeleton build before looking up its tags.
	wait 0.05;

	for(x=0; x < time; x++)
	{
		// The corpse may already be removed (body queue, map end) or have no model.
		if(!isdefined(body) || !isdefined(body.model) || body.model == "") return;

		playfxontag(level.back2uo_effect["body_bloodsplatter"], body, "pelvis");

		wait 0.10;
	}

	wait w;

	if(!isdefined(body) || !isdefined(body.model) || body.model == "") return;

	playfxontag(level.back2uo_effect["body_bloodpool"], body, "pelvis");
}
