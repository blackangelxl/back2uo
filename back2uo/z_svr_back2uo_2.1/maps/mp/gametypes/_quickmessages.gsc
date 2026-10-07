/*
	Back2Uo v2.1 - Quick chat messages (voice command menus)

	Plays the nationality-specific voice line and prints the matching localized chat text
	when a player picks an entry from one of the quick message menus.
	init() is threaded by every gametype script; the quick*() handlers are called from
	_menus.gsc when a "menuresponse" for the matching menu arrives.
	Uses game["allies"] / game["axis"] for the voice set, level.QuickMessageToAll (dm) for
	all-chat vs team-chat and the cvar back2uo_talkingicon (game["back2uo_talkingicon"]).
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
init

Registers and precaches the four quick message menus and the "talking" head icon.
=============
*/
init()
{
	game["menu_quickcommands"] = "quickcommands";
	game["menu_quickstatements"] = "quickstatements";
	game["menu_quickresponses"] = "quickresponses";
	// Back2Uo: extra "taunts" menu (grenade / smoke warnings, support requests, thanks).
	game["menu_quicktaunts"] = "quicktaunts";

	precacheMenu(game["menu_quickcommands"]);
	precacheMenu(game["menu_quickstatements"]);
	precacheMenu(game["menu_quickresponses"]);
	precacheMenu(game["menu_quicktaunts"]);
	precacheHeadIcon("talkingicon");
}

/*
=============
quickcommands

Handles the "quickcommands" menu (follow me, move in, fall back, ...). Picks the voice alias
for the player's nationality and broadcasts it, then blocks further quick messages for 2 seconds.
The commented-out //saytext lines are the stock English plaintext of each localized string.
Called on: player
Params: response - menu entry as string, "1" to "8"
=============
*/
quickcommands(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				//saytext = "Follow Me!";
				break;

			case "2":
				soundalias = "US_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				//saytext = "Move in!";
				break;

			case "3":
				soundalias = "US_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				//saytext = "Fall back!";
				break;

			case "4":
				soundalias = "US_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				//saytext = "Suppressing fire!";
				break;

			case "5":
				soundalias = "US_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				//saytext = "Attack left flank!";
				break;

			case "6":
				soundalias = "US_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				//saytext = "Attack right flank!";
				break;

			case "7":
				soundalias = "US_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				//saytext = "Hold this position!";
				break;

			default:
				assert(response == "8");
				soundalias = "US_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				//saytext = "Regroup!";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				//saytext = "Follow Me!";
				break;

			case "2":
				soundalias = "UK_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				//saytext = "Move in!";
				break;

			case "3":
				soundalias = "UK_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				//saytext = "Fall back!";
				break;

			case "4":
				soundalias = "UK_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				//saytext = "Suppressing fire!";
				break;

			case "5":
				soundalias = "UK_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				//saytext = "Attack left flank!";
				break;

			case "6":
				soundalias = "UK_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				//saytext = "Attack right flank!";
				break;

			case "7":
				soundalias = "UK_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				//saytext = "Hold this position!";
				break;

			default:
				assert(response == "8");
				soundalias = "UK_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				//saytext = "Regroup!";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				//saytext = "Follow Me!";
				break;

			case "2":
				soundalias = "RU_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				//saytext = "Move in!";
				break;

			case "3":
				soundalias = "RU_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				//saytext = "Fall back!";
				break;

			case "4":
				soundalias = "RU_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				//saytext = "Suppressing fire!";
				break;

			case "5":
				soundalias = "RU_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				//saytext = "Attack left flank!";
				break;

			case "6":
				soundalias = "RU_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				//saytext = "Attack right flank!";
				break;

			case "7":
				soundalias = "RU_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				//saytext = "Hold this position!";
				break;

			default:
				assert(response == "8");
				soundalias = "RU_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				//saytext = "Regroup!";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				//saytext = "Follow Me!";
				break;

			case "2":
				soundalias = "GE_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				//saytext = "Move in!";
				break;

			case "3":
				soundalias = "GE_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				//saytext = "Fall back!";
				break;

			case "4":
				soundalias = "GE_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				//saytext = "Suppressing fire!";
				break;

			case "5":
				soundalias = "GE_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				//saytext = "Attack left flank!";
				break;

			case "6":
				soundalias = "GE_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				//saytext = "Attack right flank!";
				break;

			case "7":
				soundalias = "GE_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				//saytext = "Hold this position!";
				break;

			default:
				assert(response == "8");
				soundalias = "GE_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				//saytext = "Regroup!";
				break;
			}
			break;
		}
	}

	self saveHeadIcon();
	self doQuickMessage(soundalias, saytext);

	wait 2;
	self.spamdelay = undefined;
	self restoreHeadIcon();
}

