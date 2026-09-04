import sys, struct, io, os
from mzip import read, central_directory

name_want = sys.argv[1]
out = sys.argv[2]

ents = central_directory()
e = next((x for x in ents if x["name"].endswith(name_want)), None)
if not e: raise SystemExit(f"not found: {name_want}")
print(f"{e['name']}  csize={e['csize']/1e6:.1f}MB usize={e['usize']/1e6:.1f}MB")

# local header: sig(4) ver(2) flag(2) method(2) time(2) date(2) crc(4) csize(4) usize(4) nlen(2) elen(2)
lh = read(e["lho"], 30)
if lh[:4] != b"PK\x03\x04": raise SystemExit("bad local header")
method = struct.unpack_from("<H", lh, 8)[0]
nlen, elen = struct.unpack_from("<HH", lh, 26)
data_at = e["lho"] + 30 + nlen + elen
print(f"method={method} ({'stored' if method==0 else 'deflated'})  data at {data_at}")

blob = read(data_at, e["csize"])
if method != 0:
    import zlib
    blob = zlib.decompress(blob, -15)
open(out,"wb").write(blob)
print(f"wrote {out}  {os.path.getsize(out)/1e6:.1f} MB")
