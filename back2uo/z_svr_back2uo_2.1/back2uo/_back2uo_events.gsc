/*
	Back2Uo v2.1 - Mod events: named notifies that replace polling loops.

	Player lifecycle:
		"back2uo_life_end" (player) - the current life of the player is over. Sent by
		_back2uo_player.gsc on death, on every spawn and spectator switch (ends leftovers of the
		previous life) and on disconnect. Every per-life loop ends on it:
			self endon("disconnect");
			self endon("back2uo_life_end");

	Player state:
		"back2uo_artillery_changed" (player) - self.pers["artillery_save"] was set or cleared.
		"back2uo_health_changed" (player) - the health may have changed (damage, regeneration,
		health pack, artillery, HQ heal; sent before or after the change in the same frame,
		listeners use waittillframeend). The health bar also sends it every 0.5 s as fallback.
		"update_playerhud_score" (player) - stock CoD2 notify, sent after a score change.

	Map events (level):
		"back2uo_warfx_tracer", "back2uo_warfx_mortar", "back2uo_warfx_airplane" - the random
		trigger in warfx\_back2uo_warfx.gsc allows one ambient tracer wave, mortar barrage or
		airplane fly-over. Any script can react to them (or send them, e.g. tests).

	A notify only reaches threads that already wait for it, so the listeners must be started
	before the first event (see _back2uo_player::back2uo_start_gametype).
*/

/*
=============
back2uo_event_life_end

Ends all per-life loops of the player (they use endon "back2uo_life_end").
Called on: self = player
=============
*/
back2uo_event_life_end()
{
	self notify("back2uo_life_end");
}

/*
=============
back2uo_event_artillery_changed

Tells the HUD that self.pers["artillery_save"] changed.
Called on: self = player
=============
*/
back2uo_event_artillery_changed()
{
	self notify("back2uo_artillery_changed");
}

/*
=============
back2uo_event_health_changed

Tells the health bar that the health may have changed.
Called on: self = player
=============
*/
back2uo_event_health_changed()
{
	self notify("back2uo_health_changed");
}

/*
=============
back2uo_event_warfx

Sends the map event of one war effect.
Called on: level
Params: fx - "tracer", "mortar" or "airplane"
=============
*/
back2uo_event_warfx(fx)
{
	level notify("back2uo_warfx_" + fx);
}
