/*
	Back2Uo v2.1 - Rank icon, rank up/down handling and rank rewards (ammo, grenades, artillery).

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".
*/

/*
=============
back2uo_ranking_draw

Creates the rank icon above the stance icons and sets the player's scoreboard status
icon to his current rank picture.
Called on: self = player
=============
*/
back2uo_ranking_draw()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Run");

	if(!isdefined(self.hud_ranking_lv))
	{
		if(level.back2uo_hudrankingdraw != 1) return;

		self.hud_ranking_lv = newClientHudElem(self);
		self.hud_ranking_lv.x = -204;
		self.hud_ranking_lv.y = 390;
		self.hud_ranking_lv.horzAlign = "center";
		self.hud_ranking_lv.vertAlign = "top";
		self.hud_ranking_lv.sort = 1;
		self.hud_ranking_lv.archived = true;
		self.hud_ranking_lv.alpha = 0.6;
	}

	if(!isdefined(self.pers["back2uo_score_ranking_pic"])) self.pers["back2uo_score_ranking_pic"] = "gfx/custom/back2uo_ranking_lv1.tga";
	if(level.back2uo_rankingscorelist == 1) self.statusicon = self.pers["back2uo_score_ranking_pic"];
}

/*
=============
back2uo_ranking_update

Every 0.5 seconds maps the player's score to a rank (1 to 5, plus extra ranks every
level.back2uo_ranking_lvextra points above level 5 when back2uo_rankextra_aktiv is set).
On a rank change it plays a sound, prints a message and pulses the rank icon.
Called on: self = player
=============
*/
back2uo_ranking_update()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Update");

	self endon("back2uo_killplayerthreads");
	self endon("disconnect");
	self endon("killed_player");

	if(!isdefined(self.pers["back2uo_ranking"])) self.pers["back2uo_ranking"] = 1;
	// Score needed for the first extra rank above level 5.
	if(!isdefined(self.pers["back2uo_ranking_extra"])) self.pers["back2uo_ranking_extra"] = level.back2uo_ranking_level5 + level.back2uo_ranking_lvextra;
	level.back2uo_ranking_over = level.back2uo_ranking_level5 + level.back2uo_ranking_lvextra;

	self.back2uo_rank_give = undefined;

	// Player still owns an unused artillery strike (from an earlier life): restart the binocular target selection.
	if(game["back2uo_artilleryfx_enable"] && isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
	{
		thread back2uo\_back2uo_warfx::back2uo_artilleryfx_binowaituse();
	}

	for(;;)
	{
		// Remember the previous rank to detect rank changes below.
		player_score = self.score;
		self.pers["back2uo_ranking_new"] = self.pers["back2uo_ranking"];

		if(player_score >= level.back2uo_ranking_level2 && player_score < level.back2uo_ranking_level3)
		{
			back2uo_ranking_level(2);

			self.pers["back2uo_ranking"] = 2;
		}
		else if(player_score >= level.back2uo_ranking_level3 && player_score < level.back2uo_ranking_level4)
		{
			back2uo_ranking_level(3);

			self.pers["back2uo_ranking"] = 3;
		}
		else if(player_score >= level.back2uo_ranking_level4 && player_score < level.back2uo_ranking_level5)
		{
			back2uo_ranking_level(4);

			self.pers["back2uo_ranking"] = 4;
		}
		else if(player_score >= level.back2uo_ranking_level5 && player_score < level.back2uo_ranking_over)
		{
			back2uo_ranking_level(5);

			self.pers["back2uo_ranking"] = 5;
		}
		else if(player_score >= self.pers["back2uo_ranking_extra"] && level.back2uo_rankextra_aktiv == 1)
		{
			// Extra ranks: one rank up every back2uo_ranking_lvextra points above level 5.
			back2uo_ranking_level(self.pers["back2uo_ranking"]);

			self.pers["back2uo_ranking"]++;
			self.pers["back2uo_ranking_extra"] += level.back2uo_ranking_lvextra;
		}
		else
		{
			// Below level 2
			back2uo_ranking_level(1);
		}

		// Teammates see the rank as head icon (team gametypes only).
		if(isdefined(self.headicon) && level.back2uo_teamrankheadicons == 1 && getCvar("g_gametype") != "dm")
		{
			self.headicon = self.pers["back2uo_head_ranking_pic"];
		}

		// Rank changed
		if(self.pers["back2uo_ranking"] != self.pers["back2uo_ranking_new"])
		{
			if(self.pers["back2uo_ranking"] <= 5)
			{
				// Rank up: sound and message; allow the rewards of the next rank.
				if(self.pers["back2uo_ranking"] > self.pers["back2uo_ranking_new"])
				{
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_up", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_UP");

					self.back2uo_rank_give = undefined;
				}
				else
				{
					// Rank down: sound and message only.
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_down", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_DOWN");
				}

				// Pulse the rank icon: grow, shrink, back to normal.
				if(isdefined(self.hud_ranking_lv))
				{
					if(level.back2uo_rankingscorelist == 1) self.statusicon = self.pers["back2uo_score_ranking_pic"];

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = -206;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.2;
					self.hud_ranking_lv.x = -208;
					self.hud_ranking_lv.y = 386;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 32, 32);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = -206;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.1;

					self.hud_ranking_lv.alpha = 0.6;
					self.hud_ranking_lv.x = -204;
					self.hud_ranking_lv.y = 390;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 24, 24);
				}
			}
			else
			{
				self.back2uo_rank_give = undefined;
			}

			self.back2uo_art_rank = undefined;
		}
		else
		{
			if(isdefined(self.hud_ranking_lv))
			{
				self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 24, 24);
			}
		}

		wait 0.5;
	}
}