/*
=============
quickstatements

Handles the "quickstatements" menu (enemy spotted, grenade, sniper, ...). Same flow as quickcommands.
The commented-out //saytext lines are the stock English plaintext of each localized string.
Called on: player
Params: response - menu entry as string, "1" to "8"
=============
*/
quickstatements(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				//saytext = "Enemy spotted!";
				break;

			case "2":
				soundalias = "US_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				//saytext = "Enemy down!";
				break;

			case "3":
				soundalias = "US_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				//saytext = "I'm in position.";
				break;

			case "4":
				soundalias = "US_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				//saytext = "Area secure!";
				break;

			case "5":
				soundalias = "US_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				//saytext = "Grenade!";
				break;

			case "6":
				soundalias = "US_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				//saytext = "Sniper!";
				break;

			case "7":
				soundalias = "US_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				//saytext = "Need reinforcements!";
				break;

			default:
				assert(response == "8");
				soundalias = "US_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				//saytext = "Hold your fire!";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				//saytext = "Enemy spotted!";
				break;

			case "2":
				soundalias = "UK_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				//saytext = "Enemy down!";
				break;

			case "3":
				soundalias = "UK_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				//saytext = "I'm in position.";
				break;

			case "4":
				soundalias = "UK_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				//saytext = "Area secure!";
				break;

			case "5":
				soundalias = "UK_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				//saytext = "Grenade!";
				break;

			case "6":
				soundalias = "UK_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				//saytext = "Sniper!";
				break;

			case "7":
				soundalias = "UK_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				//saytext = "Need reinforcements!";
				break;

			default:
				assert(response == "8");
				soundalias = "UK_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				//saytext = "Hold your fire!";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				//saytext = "Enemy spotted!";
				break;

			case "2":
				soundalias = "RU_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				//saytext = "Enemy down!";
				break;

			case "3":
				soundalias = "RU_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				//saytext = "I'm in position.";
				break;

			case "4":
				soundalias = "RU_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				//saytext = "Area secure!";
				break;

			case "5":
				soundalias = "RU_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				//saytext = "Grenade!";
				break;

			case "6":
				soundalias = "RU_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				//saytext = "Sniper!";
				break;

			case "7":
				soundalias = "RU_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				//saytext = "Need reinforcements!";
				break;

			default:
				assert(response == "8");
				soundalias = "RU_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				//saytext = "Hold your fire!";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				//saytext = "Enemy spotted!";
				break;

			case "2":
				soundalias = "GE_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				//saytext = "Enemy down!";
				break;

			case "3":
				soundalias = "GE_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				//saytext = "I'm in position.";
				break;

			case "4":
				soundalias = "GE_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				//saytext = "Area secure!";
				break;

			case "5":
				soundalias = "GE_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				//saytext = "Grenade!";
				break;

			case "6":
				soundalias = "GE_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				//saytext = "Sniper!";
				break;

			case "7":
				soundalias = "GE_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				//saytext = "Need reinforcements!";
				break;

			default:
				assert(response == "8");
				soundalias = "GE_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				//saytext = "Hold your fire!";
				break;
			}
			break;
		}
	}

	self saveHeadIcon();
	self doQuickMessage(soundalias, saytext);

	wait 2;
	self.spamdelay = undefined;
	self restoreHeadIcon();
}

/*
=============
quickresponses

Handles the "quickresponses" menu (yes sir, no sir, sorry, ...). Same flow as quickcommands.
The commented-out //saytext lines are the stock English plaintext of each localized string.
Called on: player
Params: response - menu entry as string, "1" to "7"
=============
*/
quickresponses(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				//saytext = "Yes Sir!";
				break;

			case "2":
				soundalias = "US_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				//saytext = "No Sir!";
				break;

			case "3":
				soundalias = "US_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				//saytext = "On my way.";
				break;

			case "4":
				soundalias = "US_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				//saytext = "Sorry.";
				break;

			case "5":
				soundalias = "US_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				//saytext = "Great shot!";
				break;

			case "6":
				soundalias = "US_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				//saytext = "Took long enough!";
				break;

			default:
				assert(response == "7");
				soundalias = "US_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				//saytext = "Are you crazy?";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				//saytext = "Yes Sir!";
				break;

			case "2":
				soundalias = "UK_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				//saytext = "No Sir!";
				break;

			case "3":
				soundalias = "UK_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				//saytext = "On my way.";
				break;

			case "4":
				soundalias = "UK_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				//saytext = "Sorry.";
				break;

			case "5":
				soundalias = "UK_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				//saytext = "Great shot!";
				break;

			case "6":
				soundalias = "UK_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				//saytext = "Took long enough!";
				break;

			default:
				assert(response == "7");
				soundalias = "UK_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				//saytext = "Are you crazy?";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				//saytext = "Yes Sir!";
				break;

			case "2":
				soundalias = "RU_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				//saytext = "No Sir!";
				break;

			case "3":
				soundalias = "RU_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				//saytext = "On my way.";
				break;

			case "4":
				soundalias = "RU_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				//saytext = "Sorry.";
				break;

			case "5":
				soundalias = "RU_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				//saytext = "Great shot!";
				break;

			case "6":
				soundalias = "RU_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				//saytext = "Took long enough!";
				break;

			default:
				assert(response == "7");
				soundalias = "RU_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				//saytext = "Are you crazy?";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				//saytext = "Yes Sir!";
				break;

			case "2":
				soundalias = "GE_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				//saytext = "No Sir!";
				break;

			case "3":
				soundalias = "GE_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				//saytext = "On my way.";
				break;

			case "4":
				soundalias = "GE_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				//saytext = "Sorry.";
				break;

			case "5":
				soundalias = "GE_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				//saytext = "Great shot!";
				break;

			case "6":
				soundalias = "GE_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				//saytext = "Took long enough!";
				break;

			default:
				assert(response == "7");
				soundalias = "GE_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				//saytext = "Are you crazy?";
				break;
			}
			break;
		}
	}

	self saveHeadIcon();
	self doQuickMessage(soundalias, saytext);

	wait 2;
	self.spamdelay = undefined;
	self restoreHeadIcon();
}

