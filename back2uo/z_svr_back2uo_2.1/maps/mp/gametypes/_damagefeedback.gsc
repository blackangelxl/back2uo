/*
	Back2Uo v2.1 - hit feedback (hit marker and hit sound) for the attacker

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	init() is called from the gametype scripts (dm, tdm, ctf, hq, ...). updateDamageFeedback() is
	called on the attacker from the gametype Callback_PlayerDamage and from warfx\_back2uo_artillery.gsc.
	Cvars: game["back2uo_minicrosshair_enable"] (hit marker), game["back2uo_playerhitsound_enable"] (hit sound).
*/

/*
=============
init

Precaches the hit marker shader and starts the connect watcher.
Back2Uo: does nothing when the mini crosshair (hit marker) is disabled.
=============
*/
init()
{
	// Back2Uo: hit marker only when back2uo_minicrosshair is 1 (default 0).
	if(!(game["back2uo_minicrosshair_enable"])) return;

	precacheShader("damage_feedback");

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

Creates the hidden 24x24 hit marker hud element for every connecting player.
Called on: level
=============
*/
onPlayerConnect()
{
	// Back2Uo: redundant guard, init() already returns when the hit marker is disabled.
	if(!game["back2uo_minicrosshair_enable"]) return;

	for(;;)
	{
		level waittill("connecting", player);

		// Centered on screen; -12 offsets the 24x24 shader so its middle sits on the crosshair.
		player.hud_damagefeedback = newClientHudElem(player);
		player.hud_damagefeedback.horzAlign = "center";
		player.hud_damagefeedback.vertAlign = "middle";
		player.hud_damagefeedback.x = -12;
		player.hud_damagefeedback.y = -12;
		player.hud_damagefeedback.alpha = 0;
		player.hud_damagefeedback.archived = true;
		player.hud_damagefeedback setShader("damage_feedback", 24, 24);
	}
}

/*
=============
updateDamageFeedback

Gives the attacker feedback that a hit landed: flashes the hit marker (fades out over 1 second)
and/or plays the local hit sound, depending on the Back2Uo cvars.
Called on: player (the attacker)
=============
*/
updateDamageFeedback()
{
	if(isPlayer(self))
	{
		// Back2Uo: hit marker ( 0 = off | 1 = on, default 0 ).
		if(game["back2uo_minicrosshair_enable"])
		{
			// Show at full alpha, then let the client fade it to 0 over 1 second.
			self.hud_damagefeedback.alpha = 1;
			self.hud_damagefeedback fadeOverTime(1);
			self.hud_damagefeedback.alpha = 0;
		}

		// Back2Uo: hit sound, heard only by the attacker ( 0 = off | 1 = on, default 0 ).
		if(game["back2uo_playerhitsound_enable"])
		{
			self playlocalsound("MP_hit_alert");
		}
	}
}