/*
=============
back2uo_ranking_level

Sets the rank icons (HUD, scoreboard, head icon) for the given rank and hands out the
rank rewards once per rank (self.back2uo_rank_give). Ranks above 5 use the level 5 icons
and rewards.
Called on: self = player
Params: ranking_lv - rank number used for the icon file names
=============
*/
back2uo_ranking_level(ranking_lv)
{
	// Icons only exist up to level 5.
	if(self.pers["back2uo_ranking"] >= 5) ranking_lv = 5;

	self.back2uo_ranking_pic = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_score_ranking_pic"] = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_head_lv" + ranking_lv + ".tga";

	// Hand out rank rewards once per rank (reset on rank up in back2uo_ranking_update).
	if(self.pers["back2uo_ranking"] == 1)
	{
		self.pers["back2uo_artillery_go"] = false;
	}
	else if(self.pers["back2uo_ranking"] == 2)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(2, level.back2uo_rang2_getsekammo,level.back2uo_rang2_getpriammo,level.back2uo_rang2_getgranade,level.back2uo_rang2_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 3)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(3, level.back2uo_rang3_getsekammo,level.back2uo_rang3_getpriammo,level.back2uo_rang3_getgranade,level.back2uo_rang3_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 4)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(4, level.back2uo_rang4_getsekammo,level.back2uo_rang4_getpriammo,level.back2uo_rang4_getgranade,level.back2uo_rang4_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] == 5)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(5, level.back2uo_rang5_getsekammo,level.back2uo_rang5_getpriammo,level.back2uo_rang5_getgranade,level.back2uo_rang5_getsmoke);
	}
	else if(self.pers["back2uo_ranking"] >= 6)
	{
		if(isdefined(self.back2uo_rank_give)) return;
		self.back2uo_rank_give = true;

		back2uo_ranking_give(self.pers["back2uo_ranking"], level.back2uo_rang5_getsekammo,level.back2uo_rang5_getpriammo,level.back2uo_rang5_getgranade,level.back2uo_rang5_getsmoke);
	}
}