/*
=============
quicktaunts

Back2Uo: handles the mod's "quicktaunts" menu (throwing grenade / smoke, incoming grenade /
smoke, Panzerfaust / artillery support request, thanks). Uses the mod's own sound aliases and
QUICKMESSAGE_BACK2UO_* strings. The commented-out //saytext lines are the English meaning of
the plaintext the mod used before the strings were localized.
Called on: player
Params: response - menu entry as string, "1" to "8" ("9" falls into an empty default)
=============
*/
quicktaunts(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_attack_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADE2";
				//saytext = "Attention! Throwing a grenade!";
				break;

			case "2":
				soundalias = "US_incom_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADEISCOMMING2";
				//saytext = "Watch out! Enemy grenade!";
				break;

			case "3":
				soundalias = "US_attack_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKE2";
				//saytext = "Attention! Throwing a smoke grenade!";
				break;

			case "4":
				soundalias = "US_incom_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKEDUST2";
				//saytext = "Watch out! Smoke!";
				break;

			case "5":
				soundalias = "US_attack_panzerfaust";
				saytext = &"QUICKMESSAGE_BACK2UO_PANZERFAUSTSUPPORT2";
				//saytext = "Need Panzerfaust support!";
				break;

			case "6":
				soundalias = "US_attack_artillery";
				saytext = &"QUICKMESSAGE_BACK2UO_ARTILLERYSUPPORT2";
				//saytext = "Need artillery support!";
				break;

			case "7":
				soundalias = "US_thanks1";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKSYOU2";
				//saytext = "Thank you very much!";
				break;

			case "8":
				soundalias = "US_thanks2";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKS2";
				//saytext = "Thanks!";
				break;

			default:
				assert(response == "9");
				soundalias = " ";
				saytext = " ";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_attack_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADE2";
				//saytext = "Attention! Throwing a grenade!";
				break;

			case "2":
				soundalias = "UK_incom_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADEISCOMMING2";
				//saytext = "Watch out! Enemy grenade!";
				break;

			case "3":
				soundalias = "UK_attack_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKE2";
				//saytext = "Attention! Throwing a smoke grenade!";
				break;

			case "4":
				soundalias = "UK_incom_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKEDUST2";
				//saytext = "Watch out! Smoke!";
				break;

			case "5":
				soundalias = "UK_attack_panzerfaust";
				saytext = &"QUICKMESSAGE_BACK2UO_PANZERFAUSTSUPPORT2";
				//saytext = "Need Panzerfaust support!";
				break;

			case "6":
				soundalias = "UK_attack_artillery";
				saytext = &"QUICKMESSAGE_BACK2UO_ARTILLERYSUPPORT2";
				//saytext = "Need artillery support!";
				break;

			case "7":
				soundalias = "UK_thanks1";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKSYOU2";
				//saytext = "Thank you very much!";
				break;

			case "8":
				soundalias = "UK_thanks2";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKS2";
				//saytext = "Thanks!";
				break;

			default:
				assert(response == "9");
				soundalias = " ";
				saytext = " ";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_attack_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADE2";
				//saytext = "Attention! Throwing a grenade!";
				break;

			case "2":
				soundalias = "RU_incom_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADEISCOMMING2";
				//saytext = "Watch out! Enemy grenade!";
				break;

			case "3":
				soundalias = "RU_attack_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKE2";
				//saytext = "Attention! Throwing a smoke grenade!";
				break;

			case "4":
				soundalias = "RU_incom_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKEDUST2";
				//saytext = "Watch out! Smoke!";
				break;

			case "5":
				soundalias = "RU_attack_panzerfaust";
				saytext = &"QUICKMESSAGE_BACK2UO_PANZERFAUSTSUPPORT2";
				//saytext = "Need Panzerfaust support!";
				break;

			case "6":
				soundalias = "RU_attack_artillery";
				saytext = &"QUICKMESSAGE_BACK2UO_ARTILLERYSUPPORT2";
				//saytext = "Need artillery support!";
				break;

			case "7":
				soundalias = "RU_thanks1";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKSYOU2";
				//saytext = "Thank you very much!";
				break;

			case "8":
				soundalias = "RU_thanks2";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKS2";
				//saytext = "Thanks!";
				break;

			default:
				assert(response == "9");
				soundalias = " ";
				saytext = " ";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_attack_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADE2";
				//saytext = "Attention! Throwing a grenade!";
				break;

			case "2":
				soundalias = "GE_incom_grenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONGRANADEISCOMMING2";
				//saytext = "Watch out! Enemy grenade!";
				break;

			case "3":
				soundalias = "GE_attack_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKE2";
				//saytext = "Attention! Throwing a smoke grenade!";
				break;

			case "4":
				soundalias = "GE_incom_smokegrenade";
				saytext = &"QUICKMESSAGE_BACK2UO_ATTENTIONSMOKEDUST2";
				//saytext = "Watch out! Smoke!";
				break;

			case "5":
				soundalias = "GE_attack_panzerfaust";
				saytext = &"QUICKMESSAGE_BACK2UO_PANZERFAUSTSUPPORT2";
				//saytext = "Need Panzerfaust support!";
				break;

			case "6":
				soundalias = "GE_attack_artillery";
				saytext = &"QUICKMESSAGE_BACK2UO_ARTILLERYSUPPORT2";
				//saytext = "Need artillery support!";
				break;

			case "7":
				soundalias = "GE_thanks1";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKSYOU2";
				//saytext = "Thank you very much!";
				break;

			case "8":
				soundalias = "GE_thanks2";
				saytext = &"QUICKMESSAGE_BACK2UO_THANKS2";
				//saytext = "Thanks!";
				break;

			default:
				assert(response == "9");
				soundalias = " ";
				saytext = " ";
				break;
			}
			break;
		}
	}

	self saveHeadIcon();
	self doQuickMessage(soundalias, saytext);

	wait 2;
	self.spamdelay = undefined;
	self restoreHeadIcon();
}

