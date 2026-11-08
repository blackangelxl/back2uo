/*
	Back2Uo v2.1 - Rank icon, rank up/down handling, rank loadout (ammo, grenades) and artillery.

	Part of the per-player HUD (split from the former _back2uo_hudfx.gsc). Called from
	_back2uo_player.gsc on spawn, damage and death.
	Update threads end on level "back2uo_killthreads" and player "back2uo_killplayerthreads",
	"disconnect" or "killed_player".

	Like in United Offensive the rank sets the loadout of the next life: on every spawn the
	player gets the magazines and grenades of his current rank (back2uo_rank<n>_* cvars).
	A rank change during a life only changes icon, sound and message; the new loadout comes
	with the next spawn. Artillery is still granted right on reaching the rank.
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
		self.hud_ranking_lv.x = 117;
		self.hud_ranking_lv.y = 390;
		self.hud_ranking_lv.horzAlign = "left";
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
back2uo_ranking_getrank

Maps a score to a rank: 1 to 5, plus extra ranks every level.back2uo_ranking_lvextra
points above level 5 when back2uo_rankextra_active is set.
Params: score - player score
Returns: rank number (1 or higher)
=============
*/
back2uo_ranking_getrank(score)
{
	if(score >= level.back2uo_ranking_level5)
	{
		rank = 5;
		if(level.back2uo_rankextra_active == 1) rank += int((score - level.back2uo_ranking_level5) / level.back2uo_ranking_lvextra);
		return rank;
	}

	if(score >= level.back2uo_ranking_level4) return 4;
	if(score >= level.back2uo_ranking_level3) return 3;
	if(score >= level.back2uo_ranking_level2) return 2;

	return 1;
}

