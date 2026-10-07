/*
	Back2Uo v2.1 - engine callback setup

	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
	The engine calls the CodeCallback_* functions; each one forwards to the
	function pointer the gametype stored in level.callback* (e.g. ctf.gsc main()).
	SetupCallbacks() is called by every gametype's main() and also defines the level.iDFLAGS_* damage flags.
*/

//	Callback Setup
//	This script provides the hooks from code into script for the gametype callback functions.

//=============================================================================
// Code Callback functions

/*
=============
CodeCallback_StartGameType

Called by code after the level's main script function has run.
Runs the gametype's start function only once per level.
Called on: level
=============
*/
CodeCallback_StartGameType()
{
	// Back2Uo: stop all mod threads still running from the previous map/round (they 'level endon' this notify).
	level notify("back2uo_killthreads");

	// If the gametype has not beed started, run the startup
	if(!isDefined(level.gametypestarted) || !level.gametypestarted)
	{
		[[level.callbackStartGameType]]();

		level.gametypestarted = true; // so we know that the gametype has been started up
	}
}

/*
=============
CodeCallback_PlayerConnect

Called when a player begins connecting to the server.
Called again for every map change or tournement restart.

Return undefined if the client should be allowed, otherwise return
a string with the reason for denial.

Otherwise, the client will be sent the current gamestate
and will eventually get to ClientBegin.

firstTime will be qtrue the very first time a client connects
to the server machine, but qfalse on map changes and tournement
restarts.
Called on: player
=============
*/
CodeCallback_PlayerConnect()
{
	self endon("disconnect");
	[[level.callbackPlayerConnect]]();
}

/*
=============
CodeCallback_PlayerDisconnect

Called when a player drops from the server.
Will not be called between levels.
Sends the "disconnect" notify that ends all of this player's 'self endon("disconnect")' threads.
Called on: player (the one disconnecting)
=============
*/
CodeCallback_PlayerDisconnect()
{
	self notify("disconnect");
	[[level.callbackPlayerDisconnect]]();
}

/*
=============
CodeCallback_PlayerDamage

Called when a player has taken damage. Forwards to the gametype's damage callback.
Called on: player (the one that took damage)
Params: eInflictor - entity causing the damage (e.g. grenade), eAttacker - attacking entity,
	iDamage - damage amount, iDFlags - level.iDFLAGS_* bit flags, sMeansOfDeath - MOD_* string,
	sWeapon - weapon name, vPoint - hit position, vDir - damage direction, sHitLoc - hit location,
	timeOffset - time offset of the hit in ms
=============
*/
CodeCallback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	self endon("disconnect");
	[[level.callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

/*
=============
CodeCallback_PlayerKilled

Called when a player has been killed. Forwards to the gametype's killed callback.
Called on: player (the one that was killed)
Params: same as CodeCallback_PlayerDamage, plus deathAnimDuration - length of the death animation in ms
=============
*/
CodeCallback_PlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self endon("disconnect");
	[[level.callbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

//=============================================================================

/*
=============
SetupCallbacks

Setup any misc callbacks stuff like defines and default callbacks.
Called from each gametype's main() after it has set the level.callback* pointers.
Called on: level
=============
*/
SetupCallbacks()
{
	SetDefaultCallbacks();

	// Set defined for damage flags used in the playerDamage callback
	level.iDFLAGS_RADIUS			= 1;
	level.iDFLAGS_NO_ARMOR			= 2;
	level.iDFLAGS_NO_KNOCKBACK		= 4;
	level.iDFLAGS_NO_TEAM_PROTECTION	= 8;
	level.iDFLAGS_NO_PROTECTION		= 16;
	level.iDFLAGS_PASSTHRU			= 32;
}

/*
=============
SetDefaultCallbacks

Called from the gametype script to store off the default callback functions.
This allows the callbacks to be overridden by level script, but not lost.
Called on: level
=============
*/
SetDefaultCallbacks()
{
	level.default_CallbackStartGameType = level.callbackStartGameType;
	level.default_CallbackPlayerConnect = level.callbackPlayerConnect;
	level.default_CallbackPlayerDisconnect = level.callbackPlayerDisconnect;
	level.default_CallbackPlayerDamage = level.callbackPlayerDamage;
	level.default_CallbackPlayerKilled = level.callbackPlayerKilled;
}

/*
=============
AbortLevel

Called when a gametype is not supported by the map. Replaces all callbacks
with no-ops, switches g_gametype to "dm" and exits the level.
Called on: level
=============
*/
AbortLevel()
{
	println("Aborting level - gametype is not supported");

	level.callbackStartGameType = ::callbackVoid;
	level.callbackPlayerConnect = ::callbackVoid;
	level.callbackPlayerDisconnect = ::callbackVoid;
	level.callbackPlayerDamage = ::callbackVoid;
	level.callbackPlayerKilled = ::callbackVoid;

	setcvar("g_gametype", "dm");

	exitLevel(false);
}

/*
=============
callbackVoid

Empty callback used by AbortLevel() to disable all engine callbacks.
=============
*/
callbackVoid()
{
}
