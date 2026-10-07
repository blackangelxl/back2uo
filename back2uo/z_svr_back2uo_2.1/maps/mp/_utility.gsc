/*
	Back2Uo v2.1 - Shared multiplayer utility functions

	General helpers used by the gametypes, map scripts and the mod: trigger on/off,
	vector math, exploders (scripted destruction), player model save/restore,
	bomb plant position (getPlant) and misc array / ambient helpers.
	Back2Uo adds the S&D hat model (self.hatModel) to saveModel / loadModel.
	Stock CoD2 script, modified for Back2Uo. Mod changes are marked with 'Back2Uo:' comments.
*/

/*
=============
triggerOff

Disables a trigger by moving it 10000 units below its real origin.
The real origin is remembered in self.realOrigin for triggerOn.
Called on: trigger entity
=============
*/
triggerOff()
{
	if (!isdefined (self.realOrigin))
		self.realOrigin = self.origin;

	if (self.origin == self.realorigin)
		self.origin += (0, 0, -10000);
}

/*
=============
triggerOn

Re-enables a trigger moved away by triggerOff.
Called on: trigger entity
=============
*/
triggerOn()
{
	if (isDefined (self.realOrigin) )
		self.origin = self.realOrigin;
}

/*
=============
error

Prints a script error to the console. In developer builds it also forces an assert
unless the cvar "debug" is "1".
Params: msg - error text
=============
*/
error(msg)
{
	println("^c*ERROR* ", msg);
	wait .05;	// waitframe
/#
	if (getcvar("debug") != "1")
		assertmsg("This is a forced error - attach the log file");
#/
}

/*
=============
vectorScale

Multiplies each component of a vector by a scalar.
Params: vec - vector
		scale - factor
Returns: the scaled vector
=============
*/
vectorScale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

/*
=============
add_to_array

Appends an entity to an array, creating the array if needed.
Params: array - array or undefined
		ent - element to add; undefined is ignored
Returns: the array
=============
*/
add_to_array(array, ent)
{
	if(!isdefined(ent))
		return array;

	if(!isdefined(array))
		array[0] = ent;
	else
		array[array.size] = ent;

	return array;
}

/*
=============
exploder

Fires exploder number num: plays its effects and sounds and shows, throws or deletes
the brush/model pieces registered in level._script_exploders.
Params: num - script_exploder number
=============
*/
exploder(num)
{
	num = int(num);
	ents = level._script_exploders;

	for(i = 0; i < ents.size; i++)
	{
		if(!isdefined(ents[i]))
			continue;

		if (ents[i].script_exploder != num)
			continue;

		if (isdefined(ents[i].script_fxid))
			level thread cannon_effect(ents[i]);

		if (isdefined (ents[i].script_sound))
			ents[i] thread exploder_sound();

		// "exploder" = piece that appears, "exploderchunk" = debris that flies away,
		// anything else without an effect is removed
		if (isdefined(ents[i].targetname))
		{
			if(ents[i].targetname == "exploder")
				ents[i] thread brush_show();
			else
				if((ents[i].targetname == "exploderchunk") || (ents[i].targetname == "exploderchunk visible"))
					ents[i] thread brush_throw();
			else
				if(!isdefined(ents[i].script_fxid))
					ents[i] thread brush_delete();
		}
		else
			if (!isdefined(ents[i].script_fxid))
				ents[i] thread brush_delete();
	}
}

/*
=============
exploder_sound

Plays the exploder's sound after its optional script_delay.
Called on: exploder entity
=============
*/
exploder_sound()
{
	if(isdefined(self.script_delay))
		wait self.script_delay;

	self playSound(level.scr_sound[self.script_sound]);
}

/*
=============
cannon_effect

Plays the exploder's one-shot effect, with a random delay between script_delay_min and
script_delay_max if both are set. The effect points at the entity's target, if any.
Params: source - exploder entity
=============
*/
cannon_effect(source)
{
	if(!isdefined(source.script_delay))
		source.script_delay = 0;

	if((isdefined(source.script_delay_min)) && (isdefined(source.script_delay_max)))
		source.script_delay = source.script_delay_min + randomfloat (source.script_delay_max - source.script_delay_min);

	org = undefined;
	if(isdefined(source.target))
		org = (getent(source.target, "targetname")).origin;

	level thread maps\mp\_fx::OneShotfx(source.script_fxid, source.origin, source.script_delay, org);
}

/*
=============
brush_delete

Deletes the exploder piece after its optional script_delay.
Called on: exploder entity
=============
*/
brush_delete()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	self delete();
}

/*
=============
brush_show

Shows the exploder piece and makes it solid after its optional script_delay.
Called on: exploder entity
=============
*/
brush_show()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	self show();
	self solid();
}

/*
=============
brush_throw

Throws an exploder chunk towards its target entity with physics-like motion
(rotation + gravity for 12 seconds) and deletes it after 6 seconds.
Without a target the chunk is deleted immediately.
Called on: exploder entity
=============
*/
brush_throw()
{
	if(isdefined(self.script_delay))
		wait(self.script_delay);

	ent = undefined;
	if(isdefined(self.target))
		ent = getent(self.target, "targetname");

	if(!isdefined(ent))
	{
		self delete();
		return;
	}

	self show();

	org = ent.origin;

	temp_vec = (org - self.origin);

	// Disabled: debug print of the throw vector (uses the SP-only level.player).
	//	println("start ", self.origin , " end ", org, " vector ", temp_vec, " player origin ", level.player getorigin());

	x = temp_vec[0];
	y = temp_vec[1];
	z = temp_vec[2];

	self rotateVelocity((x,y,z), 12);
	self moveGravity((x, y, z), 12);

	wait(6);
	self delete();
}

