"""Minimal GSC (CoD2) lexer used to verify that edits touch only comments/whitespace.

Usage:
  python gsclex.py compare ORIG_DIR NEW_DIR      -> compares code token streams of all *.gsc*
  python gsclex.py nonascii DIR                  -> reports non-ASCII bytes in code (not comments)
"""
import os
import sys

OPS = sorted("""
>>= <<= ... == != <= >= && || ++ -- += -= *= /= %= &= |= ^= << >> :: -> /# #/
""".split(), key=len, reverse=True)


def lex(src):
    """Return (tokens, comments). Tokens exclude whitespace and comments."""
    toks, comments = [], []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in " \t\r\n\f\v":
            i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            comments.append(src[i:j])
            i = j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            comments.append(src[i:j])
            i = j
            continue
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                if src[j] == "\\":
                    j += 1
                j += 1
            toks.append(src[i:j + 1])
            i = j + 1
            continue
        if c.isalnum() or c in "_\\":
            j = i
            while j < n and (src[j].isalnum() or src[j] in "_\\."):
                j += 1
            toks.append(src[i:j])
            i = j
            continue
        if c == "." and i + 1 < n and src[i + 1].isdigit():
            j = i + 1
            while j < n and (src[j].isalnum() or src[j] == "."):
                j += 1
            toks.append(src[i:j])
            i = j
            continue
        for op in OPS:
            if src.startswith(op, i):
                toks.append(op)
                i += len(op)
                break
        else:
            toks.append(c)
            i += 1
    return toks, comments


def read(path):
    with open(path, "rb") as f:
        return f.read().decode("latin-1")


def gsc_files(root):
    out = []
    for d, _, fs in os.walk(root):
        for f in fs:
            if ".gsc" in f:
                out.append(os.path.relpath(os.path.join(d, f), root))
    return sorted(out)


def compare(a_root, b_root):
    bad = 0
    a_files, b_files = gsc_files(a_root), gsc_files(b_root)
    if a_files != b_files:
        print("FILE SET DIFFERS:", set(a_files) ^ set(b_files))
        bad += 1
    for rel in a_files:
        if rel not in b_files:
            continue
        ta, _ = lex(read(os.path.join(a_root, rel)))
        tb, _ = lex(read(os.path.join(b_root, rel)))
        if ta != tb:
            bad += 1
            k = next((k for k, (x, y) in enumerate(zip(ta, tb)) if x != y), min(len(ta), len(tb)))
            print(f"DIFF {rel}: token #{k}: {ta[max(0,k-5):k+5]} != {tb[max(0,k-5):k+5]}")
        else:
            print(f"ok   {rel} ({len(ta)} tokens)")
    print("RESULT:", "FAIL" if bad else "PASS")
    return bad


def nonascii(root):
    for rel in gsc_files(root):
        toks, comments = lex(read(os.path.join(root, rel)))
        code_bad = [t for t in toks if any(ord(ch) > 127 for ch in t)]
        com_bad = sum(1 for c in comments if any(ord(ch) > 127 for ch in c))
        if code_bad or com_bad:
            print(f"{rel}: code={code_bad[:5]} comments_with_nonascii={com_bad}")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "compare":
        sys.exit(1 if compare(sys.argv[2], sys.argv[3]) else 0)
    elif cmd == "file":
        # python gsclex.py file ORIG_FILE NEW_FILE  -> token compare + non-ASCII comment check
        ta, _ = lex(read(sys.argv[2]))
        tb, cb = lex(read(sys.argv[3]))
        ok = ta == tb
        if not ok:
            k = next((k for k, (x, y) in enumerate(zip(ta, tb)) if x != y), min(len(ta), len(tb)))
            print(f"CODE CHANGED at token #{k}: {ta[max(0,k-5):k+5]} != {tb[max(0,k-5):k+5]}")
        bad = [c for c in cb if any(ord(ch) > 127 for ch in c)]
        for c in bad:
            print("NON-ASCII COMMENT:", c[:80])
        print("RESULT:", "PASS" if ok and not bad else "FAIL")
        sys.exit(0 if ok and not bad else 1)
    elif cmd == "nonascii":
        nonascii(sys.argv[2])
