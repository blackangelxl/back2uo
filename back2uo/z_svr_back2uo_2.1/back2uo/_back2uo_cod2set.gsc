/*
	Back2Uo v2.1 - Client cvar setup

	Pushes the mod's client-side settings (blood, crosshairs, HUD fade times, compass,
	UI flags for the mod menus) to a connecting player via setClientCvar.
	Entry point: back2uo_clientset_init(), called on the player from _back2uo_player.gsc.
	Values come from back2uo_* server cvars (back2uomod.cfg) and are cached in game[].
*/

/*
=============
back2uo_clientset_init

Sends all mod client cvars to the player once per map (guarded by
self.pers["client_set"]). Each setting is read from its back2uo_* server cvar,
stored in game[] and forwarded to the matching client cvar.
Called on: self = player
=============
*/
back2uo_clientset_init()
{
	back2uo\_back2uo_cvars::back2uo_logprint("Client Settings", "Run");

	// The thread can start after the player has already left.
	if(!isdefined(self))
	{
		back2uo\_back2uo_cvars::back2uo_logprint("client_set", "self not exist");
		return;
	}

	if(isdefined(self.pers["client_set"])) return;
	self.pers["client_set"] = true;

	// Lets the client UI show the mod credits only when the mod is enabled.
	self setClientCvar("back2uo_ui_modcredits", game["back2uo_enable"]);

	// Blood effects (0 = off, 1 = on, default 1).
	game["back2uo_blood"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_blood", 1, 0, 1);
	self setClientCvar("cg_blood", game["back2uo_blood"]);

	// Crosshair (0 = off, 1 = on, default 1).
	game["back2uo_drawcrosshair"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_crosshair", 1, 0, 1);
	self setClientCvar("cg_drawcrosshair", game["back2uo_drawcrosshair"]);

	// Crosshair while on a mounted turret (0 = off, 1 = on, default 1).
	game["back2uo_drawturretcrosshair"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_turretcrosshair", 1, 0, 1);
	self setClientCvar("cg_drawturretcrosshair", game["back2uo_drawturretcrosshair"]);

	// Player names under the crosshair (0 = off, 1 = on, default 1).
	game["back2uo_drawcrosshairnames"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_crosshairnames", 1, 0, 1);
	self setClientCvar("cg_drawcrosshairnames", game["back2uo_drawcrosshairnames"]);

	// Crosshair turns red over enemies (0 = off, 1 = on).
	game["back2uo_crosshairenemycolor"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_redcrosshair", 1, 0, 1);
	self setClientCvar("cg_crosshairenemycolor", game["back2uo_crosshairenemycolor"]);

	// Mantle (climb over) hint icon (0 = off, 1 = on).
	game["back2uo_drawmantlehint"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_drawmantlehint", 1, 0, 1);
	self setClientCvar("cg_drawmantlehint", game["back2uo_drawmantlehint"]);

	// HUD fade times in seconds (0 = never fade, 0.1 - 30 seconds).
	game["back2uo_hudcompassfade"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudcompassfade", 0, 0, 30);
	self setClientCvar("hud_fade_compass", game["back2uo_hudcompassfade"]);

	game["back2uo_hudstancefade"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudstancefade", 0, 0, 30);
	self setClientCvar("hud_fade_stance", game["back2uo_hudstancefade"]);

	game["back2uo_hudoffhandfade"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudoffhandfade", 0, 0, 30);
	self setClientCvar("hud_fade_offhand", game["back2uo_hudoffhandfade"]);

	game["back2uo_hudammodisplayfade"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudammodisplayfade", 0, 0, 30);
	self setClientCvar("hud_fade_ammodisplay", game["back2uo_hudammodisplayfade"]);

	// Client sound setting (mss_Q3fs); the original author set it to avoid overlapping sounds.
	self setClientCvar("mss_Q3fs", 1);

	// Compass size (0 = hidden, 1 = normal).
	game["back2uo_hudcompasssize"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudcompasssize", 1, 0, 1);
	self setClientCvar("cg_hudCompassSize", game["back2uo_hudcompasssize"]);

	// Enemy fire shown as red dots on the compass (read by the mod's UI).
	game["back2uo_compassreddots"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_compassfiring", 1, 0, 1);
	self setClientCvar("back2uo_ui_compassenemyfiring", game["back2uo_compassreddots"]);

	// Server message display in the mod menu.
	game["back2uo_servermsg"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_servermsg_aktiv", 1, 0, 1);
	self setClientCvar("back2uo_ui_servermsg", game["back2uo_servermsg"]);

	// Copies the configured host name to the client's sv_hostname.
	game["back2uo_hostname"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hostname", "", 0, 0, "string");
	self setClientCvar("sv_hostname", game["back2uo_hostname"]);

	// Disabled: forced the client language from the back2uo_language cvar.
	//game["back2uo_language"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_language", 0, 0, 1, "string");
	//self setClientCvar("loc_language", game["back2uo_language"]);

	// Raises the client memory hunk to 512 MB for the mod's extra assets.
	self setClientCvar("com_hunkmegs", "512");

	// Clears the weapon pickup message cvar used by the mod menu.
	self setClientCvar("back2uo_weaponpickup_msg", " ");

	// UI flags for the mod's HUD menu elements (compass needle, medic and weapon pickup icons).
	self setClientCvar("back2uo_ui_compasszeiger", 1);

	self setClientCvar("back2uo_ui_medicicon", 0);
	self setClientCvar("back2uo_ui_weaponpickup", 0);
	self setClientCvar("back2uo_ui_weaponpickup_object", 0);

	// Optional block of tuned stock client cvars (FOV, damage indicator, objective markers).
	game["back2uo_client_settings"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_client_settings", 1, 0, 1);

	if(game["back2uo_client_settings"])
	{
		self setClientCvar("cg_errordecay","100");
		self setClientCvar("cg_fov","80");
		self setClientCvar("cg_hudDamageIconHeight","64");
		self setClientCvar("cg_hudDamageIconInScope","0");
		self setClientCvar("cg_hudDamageIconOffset","128");
		self setClientCvar("cg_hudDamageIconTime","2000");
		self setClientCvar("cg_hudDamageIconWidth","128");
		self setClientCvar("cg_hudObjectiveMaxRange","2048");
		self setClientCvar("cg_hudObjectiveMinAlpha","1");
		self setClientCvar("cg_hudObjectiveMinHeight","-70");
		self setClientCvar("cg_thirdperson","0");
		self setClientCvar("fx_sort","1");
	}
}
