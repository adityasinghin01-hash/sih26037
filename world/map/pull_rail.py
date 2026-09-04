# Re-pull the railway. It was queried once but NEVER SAVED - map/ has no rail file.
# Same origin and projection as najibabad_metres.json so it lands in the same frame.
import urllib.request, urllib.parse, json, math, os
LAT0, LON0 = 29.61180, 78.34210
R = 6371000.0
def proj(lat, lon):
    x = math.radians(lon - LON0) * math.cos(math.radians(LAT0)) * R
    y = math.radians(lat - LAT0) * R
    return (round(x,2), round(y,2))
# 1.6 km half-box so lines continue past the 1 km world edge
dlat = 1600.0 / (math.pi/180 * R)
dlon = 1600.0 / (math.pi/180 * R * math.cos(math.radians(LAT0)))
S,N,W,E = LAT0-dlat, LAT0+dlat, LON0-dlon, LON0+dlon
q = f"""[out:json][timeout:120];
(
  way["railway"]({S},{W},{N},{E});
  node["railway"="level_crossing"]({S},{W},{N},{E});
  node["railway"="station"]({S},{W},{N},{E});
  node["railway"="halt"]({S},{W},{N},{E});
  way["landuse"="railway"]({S},{W},{N},{E});
);
(._;>;);
out body;"""
print("querying overpass...")
req = urllib.request.Request("https://overpass-api.de/api/interpreter",
      data=urllib.parse.urlencode({"data":q}).encode(),
      headers={"User-Agent":"SIH26037-student-project"})
raw = json.load(urllib.request.urlopen(req, timeout=180))
nodes = {e["id"]:(e["lat"],e["lon"]) for e in raw["elements"] if e["type"]=="node"}
rails, pois, areas = [], [], []
for e in raw["elements"]:
    if e["type"]=="node" and e.get("tags",{}).get("railway") in ("level_crossing","station","halt"):
        la,lo = e["lat"], e["lon"]
        pois.append({"kind":e["tags"]["railway"], "name":e["tags"].get("name",""),
                     "ref":e["tags"].get("railway:ref") or e["tags"].get("ref",""), "pt":proj(la,lo)})
    if e["type"]!="way": continue
    t = e.get("tags",{})
    pts = [proj(*nodes[n]) for n in e["nodes"] if n in nodes]
    if len(pts) < 2: continue
    if t.get("landuse")=="railway":
        areas.append({"name":t.get("name",""), "pts":pts}); continue
    if "railway" not in t: continue
    rails.append({"railway":t["railway"], "usage":t.get("usage",""), "name":t.get("name",""),
                  "electrified":t.get("electrified",""), "voltage":t.get("voltage",""),
                  "gauge":t.get("gauge",""), "bridge":bool(t.get("bridge")),
                  "service":t.get("service",""), "pts":pts})
out = {"origin":[LAT0,LON0], "rails":rails, "pois":pois, "areas":areas}
json.dump(out, open("najibabad_rail.json","w"))
def L(p):
    return sum(math.dist(p[i],p[i+1]) for i in range(len(p)-1))
def clipL(p, H=1000.0):
    t=0.0
    for i in range(len(p)-1):
        a,b=p[i],p[i+1]
        if max(abs(a[0]),abs(a[1]))<=H and max(abs(b[0]),abs(b[1]))<=H: t+=math.dist(a,b)
    return t
tot = sum(L(r["pts"]) for r in rails)
inbox = sum(clipL(r["pts"]) for r in rails)
print(f"ways: {len(rails)}   total {tot:.0f} m   inside 2 km box {inbox:.0f} m")
from collections import Counter
print("by railway tag:", dict(Counter(r['railway'] for r in rails)))
print("by service tag:", dict(Counter(r['service'] for r in rails if r['service'])))
print("electrified:", dict(Counter(r['electrified'] for r in rails if r['electrified'])))
print("bridge ways:", sum(1 for r in rails if r["bridge"]))
print("\nPOIs:")
for p in pois: print(f"  {p['kind']:16s} {p['name'][:28]:28s} ref={p['ref']:6s} at ({p['pt'][0]:8.0f},{p['pt'][1]:8.0f})")
print("\nlanduse=railway polygons:", len(areas))
for a in areas[:4]:
    xs=[p[0] for p in a["pts"]]; ys=[p[1] for p in a["pts"]]
    print(f"  {a['name'][:24]:24s} x {min(xs):7.0f}..{max(xs):7.0f}  y {min(ys):7.0f}..{max(ys):7.0f}")