/*
=============
back2uo_ranking_update

Runs once per life (threaded on spawn). Sets the rank from the score, gives the loadout
of that rank, then every 0.5 seconds follows the score: on a rank change it plays a sound,
prints a message, pulses the rank icon and (rank up) grants artillery.
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

	// Rank at spawn: the loadout of this life. Runs before the first wait, so it is done
	// before the gametype stores the spawn ammo (back2uo_weaponspawn_*slotammo).
	self.pers["back2uo_ranking"] = back2uo_ranking_getrank(self.score);
	self.pers["back2uo_ranking_new"] = self.pers["back2uo_ranking"];

	back2uo_ranking_level(self.pers["back2uo_ranking"]);
	back2uo_ranking_loadout(self.pers["back2uo_ranking"]);

	// Player still owns an unused artillery strike (from an earlier life): restart the binocular target selection.
	if(game["back2uo_artilleryfx_enable"] && isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("ranking", "artrestore", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + self.pers["back2uo_ranking"]);

		thread back2uo\warfx\_back2uo_artillery::back2uo_artilleryfx_binowaituse();
	}

	// Rank may have been reached while dead (e.g. a kill by a grenade thrown before dying).
	back2uo_ranking_artillery(self.pers["back2uo_ranking"]);

	for(;;)
	{
		// Remember the previous rank to detect rank changes below.
		player_score = self.score;
		self.pers["back2uo_ranking_new"] = self.pers["back2uo_ranking"];
		self.pers["back2uo_ranking"] = back2uo_ranking_getrank(player_score);

		back2uo_ranking_level(self.pers["back2uo_ranking"]);

		// Teammates see the rank as head icon (team gametypes only).
		if(isdefined(self.headicon) && level.back2uo_teamrankheadicons == 1 && getCvar("g_gametype") != "dm")
		{
			self.headicon = self.pers["back2uo_head_ranking_pic"];
		}

		// Rank changed
		if(self.pers["back2uo_ranking"] != self.pers["back2uo_ranking_new"])
		{
			rank_up = (self.pers["back2uo_ranking"] > self.pers["back2uo_ranking_new"]);

			if(back2uo\_back2uo_cvars::back2uo_logactive())
			{
				rank_event = "rankdown";
				if(rank_up) rank_event = "rankup";

				back2uo\_back2uo_cvars::back2uo_logevent("ranking", rank_event, back2uo\_back2uo_cvars::back2uo_logplayer(self) + " old=" + self.pers["back2uo_ranking_new"] + " rank=" + self.pers["back2uo_ranking"] + " score=" + player_score + " deaths=" + self.deaths);
			}

			self.back2uo_art_rank = undefined;

			// Rank up: artillery right away; ammo and grenades of the new rank come with the next spawn.
			if(rank_up) back2uo_ranking_artillery(self.pers["back2uo_ranking"]);

			if(self.pers["back2uo_ranking"] <= 5)
			{
				if(rank_up)
				{
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_up", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_UP");
				}
				else
				{
					if(level.back2uo_rankingsound == 1) back2uo\_back2uo_sounds::back2uo_soundonplayer("ranking_down", self);

					if(level.back2uo_rankingmsg == 1) self iprintln(&"BACK2UOMOD_RANKING_DOWN");
				}

				// Pulse the rank icon: grow, shrink, back to normal.
				if(isdefined(self.hud_ranking_lv))
				{
					if(level.back2uo_rankingscorelist == 1) self.statusicon = self.pers["back2uo_score_ranking_pic"];

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = 115;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.2;
					self.hud_ranking_lv.x = 113;
					self.hud_ranking_lv.y = 386;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 32, 32);

					wait 0.2;

					self.hud_ranking_lv.alpha = 0.4;
					self.hud_ranking_lv.x = 115;
					self.hud_ranking_lv.y = 388;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 28, 28);

					wait 0.1;

					self.hud_ranking_lv.alpha = 0.6;
					self.hud_ranking_lv.x = 117;
					self.hud_ranking_lv.y = 390;
					self.hud_ranking_lv setShader(self.back2uo_ranking_pic, 24, 24);
				}
			}
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

Sets the rank icons (HUD, scoreboard, head icon) for the given rank. Ranks above 5 use
the level 5 icons.
Called on: self = player
Params: ranking_lv - rank number
=============
*/
back2uo_ranking_level(ranking_lv)
{
	// Icons only exist up to level 5.
	if(ranking_lv > 5) ranking_lv = 5;

	self.back2uo_ranking_pic = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_score_ranking_pic"] = "gfx/custom/back2uo_ranking_lv" + ranking_lv + ".tga";
	self.pers["back2uo_head_ranking_pic"] = "gfx/hud/hud@back2uo_ranking_head_lv" + ranking_lv + ".tga";

	if(ranking_lv == 1) self.pers["back2uo_artillery_go"] = false;
}

/*
=============
back2uo_ranking_loadout

Gives the loadout of the rank (United Offensive style), called once on spawn after the
gametype has handed out the weapons: magazines of the primary weapon and the pistol
(including the loaded one) and frag / smoke grenades of the own nation. The grenade counts
are cut to back2uo_frag_allow / back2uo_smoke_allow when the grenade setup
(back2uo_smoke_grana_active) is on. Ranks above 5 get the rank 5 loadout.
Called on: self = player
Params: ranking_lv - current rank
=============
*/
back2uo_ranking_loadout(ranking_lv)
{
	back2uo\_back2uo_cvars::back2uo_logprint("Hud Ranking", "Loadout");

	if(ranking_lv > 5) ranking_lv = 5;
	if(ranking_lv < 1) ranking_lv = 1;

	pri_mags = level.back2uo_rank_primags[ranking_lv];
	sek_mags = level.back2uo_rank_pistolmags[ranking_lv];
	frag = level.back2uo_rank_frags[ranking_lv];
	smoke = level.back2uo_rank_smokes[ranking_lv];

	pri_ammo = back2uo_ranking_setmags("primary", pri_mags);
	sek_ammo = back2uo_ranking_setmags("primaryb", sek_mags);

	// Frag grenades
	if(!getcvarint("scr_allow_fraggrenades")) frag = 0;
	if(level.back2uo_smoke_grana_active && frag > level.back2uo_granaten_allow) frag = level.back2uo_granaten_allow;

	granadetype = self back2uo\tools\_back2uo_names::back2uo_getgranade_type("granade");
	if(frag > 0)
	{
		self giveWeapon(granadetype);
		self setWeaponClipAmmo(granadetype, frag);
		self switchtooffhand(granadetype);
	}
	else
	{
		self takeWeapon(granadetype);
	}

	// Smoke grenades
	if(!getcvarint("scr_allow_smokegrenades")) smoke = 0;
	if(level.back2uo_smoke_grana_active && smoke > level.back2uo_smoke_allow) smoke = level.back2uo_smoke_allow;

	smokegrenadetype = self back2uo\tools\_back2uo_names::back2uo_getgranade_type("smoke");
	if(smoke > 0)
	{
		self giveWeapon(smokegrenadetype);
		self setWeaponClipAmmo(smokegrenadetype, smoke);
	}
	else
	{
		self takeWeapon(smokegrenadetype);
	}

	back2uo\_back2uo_cvars::back2uo_logevent("ranking", "loadout", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + ranking_lv + " score=" + self.score + " primags=" + pri_mags + " pri=" + pri_ammo + " sekmags=" + sek_mags + " sek=" + sek_ammo + " frag=" + frag + " smoke=" + smoke);
}

