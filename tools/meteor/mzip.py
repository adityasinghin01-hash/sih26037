"""Range-read the METEOR split zip on HuggingFace without downloading it."""
import urllib.request, struct, io, sys

BASE = "https://huggingface.co/datasets/XijunWang/METEOR/resolve/main/chunk_"
CHUNKS = [("aa",20401094656),("ab",20401094656),("ac",20401094656),
          ("ad",20401094656),("ae",11777868276)]
TOTAL = sum(s for _,s in CHUNKS)

_starts=[]; _o=0
for name,size in CHUNKS:
    _starts.append((_o,_o+size,name)); _o+=size

def read(offset, length):
    """Read `length` bytes at virtual `offset`, spanning chunk boundaries."""
    out=io.BytesIO(); need=length; pos=offset
    while need>0:
        for s,e,name in _starts:
            if s<=pos<e:
                take=min(need, e-pos)
                req=urllib.request.Request(BASE+name,
                    headers={"Range":f"bytes={pos-s}-{pos-s+take-1}"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    data=r.read()
                out.write(data); pos+=len(data); need-=len(data)
                break
        else:
            break
    return out.getvalue()

def central_directory():
    """Locate and parse the zip central directory. Returns list of entries."""
    tail = read(TOTAL-2_000_000, 2_000_000)
    i = tail.rfind(b"PK\x06\x06")                     # Zip64 EOCD
    if i < 0: raise SystemExit("no Zip64 EOCD found")
    cd_entries = struct.unpack_from("<Q", tail, i+32)[0]
    cd_size    = struct.unpack_from("<Q", tail, i+40)[0]
    cd_offset  = struct.unpack_from("<Q", tail, i+48)[0]
    print(f"central directory: {cd_entries} entries, {cd_size/1e6:.1f} MB at offset {cd_offset}",
          file=sys.stderr)
    cd = read(cd_offset, cd_size)
    entries=[]; p=0
    while p < len(cd)-4 and cd[p:p+4]==b"PK\x01\x02":
        csize, usize = struct.unpack_from("<II", cd, p+20)
        nlen, elen, clen = struct.unpack_from("<HHH", cd, p+28)
        lho = struct.unpack_from("<I", cd, p+42)[0]
        name = cd[p+46:p+46+nlen].decode("utf-8","replace")
        ex = cd[p+46+nlen : p+46+nlen+elen]
        # Zip64 extra field overrides the 0xFFFFFFFF placeholders
        q=0
        while q < len(ex)-3:
            hid, hsz = struct.unpack_from("<HH", ex, q)
            if hid==0x0001:
                vals=[]; r=q+4
                for placeholder,_ in ((usize,0),(csize,0),(lho,0)):
                    if placeholder==0xFFFFFFFF and r+8<=q+4+hsz:
                        vals.append(struct.unpack_from("<Q", ex, r)[0]); r+=8
                    else:
                        vals.append(None)
                if vals[0] is not None: usize=vals[0]
                if vals[1] is not None: csize=vals[1]
                if vals[2] is not None: lho=vals[2]
                break
            q += 4+hsz
        entries.append(dict(name=name, csize=csize, usize=usize, lho=lho))
        p += 46+nlen+elen+clen
    return entries

if __name__=="__main__":
    e = central_directory()
    print(f"parsed {len(e)} entries")
    vids=[x for x in e if x["name"].lower().endswith((".mp4",".mov",".avi"))]
    print(f"video entries: {len(vids)}")
    for v in vids[:5]:
        print(f"  {v['name']}  {v['csize']/1e6:.1f} MB  @ {v['lho']}")