/*
=============
back2uo_ranking_give

Gives the rewards for reaching a rank: extra primary/secondary ammo, frag and smoke
grenades (up to the grenade limits), removes the binoculars at the configured rank and
grants an artillery strike from back2uo_artillery_onrank on.
Called on: self = player
Params: ranking_lv - reached rank
		sek_ammo - extra secondary (pistol) ammo
		pri_ammo - extra primary ammo
		granat - extra frag grenades
		smoke - extra smoke grenades
=============
*/
back2uo_ranking_give(ranking_lv, sek_ammo,pri_ammo,granat,smoke)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Give");

	rank_extras_a = 0;
	rank_extras_b = 0;

	// Primary weapon ammo
	if(pri_ammo > 0)
	{
		mgammo = self getWeaponSlotClipAmmo("primary");
		mgresammo = self getWeaponSlotAmmo("primary");
		mgend_ammo = mgammo + mgresammo + pri_ammo;
		self setWeaponSlotAmmo("primary", mgend_ammo);

		mg_maxammo = self getWeaponSlotAmmo("primary");

		if(mgend_ammo >= mg_maxammo) rank_extras_a++;
	}

	// Secondary (pistol) ammo
	if(sek_ammo > 0)
	{
		pistelammo = self getWeaponSlotClipAmmo("primaryb");
		pistelresammo = self getWeaponSlotAmmo("primaryb");
		pistelend_ammo = pistelammo + pistelresammo + sek_ammo;
		self setWeaponSlotAmmo("primaryb", pistelend_ammo);

		pistel_maxammo = self getWeaponSlotAmmo("primaryb");

		if(pistelend_ammo >= pistel_maxammo) rank_extras_a++;
	}

	// Message if any ammo was given (rank_extras_a is 1 or 2).
	if(level.back2uo_rankingmsg == 1 && (rank_extras_a == 1 || rank_extras_a == 2)) self iprintln(&"BACK2UOMOD_RANKING_MUN");

	// Frag grenades, only up to the level.back2uo_granaten_allow limit.
	if(granat > 0)
	{
		// Count grenades of both nationalities (the player may carry either type).
		grenadetype1 = "frag_grenade_" + game["allies"] + "_mp" + level.back2uo_specialgranade;
		grenadetype2 = "frag_grenade_" + game["axis"] + "_mp" + level.back2uo_specialgranade;
		count1 = self getammocount(grenadetype1);
		count2 = self getammocount(grenadetype2);

		granadecount = count1 + count2;
		granadeend_count = granadecount + granat;

		if(granadeend_count <= level.back2uo_granaten_allow)
		{
			granadetype = self back2uo\_back2uo_tools::back2uo_getgranade_type("granade");

			self giveWeapon(granadetype);
			self setWeaponClipAmmo(granadetype, granadeend_count);
			rank_extras_b++;
		}
	}

	// Smoke grenades, only up to the level.back2uo_smoke_allow limit.
	if(smoke > 0)
	{
		grenadetype1 = "smoke_grenade_" + game["allies"] + "_mp" + level.back2uo_specialsmoke;
		grenadetype2 = "smoke_grenade_" + game["axis"] + "_mp" + level.back2uo_specialsmoke;
		count1 = self getammocount(grenadetype1);
		count2 = self getammocount(grenadetype2);

		smokecount = count1 + count2;
		smokeend_count = smokecount + smoke;

		if(smokeend_count <= level.back2uo_smoke_allow)
		{
			smokegrenadetype = self back2uo\_back2uo_tools::back2uo_getgranade_type("smoke");

			self giveWeapon(smokegrenadetype);
			self setWeaponClipAmmo(smokegrenadetype, smokeend_count);
			rank_extras_b++;
		}
	}

	// Message if any grenade was given.
	if(level.back2uo_rankingmsg == 1 && (rank_extras_b == 1 || rank_extras_b == 2)) self iprintln(&"BACK2UOMOD_RANKING_GRA");

	// Binoculars are taken away from the configured rank on.
	if(level.back2uo_binocular_allow)
	{
		if(level.back2uo_binocular_onrank <= ranking_lv)
		{
			self takeWeapon("binoculars_mp");
		}
	}

	// Artillery strike from the configured rank on, once per rank.
	if(game["back2uo_artilleryfx_enable"])
	{
		if(level.back2uo_artillery_onrank <= ranking_lv)
		{
			art_rank_check = thread back2uo_ranking_artillery_check(ranking_lv);

			// Note: a function called with 'thread' does not return a value, so art_rank_check is undefined here.
			if(art_rank_check == 1) return;

			if(isdefined(self.back2uo_art_rank)) return;
			self.back2uo_art_rank = true;

			// Player still has an unused strike.
			if(isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true) return;

			thread back2uo\_back2uo_warfx::back2uo_artilleryfx_control();
		}
	}
}

/*
=============
back2uo_ranking_artillery_check

Remembers in self.pers that the artillery reward for this rank was handed out.
Called on: self = player
Params: ranking_lv - rank to check
Returns: 1 if the reward was already given for this rank, else 0
=============
*/
back2uo_ranking_artillery_check(ranking_lv)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking Artillery Check", "Run");

	ausgabe = 0;

	if(isdefined(self.pers["art_rang_" + ranking_lv])) ausgabe = 1;
	self.pers["art_rang_" + ranking_lv] = true;

	return ausgabe;
}

/*
=============
back2uo_ranking_clear

Destroys the rank icon and resets the scoreboard status icon to the dead icon.
Called on: self = player
=============
*/
back2uo_ranking_clear()
{
	if(!game["back2uo_ranking_enable"]) return;

	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Clear");

	if(isDefined(self.hud_ranking_lv))
		self.hud_ranking_lv destroy();

	if(level.back2uo_rankingscorelist == 1) self.statusicon = "hud_status_dead";
}
