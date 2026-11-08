"""Build the mod and deploy it to the local docker server and the local CoD2 install.

Steps:
    1. python tools/build.py --no-minify
    2. server/sync_mod.sh (dist/back2uo -> docker volume "back2uo")
    3. Copy dist/back2uo into <cod2_setup_dir>/back2uo
    4. docker compose up -d (server/docker-compose.yml)

cod2_setup_dir is read from the .env file in the repository root:
    cod2_setup_dir=D:\\Disc\\Call of Duty 2

Usage:
    python tools/test.py
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "server")
DIST = os.path.join(ROOT, "dist", "back2uo")
ENV_FILE = os.path.join(ROOT, ".env")
ENV_KEY = "cod2_setup_dir"


def read_env(path, key):
    """Return the value of key from a KEY=value file, or None if the key is missing."""
    with open(path, encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, value = line.split("=", 1)
            if name.strip() == key:
                return value.strip().strip("\"'")
    return None


def find_bash():
    """Return the shell for sync_mod.sh. On Windows, plain "bash" would be WSL's, so use Git Bash."""
    if os.name != "nt":
        return "bash"
    # git.exe is in Git\cmd or, inside Git Bash, in Git\mingw64\bin: search upwards for Git\bin\bash.exe
    git = shutil.which("git")
    folder = os.path.dirname(git) if git else None
    while folder:
        bash = os.path.join(folder, "bin", "bash.exe")
        if os.path.isfile(bash):
            return bash
        parent = os.path.dirname(folder)
        folder = parent if parent != folder else None
    sys.exit("Git Bash not found (needed for server/sync_mod.sh)")


def read_target():
    """Return the CoD2 install directory from .env. Exits if it is not set or does not exist."""
    if not os.path.isfile(ENV_FILE):
        sys.exit(f"File not found: {ENV_FILE}")
    target = read_env(ENV_FILE, ENV_KEY)
    if not target:
        sys.exit(f"{ENV_KEY} is not set in {ENV_FILE}")
    if not os.path.isdir(target):
        sys.exit(f"{ENV_KEY} is not a directory: {target}")
    return target


def run(title, cmd, cwd):
    """Print title and run cmd in cwd. Exits if the command fails."""
    print(f"\n=== {title} ===", flush=True)
    try:
        subprocess.run(cmd, cwd=cwd, check=True)
    except subprocess.CalledProcessError as e:
        sys.exit(f"{title} failed with exit code {e.returncode}")


def main():
    # Check the setup first, so a bad .env fails before anything is built or synced
    target = os.path.join(read_target(), "back2uo")
    bash = find_bash()

    run("Stop server", ["docker", "compose", "down", "-v"], SERVER)
    run("Build", [sys.executable, os.path.join(ROOT, "tools", "build.py"), "--no-minify"], ROOT)
    # sync_mod.sh looks for ../dist/back2uo, so it has to run inside server/
    run("Sync docker volume", [bash, "sync_mod.sh"], SERVER)

    print(f"\n=== Copy to {target} ===", flush=True)
    shutil.copytree(DIST, target, dirs_exist_ok=True)

    run("Start server", ["docker", "compose", "up", "-d"], SERVER)
    print("\nDone.")


if __name__ == "__main__":
    main()
