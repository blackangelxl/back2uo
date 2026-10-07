/*
	Back2Uo v2.1 - gametype object filter

	Stock CoD2 script, unchanged by Back2Uo. Called from each gametype's
	Callback_StartGameType() to remove map entities that belong to other gametypes.
*/

/*
=============
main

Deletes every map entity whose script_gameobjectname is not in the allowed list,
e.g. removes the CTF flags when playing TDM. Entities without a script_gameobjectname are kept.
Params: allowed - array of gameobject names the current gametype uses (e.g. "ctf", "dm")
=============
*/
main(allowed)
{
	entitytypes = getentarray();
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].script_gameobjectname))
		{
			dodelete = true;

			for(j = 0; j < allowed.size; j++)
			{
				if(entitytypes[i].script_gameobjectname == allowed[j])
				{
					dodelete = false;
					break;
				}
			}

			if(dodelete)
			{
				// Disabled: debug print of each deleted entity's classname
				//println("DELETED: ", entitytypes[i].classname);
				entitytypes[i] delete();
			}
		}
	}
}
