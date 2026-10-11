/*
	Back2Uo v2.1 - Name lookups: grenade weapon names, localized gametype and map names,
	and the nation code of a player's side.
*/

/*
=============
back2uo_getgranade_type

Builds the weapon name of the frag or smoke grenade matching the player's team and
nationality. level.back2uo_specialgranade / level.back2uo_specialsmoke hold an optional
"_special<n>" suffix set in _weapons.gsc when the special grenade cvars are enabled.
Called on: player
Params: type - "granade" for frag grenades, "smoke" for smoke grenades
Returns: grenade weapon name, or "" for an unknown type
=============
*/
back2uo_getgranade_type(type)
{
	grenadetype = "";

	if(type == "granade")
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
			case "american":
				grenadetype = "frag_grenade_american_mp" + level.back2uo_specialgranade;
				break;

			case "british":
				grenadetype = "frag_grenade_british_mp" + level.back2uo_specialgranade;
				break;

			default:
				grenadetype = "frag_grenade_russian_mp" + level.back2uo_specialgranade;
				break;
			}
		}
		else
		{
			grenadetype = "frag_grenade_german_mp" + level.back2uo_specialgranade;
		}
	}

	if(type == "smoke")
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
			case "american":
				grenadetype = "smoke_grenade_american_mp" + level.back2uo_specialsmoke;
				break;

			case "british":
				grenadetype = "smoke_grenade_british_mp" + level.back2uo_specialsmoke;
				break;

			default:
				grenadetype = "smoke_grenade_russian_mp" + level.back2uo_specialsmoke;
				break;
			}
		}
		else
		{
			grenadetype = "smoke_grenade_german_mp" + level.back2uo_specialsmoke;
		}
	}

	return grenadetype;
}

/*
=============
back2uo_get_gametypename

Maps a gametype short name to its localized display string.
Params: gt - gametype short name ("dm", "tdm", "sd", "hq", "ctf")
Returns: localized string, or gt itself for unknown gametypes
=============
*/
back2uo_get_gametypename(gt)
{
	switch(gt)
	{
	case "dm":
		gtname = &"BACK2UOMOD_GT_DM";
		break;

	case "tdm":
		gtname = &"BACK2UOMOD_GT_TDM";
		break;

	case "sd":
		gtname = &"BACK2UOMOD_GT_SD";
		break;

	case "hq":
		gtname = &"BACK2UOMOD_GT_HQ";
		break;

	case "ctf":
		gtname = &"BACK2UOMOD_GT_CTF";
		break;

	default:
		gtname = gt;
		break;
	}

	return gtname;
}

/*
=============
back2uo_get_mapname

Maps a stock map name to its localized display string (used by the next map message).
Params: map - map BSP name, e.g. "mp_toujane"
Returns: localized string, or map itself for custom maps
=============
*/
back2uo_get_mapname(map)
{
	switch(map)
	{
	case "mp_farmhouse":
		mapname = &"BACK2UOMOD_MAP_MP_FARMHOUSE";
		break;

	case "mp_brecourt":
		mapname = &"BACK2UOMOD_MAP_MP_BRECOURT";
		break;

	case "mp_burgundy":
		mapname = &"BACK2UOMOD_MAP_MP_BURGUNDY";
		break;

	case "mp_trainstation":
		mapname = &"BACK2UOMOD_MAP_MP_TRAINSTATION";
		break;

	case "mp_carentan":
		mapname = &"BACK2UOMOD_MAP_MP_CARENTAN";
		break;

	case "mp_decoy":
		mapname = &"BACK2UOMOD_MAP_MP_DECOY";
		break;

	case "mp_leningrad":
		mapname = &"BACK2UOMOD_MAP_MP_LENINGRAD";
		break;

	case "mp_matmata":
		mapname = &"BACK2UOMOD_MAP_MP_MATMATA";
		break;

	case "mp_downtown":
		mapname = &"BACK2UOMOD_MAP_MP_DOWNTOWN";
		break;

	case "mp_dawnville":
		mapname = &"BACK2UOMOD_MAP_MP_DAWNVILLE";
		break;

	case "mp_railyard":
		mapname = &"BACK2UOMOD_MAP_MP_RAILYARD";
		break;

	case "mp_toujane":
		mapname = &"BACK2UOMOD_MAP_MP_TOUJANE";
		break;

	case "mp_breakout":
		mapname = &"BACK2UOMOD_MAP_MP_BREAKOUT";
		break;

	case "mp_harbor":
		mapname = &"BACK2UOMOD_MAP_MP_HARBOR";
		break;

	case "mp_rhine":
		mapname = &"BACK2UOMOD_MAP_MP_RHINE";
		break;

	default:
		mapname = map;
		break;
	}

	return mapname;
}

/*
=============
back2uo_teams

Returns the two-letter nation code of a player's side, used to pick
nation-specific sounds and effects.
Params: attacker - player whose team is checked
Returns: "US", "UK", "RU" for allies, "GE" for axis
=============
*/
back2uo_teams(attacker)
{
	level endon("back2uo_killthreads");
	self endon("back2uo_killplayerthreads");
	self endon("killed_player");
	self endon("disconnect");

	kurz = "GE";

	if(attacker.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			kurz = "US";
			break;

		case "british":
			kurz = "UK";
			break;

		case "russian":
			kurz = "RU";
			break;
		}
	}

	return kurz;
}
