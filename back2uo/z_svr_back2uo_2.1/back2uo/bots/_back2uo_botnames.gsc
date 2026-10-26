/*
	Back2Uo v2.1 - Bot name pool

	Realistic WW2-era first and last names per CoD2 nationality (american, british, russian,
	german). Fictional combinations, no historical persons. Every name gets the suffix
	" ^3[BOT]" so players can tell bots apart. Longest name incl. suffix: 27 characters
	(CoD2 limit: 31). ASCII only, German umlauts written as ae/oe/ue.
	Each name is handed out only once per map (level.back2uo_botnames_used).
*/

/*
=============
back2uo_botname_get

Returns a random, not yet used bot name with suffix for the given nationality.
When every name of the pool is taken, a number is appended.
Params: nationality - "american", "british", "russian" or "german"
            (game["allies"] or game["axis"])
=============
*/
back2uo_botname_get(nationality)
{
	pool = back2uo_botname_pool(nationality);

	if(!isdefined(level.back2uo_botnames_used)) level.back2uo_botnames_used = [];

	free = [];

	for(i = 0; i < pool.size; i++)
	{
		if(!isdefined(level.back2uo_botnames_used[pool[i]])) free[free.size] = pool[i];
	}

	if(free.size > 0)
	{
		name = free[randomInt(free.size)];
		level.back2uo_botnames_used[name] = true;
	}
	else
	{
		name = pool[randomInt(pool.size)] + " " + (randomInt(90) + 10);
	}

	return name + " ^3[BOT]";
}