/*
=============
doQuickMessage

Plays the voice alias on the player and prints the text in chat: to everyone when
level.QuickMessageToAll is set (dm), otherwise to the team plus a compass ping.
Only living players can send quick messages.
Called on: player
Params: soundalias - sound alias to play
		saytext - localized chat string
=============
*/
doQuickMessage(soundalias, saytext)
{
	if(self.sessionstate != "playing")
		return;

	if(isdefined(level.QuickMessageToAll) && level.QuickMessageToAll)
	{
		// Back2Uo: back2uo_talkingicon = 0 skips the "talkingicon" head icon above the speaker.
		if(!game["back2uo_talkingicon"])
		{
			self playSound(soundalias);
			self sayAll(saytext);
		}
		else
		{
			self.headiconteam = "none";
			self.headicon = "talkingicon";

			self playSound(soundalias);
			self sayAll(saytext);
		}
	}
	else
	{
		// Back2Uo: same talking icon switch for team chat; headiconteam is still set to the own team.
		if(!game["back2uo_talkingicon"])
		{
			if(self.sessionteam == "allies")
				self.headiconteam = "allies";
			else if(self.sessionteam == "axis")
				self.headiconteam = "axis";

			self playSound(soundalias);
			self sayTeam(saytext);
			self pingPlayer();
		}
		else
		{
			if(self.sessionteam == "allies")
				self.headiconteam = "allies";
			else if(self.sessionteam == "axis")
				self.headiconteam = "axis";

			self.headicon = "talkingicon";

			self playSound(soundalias);
			self sayTeam(saytext);
			self pingPlayer();
		}
	}
}

/*
=============
saveHeadIcon

Remembers the current head icon and its team so doQuickMessage can temporarily
replace it with the talking icon.
Called on: player
=============
*/
saveHeadIcon()
{
	if(isdefined(self.headicon))
		self.oldheadicon = self.headicon;

	if(isdefined(self.headiconteam))
		self.oldheadiconteam = self.headiconteam;
}

/*
=============
restoreHeadIcon

Restores the head icon saved by saveHeadIcon after the quick message delay.
Called on: player
=============
*/
restoreHeadIcon()
{
	if(isdefined(self.oldheadicon))
		self.headicon = self.oldheadicon;

	if(isdefined(self.oldheadiconteam))
		self.headiconteam = self.oldheadiconteam;
}
