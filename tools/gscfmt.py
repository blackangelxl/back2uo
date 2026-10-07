"""Re-indent CoD2 GSC files (tabs, IW style), trim trailing whitespace,
collapse blank lines, normalise line endings to CRLF.

Does NOT change tokens. Verify with gsclex.py compare.

Usage: python gscfmt.py FILE [FILE...]
"""
import re
import sys

TRANSLIT = {
    "\xe4": "ae", "\xf6": "oe", "\xfc": "ue", "\xc4": "Ae", "\xd6": "Oe", "\xdc": "Ue",
    "\xdf": "ss", "\xb4": "'", "\x60": "`", "\xe9": "e", "\xe8": "e", "\xb0": " deg",
}

TAB = "\t"
CASE_OR_COMMENT_RE = re.compile(r"^\t*(case\b|default\s*:|//)")
CONTROL_RE = re.compile(r"^(if|else\s+if|while|for|foreach)\s*\(.*\)\s*$|^else\s*$")


def scan(line, in_block):
    """Split a line into (code_without_comments, in_block_after, opens_comment_tail).

    Returns the code part with strings blanked so brace/paren counting is safe.
    """
    out = []
    i, n = 0, len(line)
    while i < n:
        if in_block:
            j = line.find("*/", i)
            if j < 0:
                return "".join(out), True
            i = j + 2
            in_block = False
            continue
        c = line[i]
        if line.startswith("//", i):
            break
        if line.startswith("/*", i):
            in_block = True
            i += 2
            continue
        if c == '"':
            j = i + 1
            while j < n and line[j] != '"':
                if line[j] == "\\":
                    j += 1
                j += 1
            out.append('""')
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out), in_block


def translit_comment(text):
    """Transliterate non-ASCII characters, but only inside comments."""
    res, in_block, i, n = [], False, 0, len(text)
    while i < n:
        if in_block:
            j = text.find("*/", i)
            j = n if j < 0 else j + 2
            res.append("".join(TRANSLIT.get(ch, ch if ord(ch) < 128 else "?") for ch in text[i:j]))
            i = j
            in_block = False
            continue
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            res.append("".join(TRANSLIT.get(ch, ch if ord(ch) < 128 else "?") for ch in text[i:j]))
            i = j
            continue
        if text.startswith("/*", i):
            in_block = True
            continue
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\\":
                    j += 1
                j += 1
            res.append(text[i:j + 1])
            i = j + 1
            continue
        res.append(c)
        i += 1
    return "".join(res)


def fmt(src):
    src = src.replace("\r\n", "\n").replace("\r", "\n")
    src = translit_comment(src)
    lines = src.split("\n")
    out = []
    depth = 0          # brace depth
    paren = 0          # open parens carried over from previous lines
    pending = 0        # braceless control statements waiting for their body
    switch_stack = []  # brace depths that belong to switch blocks
    extra = []         # extra indent per open brace (e.g. "else" + "if(...)" + "{")
    next_is_switch = False
    in_block = False
    blank = 0
    fixed = set()

    for raw in lines:
        stripped = raw.strip()
        was_block = in_block
        if was_block:
            # Inside a multi-line /* */ comment: keep text, only trim the right side.
            code, in_block = scan(raw, True)
            out.append(raw.rstrip().replace("    ", "\t") if raw.strip() else "")
            continue
        if not stripped:
            blank += 1
            if blank <= 1:
                out.append("")
            continue
        blank = 0

        code, in_block = scan(stripped, False)
        code_s = code.strip()
        is_comment_only = code_s == ""

        lead_close = len(code_s) - len(code_s.lstrip("}"))
        ind = depth - lead_close + paren + sum(extra[:len(extra) - lead_close] if lead_close else extra)
        brace_extra = 0
        if code_s.startswith("{") and pending:
            brace_extra = pending - 1
            pending = 0
        ind += pending + brace_extra
        if switch_stack and switch_stack[-1] == depth and re.match(r"^(case\b|default\s*:)", code_s):
            ind -= 1
        # Function-level dev blocks /# #/ stay at column 0
        if code_s in ("/#", "#/"):
            ind = 0
        out.append("\t" * max(ind, 0) + stripped.rstrip())

        if is_comment_only:
            continue

        # Update state from this line's code
        if re.match(r"^switch\s*\(", code_s):
            next_is_switch = True
        for ch in code_s:
            if ch == "{":
                depth += 1
                extra.append(brace_extra)
                brace_extra = 0
                if next_is_switch:
                    switch_stack.append(depth)
                    next_is_switch = False
            elif ch == "}":
                if switch_stack and switch_stack[-1] == depth:
                    switch_stack.pop()
                depth -= 1
                if extra:
                    extra.pop()
            elif ch == "(":
                paren += 1
            elif ch == ")":
                paren -= 1
        paren = max(paren, 0)

        if paren == 0:
            if CONTROL_RE.match(code_s):
                pending += 1
            elif code_s.endswith(";") or code_s.endswith("}") or code_s.endswith("{"):
                pending = 0

    # Comments directly above a case label get the label's indentation.
    for k in range(len(out) - 2, -1, -1):
        cur, nxt = out[k].lstrip(TAB), out[k + 1]
        if cur.startswith("//") and CASE_OR_COMMENT_RE.match(nxt):
            nxt_s = nxt.lstrip(TAB)
            if nxt_s.startswith("case") or nxt_s.startswith("default") or (nxt_s.startswith("//") and k + 1 in fixed):
                out[k] = nxt[:len(nxt) - len(nxt_s)] + cur
                fixed.add(k)

    while out and out[-1] == "":
        out.pop()
    return "\r\n".join(out) + "\r\n", depth


def main(paths):
    for p in paths:
        with open(p, "rb") as f:
            src = f.read().decode("latin-1")
        new, depth = fmt(src)
        if depth != 0:
            print(f"WARN {p}: brace depth ends at {depth}")
        with open(p, "wb") as f:
            f.write(new.encode("latin-1"))


if __name__ == "__main__":
    main(sys.argv[1:])
