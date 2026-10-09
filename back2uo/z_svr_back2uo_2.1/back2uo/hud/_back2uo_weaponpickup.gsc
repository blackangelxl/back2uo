/*
	Back2Uo v2.1 - Weapon pickup hint.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_weaponpickup_hud_draw

Creates the hidden "swap weapons" hint text shown when the player stands on a pickup
weapon (made visible by _back2uo_weaponsystem.gsc).
Called on: self = player
=============
*/
back2uo_weaponpickup_hud_draw()
{
	if(!game["back2uo_sprint_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Weapon Pickup Hud Draw", "Run");

	if(!isdefined(self.back2uo_weaponpickup))
	{
		self.back2uo_weaponpickup = newClientHudElem(self);
		self.back2uo_weaponpickup.alignX = "right";
		self.back2uo_weaponpickup.alignY = "top";
		self.back2uo_weaponpickup.fontScale = 0.9;
		self.back2uo_weaponpickup.x = 375;
		self.back2uo_weaponpickup.y = 345;
		self.back2uo_weaponpickup.alpha = 0;
		self.back2uo_weaponpickup setText(level.back2uo_weaponpickup);
	}
}
