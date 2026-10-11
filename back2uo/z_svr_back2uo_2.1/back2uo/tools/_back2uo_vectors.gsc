/*
	Back2Uo v2.1 - Position and vector math: artillery shell impact points and airplane
	fly-over paths.
*/

/*
=============
back2uo_calcshellpos

Picks a random impact point within 360 units (horizontally) of targetPos by tracing
3000 units straight down. Retries every 0.1 seconds until the trace hits ground.
Used for artillery shell impacts.
Params: targetPos - center of the impact area
Returns: impact position on the ground
=============
*/
back2uo_calcshellpos(targetPos)
{
	shellPos = undefined;

	while(!isdefined (shellPos))
	{
		shellPos = targetPos;
		angle = randomfloat( 360 );
		radius = randomfloat( 360 );
		randomOffset = (cos(angle) * radius, sin(angle) * radius, 0);
		shellPos += randomOffset;
		startOrigin = shellPos;
		endOrigin = shellPos - (0, 0, 3000);

		trace = bulletTrace( startOrigin, endOrigin, true, undefined );

		// No ground below: try another random point.
		if(trace["fraction"] < 1.0)
			shellPos = trace["position"];
		else
			shellPos = undefined;

		wait 0.1;
	}

	return ( shellPos );
}

/*
=============
back2uo_airplane_vectorpos

Computes the start and end point of an airplane fly-over: from startpos (+ offset)
it traces 50000 units backwards and forwards along the yaw angle and stops at map
geometry, so the plane enters and leaves at the map edges.
Params: startpos - center position of the flight path
		angle - flight yaw in degrees
		airplane_extras - offset vector added to startpos (formation position)
Returns: array [0] = start point, [1] = end point
=============
*/
back2uo_airplane_vectorpos(startpos, angle, airplane_extras)
{
	startpos = startpos + airplane_extras;
	forwardvector = anglestoforward((0,angle,0));

	backpos = startpos + (back2uo_airplane_vectormulti(forwardvector,-50000));
	trace = bulletTrace(startpos, backpos, false, undefined);

	if(trace["fraction"] != 1)
	{
		startpoint = trace["position"];
	}
	else
	{
		startpoint = backpos;
	}

	frontpos = startpos + (back2uo_airplane_vectormulti(forwardvector,50000));
	trace = bulletTrace(startpos, frontpos, false, undefined);

	if(trace["fraction"] != 1)
	{
		endpoint = trace["position"];
	}
	else
	{
		endpoint = frontpos;
	}

	stenpos[0] = startpoint;
	stenpos[1] = endpoint;

	return stenpos;
}

/*
=============
back2uo_airplane_vectormulti

Multiplies a vector by a scalar.
Params: vec - vector
		size - scale factor
Returns: scaled vector
=============
*/
back2uo_airplane_vectormulti(vec, size)
{
	x = vec[0] * size;
	y = vec[1] * size;
	z = vec[2] * size;
	vec = (x,y,z);

	return vec;
}
