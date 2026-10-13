/*
	Back2Uo v2.1 - assertions and output for the GSC tests (test build only)

	Counters live in level.b2utest_*. Values are compared with ==, so compare like with
	like: getcvar() returns strings, getcvarint()/getcvarfloat() return numbers.
*/

/*
=============
init

Resets the result counters.
=============
*/
init()
{
	level.b2utest_pass = 0;
	level.b2utest_fail = 0;
	level.b2utest_xfail = 0;
	level.b2utest_xpass = 0;
	level.b2utest_skip = 0;
}

/*
=============
out

Writes one result line to the game log and the console.
Params: line - text after the "B2UTEST;" prefix
=============
*/
out(line)
{
	logprint("B2UTEST;" + line + "\n");
	println("B2UTEST;" + line);
}

/*
=============
suite

Marks the start of a test suite in the output.
Params: name - suite name
=============
*/
suite(name)
{
	out("SUITE;" + name);
}

/*
=============
assert_eq

Passes if got == want.
Params: name - test name
		got - actual value
		want - expected value
=============
*/
assert_eq(name, got, want)
{
	if(isdefined(got) && got == want)
	{
		level.b2utest_pass++;
		out("PASS;" + name);
	}
	else
	{
		level.b2utest_fail++;
		out("FAIL;" + name + ";got=" + str(got) + ";want=" + str(want));
	}
}

/*
=============
assert_true

Passes if value is defined and true.
Params: name - test name
		value - value to check
=============
*/
assert_true(name, value)
{
	if(isdefined(value) && value)
	{
		level.b2utest_pass++;
		out("PASS;" + name);
	}
	else
	{
		level.b2utest_fail++;
		out("FAIL;" + name + ";got=" + str(value) + ";want=true");
	}
}

/*
=============
known_bug

Documents a known bug: want is the correct value. While the bug is present (got != want)
the result is XFAIL and does not fail the run. Once the bug is fixed the result is XPASS;
then turn the call into assert_eq().
Params: name - test name
		got - actual value
		want - correct value
=============
*/
known_bug(name, got, want)
{
	if(isdefined(got) && got == want)
	{
		level.b2utest_xpass++;
		out("XPASS;" + name);
	}
	else
	{
		level.b2utest_xfail++;
		out("XFAIL;" + name + ";got=" + str(got) + ";want=" + str(want));
	}
}

/*
=============
skip

Records a skipped test.
Params: name - test name
		reason - why it was skipped
=============
*/
skip(name, reason)
{
	level.b2utest_skip++;
	out("SKIP;" + name + ";" + reason);
}

/*
=============
done

Prints the summary line. tests/run_tests.py waits for it.
=============
*/
done()
{
	out("DONE;pass=" + level.b2utest_pass + ";fail=" + level.b2utest_fail + ";xfail=" + level.b2utest_xfail
		+ ";xpass=" + level.b2utest_xpass + ";skip=" + level.b2utest_skip);
}

/*
=============
str

Converts a value for output; undefined becomes "undefined".
=============
*/
str(value)
{
	if(!isdefined(value)) return "undefined";

	return "" + value;
}

/*
=============
cvar_save / cvar_restore

Keep a cvar value so a test can change it and put it back afterwards.
=============
*/
cvar_save(name)
{
	return getcvar(name);
}

cvar_restore(name, value)
{
	setcvar(name, value);
}