/*
=============
back2uo_botname_pool

Returns the name array for a nationality. Unknown nationalities get the german pool.
=============
*/
back2uo_botname_pool(nationality)
{
	n = [];

	switch(nationality)
	{
	case "american":
		n[n.size] = "Eugene Whitaker";
		n[n.size] = "Raymond Delaney";
		n[n.size] = "Clarence Pruitt";
		n[n.size] = "Earl Sorensen";
		n[n.size] = "Howard Callahan";
		n[n.size] = "Leroy Dawson";
		n[n.size] = "Floyd Hendricks";
		n[n.size] = "Chester Novak";
		n[n.size] = "Vernon Larson";
		n[n.size] = "Lloyd Caldwell";
		n[n.size] = "Wilbur Garrett";
		n[n.size] = "Elmer Dombrowski";
		n[n.size] = "Roy Marino";
		n[n.size] = "Marvin Tucker";
		n[n.size] = "Herbert Lindquist";
		n[n.size] = "Virgil Brennan";
		n[n.size] = "Russell Wheeler";
		n[n.size] = "Norman Prescott";
		n[n.size] = "Ralph Morales";
		n[n.size] = "Donald Mitchell";
		n[n.size] = "Kenneth Sullivan";
		n[n.size] = "Frank Russo";
		n[n.size] = "Joseph Wozniak";
		n[n.size] = "Robert Holloway";
		n[n.size] = "Edward Bishop";
		n[n.size] = "Arthur Peterson";
		n[n.size] = "Leonard Walsh";
		n[n.size] = "Stanley Hughes";
		n[n.size] = "Walter Fiske";
		n[n.size] = "Harold Bennett";
		n[n.size] = "Dale Kirkland";
		n[n.size] = "Warren Ostrowski";
		n[n.size] = "Glenn Abernathy";
		n[n.size] = "Lester McCoy";
		n[n.size] = "Homer Reyes";
		n[n.size] = "Irving Goldberg";
		n[n.size] = "Carl Lindgren";
		n[n.size] = "Willard Doyle";
		n[n.size] = "Jack Carver";
		n[n.size] = "Francis Moretti";
		break;

	case "british":
		n[n.size] = "Alfred Ashworth";
		n[n.size] = "Cyril Barnes";
		n[n.size] = "Reginald Fletcher";
		n[n.size] = "Percy Hargreaves";
		n[n.size] = "Albert Hutchins";
		n[n.size] = "Bernard Jennings";
		n[n.size] = "Leslie Kemp";
		n[n.size] = "Sidney Marsh";
		n[n.size] = "Ernest Nash";
		n[n.size] = "Frederick Oakley";
		n[n.size] = "Geoffrey Pearce";
		n[n.size] = "Dennis Pritchard";
		n[n.size] = "Gordon Rowe";
		n[n.size] = "Ronald Thorne";
		n[n.size] = "Wilfred Whitfield";
		n[n.size] = "Douglas Atkinson";
		n[n.size] = "Thomas Bramley";
		n[n.size] = "William Cartwright";
		n[n.size] = "George Dobson";
		n[n.size] = "Alan Ellis";
		n[n.size] = "Victor Griffiths";
		n[n.size] = "Clifford Ingram";
		n[n.size] = "Edmund Morley";
		n[n.size] = "Herbert Naylor";
		n[n.size] = "Arthur Rigby";
		n[n.size] = "Stanley Sutcliffe";
		n[n.size] = "Harold Yates";
		n[n.size] = "Kenneth Parsons";
		n[n.size] = "Norman Lowe";
		n[n.size] = "Frank Haworth";
		n[n.size] = "Hamish Ferguson";
		n[n.size] = "Owen Pryce";
		n[n.size] = "Gareth Llewellyn";
		n[n.size] = "Patrick Doherty";
		n[n.size] = "Colin Bradshaw";
		n[n.size] = "Maurice Coates";
		n[n.size] = "Leonard Hebden";
		n[n.size] = "Eric Pickering";
		n[n.size] = "Roland Ashby";
		n[n.size] = "Basil Whitcombe";
		break;

	case "russian":
		n[n.size] = "Ivan Sokolov";
		n[n.size] = "Aleksei Morozov";
		n[n.size] = "Dmitri Volkov";
		n[n.size] = "Nikolai Lebedev";
		n[n.size] = "Sergei Novikov";
		n[n.size] = "Mikhail Gusev";
		n[n.size] = "Pavel Orlov";
		n[n.size] = "Grigori Belov";
		n[n.size] = "Viktor Smirnov";
		n[n.size] = "Yuri Vasiliev";
		n[n.size] = "Boris Zakharov";
		n[n.size] = "Fyodor Tarasov";
		n[n.size] = "Andrei Yegorov";
		n[n.size] = "Konstantin Nikitin";
		n[n.size] = "Leonid Sorokin";
		n[n.size] = "Pyotr Kiselev";
		n[n.size] = "Stepan Andreev";
		n[n.size] = "Timofei Loginov";
		n[n.size] = "Vladimir Grachev";
		n[n.size] = "Yakov Antonov";
		n[n.size] = "Anatoli Frolov";
		n[n.size] = "Gennadi Gromov";
		n[n.size] = "Arkadi Danilov";
		n[n.size] = "Semyon Baranov";
		n[n.size] = "Matvei Sidorov";
		n[n.size] = "Ilya Zuev";
		n[n.size] = "Oleg Krylov";
		n[n.size] = "Aleksandr Rybakov";
		n[n.size] = "Kirill Shirokov";
		n[n.size] = "Nikita Komarov";
		n[n.size] = "Roman Kuznetsov";
		n[n.size] = "Yegor Petrov";
		n[n.size] = "Maksim Kovalenko";
		n[n.size] = "Taras Bondarenko";
		n[n.size] = "Ruslan Aliev";
		n[n.size] = "Afanasi Kudryavtsev";
		n[n.size] = "Prokhor Maslov";
		n[n.size] = "Igor Tikhonov";
		n[n.size] = "Gavriil Myasnikov";
		n[n.size] = "Savely Ignatov";
		break;

	case "german":
	default:
		n[n.size] = "Hans Schaefer";
		n[n.size] = "Karl Becker";
		n[n.size] = "Friedrich Hoffmann";
		n[n.size] = "Wilhelm Koch";
		n[n.size] = "Otto Lehmann";
		n[n.size] = "Ernst Richter";
		n[n.size] = "Walter Klein";
		n[n.size] = "Kurt Wolf";
		n[n.size] = "Werner Schroeder";
		n[n.size] = "Helmut Neumann";
		n[n.size] = "Gerhard Schwarz";
		n[n.size] = "Fritz Zimmermann";
		n[n.size] = "Josef Krueger";
		n[n.size] = "Franz Hartwig";
		n[n.size] = "Ludwig Lange";
		n[n.size] = "Hermann Koehler";
		n[n.size] = "Rudolf Haas";
		n[n.size] = "Alfred Vogel";
		n[n.size] = "Paul Keller";
		n[n.size] = "Georg Berger";
		n[n.size] = "Erwin Roth";
		n[n.size] = "Guenter Kuhn";
		n[n.size] = "Horst Sommer";
		n[n.size] = "Dieter Seidel";
		n[n.size] = "Klaus Graf";
		n[n.size] = "Manfred Engel";
		n[n.size] = "Rolf Ziegler";
		n[n.size] = "Bruno Huber";
		n[n.size] = "Emil Scholz";
		n[n.size] = "Heinrich Moeller";
		n[n.size] = "Johann Jaeger";
		n[n.size] = "Willi Winkler";
		n[n.size] = "August Lorenz";
		n[n.size] = "Max Brenner";
		n[n.size] = "Erich Hahn";
		n[n.size] = "Konrad Beckmann";
		n[n.size] = "Gustav Pfeiffer";
		n[n.size] = "Albert Reuter";
		n[n.size] = "Hugo Brandl";
		n[n.size] = "Anton Hofer";
		break;
	}

	return n;
}
