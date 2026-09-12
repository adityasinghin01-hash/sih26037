# Curate high-value IDD Detection subset for fast YOLOX training (~1 hour)
import os, sys, shutil, random
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

random.seed(42)

ann_dir = Path('C:/Users/admin/idd-detection/Annotations')
img_dir = Path('C:/Users/admin/idd-detection/JPEGImages')
out_dir = Path('C:/Users/admin/idd-curated')

out_ann = out_dir / 'Annotations'
out_img = out_dir / 'JPEGImages'
out_ann.mkdir(parents=True, exist_ok=True)
out_img.mkdir(parents=True, exist_ok=True)

FWD_DIRS = ['frontFar', 'frontNear', 'highquality_16k']
COW_ALIASES = {'animal', 'cattle', 'cow'}
AUTO_ALIASES = {'autorickshaw', 'auto-rickshaw', 'auto_rickshaw', 'auto rickshaw', 'rickshaw'}

print('Phase 1: Scanning forward cameras for target objects...')
cow_files = []
auto_by_clip = defaultdict(list)
other_by_clip = defaultdict(list)

for fwd in FWD_DIRS:
    d = ann_dir / fwd
    if not d.exists(): continue
    for x in d.rglob('*.xml'):
        try:
            tree = ET.parse(x)
            root = tree.getroot()
            objs = root.findall('object')
            if not objs: continue
            
            # Check corresponding image exists
            rel = x.relative_to(ann_dir)
            img_candidate = img_dir / rel.with_suffix('.jpg')
            if not img_candidate.exists():
                img_candidate = img_dir / rel.with_suffix('.png')
                if not img_candidate.exists():
                    continue

            has_c = any(o.find('name') is not None and o.find('name').text.strip().lower() in COW_ALIASES for o in objs)
            has_a = any(o.find('name') is not None and o.find('name').text.strip().lower() in AUTO_ALIASES for o in objs)
            
            clip_key = x.parent.name
            if has_c:
                cow_files.append((x, img_candidate, rel))
            elif has_a:
                auto_by_clip[clip_key].append((x, img_candidate, rel))
            else:
                other_by_clip[clip_key].append((x, img_candidate, rel))
        except:
            pass

print(f'Found {len(cow_files):,} cow frames.')
print(f'Found {sum(len(v) for v in auto_by_clip.values()):,} auto frames across {len(auto_by_clip)} clips.')
print(f'Found {sum(len(v) for v in other_by_clip.values()):,} other traffic frames across {len(other_by_clip)} clips.')

# Phase 2: Stratified Selection
selected = list(cow_files) # Take 100% of cow frames

# Select ~2,000 auto frames uniformly across clips
target_autos = 2000
auto_clips = list(auto_by_clip.keys())
per_clip_auto = max(1, target_autos // len(auto_clips))
for c in auto_clips:
    items = auto_by_clip[c]
    k = min(len(items), per_clip_auto)
    selected.extend(random.sample(items, k))

# Select ~1,000 other background frames uniformly across clips
target_others = 1000
other_clips = list(other_by_clip.keys())
per_clip_other = max(1, target_others // len(other_clips))
for c in other_clips:
    items = other_by_clip[c]
    k = min(len(items), per_clip_other)
    selected.extend(random.sample(items, k))

print(f'Total curated frames selected: {len(selected):,}')

# Phase 3: Create NTFS Hardlinks
print('Phase 3: Creating hardlinks in C:/Users/admin/idd-curated...')
linked = 0
for xml_src, img_src, rel in selected:
    xml_dst = out_ann / rel
    img_dst = out_img / rel.with_suffix(img_src.suffix)
    
    xml_dst.parent.mkdir(parents=True, exist_ok=True)
    img_dst.parent.mkdir(parents=True, exist_ok=True)
    
    if not xml_dst.exists():
        os.link(xml_src, xml_dst)
    if not img_dst.exists():
        os.link(img_src, img_dst)
    linked += 1

print(f'Successfully linked {linked:,} image-annotation pairs!')
