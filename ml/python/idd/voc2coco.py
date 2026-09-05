"""Convert IDD Detection Pascal-VOC XML annotations to COCO JSON format for YOLOX.

Maps IDD class vocabulary directly to the frozen S5 contract (AGENTS.md Section 3).
Operates recursively across IDD clip subdirectories.
Splits images into train and validation sets with user-configurable ratio.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# Frozen Contract S5 Class definitions (1-indexed for COCO categories)
S5_CATEGORIES: List[Dict[str, Any]] = [
    {"id": 1, "name": "car", "supercategory": "vehicle"},
    {"id": 2, "name": "truck", "supercategory": "vehicle"},
    {"id": 3, "name": "bus", "supercategory": "vehicle"},
    {"id": 4, "name": "auto-rickshaw", "supercategory": "vehicle"},
    {"id": 5, "name": "motorbike", "supercategory": "vehicle"},
    {"id": 6, "name": "scooter", "supercategory": "vehicle"},
    {"id": 7, "name": "van", "supercategory": "vehicle"},
    {"id": 8, "name": "pedestrian", "supercategory": "human"},
    {"id": 9, "name": "bicycle", "supercategory": "cycle"},
    {"id": 10, "name": "cow", "supercategory": "animal"},
    {"id": 11, "name": "dog", "supercategory": "animal"},
    {"id": 12, "name": "pushcart", "supercategory": "cart"},
    {"id": 13, "name": "animal-drawn cart", "supercategory": "cart"},
    {"id": 14, "name": "tractor", "supercategory": "vehicle"},
    {"id": 15, "name": "static obstacle", "supercategory": "obstacle"},
]

S5_NAME_TO_ID: Dict[str, int] = {cat["name"]: cat["id"] for cat in S5_CATEGORIES}

# IDD vocabulary spelling -> S5 canonical name
# Matches matlab/+sih/+models/readDetectionData.m alias table exactly
ALIAS_MAP: Dict[str, str] = {
    "autorickshaw": "auto-rickshaw",
    "auto rickshaw": "auto-rickshaw",
    "auto_rickshaw": "auto-rickshaw",
    "rickshaw": "auto-rickshaw",
    "motorcycle": "motorbike",
    "bike": "motorbike",
    "person": "pedestrian",
    "animal": "cow",
    "cattle": "cow",
    "traffic sign": "static obstacle",
    "trafficsign": "static obstacle",
    "caravan": "van",
    "trailer": "truck",
    "cart": "pushcart",
}

# Deliberately dropped classes (never taught as something they are not)
# "vehicle fallback" -> unusual vehicle, not a static obstacle
# "rider"            -> person on two-wheeler; folding into motorbike double-counts
IGNORED_CLASSES = {"vehicle fallback", "rider", "traffic light", "train"}


def map_class_name(raw_name: str) -> Optional[str]:
    """Map raw IDD class name to S5 canonical name, or return None if dropped."""
    clean = raw_name.strip().lower()
    if clean in IGNORED_CLASSES:
        return None
    mapped = ALIAS_MAP.get(clean, clean)
    if mapped in S5_NAME_TO_ID:
        return mapped
    return None


def find_image_file(img_dir: Path, rel_stem: Path) -> Optional[Path]:
    """Find matching image file in img_dir with common extensions."""
    for ext in (".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"):
        candidate = img_dir / rel_stem.with_suffix(ext)
        if candidate.is_file():
            return candidate
    return None


def parse_voc_xml(
    xml_path: Path,
    ann_dir: Path,
    img_dir: Path,
) -> Optional[Tuple[Dict[str, Any], List[Dict[str, Any]], Counter]]:
    """Parse a single Pascal-VOC XML file and return image and annotation dicts."""
    dropped_counter: Counter = Counter()

    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
    except Exception:
        return None

    objects = root.findall("object")
    if not objects:
        return None

    # Compute relative path from annotation root
    try:
        rel_path = xml_path.relative_to(ann_dir)
    except ValueError:
        rel_path = Path(xml_path.name)
    rel_stem = rel_path.with_suffix("")

    img_file = find_image_file(img_dir, rel_stem)
    if img_file is None:
        return None

    # Relative path from img_dir for storage in COCO json
    try:
        stored_rel_path = img_file.relative_to(img_dir).as_posix()
    except ValueError:
        stored_rel_path = img_file.name

    # Image dimensions
    width = 0
    height = 0
    size_elem = root.find("size")
    if size_elem is not None:
        w_elem = size_elem.find("width")
        h_elem = size_elem.find("height")
        if w_elem is not None and w_elem.text:
            try:
                width = int(float(w_elem.text.strip()))
            except ValueError:
                pass
        if h_elem is not None and h_elem.text:
            try:
                height = int(float(h_elem.text.strip()))
            except ValueError:
                pass

    if (width <= 0 or height <= 0) and HAS_PIL:
        try:
            with Image.open(img_file) as im:
                width, height = im.size
        except Exception:
            pass

    if width <= 0 or height <= 0:
        # Fallback to standard 1080p if unreadable
        width, height = 1920, 1080

    image_info = {
        "file_name": stored_rel_path,
        "width": width,
        "height": height,
    }

    parsed_boxes: List[Dict[str, Any]] = []
    for obj in objects:
        name_elem = obj.find("name")
        if name_elem is None or not name_elem.text:
            continue
        raw_name = name_elem.text.strip()
        canonical_name = map_class_name(raw_name)
        if canonical_name is None:
            dropped_counter[raw_name] += 1
            continue

        bndbox = obj.find("bndbox")
        if bndbox is None:
            continue

        try:
            xmin = float(bndbox.findtext("xmin", "0"))
            ymin = float(bndbox.findtext("ymin", "0"))
            xmax = float(bndbox.findtext("xmax", "0"))
            ymax = float(bndbox.findtext("ymax", "0"))
        except ValueError:
            continue

        # Clamp and validate bounding box
        xmin = max(0.0, xmin)
        ymin = max(0.0, ymin)
        xmax = min(float(width), xmax)
        ymax = min(float(height), ymax)
        box_w = xmax - xmin
        box_h = ymax - ymin

        if box_w <= 1.0 or box_h <= 1.0:
            continue

        category_id = S5_NAME_TO_ID[canonical_name]
        area = round(box_w * box_h, 2)
        parsed_boxes.append({
            "category_id": category_id,
            "bbox": [round(xmin, 2), round(ymin, 2), round(box_w, 2), round(box_h, 2)],
            "area": area,
            "iscrowd": 0,
            "segmentation": [],
        })

    if not parsed_boxes:
        return None

    return image_info, parsed_boxes, dropped_counter


def resolve_dir_alias(base: Path, candidate_names: List[str]) -> Path:
    """Find the first existing directory matching any candidate name (case-insensitive)."""
    if base.is_dir():
        return base
    parent = base.parent
    if parent.is_dir():
        for item in parent.iterdir():
            if item.is_dir() and item.name.lower() in [c.lower() for c in candidate_names]:
                return item
    return base


def convert_voc_to_coco(
    ann_dir: Path,
    img_dir: Path,
    output_dir: Path,
    train_ratio: float = 0.8,
    seed: int = 42,
) -> Tuple[int, int, int]:
    """Convert dataset from Pascal VOC XML to COCO JSON format.

    Returns:
        Tuple of (num_train_images, num_val_images, num_total_annotations)
    """
    # Auto-resolve casing variations
    ann_dir = resolve_dir_alias(ann_dir, ["annotations", "Annotations", "ann"])
    img_dir = resolve_dir_alias(img_dir, ["jpegimages", "JPEGImages", "images", "img"])

    if not ann_dir.is_dir():
        raise FileNotFoundError(f"Annotations directory not found: {ann_dir}")
    if not img_dir.is_dir():
        raise FileNotFoundError(f"Images directory not found: {img_dir}")

    print(f"Scanning annotations in: {ann_dir}")
    print(f"Matching images in:      {img_dir}")

    xml_files = sorted(list(ann_dir.rglob("*.xml")))
    print(f"Found {len(xml_files):,} XML annotation files.")

    total_dropped: Counter = Counter()
    class_box_counts: Counter = Counter()
    dataset_records: List[Tuple[Dict[str, Any], List[Dict[str, Any]]]] = []

    for idx, xml_path in enumerate(xml_files):
        parsed = parse_voc_xml(xml_path, ann_dir, img_dir)
        if parsed is None:
            continue
        img_info, boxes, dropped = parsed
        total_dropped.update(dropped)
        for b in boxes:
            class_box_counts[b["category_id"]] += 1
        dataset_records.append((img_info, boxes))

    num_usable = len(dataset_records)
    print(f"Successfully parsed {num_usable:,} images containing usable S5 objects.")

    if num_usable == 0:
        raise RuntimeError("No usable bounding boxes found across all XML files.")

    # Print class counts
    print("\nS5 Box Counts:")
    for cat in S5_CATEGORIES:
        cid = cat["id"]
        cname = cat["name"]
        cnt = class_box_counts.get(cid, 0)
        print(f"  [{cid:2d}] {cname:<20s}: {cnt:,} box(es)")

    if total_dropped:
        print("\nDropped unmapped / ignored classes:")
        for raw, cnt in total_dropped.most_common():
            print(f"  {raw:<24s}: {cnt:,} box(es)")

    # Deterministic train / val split
    random.seed(seed)
    random.shuffle(dataset_records)

    split_idx = int(num_usable * train_ratio)
    train_records = dataset_records[:split_idx]
    val_records = dataset_records[split_idx:]

    output_dir.mkdir(parents=True, exist_ok=True)
    annotations_dir = output_dir / "annotations"
    annotations_dir.mkdir(parents=True, exist_ok=True)

    def build_coco_dict(records: List[Tuple[Dict[str, Any], List[Dict[str, Any]]]]) -> Dict[str, Any]:
        images_list: List[Dict[str, Any]] = []
        annotations_list: List[Dict[str, Any]] = []
        ann_id = 1
        for img_id, (im_info, boxes) in enumerate(records, start=1):
            im_entry = dict(im_info)
            im_entry["id"] = img_id
            images_list.append(im_entry)

            for b in boxes:
                b_entry = dict(b)
                b_entry["id"] = ann_id
                b_entry["image_id"] = img_id
                annotations_list.append(b_entry)
                ann_id += 1

        return {
            "info": {
                "description": "IDD Curated S5 Detection Dataset",
                "version": "1.0",
                "year": 2026,
            },
            "licenses": [],
            "categories": S5_CATEGORIES,
            "images": images_list,
            "annotations": annotations_list,
        }

    train_coco = build_coco_dict(train_records)
    val_coco = build_coco_dict(val_records)

    # Save to both annotations/ subdirectory (standard COCO) and output root
    for target_dir in (annotations_dir, output_dir):
        train_path = target_dir / "instances_train.json"
        val_path = target_dir / "instances_val.json"
        with open(train_path, "w", encoding="utf-8") as f:
            json.dump(train_coco, f)
        with open(val_path, "w", encoding="utf-8") as f:
            json.dump(val_coco, f)

    total_annotations = len(train_coco["annotations"]) + len(val_coco["annotations"])
    print(f"\nGenerated COCO JSON files:")
    print(f"  Train: {len(train_records):,} images, {len(train_coco['annotations']):,} annotations")
    print(f"  Val:   {len(val_records):,} images, {len(val_coco['annotations']):,} annotations")
    print(f"  Saved to: {annotations_dir}/instances_{{train,val}}.json")

    return len(train_records), len(val_records), total_annotations


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert IDD Pascal VOC annotations to COCO JSON format for YOLOX.",
    )
    parser.add_argument(
        "--ann_dir",
        type=Path,
        required=True,
        help="Path to directory containing Pascal VOC XML annotations.",
    )
    parser.add_argument(
        "--img_dir",
        type=Path,
        required=True,
        help="Path to directory containing images.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output directory where COCO JSON annotations will be saved.",
    )
    parser.add_argument(
        "--train_ratio",
        type=float,
        default=0.8,
        help="Fraction of dataset to allocate to training split (default: 0.8).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for deterministic split (default: 42).",
    )

    args = parser.parse_args()
    convert_voc_to_coco(
        ann_dir=args.ann_dir,
        img_dir=args.img_dir,
        output_dir=args.output,
        train_ratio=args.train_ratio,
        seed=args.seed,
    )


if __name__ == "__main__":
    main()
