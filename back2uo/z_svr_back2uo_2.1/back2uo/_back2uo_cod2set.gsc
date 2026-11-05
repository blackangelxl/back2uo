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
		back2uo\_back2uo_cvars::back2uo_logevent("clientset", "error", "reason=noself");
		return;
	}

	// Already sent this map: no log, this runs on every spawn
	if(isdefined(self.pers["client_set"])) return;
	self.pers["client_set"] = true;

	// Lets the client UI show the mod credits only when the mod is enabled.
	self setClientCvar("back2uo_ui_modcredits", game["back2uo_enable"]);

	// Clears the weapon pickup message cvar used by the mod menu.
	self setClientCvar("back2uo_weaponpickup_msg", " ");

	// Compass needle in the mod's HUD menu (0 = off, 1 = on, default 1).
	game["back2uo_compassneedle"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_compassneedle", 1, 0, 1);
	self setClientCvar("back2uo_ui_compassneedle", game["back2uo_compassneedle"]);

	// UI flags for the mod's HUD menu elements (medic and weapon pickup icons).
	self setClientCvar("back2uo_ui_medicicon", 0);
	self setClientCvar("back2uo_ui_weaponpickup", 0);
	self setClientCvar("back2uo_ui_weaponpickup_object", 0);

	// UI flags for the serverinfos menu: hide the action info of disabled features, and the whole box if both are off.
	self setClientCvar("back2uo_ui_sprint", game["back2uo_sprint_enable"]);
	self setClientCvar("back2uo_ui_artillery", game["back2uo_artilleryfx_enable"]);
	self setClientCvar("back2uo_ui_actioninfo", game["back2uo_sprint_enable"] || game["back2uo_artilleryfx_enable"]);

	// Blood effects (0 = off, 1 = on, default 1).
	game["back2uo_blood"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_blood_active", 1, 0, 1);
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

	// Compass size (0 = hidden, 1 = normal).
	game["back2uo_hudcompasssize"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_hudcompasssize", 1, 0, 1);
	self setClientCvar("cg_hudCompassSize", game["back2uo_hudcompasssize"]);

	// Enemy fire shown as red dots on the compass (read by the mod's UI).
	game["back2uo_compassreddots"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_compassfiring", 1, 0, 1);
	self setClientCvar("back2uo_ui_compassenemyfiring", game["back2uo_compassreddots"]);

	// Server message display in the mod menu.
	game["back2uo_servermsg"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_servermsg_active", 1, 0, 1);
	self setClientCvar("back2uo_ui_servermsg", game["back2uo_servermsg"]);

	// Copies the configured host name to the client's sv_hostname.
	game["back2uo_hostname"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_hostname", "", 0, 0, "string");
	self setClientCvar("sv_hostname", game["back2uo_hostname"]);

	// Disabled: forced the client language from the back2uo_language cvar.
	//game["back2uo_language"] = back2uo\_back2uo_cvars::back2uo_getcvardef("back2uo_language", 0, 0, 1, "string");
	//self setClientCvar("loc_language", game["back2uo_language"]);

	// Optional reset of stock client cvars to their default values (FOV, damage indicator, objective markers).
	game["back2uo_client_settings"] = back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_client_settings", 1, 0, 1);
	if(game["back2uo_client_settings"])
	{
		self setClientCvar("cg_errordecay", "100");
		self setClientCvar("cg_fov", "80");
		self setClientCvar("cg_hudDamageIconHeight", "64");
		self setClientCvar("cg_hudDamageIconInScope", "0");
		self setClientCvar("cg_hudDamageIconOffset", "128");
		self setClientCvar("cg_hudDamageIconTime", "2000");
		self setClientCvar("cg_hudDamageIconWidth", "128");
		self setClientCvar("cg_hudObjectiveMaxRange", "2048");
		self setClientCvar("cg_hudObjectiveMinAlpha", "1");
		self setClientCvar("cg_hudObjectiveMinHeight", "-70");
		self setClientCvar("cg_thirdperson", "0");
		self setClientCvar("fx_sort", "1");
	}

	// Client sound setting (mss_Q3fs); the original author set it to avoid overlapping sounds.
	self setClientCvar("mss_Q3fs", 1);

	// Raises the client memory hunk from 160 to 512 MB (engine maximum).
	// Applies only after the next game restart and stays in the player's config, also on other servers.
	self setClientCvar("com_hunkmegs", "512");

	back2uo\_back2uo_cvars::back2uo_logevent("clientset", "set", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " blood=" + game["back2uo_blood"] + " crosshair=" + game["back2uo_drawcrosshair"] + " crosshairnames=" + game["back2uo_drawcrosshairnames"] + " redcrosshair=" + game["back2uo_crosshairenemycolor"] + " compasssize=" + game["back2uo_hudcompasssize"] + " compassfiring=" + game["back2uo_compassreddots"] + " compassneedle=" + game["back2uo_compassneedle"] + " clientsettings=" + game["back2uo_client_settings"]);
}
