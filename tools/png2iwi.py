"""Convert PNG images to CoD2 textures: an IWI image plus its material (.tga).

For every <name>.png this writes, relative to the client folder:
    images/<name>.iwi                  DXT5 texture (version 5) with mipmaps
    materials/gfx/custom/<name>.tga    binary "2d" material that uses the image

The .tga in materials/ is not a TGA image but the compiled CoD2 material, named
after the original TGA source as the stock tools do. In menus/scripts the
material is referenced as "gfx/custom/<name>.tga".

If the material already exists it is used as template (keeping its blend and
sampler settings), only the names and the image size are rewritten. New
materials get the settings of the stock 2d HUD materials (alpha blended).

Without inputs all PNGs in material/src/hud/ (repo root) are converted.
Images are scaled to the nearest power of two per side unless --size is given.
The 2d HUD material blends premultiplied (the color is added regardless of alpha),
so the colors are stored multiplied with alpha: transparent pixels are black and
edges do not fray. Scaling and mipmaps are done in that space as well. Use
--straight for materials with normal alpha blending.

Requires Pillow (pip install pillow).

Usage:
    python tools/png2iwi.py [file.png | directory ...] [--client DIR] [--format dxt5|dxt1|argb32] [--size WxH] [--nomip] [--straight]
"""

