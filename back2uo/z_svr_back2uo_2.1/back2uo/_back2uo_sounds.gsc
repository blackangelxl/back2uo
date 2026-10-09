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

	back2uo\_back2uo_cvars::back2uo_logprint("Pain Sound", "Run");

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

	// Random range per hit zone; a smaller range means the cvar threshold is passed more often.
	randomnr = 50;

	if(!isdefined(hitloc)) hitloc = "nothing";

	switch(hitloc)
	{
	// Heavy hit
	case "head":
	case "neck":
	case "torso_upper":
	case "torso_lower":
		randomnr = 30;
		break;

	// Medium hit
	case "left_leg_upper":
	case "right_leg_upper":
	case "left_arm_upper":
	case "right_arm_upper":
		randomnr = 40;
		break;

	// Light hit
	default:
		randomnr = 50;
		break;
	}

	// Sum of two rolls (triangular distribution); play only if it stays at or below the cvar value.
	if(level.back2uo_painsound_random > 0 && int(randomInt(randomnr) + randomInt(randomnr)) > level.back2uo_painsound_random) return;

	back2uo_play_goresounds("generic_pain");
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

	// Random range per hit zone; a smaller range means the cvar threshold is passed more often.
	randomnr = 50;

	if(!isdefined(hitloc)) hitloc = "nothing";

	switch(hitloc)
	{
	// Heavy hit
	case "head":
	case "neck":
	case "torso_upper":
	case "torso_lower":
		randomnr = 30;
		break;

	// Medium hit
	case "left_leg_upper":
	case "right_leg_upper":
	case "left_arm_upper":
	case "right_arm_upper":
		randomnr = 40;
		break;

	// Light hit
	default:
		randomnr = 50;
		break;
	}

	if(level.back2uo_deathsound_random > 0 && int(randomInt(randomnr) + randomInt(randomnr)) > level.back2uo_deathsound_random) return;

	back2uo_play_goresounds("generic_death");
}

/*
=============
back2uo_play_goresounds

Plays a random voice variant of a pain/death sound at the player. The alias is built as
<sound>_<nationality>_<n>, where n is below level.back2uo_voices[nationality].
Allies use game["allies"] (american/british/russian), axis always use "german".
Called on: self = player
Params: sound - alias prefix, e.g. "generic_pain" or "generic_death"
=============
*/
back2uo_play_goresounds(sound)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Gore Sounds", "Run");

	if(isdefined(self.origin))
	{
		if(self.pers["team"] == "allies")
		{
			special_sound = sound + "_" + game["allies"] + "_" + randomInt(level.back2uo_voices[game["allies"]]);
		}
		else
		{
			special_sound = sound + "_german_" + randomInt(level.back2uo_voices["german"]);
		}

		if(isdefined(special_sound)) self playSound(special_sound);
	}
}

/*
=============
back2uo_hit_taunts

Decides whether the attacker shouts a taunt after a hit. Only hits on helmet, neck,
upper torso or upper arms by an enemy player (any other player in DM) qualify.
Called on: self = victim
Params: eAttacker - attacking entity
		sHitLoc - hit location (defaults to "torso_upper")
=============
*/
back2uo_hit_taunts(eAttacker, sHitLoc)
{
	if(level.back2uo_tauntsounds_random == 0) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hit Taunts", "Run");

	if(!isdefined(eAttacker)) return;

	if(!isdefined(sHitLoc)) sHitLoc = "torso_upper";

	if(isplayer(eAttacker) && eAttacker != self)
	{
		if(getcvar("g_gametype") == "dm")
		{
			// Head and upper body area
			if(sHitLoc == "helmet" || sHitLoc == "neck" || sHitLoc == "torso_upper" || sHitLoc == "left_arm_upper" || sHitLoc == "right_arm_upper")
			{
				back2uo_tauntsounds(eAttacker);
			}
		}
		else
		{
			// Team gametypes: no taunts for friendly fire
			if(self.pers["team"] != eAttacker.pers["team"])
			{
				// Head and upper body area
				if(sHitLoc == "helmet" || sHitLoc == "neck" || sHitLoc == "torso_upper" || sHitLoc == "left_arm_upper" || sHitLoc == "right_arm_upper")
				{
					back2uo_tauntsounds(eAttacker);
				}
			}
		}
	}
}

/*
=============
back2uo_tauntsounds

Randomly plays a taunt in the attacker's nationality at the attacker's position, half a second
after the hit. self.pers["tauntsound_onplayer"] blocks overlapping taunts for about 2.5 seconds.
Called on: self = victim
Params: eAttacker - attacking player (taunt voice and sound position)
=============
*/
back2uo_tauntsounds(eAttacker)
{
	if(int(randomInt(50) + randomInt(50)) > level.back2uo_tauntsounds_random) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Taunt Sounds", "Run");

	// Only one taunt at a time per victim
	if(isdefined(self.pers["tauntsound_onplayer"])) return;
	self.pers["tauntsound_onplayer"] = true;

	// Nation code: GE, US, UK or RU
	land = back2uo\_back2uo_tools::back2uo_teams(eAttacker);

	// The attacker shouts: his voice variant, set in _back2uo_player.gsc (randomint(4) = 0..3)
	if(isdefined(eAttacker.pers["taunt_person"])) person = eAttacker.pers["taunt_person"];
	else person = randomint(4);

	// Disabled: old alias format without random line number
	//sound = "Taunt_" + land + "_" + person;
	sound = back2uo_tauntsounds_string(land, person);

	wait 0.5;

	self thread back2uo_soundonplayerorigin(sound, eAttacker);

	// Lock time before the next taunt can play
	wait 2;

	self.pers["tauntsound_onplayer"] = undefined;
}

/*
=============
back2uo_tauntsounds_string

Builds the taunt alias "Taunt_<land>_<person>_<n>" with a random line number n. The
upper bound of n is the number of recorded lines for that voice in soundaliases/_back2uo.csv.
Params: land - nation code (GE, RU, UK, US)
		person - voice variant 0..3
Returns: the sound alias, or "" if land/person do not match
=============
*/
back2uo_tauntsounds_string(land, person)
{
	// Recorded lines per voice 0..3
	lines = [];

	switch(land)
	{
	// German
	case "GE":
		lines[0] = 12;
		lines[1] = 10;
		lines[2] = 8;
		lines[3] = 7;
		break;

	// Russian
	case "RU":
		lines[0] = 6;
		lines[1] = 7;
		lines[2] = 7;
		lines[3] = 8;
		break;

	// British
	case "UK":
		lines[0] = 7;
		lines[1] = 7;
		lines[2] = 9;
		lines[3] = 8;
		break;

	// American
	case "US":
		lines[0] = 8;
		lines[1] = 6;
		lines[2] = 8;
		lines[3] = 8;
		break;

	default:
		return "";
	}

	if(!isdefined(person) || !isdefined(lines[person])) return "";

	return "Taunt_" + land + "_" + person + "_" + randomint(lines[person]);
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

	land = back2uo\_back2uo_tools::back2uo_teams(self);

	// Same voice variant (0..3) as the player's taunts
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

	if(!isdefined(person.origin) && person.sessionstate != "playing") return;

	back2uo\_back2uo_cvars::back2uo_logprint("Sound on Player Origin", "Play");

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
