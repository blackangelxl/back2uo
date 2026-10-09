"""Build the Back2Uo release folder from the unpacked sources.

Every directory in back2uo/ is zipped into an .iwd archive of the same name
(CoD2 .iwd files are plain ZIP archives). The server config files are copied
next to them. The result is written to dist/back2uo/, ready to be copied into
the Call of Duty 2 install directory.

All .gsc files are minified on the way into the archive: comments are removed,
indentation, blank lines and redundant whitespace are dropped. Developer blocks
(/# ... #/) are kept. Pass --no-minify to pack the scripts unchanged, which
keeps the line numbers in script errors matching the sources.

Usage:
    python tools/build.py [--no-minify]
"""
import os
import shutil
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "back2uo")
DIST = os.path.join(ROOT, "dist", "back2uo")

# "." counts as a word char so "wait .05" does not become "wait.05"
WORD_CHARS = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
OPERATOR_CHARS = set("+-*/%&|^<>=!")


def needs_space(prev, nxt):
    """True if dropping the whitespace between prev and nxt would merge two tokens."""
    if prev in WORD_CHARS and nxt in WORD_CHARS:
        return True
    # Keeps e.g. "a - -b" or "x < -1" from turning into "a--b" or "x<-1"
    return prev in OPERATOR_CHARS and nxt in OPERATOR_CHARS


def minify_gsc(text):
    """Strip comments and redundant whitespace from GSC source, one statement line per source line."""
    lines = []
    line = []
    pending_space = False
    i = 0
    n = len(text)

    def flush():
        stripped = "".join(line).strip()
        if stripped:
            lines.append(stripped)
        line.clear()

    while i < n:
        c = text[i]
        two = text[i:i + 2]
        if two == "//":
            end = text.find("\n", i)
            i = n if end == -1 else end
        elif two == "/*":
            end = text.find("*/", i + 2)
            if end == -1:
                raise ValueError("unterminated block comment")
            # A comment separates tokens like whitespace does
            pending_space = True
            i = end + 2
        elif two in ("/#", "#/"):
            # Developer block markers must stay on a line of their own
            flush()
            lines.append(two)
            pending_space = False
            i += 2
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\\":
                    j += 1
                elif text[j] == "\n":
                    raise ValueError("unterminated string")
                j += 1
            if j >= n:
                raise ValueError("unterminated string")
            if pending_space and line and needs_space(line[-1][-1], c):
                line.append(" ")
            line.append(text[i:j + 1])
            pending_space = False
            i = j + 1
        elif c == "\n":
            flush()
            pending_space = False
            i += 1
        elif c.isspace():
            pending_space = True
            i += 1
        else:
            if pending_space and line and needs_space(line[-1][-1], c):
                line.append(" ")
            line.append(c)
            pending_space = False
            i += 1
    flush()
    return "\n".join(lines) + "\n"


def build_iwd(src_dir, iwd_path, minify):
    """Zip src_dir into iwd_path. Entry names use forward slashes, as the engine expects."""
    count = 0
    saved = 0
    with zipfile.ZipFile(iwd_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for base, dirs, files in os.walk(src_dir):
            dirs.sort()
            for name in sorted(files):
                full = os.path.join(base, name)
                arcname = os.path.relpath(full, src_dir).replace(os.sep, "/")
                if minify and name.lower().endswith(".gsc"):
                    with open(full, "r", encoding="latin-1", newline="") as f:
                        source = f.read().replace("\r\n", "\n").replace("\r", "\n")
                    try:
                        result = minify_gsc(source)
                    except ValueError as e:
                        sys.exit(f"Cannot minify {full}: {e}")
                    zf.writestr(arcname, result.encode("latin-1"))
                    saved += len(source) - len(result)
                else:
                    zf.write(full, arcname)
                count += 1
    return count, saved


def main():
    minify = "--no-minify" not in sys.argv[1:]

    if not os.path.isdir(SRC):
        sys.exit(f"Source folder not found: {SRC}")

    if os.path.isdir(DIST):
        shutil.rmtree(DIST)
    os.makedirs(DIST)

    for entry in sorted(os.listdir(SRC)):
        path = os.path.join(SRC, entry)
        if os.path.isdir(path):
            target = os.path.join(DIST, entry + ".iwd")
            n, saved = build_iwd(path, target, minify)
            info = f", gsc -{saved // 1024} KB" if saved else ""
            print(f"  {entry}.iwd ({n} files{info})")
        elif entry.lower().endswith(".cfg"):
            shutil.copy2(path, DIST)
            print(f"  {entry}")

    print(f"Done: {DIST}")


if __name__ == "__main__":
    main()
