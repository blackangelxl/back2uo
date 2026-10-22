/*
	Back2Uo v2.1 - test hook (release stub)

	back2uo_main() threads run() once per map. In the release this file does nothing.
	The test build (python tools/build.py --test) adds z_svr_back2uo_2.1_test.iwd, which replaces
	this file with the GSC test runner from tests/gsc/. See tests/README.md.
*/

/*
=============
run

Empty in the release. The test archive overrides it.
Called on: level (threaded from _back2uo_main::back2uo_main)
=============
*/
run()
{
}
