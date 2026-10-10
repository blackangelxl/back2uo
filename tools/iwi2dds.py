"""Convert Call of Duty IWI textures (version 5, CoD1/UO/CoD2) to DDS.

Usage:
    python tools/iwi2dds.py <file.iwi | directory> [...] [-o OUTDIR] [-r]

Without -o the .dds is written next to the source file.
"""

import argparse
import struct
import sys
from pathlib import Path

HEADER_SIZE = 28
FLAG_NOMIP = 0x02

# IWI format byte -> (name, bytes per 4x4 block or None, bytes per pixel or None)
FORMATS = {
    0x01: ("ARGB32", None, 4),
    0x02: ("RGB24", None, 3),
    0x03: ("GA16", None, 2),
    0x04: ("A8", None, 1),
    0x0B: ("DXT1", 8, None),
    0x0C: ("DXT3", 16, None),
    0x0D: ("DXT5", 16, None),
}

# DDS constants
DDSD_CAPS, DDSD_HEIGHT, DDSD_WIDTH, DDSD_PITCH = 0x1, 0x2, 0x4, 0x8
DDSD_PIXELFORMAT, DDSD_MIPMAPCOUNT, DDSD_LINEARSIZE = 0x1000, 0x20000, 0x80000
DDPF_ALPHAPIXELS, DDPF_ALPHA, DDPF_FOURCC, DDPF_RGB, DDPF_LUMINANCE = 0x1, 0x2, 0x4, 0x40, 0x20000
DDSCAPS_COMPLEX, DDSCAPS_TEXTURE, DDSCAPS_MIPMAP = 0x8, 0x1000, 0x400000


def mip_size(fmt, w, h):
    _, block, bpp = FORMATS[fmt]
    if block:
        return max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * block
    return w * h * bpp


def mip_chain(w, h):
    dims = [(w, h)]
    while w > 1 or h > 1:
        w, h = max(1, w // 2), max(1, h // 2)
        dims.append((w, h))
    return dims


def read_iwi(path):
    data = path.read_bytes()
    if len(data) < HEADER_SIZE or data[:3] != b"IWi":
        raise ValueError("not an IWI file")
    version, fmt, flags = data[3], data[4], data[5]
    if version != 5:
        raise ValueError(f"unsupported IWI version {version} (only 5)")
    if fmt not in FORMATS:
        raise ValueError(f"unknown format 0x{fmt:02X}")
    width, height, _depth = struct.unpack_from("<HHH", data, 6)

    pixels = data[HEADER_SIZE:]
    dims = mip_chain(width, height)
    sizes = [mip_size(fmt, w, h) for w, h in dims]

    if flags & FLAG_NOMIP or len(pixels) < sum(sizes):
        # Single level, stored right after the header
        if len(pixels) < sizes[0]:
            raise ValueError("file truncated")
        return fmt, width, height, [pixels[: sizes[0]]]

    # Mips are stored smallest first, largest level ends at end of data
    total = sum(sizes)
    pixels = pixels[len(pixels) - total:]
    levels, end = [], len(pixels)
    for size in sizes:
        levels.append(pixels[end - size: end])
        end -= size
    return fmt, width, height, levels


def dds_header(fmt, width, height, mip_count):
    name, block, bpp = FORMATS[fmt]
    flags = DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT
    caps = DDSCAPS_TEXTURE
    if mip_count > 1:
        flags |= DDSD_MIPMAPCOUNT
        caps |= DDSCAPS_COMPLEX | DDSCAPS_MIPMAP

    if block:
        flags |= DDSD_LINEARSIZE
        pitch = mip_size(fmt, width, height)
        pf = struct.pack("<II4sIIIII", 32, DDPF_FOURCC, name.encode(), 0, 0, 0, 0, 0)
    else:
        flags |= DDSD_PITCH
        pitch = width * bpp
        if fmt == 0x01:  # A8R8G8B8
            pf_flags, masks = DDPF_RGB | DDPF_ALPHAPIXELS, (0xFF0000, 0xFF00, 0xFF, 0xFF000000)
        elif fmt == 0x02:  # R8G8B8
            pf_flags, masks = DDPF_RGB, (0xFF0000, 0xFF00, 0xFF, 0)
        elif fmt == 0x03:  # A8L8
            pf_flags, masks = DDPF_LUMINANCE | DDPF_ALPHAPIXELS, (0xFF, 0, 0, 0xFF00)
        else:  # A8
            pf_flags, masks = DDPF_ALPHA, (0, 0, 0, 0xFF)
        pf = struct.pack("<II4sIIIII", 32, pf_flags, b"\0" * 4, bpp * 8, *masks)

    header = struct.pack("<4sIIIIIII", b"DDS ", 124, flags, height, width, pitch, 0, mip_count)
    header += b"\0" * 44  # dwReserved1[11]
    header += pf
    header += struct.pack("<IIIII", caps, 0, 0, 0, 0)
    return header


def convert(src, dst):
    fmt, width, height, levels = read_iwi(src)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(dds_header(fmt, width, height, len(levels)) + b"".join(levels))
    print(f"{src} -> {dst} ({FORMATS[fmt][0]} {width}x{height}, {len(levels)} mips)")


def collect(inputs, recursive):
    for item in inputs:
        p = Path(item)
        if p.is_dir():
            yield from (p.rglob("*.iwi") if recursive else p.glob("*.iwi"))
        else:
            yield p


def main():
    ap = argparse.ArgumentParser(description="Convert IWI textures to DDS")
    ap.add_argument("inputs", nargs="+", help="IWI files or directories")
    ap.add_argument("-o", "--outdir", type=Path, help="output directory")
    ap.add_argument("-r", "--recursive", action="store_true", help="search directories recursively")
    args = ap.parse_args()

    failed = 0
    for src in collect(args.inputs, args.recursive):
        dst = (args.outdir / src.name if args.outdir else src).with_suffix(".dds")
        try:
            convert(src, dst)
        except (OSError, ValueError) as e:
            print(f"{src}: ERROR {e}", file=sys.stderr)
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