/*
=============
back2uo_ranking_setmags

Sets the ammo of a weapon slot to a number of magazines: one loaded plus (mags - 1) in
the reserve. Uses the clip ammo right after the spawn as magazine size (the gametype
fills the clip). The engine clamps the reserve to the weapon's maximum.
Called on: self = player
Params: slot - "primary" or "primaryb"
		mags - magazines including the loaded one (0 = empty weapon)
Returns: total ammo (clip + reserve) after the change, 0 for an empty slot
=============
*/
back2uo_ranking_setmags(slot, mags)
{
	if(self getWeaponSlotWeapon(slot) == "none") return 0;

	clipsize = self getWeaponSlotClipAmmo(slot);
	if(clipsize <= 0) return 0;

	if(mags <= 0)
	{
		self setWeaponSlotClipAmmo(slot, 0);
		self setWeaponSlotAmmo(slot, 0);
		return 0;
	}

	self setWeaponSlotAmmo(slot, (mags - 1) * clipsize);

	return self getWeaponSlotClipAmmo(slot) + self getWeaponSlotAmmo(slot);
}

/*
=============
back2uo_ranking_artillery

Grants an artillery strike from the configured rank on, once per rank and map
(back2uo_artillery_onrang 0 = none). Nothing if the player still owns an unused strike.
Called on: self = player
Params: ranking_lv - reached rank
=============
*/
back2uo_ranking_artillery(ranking_lv)
{
	if(!game["back2uo_artilleryfx_enable"]) return;
	if(level.back2uo_artillery_onrank <= 0 || level.back2uo_artillery_onrank > ranking_lv) return;

	// Called directly (no thread), so the return value is available.
	art_rank_check = back2uo_ranking_artillery_check(ranking_lv);

	if(art_rank_check == 1)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("ranking", "artskip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + ranking_lv + " reason=given");
		return;
	}

	if(isdefined(self.back2uo_art_rank))
	{
		back2uo\_back2uo_cvars::back2uo_logevent("ranking", "artskip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + ranking_lv + " reason=rankflag");
		return;
	}
	self.back2uo_art_rank = true;

	// Player still has an unused strike.
	if(isdefined(self.pers["artillery_save"]) && self.pers["artillery_save"] == true)
	{
		back2uo\_back2uo_cvars::back2uo_logevent("ranking", "artskip", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + ranking_lv + " reason=unused");
		return;
	}

	back2uo\_back2uo_cvars::back2uo_logevent("ranking", "artgrant", back2uo\_back2uo_cvars::back2uo_logplayer(self) + " rank=" + ranking_lv + " score=" + self.score);

	thread back2uo\warfx\_back2uo_artillery::back2uo_artilleryfx_control();
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
