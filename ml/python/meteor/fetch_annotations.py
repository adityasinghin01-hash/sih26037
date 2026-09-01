"""Fetch only METEOR's annotations, by HTTP range request.

The dataset is one 93.38 GB zip split into five chunks on HuggingFace. Its entries
are ordered by category, so the 2,502 annotation files are contiguous at the two
ends of the archive and can be pulled without touching the 91.57 GB of video.

    python ml/python/meteor/fetch_annotations.py --out /Volumes/DRIVE/meteor

Downloads ~1.81 GB, writes ~10.28 GB. Resumable: rerun it and it skips whatever
is already on disk with the right size. Every file is CRC-32 checked.
"""

from __future__ import annotations

import argparse
import struct
import sys
import urllib.request
import zlib
from pathlib import Path

BASE = "https://huggingface.co/datasets/XijunWang/METEOR/resolve/main/"

# Byte layout of the joined archive, measured 31 Aug 2026 from its central directory.
TOTAL = 93_382_246_900
CHUNKS: list[tuple[str, int, int]] = [
    ("chunk_aa", 0, 20_401_094_656),
    ("chunk_ab", 20_401_094_656, 40_802_189_312),
    ("chunk_ac", 40_802_189_312, 61_203_283_968),
    ("chunk_ad", 61_203_283_968, 81_604_378_624),
    ("chunk_ae", 81_604_378_624, 93_382_246_900),
]


def _get(chunk: str, start: int, end: int) -> bytes:
    """Range-fetch [start, end] inclusive, as offsets within one chunk file."""
    req = urllib.request.Request(
        BASE + chunk,
        headers={"Range": f"bytes={start}-{end}", "User-Agent": "sih26037/1.0"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read()


def _read(offset_abs: int, length: int) -> bytes:
    """Read `length` bytes from absolute offset in the joined archive."""
    out = bytearray()
    while length > 0:
        for name, lo, hi in CHUNKS:
            if lo <= offset_abs < hi:
                take = min(length, hi - offset_abs)
                out += _get(name, offset_abs - lo, offset_abs - lo + take - 1)
                offset_abs += take
                length -= take
                break
        else:
            raise RuntimeError(f"offset {offset_abs} is outside the archive")
    return bytes(out)


def central_directory() -> list[tuple[str, int, int, int, int, int]]:
    """Parse the Zip64 central directory. Returns (name, offset, csize, usize, method, crc)."""
    tail_len = 2_000_000
    tail = _read(TOTAL - tail_len, tail_len)
    j = tail.rfind(b"PK\x06\x06")
    if j < 0:
        raise RuntimeError("no Zip64 end-of-central-directory record found")
    cd_size = struct.unpack("<Q", tail[j + 40 : j + 48])[0]
    cd_off = struct.unpack("<Q", tail[j + 48 : j + 56])[0]
    cd = _read(cd_off, cd_size)

    entries, p = [], 0
    while p + 46 <= len(cd) and cd[p : p + 4] == b"PK\x01\x02":
        method = struct.unpack("<H", cd[p + 10 : p + 12])[0]
        crc = struct.unpack("<I", cd[p + 16 : p + 20])[0]
        csize, usize = struct.unpack("<II", cd[p + 20 : p + 28])
        nlen, elen, clen = struct.unpack("<HHH", cd[p + 28 : p + 34])
        lho = struct.unpack("<I", cd[p + 42 : p + 46])[0]
        name = cd[p + 46 : p + 46 + nlen].decode("utf-8", "replace")
        extra = cd[p + 46 + nlen : p + 46 + nlen + elen]
        if 0xFFFFFFFF in (usize, csize, lho):  # Zip64 extended information
            q = 0
            while q + 4 <= len(extra):
                hid, hsz = struct.unpack("<HH", extra[q : q + 4])
                if hid == 1:
                    v, k = extra[q + 4 : q + 4 + hsz], 0
                    if usize == 0xFFFFFFFF:
                        usize = struct.unpack("<Q", v[k : k + 8])[0]; k += 8
                    if csize == 0xFFFFFFFF:
                        csize = struct.unpack("<Q", v[k : k + 8])[0]; k += 8
                    if lho == 0xFFFFFFFF:
                        lho = struct.unpack("<Q", v[k : k + 8])[0]
                    break
                q += 4 + hsz
        entries.append((name, lho, csize, usize, method, crc))
        p += 46 + nlen + elen + clen
    return entries


def fetch(entry: tuple[str, int, int, int, int, int], out_dir: Path) -> str:
    """Fetch one member and write it under out_dir. Returns 'skip', 'ok' or an error string."""
    name, lho, csize, usize, method, crc = entry
    dest = out_dir / name
    if dest.exists() and dest.stat().st_size == usize:
        return "skip"

    # Local headers in this archive use data descriptors, so their size fields are
    # zero — sizes must come from the central directory. Only the name/extra
    # lengths are trustworthy here, and they give us where the data starts.
    head = _read(lho, 512)
    if head[:4] != b"PK\x03\x04":
        return f"bad local header at {lho}"
    nlen, elen = struct.unpack("<HH", head[26:30])
    blob = _read(lho + 30 + nlen + elen, csize)

    data = zlib.decompress(blob, -15) if method == 8 else blob
    if len(data) != usize:
        return f"size mismatch: got {len(data)}, expected {usize}"
    if zlib.crc32(data) != crc:
        return "CRC mismatch"

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    return "ok"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, required=True, help="target directory (e.g. the drive)")
    ap.add_argument("--videos", type=int, default=0, help="also fetch this many sample .MP4 clips")
    ap.add_argument("--limit", type=int, default=0, help="stop after N files (for a quick test)")
    args = ap.parse_args()

    print("reading the central directory ...", flush=True)
    entries = central_directory()
    ann = [e for e in entries if "XML Annotations" in e[0] and not e[0].endswith("/")]
    vids = sorted((e for e in entries if e[0].endswith(".MP4")), key=lambda e: e[2])[: args.videos]
    todo = ann + vids
    if args.limit:
        todo = todo[: args.limit]

    dl = sum(e[2] for e in todo) / 1e9
    ex = sum(e[3] for e in todo) / 1e9
    print(f"{len(todo):,} files — {dl:.2f} GB to download, {ex:.2f} GB on disk")
    args.out.mkdir(parents=True, exist_ok=True)

    done = skipped = 0
    failures: list[str] = []
    for i, e in enumerate(todo, 1):
        try:
            r = fetch(e, args.out)
        except Exception as exc:  # noqa: BLE001 — one bad file must not stop 2,502
            r = f"{type(exc).__name__}: {exc}"
        if r == "ok":
            done += 1
        elif r == "skip":
            skipped += 1
        else:
            failures.append(f"{e[0]}: {r}")
        if i % 25 == 0 or i == len(todo):
            print(f"  [{i:>5}/{len(todo)}] fetched={done} skipped={skipped} failed={len(failures)}",
                  flush=True)

    print(f"\ndone. fetched={done} skipped={skipped} failed={len(failures)} -> {args.out}")
    for f in failures[:20]:
        print("  FAILED", f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