/*
=============
saveModel

Captures the player's body model, view model and all attached models so they can be
restored later with loadModel.
Called on: player
Returns: info array ("model", "viewmodel", "attach", optional "player_hatmodel")
=============
*/
saveModel()
{
	info["model"] = self.model;
	info["viewmodel"] = self getViewModel();
	attachSize = self getAttachSize();
	info["attach"] = [];

	// Back2Uo: also remember the S&D hat model (self.hatModel)
	if(isdefined(self.hatModel)) info["player_hatmodel"] = self.hatModel;

	for(i = 0; i < attachSize; i++)
	{
		info["attach"][i]["model"] = self getAttachModelName(i);
		info["attach"][i]["tag"] = self getAttachTagName(i);
		info["attach"][i]["ignoreCollision"] = self getAttachIgnoreCollision(i);
	}

	return info;
}

/*
=============
loadModel

Restores a model setup captured by saveModel.
Called on: player
Params: info - array returned by saveModel
=============
*/
loadModel(info)
{
	self detachAll();
	self setModel(info["model"]);
	self setViewModel(info["viewmodel"]);

	// Back2Uo: restore the S&D hat model reference
	if(isdefined(info["player_hatmodel"])) self.hatModel = info["player_hatmodel"];

	attachInfo = info["attach"];
	attachSize = attachInfo.size;

	for(i = 0; i < attachSize; i++)
		self attach(attachInfo[i]["model"], attachInfo[i]["tag"], attachInfo[i]["ignoreCollision"]);
}

/*
=============
getPlant

Finds the ground position and orientation for planting an object (the S&D bomb):
first traces down just in front of the player, then below the player, then picks the
closest ground of four traces around the player.
Called on: player
Returns: struct with origin and angles
=============
*/
getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 11;
	forward = anglesToForward(self.angles);
	forward = maps\mp\_utility::vectorScale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	// Short downward trace (18 units) in front of the player
	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[0], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	// Short downward trace below the player
	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[1], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	// Fallback: long traces at four corners around the player, use the closest hit
	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		// Disabled: debug markers for the trace origins
		//ent[i] = spawn("script_model",(traceorigins[i]+(0, 0, -2)));
		//ent[i].angles = (0, 180, 180);
		//ent[i] setmodel("xmodel/105");

		//println("^6trace ", i ," fraction is ", trace["fraction"]);

		if(!isdefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];

			//println("^6besttracefraction set to ", besttracefraction, " which is traceorigin[", i, "]");
		}
	}

	// Nothing hit: plant at the player's feet
	if(besttracefraction == 1)
		besttraceposition = self.origin;

	temp = spawnstruct();
	temp.origin = besttraceposition;
	// Note: uses the normal of the last trace, not of the best one
	temp.angles = orientToNormal(trace["normal"]);
	return temp;
}

/*
=============
orientToNormal

Converts a surface normal into angles that make an object lie flat on that surface.
Params: normal - surface normal from a trace
Returns: angles; (0, 0, 0) for flat ground
=============
*/
orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length)
		return (0, 0, 0);

	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	// Disabled: debug prints of the intermediate values
	//println("^6hor_normal is ", hor_normal);
	//println("^6hor_length is ", hor_length);
	//println("^6hor_dir is ", hor_dir);
	//println("^6neg_height is ", neg_height);
	//println("^6tangent is ", tangent);
	//println("^6plant_angle is ", plant_angle);

	return plant_angle;
}

/*
=============
array_levelthread

Starts process as a level thread for every entity in ents, except those in excluders.
Params: ents - entity array
		process - function pointer, called as process(ent) or process(ent, var)
		var - optional extra argument
		excluders - optional array of entities to skip
=============
*/
array_levelthread (ents, process, var, excluders)
{
	exclude = [];
	for (i=0;i<ents.size;i++)
		exclude[i] = false;

	if (isdefined (excluders))
	{
		for (i=0;i<ents.size;i++)
			for (p=0;p<excluders.size;p++)
				if (ents[i] == excluders[p])
					exclude[i] = true;
	}

	for (i=0;i<ents.size;i++)
	{
		if (!exclude[i])
		{
			if (isdefined (var))
				level thread [[process]](ents[i], var);
			else
				level thread [[process]](ents[i]);
		}
	}
}

/*
=============
set_ambient

Switches the ambient sound track (2 second crossfade) if level.ambient_track has it.
Params: track - key into level.ambient_track
=============
*/
set_ambient (track)
{
	level.ambient = track;
	if ((isdefined (level.ambient_track)) && (isdefined (level.ambient_track[track])))
	{
		ambientPlay (level.ambient_track[track], 2);
		println ("playing ambient track ", track);
	}
}

/*
=============
abs

Absolute value.
Params: num - number
Returns: num without sign
=============
*/
abs (num)
{
	if (num < 0)
		num*= -1;

	return num;
}

/*
=============
deletePlacedEntity

Deletes all map entities of the given classname (e.g. unused gametype objects).
Params: entity - classname
=============
*/
deletePlacedEntity(entity)
{
	entities = getentarray(entity, "classname");
	for(i = 0; i < entities.size; i++)
	{
		//println("DELETED: ", entities[i].classname);
		entities[i] delete();
	}
}