import argparse
import struct
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops
except ImportError:
    sys.exit("Pillow is missing: pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
CLIENT = ROOT / "back2uo" / "z_back2uo_2.1_client"
SOURCE = ROOT / "material" / "src" / "hud"
MATERIAL_DIR = "gfx/custom"

FMT_ARGB32, FMT_DXT1, FMT_DXT5 = 0x01, 0x0B, 0x0D
FORMATS = {"argb32": FMT_ARGB32, "dxt1": FMT_DXT1, "dxt5": FMT_DXT5}
# IWI flags: 0x01 no picmip (never scaled down by r_picmip), 0x02 no mipmaps
FLAG_NOPICMIP, FLAG_NOMIP = 0x01, 0x02

# Material header bytes 0x08..0x50 of the stock 2d HUD materials (e.g. back2uo_logo.tga)
MATERIAL_TEMPLATE = bytes.fromhex(
    "00000000" "00030101" "000000000000" "2000" "ffff0700" "00000000"
    "0000000000000000" "01000000" "63895429" "04000000" "01000000"
    "50000000" "44000000" "50000000" "00000000" "00000000" "00000000"
)
MATERIAL_HEADER = 0x50
TECHNIQUE = b"2d\0"


# --- DXT compression -------------------------------------------------------

def rgb565(c):
    return ((c[0] >> 3) << 11) | ((c[1] >> 2) << 5) | (c[2] >> 3)


def expand565(v):
    r, g, b = (v >> 11) & 31, (v >> 5) & 63, v & 31
    return ((r << 3) | (r >> 2), (g << 2) | (g >> 4), (b << 3) | (b >> 2))


def dist2(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def color_endpoints(colors):
    """Endpoints along the principal axis of the block colors."""
    n = len(colors)
    mean = [sum(c[i] for c in colors) / n for i in range(3)]
    cov = [[0.0] * 3 for _ in range(3)]
    for c in colors:
        d = [c[0] - mean[0], c[1] - mean[1], c[2] - mean[2]]
        for i in range(3):
            for j in range(3):
                cov[i][j] += d[i] * d[j]
    axis = [1.0, 1.0, 1.0]
    for _ in range(8):
        axis = [sum(cov[i][j] * axis[j] for j in range(3)) for i in range(3)]
        norm = max(abs(a) for a in axis)
        if norm < 1e-9:
            return colors[0], colors[0]
        axis = [a / norm for a in axis]
    proj = [sum((c[i] - mean[i]) * axis[i] for i in range(3)) for c in colors]
    lo = colors[proj.index(min(proj))]
    hi = colors[proj.index(max(proj))]
    return hi, lo


def color_block(colors, mask=None):
    """8 byte DXT color block, always in 4 color mode (as DXT5 requires)."""
    used = [c for i, c in enumerate(colors) if mask is None or mask[i]] or colors
    hi, lo = color_endpoints(used)
    c0, c1 = rgb565(hi), rgb565(lo)
    if c0 < c1:
        c0, c1 = c1, c0
    if c0 == c1:
        return struct.pack("<HHI", c0, c1, 0)
    p0, p1 = expand565(c0), expand565(c1)
    palette = [p0, p1,
               tuple((2 * a + b) // 3 for a, b in zip(p0, p1)),
               tuple((a + 2 * b) // 3 for a, b in zip(p0, p1))]
    bits = 0
    for i, c in enumerate(colors):
        best = min(range(4), key=lambda k: dist2(c, palette[k]))
        bits |= best << (2 * i)
    return struct.pack("<HHI", c0, c1, bits)


def dxt1_block(colors, alphas):
    """DXT1 in 3 color mode when the block has transparent pixels (index 3 = transparent)."""
    opaque = [a >= 128 for a in alphas]
    if all(opaque):
        return color_block(colors)
    if not any(opaque):
        return struct.pack("<HHI", 0, 0xFFFF, 0xFFFFFFFF)
    hi, lo = color_endpoints([c for c, o in zip(colors, opaque) if o])
    c0, c1 = rgb565(hi), rgb565(lo)
    if c0 > c1:
        c0, c1 = c1, c0
    p0, p1 = expand565(c0), expand565(c1)
    palette = [p0, p1, tuple((a + b) // 2 for a, b in zip(p0, p1))]
    bits = 0
    for i, c in enumerate(colors):
        idx = min(range(3), key=lambda k: dist2(c, palette[k])) if opaque[i] else 3
        bits |= idx << (2 * i)
    return struct.pack("<HHI", c0, c1, bits)


def alpha_indices(alphas, palette):
    bits = err = 0
    for i, a in enumerate(alphas):
        best = min(range(len(palette)), key=lambda k: abs(a - palette[k]))
        bits |= best << (3 * i)
        err += (a - palette[best]) ** 2
    return bits, err


def alpha_block(alphas):
    """8 alpha mode (a0 > a1) or 6 alpha mode with exact 0 and 255, whichever fits better.
    The 6 alpha mode keeps soft edges next to fully opaque/transparent pixels precise."""
    a0, a1 = max(alphas), min(alphas)
    if a0 == a1:
        return struct.pack("<BB", a0, a1) + bytes(6)
    palette = [a0, a1] + [((8 - i) * a0 + (i - 1) * a1) // 7 for i in range(2, 8)]
    best = (*alpha_indices(alphas, palette), a0, a1)
    inner = [a for a in alphas if 0 < a < 255]
    if inner:
        b0, b1 = min(inner), max(inner)
        palette = [b0, b1] + [((6 - i) * b0 + (i - 1) * b1) // 5 for i in range(2, 6)] + [0, 255]
        bits, err = alpha_indices(alphas, palette)
        if err < best[1]:
            best = (bits, err, b0, b1)
    bits, _, a0, a1 = best
    return struct.pack("<BB", a0, a1) + bits.to_bytes(6, "little")


def compress(img, fmt):
    w, h = img.size
    px = img.tobytes()
    out = bytearray()
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            colors, alphas = [], []
            for y in range(4):
                for x in range(4):
                    o = (min(by + y, h - 1) * w + min(bx + x, w - 1)) * 4
                    colors.append((px[o], px[o + 1], px[o + 2]))
                    alphas.append(px[o + 3])
            if fmt == FMT_DXT5:
                # Straight alpha: fully transparent pixels do not need a matching color.
                # Premultiplied: they must stay black, so all pixels pick the endpoints.
                mask = [a > 0 for a in alphas] if img.mode == "RGBA" else None
                out += alpha_block(alphas) + color_block(colors, mask)
            else:
                out += dxt1_block(colors, alphas)
    return bytes(out)


def encode(img, fmt):
    """Pixel data of an "RGBA" (straight) or "RGBa" (premultiplied) image."""
    if fmt == FMT_ARGB32:
        r, g, b, a = img.split()
        return Image.merge("RGBA", (b, g, r, a)).tobytes()  # stored as BGRA
    return compress(img, fmt)


# --- IWI / material writers -------------------------------------------------

def mip_chain(img):
    levels = [img]
    while img.width > 1 or img.height > 1:
        img = img.resize((max(1, img.width // 2), max(1, img.height // 2)), Image.Resampling.BOX)
        levels.append(img)
    return levels


def build_iwi(img, fmt, mips):
    w, h = img.size
    levels = [encode(level, fmt) for level in (mip_chain(img) if mips else [img])]
    # HUD images are never scaled down by r_picmip, that would fray their edges
    flags = FLAG_NOPICMIP if mips else FLAG_NOPICMIP | FLAG_NOMIP
    data = b"".join(reversed(levels))  # smallest mip first, full size image at the end
    size = 28 + len(data)
    # File offsets where the first three levels start (the first one is the file end)
    offsets, end = [size], size
    for level in levels[:3]:
        end -= len(level)
        offsets.append(end)
    offsets = (offsets + [offsets[-1]] * 4)[:4] if mips else [size] * 4
    header = b"IWi" + struct.pack("<BBBHHH4I", 5, fmt, flags, w, h, 1, *offsets)
    return header + data


def build_material(name, width, height, template):
    material_name = f"{MATERIAL_DIR}/{name}.tga".encode() + b"\0"
    image_name = name.encode() + b"\0"
    name_off = MATERIAL_HEADER + len(TECHNIQUE)
    image_off = name_off + len(material_name)
    map_off = image_off + len(image_name)

    head = bytearray(template)
    struct.pack_into("<II", head, 0x00, name_off, image_off)
    struct.pack_into("<HH", head, 0x1C, width, height)
    struct.pack_into("<III", head, 0x38, MATERIAL_HEADER, 0x44, MATERIAL_HEADER)
    # Texture entry: name ("colorMap"), sampler state (from template), image name
    struct.pack_into("<I", head, 0x44, map_off)
    struct.pack_into("<I", head, 0x4C, image_off)
    return bytes(head) + TECHNIQUE + material_name + image_name + b"colorMap\0"


def material_template(path):
    if path.is_file():
        data = path.read_bytes()
        # Only reuse materials with the simple one texture "2d" layout written here
        if len(data) > MATERIAL_HEADER and data[MATERIAL_HEADER:MATERIAL_HEADER + 3] == TECHNIQUE:
            return data[:MATERIAL_HEADER]
    return bytes(8) + MATERIAL_TEMPLATE


def pow2(n):
    """Nearest power of two (on a log scale)."""
    lo = 1 << (n.bit_length() - 1)
    return lo if n * n < 2 * lo * lo else lo * 2


def parse_size(text):
    w, _, h = text.lower().partition("x")
    return int(w), int(h or w)


def convert(src, client, fmt, mips, size, straight):
    name = src.stem.lower()
    # "RGBa" = premultiplied; scaling, mipmaps and encoding then all work on premultiplied colors
    img = Image.open(src).convert("RGBA" if straight else "RGBa")
    w, h = size or (pow2(img.width), pow2(img.height))
    if (w, h) != img.size:
        print(f"{src.name}: scaling {img.width}x{img.height} -> {w}x{h}")
        img = img.resize((w, h), Image.Resampling.LANCZOS)
        if not straight:
            # Lanczos overshoots; a premultiplied color above its alpha would glow on screen
            r, g, b, a = img.split()
            img = Image.merge("RGBa", [ImageChops.darker(c, a) for c in (r, g, b)] + [a])
    if w & (w - 1) or h & (h - 1):
        print(f"{src}: WARNING {w}x{h} is not a power of two", file=sys.stderr)

    iwi = client / "images" / f"{name}.iwi"
    iwi.parent.mkdir(parents=True, exist_ok=True)
    iwi.write_bytes(build_iwi(img, fmt, mips))

    mat = client / "materials" / MATERIAL_DIR / f"{name}.tga"
    mat.parent.mkdir(parents=True, exist_ok=True)
    mat.write_bytes(build_material(name, w, h, material_template(mat)))
    print(f"{src.name} -> {iwi.relative_to(client)}, {mat.relative_to(client)} ({w}x{h})")


def collect(inputs):
    for item in inputs or [SOURCE]:
        p = Path(item)
        yield from sorted(p.glob("*.png")) if p.is_dir() else [p]


def main():
    ap = argparse.ArgumentParser(description="Convert PNG images to CoD2 IWI textures and materials")
    ap.add_argument("inputs", nargs="*", help="PNG files or directories (default: material/src/hud)")
    ap.add_argument("--client", type=Path, default=CLIENT, help="client folder (default: z_back2uo_2.1_client)")
    ap.add_argument("--format", choices=FORMATS, default="dxt5", help="texture format (default: dxt5)")
    ap.add_argument("--size", type=parse_size, help="scale to WxH or N (default: nearest power of two)")
    ap.add_argument("--nomip", action="store_true", help="no mipmaps, no picmip (sharp 1:1 HUD images)")
    ap.add_argument("--straight", action="store_true", help="straight instead of premultiplied alpha colors")
    args = ap.parse_args()

    failed = 0
    for src in collect(args.inputs):
        try:
            convert(src, args.client, FORMATS[args.format], not args.nomip, args.size, args.straight)
        except OSError as e:
            print(f"{src}: ERROR {e}", file=sys.stderr)
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
