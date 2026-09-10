# Component 4 (Buildings) prerequisite: real building footprints, not invented ones - same
# principle as pull_rail.py's rail pull. Same origin/projection so it lands in the same frame.
import urllib.request, urllib.parse, json, math, os
LAT0, LON0 = 29.61180, 78.34210
R = 6371000.0
def proj(lat, lon):
    x = math.radians(lon - LON0) * math.cos(math.radians(LAT0)) * R
    y = math.radians(lat - LAT0) * R
    return (round(x,2), round(y,2))
dlat = 1600.0 / (math.pi/180 * R)
dlon = 1600.0 / (math.pi/180 * R * math.cos(math.radians(LAT0)))
S,N,W,E = LAT0-dlat, LAT0+dlat, LON0-dlon, LON0+dlon
q = f"""[out:json][timeout:180];
(
  way["building"]({S},{W},{N},{E});
  way["shop"]({S},{W},{N},{E});
  way["amenity"="place_of_worship"]({S},{W},{N},{E});
  node["amenity"="place_of_worship"]({S},{W},{N},{E});
  way["landuse"]({S},{W},{N},{E});
);
(._;>;);
out body;"""
print("querying overpass for building footprints...")
req = urllib.request.Request("https://overpass-api.de/api/interpreter",
      data=urllib.parse.urlencode({"data":q}).encode(),
      headers={"User-Agent":"SIH26037-student-project"})
raw = json.load(urllib.request.urlopen(req, timeout=240))
nodes = {e["id"]:(e["lat"],e["lon"]) for e in raw["elements"] if e["type"]=="node"}
buildings, shrine_pois, zones = [], [], []
for e in raw["elements"]:
    if e["type"] == "node" and e.get("tags", {}).get("amenity") == "place_of_worship":
        la, lo = e["lat"], e["lon"]
        shrine_pois.append({"religion": e["tags"].get("religion",""),
                             "name": e["tags"].get("name",""), "pt": proj(la, lo)})
    if e["type"] != "way": continue
    t = e.get("tags", {})
    pts = [proj(*nodes[n]) for n in e["nodes"] if n in nodes]
    if len(pts) < 3: continue
    if pts[0] == pts[-1]: pts = pts[:-1]   # closed way, drop the duplicate closing vertex
    if "landuse" in t:
        zones.append({"landuse": t["landuse"], "name": t.get("name",""), "pts": pts})
        continue
    if "building" not in t and "shop" not in t and t.get("amenity") != "place_of_worship":
        continue
    buildings.append({
        "building": t.get("building", ""), "shop": t.get("shop", ""),
        "amenity": t.get("amenity", ""), "name": t.get("name", ""),
        "levels": t.get("building:levels", ""), "religion": t.get("religion", ""),
        "pts": pts,
    })
out = {"origin": [LAT0, LON0], "buildings": buildings, "shrine_pois": shrine_pois, "zones": zones}
json.dump(out, open(os.path.join(os.path.dirname(__file__), "najibabad_buildings.json"), "w"))

def area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1,y1 = pts[i]; x2,y2 = pts[(i+1) % len(pts)]
        a += x1*y2 - x2*y1
    return abs(a) / 2.0
def inside_box(pts, H=1000.0):
    return all(max(abs(x),abs(y)) <= H for x,y in pts)

n_inbox = sum(1 for b in buildings if inside_box(b["pts"]))
areas = [area(b["pts"]) for b in buildings if inside_box(b["pts"])]
print(f"ways: {len(buildings)} total, {n_inbox} inside the 2 km box")
if areas:
    areas.sort()
    print(f"  footprint area: min {areas[0]:.0f} m^2  median {areas[len(areas)//2]:.0f} m^2  "
          f"max {areas[-1]:.0f} m^2")
from collections import Counter
print("by building tag:", dict(Counter(b['building'] for b in buildings if b['building'])))
print("by shop tag:", dict(Counter(b['shop'] for b in buildings if b['shop'])))
print("with building:levels tag:", sum(1 for b in buildings if b['levels']))
print(f"\nplace_of_worship: {len(shrine_pois)} node POIs + "
      f"{sum(1 for b in buildings if b['amenity']=='place_of_worship')} way footprints")
for p in shrine_pois[:10]:
    print(f"  node  {p['religion'][:12]:12s} {p['name'][:28]:28s} at ({p['pt'][0]:8.0f},{p['pt'][1]:8.0f})")

print(f"\nlanduse zones: {len(zones)}")
print("by landuse tag:", dict(Counter(z['landuse'] for z in zones)))
for z in zones:
    if not inside_box(z["pts"]): continue
    xs=[p[0] for p in z["pts"]]; ys=[p[1] for p in z["pts"]]
    print(f"  {z['landuse']:12s} {z['name'][:20]:20s} area {area(z['pts']):8.0f} m^2  "
          f"x {min(xs):7.0f}..{max(xs):7.0f}  y {min(ys):7.0f}..{max(ys):7.0f}")
