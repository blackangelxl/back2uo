/*
	Back2Uo v2.1 - player voice sounds (pain, death, taunts, grenade warnings) and sound helpers

	Pain/death/taunt sounds are threaded from _back2uo_player.gsc on damage and death.
	back2uo_grenade_isthrowing() is threaded per player on spawn and watches the frag count.
	The generic helpers (soundonplayer, soundonplayers, soundonplayerorigin) are used by
	the hud\, warfx\ and weatherfx\ scripts.
	Cvars (via level.): back2uo_painsound_random, back2uo_deathsound_random,
	back2uo_tauntsounds_random, back2uo_nadesounds_random (0 = off, higher = more frequent).
	Uses level.back2uo_voices[nationality] (voice count per nation) and game["allies"].
*/

/*
=============
back2uo_painsound_play

Randomly plays a nationality-specific pain sound when the player is hit. Hits to the head and
torso use a smaller random range, so they trigger the sound more often than limb hits.
Teammate hits in team gametypes are additionally halved by a coin flip.
Called on: self = damaged player
Params: hitloc - hit location string from the damage callback
		attacker - attacking entity (may be undefined or a non-player)
=============
*/
back2uo_painsound_play(hitloc, attacker)
{
	if(level.back2uo_painsound_random == 0) return;

	// No trace call: runs on every hit

	// Friendly fire in team gametypes: skip roughly half of the pain sounds.
	if(getcvar("g_gametype") != "dm")
	{
		if(isdefined(self.pers["team"]))
		{
			if(isdefined(attacker) && isPlayer(attacker) && self.pers["team"] == attacker.pers["team"])
			{
				if(int(randomInt(50) + randomInt(50)) > 50) return;
			}
		}
	}

	// Sum of two rolls (triangular distribution); play only if it stays at or below the cvar value.
	randomnr = back2uo_goresound_range(hitloc);
	if(int(randomInt(randomnr) + randomInt(randomnr)) > level.back2uo_painsound_random) return;

	back2uo_play_goresounds("generic_pain");
}

/*
=============
back2uo_goresound_range

Random range per hit zone for pain/death sounds. A smaller range means the cvar threshold
is passed more often, so head and torso hits trigger the sound more often than limb hits.
Params: hitloc - hit location string (may be undefined)
Returns: 30 (head/torso), 40 (upper limbs) or 50 (everything else)
=============
*/
back2uo_goresound_range(hitloc)
{
	if(!isdefined(hitloc)) return 50;

	switch(hitloc)
	{
	// Heavy hit
	case "helmet":
	case "head":
	case "neck":
	case "torso_upper":
	case "torso_lower":
		return 30;

	// Medium hit
	case "left_leg_upper":
	case "right_leg_upper":
	case "left_arm_upper":
	case "right_arm_upper":
		return 40;

	// Light hit
	default:
		return 50;
	}
}

