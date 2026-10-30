"""Pack the Back2Uo release zip from the build output.

The zip contains the contents of dist/back2uo/ (without the *.default.cfg and *.dev.cfg
files), the docs from docs/ and the LICENSE:

    back2uo/    .iwd archives and config files, ready for the CoD2 install directory
    docs/       ReadMe and Index, English and German
    LICENSE

Run tools/build.py first, or pass --build to do it here. The version in the file name
defaults to <VERSION>_<date> (e.g. 2.1_2026-10-30); pass --version to override it.
The result is written to dist-release/back2uo_<version>.zip.

Usage:
    python tools/release.py [--build] [--version VERSION]
"""
import datetime
import os
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist", "back2uo")
DOCS = os.path.join(ROOT, "docs")
LICENSE = os.path.join(ROOT, "LICENSE")
OUT = os.path.join(ROOT, "dist-release")
EXCLUDE_SUFFIXES = (".default.cfg", ".dev.cfg")
VERSION = "2.1"


def add_tree(zf, src_dir, prefix):
    """Add all files below src_dir to zf under prefix/, skipping excluded configs."""
    count = 0
    for base, dirs, files in os.walk(src_dir):
        dirs.sort()
        for name in sorted(files):
            if name.lower().endswith(EXCLUDE_SUFFIXES):
                print(f"  skip {name}")
                continue
            full = os.path.join(base, name)
            arcname = prefix + "/" + os.path.relpath(full, src_dir).replace(os.sep, "/")
            zf.write(full, arcname)
            count += 1
    return count


def main():
    args = sys.argv[1:]
    version = None
    if "--version" in args:
        i = args.index("--version")
        if i + 1 >= len(args):
            sys.exit("--version needs a value")
        version = args[i + 1]
    version = version or f"{VERSION}_{datetime.date.today():%Y-%m-%d}"

    if "--build" in args:
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "build.py")], check=True)

    if not os.path.isdir(DIST) or not os.listdir(DIST):
        sys.exit(f"Build output not found: {DIST} (run tools/build.py or pass --build)")

    os.makedirs(OUT, exist_ok=True)
    zip_path = os.path.join(OUT, f"back2uo_{version}.zip")
    if os.path.exists(zip_path):
        os.remove(zip_path)

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        n = add_tree(zf, DIST, "back2uo")
        print(f"  back2uo/ ({n} files)")
        n = add_tree(zf, DOCS, "docs")
        print(f"  docs/ ({n} files)")
        zf.write(LICENSE, "LICENSE")
        print("  LICENSE")

    print(f"Done: {zip_path} ({os.path.getsize(zip_path) // 1024} KB)")


if __name__ == "__main__":
    main()
