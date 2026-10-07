"""Build the Back2Uo release folder from the unpacked sources.

Every directory in back2uo/ is zipped into an .iwd archive of the same name
(CoD2 .iwd files are plain ZIP archives). The server config files are copied
next to them. The result is written to dist/back2uo/, ready to be copied into
the Call of Duty 2 install directory.

Usage:
    python tools/build.py
"""
import os
import shutil
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "back2uo")
DIST = os.path.join(ROOT, "dist", "back2uo")


def build_iwd(src_dir, iwd_path):
    """Zip src_dir into iwd_path. Entry names use forward slashes, as the engine expects."""
    count = 0
    with zipfile.ZipFile(iwd_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for base, dirs, files in os.walk(src_dir):
            dirs.sort()
            for name in sorted(files):
                full = os.path.join(base, name)
                arcname = os.path.relpath(full, src_dir).replace(os.sep, "/")
                zf.write(full, arcname)
                count += 1
    return count


def main():
    if not os.path.isdir(SRC):
        sys.exit(f"Source folder not found: {SRC}")

    if os.path.isdir(DIST):
        shutil.rmtree(DIST)
    os.makedirs(DIST)

    for entry in sorted(os.listdir(SRC)):
        path = os.path.join(SRC, entry)
        if os.path.isdir(path):
            target = os.path.join(DIST, entry + ".iwd")
            n = build_iwd(path, target)
            print(f"  {entry}.iwd ({n} files)")
        elif entry.lower().endswith(".cfg"):
            shutil.copy2(path, DIST)
            print(f"  {entry}")

    print(f"Done: {DIST}")


if __name__ == "__main__":
    main()
