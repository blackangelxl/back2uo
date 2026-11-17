/*
	Back2Uo - Fernglas-Sperre pro Spieler (zk_libcod "extra"-Modul)

	Einbau: server/Dockerfile baut libcod aus cod2-server (rutkowski-tomasz) neu, kopiert diese
	Datei nach code/extra/ und trägt die beiden Methoden per server/back2uo_methods.patch in die
	methods[]-Tabelle von nl_functions.cpp ein (Prototypen in nl.hpp). doit.sh kompiliert alle
	.cpp aus code/extra/ automatisch mit.

	Neue Script-Methoden (self = Spieler):
	    self setBinocularsBlocked(<bool>)   sperrt (1) oder erlaubt (0) das Fernglas
	    self isBinocularsBlocked()           liefert 1, wenn gesperrt

	Neuer Notify:
	    self waittill("binoculars_blocked");  kommt einmal pro Tastendruck, solange gesperrt

	Funktionsweise: Vor jedem Bewegungsbefehl (SV_ClientThink) wird bei gesperrten Spielern das
	Fernglas-Bit (KEY_MASK_BINOCULARS, 0x4000) aus usercmd_t.buttons entfernt. Die Engine sieht die
	Taste dann nie gedrückt und hebt das Fernglas nicht an. Ein bereits gehobenes Fernglas wird
	wie beim Loslassen der Taste gesenkt. takeWeapon("binoculars_mp") wirkt in CoD2 nicht auf die
	Taste, darum geht es nur hier.

	Die Sperre wird bei jedem Connect (auch nach Mapwechsel) und beim Disconnect zurückgesetzt.

	Belegt die schwachen Hooks extra_SV_ClientThink_Before, extra_Scr_PlayerConnect_After,
	extra_SV_DropClient_Before und extra_GScr_LoadGameTypeScript_After aus gsc_extra.hpp
	(Scr_GetExtraMethod gehört nl_functions.cpp). Die Hooks sind weak deklariert: belegt ein
	anderes Modul in code/extra/ denselben Hook, gibt es keinen Linker-Fehler, sondern der Linker
	nimmt stillschweigend eine Definition. Dann beide in einer Datei zusammenführen.
*/

#include "../gsc.hpp"

#if COMPILE_PLAYER == 1

static qboolean b2u_binoBlocked[MAX_CLIENTS];
static qboolean b2u_binoPressed[MAX_CLIENTS];
static unsigned short b2u_str_binoculars_blocked = 0;

static void b2u_bino_reset(int id)
{
	if ( id < 0 || id >= MAX_CLIENTS )
		return;

	b2u_binoBlocked[id] = qfalse;
	b2u_binoPressed[id] = qfalse;
}

/* --- Script-Methoden --- */

void gsc_back2uo_setbinocularsblocked(scr_entref_t ref)
{
	int id = ref.entnum;
	int blocked;

	if ( !stackGetParams("i", &blocked) )
	{
		stackError("setBinocularsBlocked() argument is undefined or has a wrong type");
		stackPushUndefined();
		return;
	}

	if ( id >= MAX_CLIENTS )
	{
		stackError("setBinocularsBlocked() entity %i is not a player", id);
		stackPushUndefined();
		return;
	}

	b2u_binoBlocked[id] = blocked ? qtrue : qfalse;
	if ( !blocked )
		b2u_binoPressed[id] = qfalse;

	stackPushBool(qtrue);
}

void gsc_back2uo_isbinocularsblocked(scr_entref_t ref)
{
	int id = ref.entnum;

	if ( id >= MAX_CLIENTS )
	{
		stackError("isBinocularsBlocked() entity %i is not a player", id);
		stackPushUndefined();
		return;
	}

	stackPushBool(b2u_binoBlocked[id]);
}

/* --- Hooks --- */

void extra_GScr_LoadGameTypeScript_After()
{
	// Notify-String pro Level neu anlegen (Stringtabelle wird beim Levelwechsel geleert)
	b2u_str_binoculars_blocked = GScr_AllocString("binoculars_blocked");
}

void extra_Scr_PlayerConnect_After(gentity_t *ent)
{
	b2u_bino_reset(ent->s.number);
}

void extra_SV_DropClient_Before(client_t *drop, const char *reason)
{
	b2u_bino_reset(drop - svs.clients);
}

void extra_SV_ClientThink_Before(client_t *client, usercmd_t *ucmd)
{
	int id = client - svs.clients;

	if ( id < 0 || id >= MAX_CLIENTS || !b2u_binoBlocked[id] )
		return;

	qboolean pressed = ( ucmd->buttons & KEY_MASK_BINOCULARS ) ? qtrue : qfalse;

	if ( pressed )
	{
		ucmd->buttons &= ~KEY_MASK_BINOCULARS;

		// Einmal pro Tastendruck melden, damit GSC einen Hinweis zeigen kann
		if ( !b2u_binoPressed[id] && b2u_str_binoculars_blocked )
		{
			gentity_t *ent = &g_entities[id];

			if ( ent->client )
				Scr_Notify(ent, b2u_str_binoculars_blocked, 0);
		}
	}

	b2u_binoPressed[id] = pressed;
}

#endif
