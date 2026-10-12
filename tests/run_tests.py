"""Run the Back2Uo GSC tests on a dockerised CoD2 server.

Steps:
  1. python tools/build.py --test --no-minify  (dist-test/back2uo/, keeps script line numbers)
  2. start tests/docker-compose.test.yml for each gametype
  3. read the "B2UTEST;" lines from the server console and games_mp.log
  4. stop the server, print the results, exit 1 on any failure

The server console is also checked for script compile and runtime errors.

Requires Docker and the environment variable COD2_MAIN (folder with the CoD2 main/*.iwd files).

Usage:
    python tests/run_tests.py [--gametype tdm --gametype sd ...] [--map mp_toujane]
                              [--timeout 180] [--no-build] [--keep]
"""
import argparse
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMPOSE = os.path.join(ROOT, "tests", "docker-compose.test.yml")
GAME_LOG = os.path.join(ROOT, "dist-test", "back2uo", "games_mp.log")
PROJECT = "back2uo-test"
PREFIX = "B2UTEST;"

# Console lines that fail the run even if every test passed
ERROR_MARKERS = (
    "script compile error",
    "script runtime error",
    "G_ModelIndex: overflow",
    "Hunk_Alloc failed",
)


def compose(*args, env=None, capture=False):
    cmd = ["docker", "compose", "-f", COMPOSE, "-p", PROJECT, *args]
    if capture:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace")
        return result.stdout + result.stderr
    subprocess.run(cmd, env=env, check=True)
    return ""


def read_game_log():
    try:
        with open(GAME_LOG, "r", encoding="latin-1") as f:
            return f.read()
    except OSError:
        return ""


def test_lines(text):
    """Return the B2UTEST lines without prefix, in order, without duplicates."""
    lines = []
    for raw in text.replace("\r", "\n").split("\n"):
        i = raw.find(PREFIX)
        if i >= 0:
            line = raw[i + len(PREFIX):].strip()
            if line not in lines:
                lines.append(line)
    return lines


def error_lines(text):
    """Return console lines with a script error marker, plus the next lines with details."""
    lines = text.replace("\r", "\n").split("\n")
    found = []
    for i, line in enumerate(lines):
        if any(m.lower() in line.lower() for m in ERROR_MARKERS):
            found.extend(l for l in lines[i:i + 6] if l.strip())
    return found


def run_gametype(gametype, mapname, timeout, keep):
    env = dict(os.environ, B2U_GAMETYPE=gametype, B2U_MAP=mapname)
    print(f"\n=== {gametype} on {mapname} ===")

    if os.path.exists(GAME_LOG):
        os.remove(GAME_LOG)

    compose("up", "-d", "--force-recreate", env=env)
    console = ""
    lines = []
    try:
        deadline = time.time() + timeout
        while time.time() < deadline:
            time.sleep(2)
            console = compose("logs", "--no-color", env=env, capture=True)
            lines = test_lines(console) or test_lines(read_game_log())
            if any(l.startswith("DONE;") for l in lines) or error_lines(console):
                break
    finally:
        if not keep:
            compose("down", env=env)

    failed = False
    for line in lines:
        kind = line.split(";", 1)[0]
        if kind in ("FAIL", "XFAIL", "XPASS", "SKIP", "START", "DONE"):
            print("  " + line)
        if kind == "FAIL":
            failed = True

    errors = error_lines(console)
    if errors:
        failed = True
        print("  Script errors in the server console:")
        for e in errors:
            print("    " + e)

    if not any(l.startswith("DONE;") for l in lines):
        failed = True
        print(f"  No DONE line after {timeout} s. Server console tail:")
        for l in console.replace("\r", "\n").split("\n")[-30:]:
            if l.strip():
                print("    " + l)

    return not failed


def main():
    parser = argparse.ArgumentParser(description="Run the Back2Uo GSC tests on a docker CoD2 server.")
    parser.add_argument("--gametype", action="append", help="gametype to test, repeatable (default: tdm)")
    parser.add_argument("--map", default="mp_toujane", help="map to load (default: mp_toujane)")
    parser.add_argument("--timeout", type=int, default=180, help="seconds to wait per gametype (default: 180)")
    parser.add_argument("--no-build", action="store_true", help="use the existing dist-test/ build")
    parser.add_argument("--keep", action="store_true", help="leave the server running after the run")
    args = parser.parse_args()

    if not os.environ.get("COD2_MAIN"):
        sys.exit("Set COD2_MAIN to the folder with the CoD2 main/*.iwd files.")

    if not args.no_build:
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "build.py"), "--test", "--no-minify"], check=True)

    results = {}
    for gametype in args.gametype or ["tdm"]:
        results[gametype] = run_gametype(gametype, args.map, args.timeout, args.keep)

    print()
    for gametype, ok in results.items():
        print(f"{gametype}: {'OK' if ok else 'FAILED'}")
    sys.exit(0 if all(results.values()) else 1)


if __name__ == "__main__":
    main()
