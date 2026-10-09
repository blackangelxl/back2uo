/*
	Back2Uo v2.1 - player health regeneration and hurt breathing sounds

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from the gametype scripts. Each spawn starts playerHealthRegen(), which is
	stopped by the "end_healthregen" notify (death, team change, spectating, disconnect).
	Back2Uo: game["back2uo_health_is_enable"] (cvar back2uo_health_is, default 1) switches to
	"realistic" health: no regeneration at all, only a single hurt breathing sound.
	Tuning: level.healthOverlayCutoff, level.playerHealth_RegularRegenDelay.
*/

/*
=============
init

Precaches the low health overlay, sets the regeneration tuning values and starts the connect watcher.
=============
*/
init()
{
	precacheShader("overlay_low_health");

	// Health fraction at or below which the player counts as "very hurt".
	level.healthOverlayCutoff = 0.35;
	// Milliseconds without new damage before health starts to regenerate.
	level.playerHealth_RegularRegenDelay = 5000;

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Starts the per-player event watchers that start and stop health regeneration.
Called on: level
=============
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player thread onPlayerSpawned();
		player thread onPlayerKilled();
		player thread onJoinedTeam();
		player thread onJoinedSpectators();
		player thread onPlayerDisconnect();
	}
}

/*
=============
onJoinedTeam

Stops health regeneration when the player switches team.
Called on: player
=============
*/
onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");
		self notify("end_healthregen");
	}
}

/*
=============
onJoinedSpectators

Stops health regeneration when the player goes to spectator.
Called on: player
=============
*/
onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self notify("end_healthregen");
	}
}

/*
=============
onPlayerSpawned

Starts a fresh health regeneration thread on every spawn.
Called on: player
=============
*/
onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		self thread playerHealthRegen();
	}
}

/*
=============
onPlayerKilled

Stops health regeneration when the player dies.
Called on: player
=============
*/
onPlayerKilled()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("killed_player");
		self notify("end_healthregen");
	}
}

/*
=============
onPlayerDisconnect

Stops health regeneration when the player disconnects.
Called on: player
=============
*/
onPlayerDisconnect()
{
	self waittill("disconnect");
	self notify("end_healthregen");
}

/*
=============
playerHealthRegen

Stock health regeneration. Polls health every server frame; after level.playerHealth_RegularRegenDelay ms
without new damage health is restored: instantly to full if the player was only lightly hurt,
or in regenRate steps (after an extra 3 seconds) if the player dropped below level.healthOverlayCutoff.
Back2Uo: with realistic health enabled there is no regeneration, only one breathing sound thread.
Called on: player
=============
*/
playerHealthRegen()
{
	self endon("end_healthregen");

	// Health at spawn time is taken as the maximum.
	maxhealth = self.health;
	oldhealth = maxhealth;
	player = self;
	health_add = 0;

	// Fraction of max health added per frame while regenerating from "very hurt" (stock value was 0.017).
	regenRate = 0.1; // 0.017;
	veryHurt = false;

	// Back2Uo: health mode ( 0 = health regeneration | 1 = realistic health, no regeneration ).
	if(game["back2uo_health_is_enable"])
	{
		// extra = 1: the breathing thread plays the hurt sound only once.
		thread playerBreathingSound(maxhealth * 0.35, 1);

		return;
	}

	thread playerBreathingSound(maxhealth * 0.35, 0);
	lastSoundTime_Recover = 0;
	hurtTime = 0;
	newHealth = 0;

	for (;;)
	{
		wait (0.05);
		if (player.health == maxhealth)
		{
			veryHurt = false;
			continue;
		}

		if (player.health <= 0)
			return;

		wasVeryHurt = veryHurt;
		ratio = player.health / maxHealth;
		if (ratio <= level.healthOverlayCutoff)
		{
			veryHurt = true;
			if (!wasVeryHurt)
			{
				hurtTime = gettime();
			}
		}

		// No new damage since the last frame: regenerate once the delay has passed.
		if (player.health >= oldhealth)
		{
			if (gettime() - hurttime < level.playerHealth_RegularRegenDelay)
				continue;

			if (gettime() - lastSoundTime_Recover > level.playerHealth_RegularRegenDelay)
			{
				lastSoundTime_Recover = gettime();
				self playLocalSound("breathing_better");
			}

			if (veryHurt)
			{
				newHealth = ratio;
				if (gettime() > hurtTime + 3000)
					newHealth += regenRate;
			}
			else
				newHealth = 1;

			if (newHealth > 1.0)
				newHealth = 1.0;

			if (newHealth <= 0)
			{
				// Player is dead
				return;
			}

			// setnormalhealth takes a 0..1 fraction of max health.
			player setnormalhealth (newHealth);
			oldhealth = player.health;
			continue;
		}

		// Player took damage this frame: restart the regeneration delay.
		oldhealth = player.health;

		health_add = 0;
		hurtTime = gettime();
	}
}

/*
=============
playerBreathingSound

Plays the "breathing_hurt" local sound in a loop while the player's health is below healthcap.
Params: healthcap - health value below which the player breathes hard
		extra - 1 = Back2Uo realistic health mode, return after the first breathing sound;
				0 = loop until death or "end_healthregen"
Called on: player
=============
*/
playerBreathingSound(healthcap, extra)
{
	self endon("end_healthregen");

	wait (2);
	player = self;
	for (;;)
	{
		wait (0.2);
		if (player.health <= 0)
			return;

		// Player still has a lot of health so no breathing sound
		if (player.health >= healthcap)
			continue;

		player playLocalSound("breathing_hurt");
		// Pause between breaths: fixed .784 s plus a random 0.1 - 0.9 s.
		wait .784;
		wait (0.1 + randomfloat (0.8));

		// Back2Uo: realistic health mode plays the sound only once.
		if(extra == 1) return;
	}
}
