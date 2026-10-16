# GSC tests

The tests run inside a real CoD2 server in Docker (CoD2 1.3 with zk_libcod, same image as
`server/docker-compose.yml`). A GSC test runner checks mod functions on the running server
and writes the results to the log. `run_tests.py` reads them and sets the exit code.

## Run

Requires Docker, Python 3 and the original CoD2 `main/*.iwd` files.

```sh
python tests/run_tests.py                                 # tdm on mp_toujane
python tests/run_tests.py --gametype tdm --gametype sd    # several gametypes
python tests/run_tests.py --map mp_carentan --keep        # leave the server running
```

Exit code 0 = all tests passed and no script errors in the console.

## How it works

1. `python tools/build.py --test --no-minify` writes `dist-test/back2uo/`. It has the normal
   archives plus `zz_back2uo_test.iwd` (built from `tests/gsc/`) and `server_test.cfg`.
2. `_back2uo_main::back2uo_main()` threads `back2uo\_back2uo_test::run()` on every map.
   In the release that file is an empty stub. `zz_back2uo_test.iwd` sorts after
   `z_svr_back2uo_2.1.iwd`, so its `back2uo/_back2uo_test.gsc` replaces the stub.
3. The runner starts only with `back2uo_test 1` (set in `server_test.cfg`). It waits 1 s
   for the gametype start code, runs the suites and prints `B2UTEST;...` lines with
   `logprint` (games_mp.log) and `println` (console, needs `developer 1`).
4. `run_tests.py` waits for `B2UTEST;DONE`. It fails on any `FAIL` line, on
   `script compile error` / `script runtime error` in the console, or on timeout.

## Results

| Line | Meaning | Fails the run |
|------|---------|---------------|
| `PASS` | test passed | no |
| `FAIL` | value differs from the expected one | yes |
| `XFAIL` | known bug, still present | no |
| `XPASS` | known bug is fixed, turn `known_bug()` into `assert_eq()` | no |
| `SKIP` | test not possible with this config | no |

## Write a test

Suites live in `tests/gsc/back2uo/test/_test_<area>.gsc`. Add the suite's `run()` call to
`tests/gsc/back2uo/_back2uo_test.gsc`.

```c
test_example()
{
	saved = back2uo\test\_assert::cvar_save("back2uo_some_cvar");

	setcvar("back2uo_some_cvar", "5");
	back2uo\test\_assert::assert_eq("some cvar clamps to 1", back2uo\_back2uo_cvars::back2uo_setconfig("back2uo_some_cvar", 1, 0, 1), 1);

	back2uo\test\_assert::cvar_restore("back2uo_some_cvar", saved);
}
```

Rules:

- Put back every cvar and `game[]` / `level.` value the test changes. All suites share one server.
- Compare like with like: `getcvar()` returns strings, `getcvarint()` / `getcvarfloat()` numbers.
- Document bugs from `docs/code-review-notes.md` with `known_bug(name, got, correct_value)`.
- GSC has no exceptions. A runtime error stops the test thread. `run_tests.py` then reports
  the error from the console and the missing `DONE` line.
- Only server-side logic is testable. Menus, HUD, effects and sounds need a game client.