/*
=============
back2uo_deathsound_play

Randomly plays a nationality-specific death sound. Uses the same hit zone weighting
as back2uo_painsound_play, with level.back2uo_deathsound_random as threshold.
Called on: self = killed player
Params: hitloc - hit location string of the killing hit
=============
*/
back2uo_deathsound_play(hitloc)
{
	if(level.back2uo_deathsound_random == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Death Sound", "Run");

	randomnr = back2uo_goresound_range(hitloc);
	if(int(randomInt(randomnr) + randomInt(randomnr)) > level.back2uo_deathsound_random) return;

	back2uo_play_goresounds("generic_death");
}

/*
=============
back2uo_play_goresounds

Plays a random voice variant of a pain/death sound at the player. The alias is built as
<sound>_<nationality>_<n> with n = 1..level.back2uo_voices[nationality] (the stock
aliases are numbered from 1). Allies use game["allies"] (american/british/russian),
axis always use "german".
Called on: self = player
Params: sound - alias prefix, e.g. "generic_pain" or "generic_death"
=============
*/
back2uo_play_goresounds(sound)
{
	if(isdefined(self.origin))
	{
		if(self.pers["team"] == "allies")
		{
			special_sound = sound + "_" + game["allies"] + "_" + (randomInt(level.back2uo_voices[game["allies"]]) + 1);
		}
		else
		{
			special_sound = sound + "_german_" + (randomInt(level.back2uo_voices["german"]) + 1);
		}

		if(isdefined(special_sound)) self playSound(special_sound);
	}
}

/*
=============
back2uo_hit_taunts

Decides whether the attacker shouts a taunt after a hit. Only hits on head, helmet, neck,
upper torso or upper arms by an enemy player (any other player in DM) qualify.
Called on: self = victim
Params: eAttacker - attacking entity
		sHitLoc - hit location (defaults to "torso_upper")
=============
*/
back2uo_hit_taunts(eAttacker, sHitLoc)
{
	if(level.back2uo_tauntsounds_random == 0) return;

	// No trace call: runs on every hit

	if(!isdefined(eAttacker)) return;

	if(!isdefined(sHitLoc)) sHitLoc = "torso_upper";

	if(!isplayer(eAttacker) || eAttacker == self) return;

	// Team gametypes: no taunts for friendly fire
	if(getcvar("g_gametype") != "dm" && self.pers["team"] == eAttacker.pers["team"]) return;

	// Head and upper body area
	switch(sHitLoc)
	{
	case "head":
	case "helmet":
	case "neck":
	case "torso_upper":
	case "left_arm_upper":
	case "right_arm_upper":
		eAttacker thread back2uo_tauntsounds();
		break;
	}
}

/*
=============
back2uo_tauntsounds

Randomly plays a taunt in the attacker's nationality at the attacker's position, half a second
after the hit. The alias "Taunt_<land>" has one variant per recorded line (ElevenLabs, see
tools/elevenlabs_sprueche.py); the engine picks one at random.
self.back2uo_taunting blocks a second taunt of the same attacker (e.g. a double kill) until
the longest line (~4.7 s) is over. It is a plain entity field, not pers, so it cannot get
stuck across rounds; the thread runs on the attacker, so it ends if the attacker leaves.
Called on: self = attacking player (taunt voice and sound position)
=============
*/
back2uo_tauntsounds()
{
	if(int(randomInt(50) + randomInt(50)) > level.back2uo_tauntsounds_random) return;

	// Only one taunt at a time per attacker
	if(isdefined(self.back2uo_taunting)) return;
	self.back2uo_taunting = true;

	back2uo\_back2uo_cvars::back2uo_logprint("Taunt Sounds", "Run");

	// Nation code: GE, US, UK or RU
	land = back2uo\tools\_back2uo_names::back2uo_teams(self);

	wait 0.5;

	self thread back2uo_soundonplayerorigin("Taunt_" + land, self);

	// Lock time before the next taunt can play (longest line is about 4.7 seconds)
	wait 4.5;

	self.back2uo_taunting = undefined;
}

/*
=============
back2uo_grenade_isthrowing

Polls the player's frag grenade count every 0.1 seconds. When the count drops while the
player is alive and playing, a grenade was thrown and a warning shout is triggered.
A rising count (pickup/respawn) just updates the stored value.
Called on: self = player (threaded on spawn)
=============
*/
back2uo_grenade_isthrowing()
{
	if(level.back2uo_nadesounds_random == 0) return;

	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	self.pers["nade_count"] = maps\mp\gametypes\_weapons::getFragGrenadeCount();

	for(;;)
	{
		grenade_count = maps\mp\gametypes\_weapons::getFragGrenadeCount();

		if(grenade_count < self.pers["nade_count"] && isAlive(self) && self.sessionstate == "playing")
		{
			self.pers["nade_count"] = maps\mp\gametypes\_weapons::getFragGrenadeCount();

			self thread back2uo_grenade_tauntsounds();
		}
		else if(grenade_count > self.pers["nade_count"])
		{
			self.pers["nade_count"] = maps\mp\gametypes\_weapons::getFragGrenadeCount();
		}

		wait 0.1;
	}
}

/*
=============
back2uo_grenade_tauntsounds

Randomly plays a "grenade!" shout in the thrower's nationality at the thrower's position.
Alias format: <land>_<0..3>_inform_attacker_grenade.
Called on: self = player who threw the grenade
=============
*/
back2uo_grenade_tauntsounds()
{
	if(int(randomInt(50) + randomInt(50)) > level.back2uo_nadesounds_random) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Grenade Taunt Sounds", "Run");

	land = back2uo\tools\_back2uo_names::back2uo_teams(self);

	// Voice variant (0..3) picked on spawn in _back2uo_player.gsc
	if(isdefined(self.pers["taunt_person"])) person = self.pers["taunt_person"];
	else person = randomint(4);

	sound = land + "_" + person + "_inform_attacker_grenade";

	self thread back2uo_soundonplayerorigin(sound, self);
}

/*
=============
back2uo_soundonplayerorigin

Plays a sound in 3D at the given player's current position. A temporary script_model is
spawned there as the sound source so the sound stays in place even if the player moves,
and is deleted after 5 seconds.
Called on: self = player that owns the thread
Params: sound - sound alias
		person - player whose position is used
=============
*/
back2uo_soundonplayerorigin(sound, person)
{
	// No player endon: the sound entity must be deleted even if the player disconnects.
	level endon("back2uo_killthreads");

	if(!isdefined(sound) || sound == "") return;

	// The player may have left in the meantime (taunts are delayed by half a second)
	if(!isdefined(person) || !isdefined(person.origin)) return;

	soundorg = spawn("script_model", (person.origin));
	soundorg.origin = person.origin;
	soundorg playsound(sound);

	// Give the sound time to finish before removing the source entity
	wait 5;

	soundorg delete();
}

/*
=============
back2uo_soundonplayer

Plays a 2D (local) sound that only the given player hears.
Params: sound - sound alias
		person - receiving player
=============
*/
back2uo_soundonplayer(sound, person)
{
	if(isdefined(person)) person playLocalSound(sound);
}

/*
=============
back2uo_soundonplayers

Plays a 2D (local) sound for every connected player.
Params: sound - sound alias
=============
*/
back2uo_soundonplayers(sound)
{
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++)
	{
		players[i] playLocalSound(sound);
	}
}

/*
=============
back2uo_soundambiente

Not in use. Endless loop that spawns a looping ambient sound source (alias <sound>1) once
per player at the player's position. The spawned entities are never deleted.
Params: sound - ambient alias prefix
=============
*/
back2uo_soundambiente(sound)
{
	if(!isdefined(sound)) return;

	while(1)
	{
		players = getentarray("player", "classname");

		for(i = 0; i < players.size; i++)
		{
			if(!isdefined(players[i].back2uo_ambientsound))
			{
				ambient = spawn("script_model", (0, 0, 1));
				ambient.origin = players[i].origin;
				ambient playloopsound(sound + "1");

				players[i].back2uo_ambientsound = true;
			}
		}

		wait 0.1;
	}
}
