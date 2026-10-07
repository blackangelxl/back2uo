/*
	Back2Uo v2.1 - multiplayer character helper

	Stock CoD2 script, unchanged by Back2Uo. Used by the generated character
	scripts (xmodel character definitions) to pick and attach a random head model.
*/

/*
=============
attachFromArray

Picks a random head model from the given list and attaches it to the player model.
Called on: player / character entity
Params: a - array of head model names
=============
*/
attachFromArray(a)
{
	self.player_headmodel = codescripts\character::randomElement(a);
	self attach(self.player_headmodel, "", true);
}
