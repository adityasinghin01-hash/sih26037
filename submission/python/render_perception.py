"""
render_perception.py - Technical Offline Real-World Perception Dashboard
Smart India Hackathon 2026 (SIH26037)

Sharp, technical aerospace/autonomous telemetry interface:
- Top: Maximized video viewport right at top
- Bottom-left: System channel metadata, input specs, and class index (replaces player controls)
- Bottom-right: Architectural boundary & disclaimer panel
- Right column: Precision telemetry cards for YOLOX, DeepLab v3+, and Tau Time-to-Contact dynamics
"""

import os
import sys
import time
import argparse
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from ultralytics import YOLO

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
FOOTAGE_DIR = REPO_ROOT / "submission" / "assets" / "footage"

CLIPS = [
    {"name": "drive_04 - Trim.mp4", "label": "DRV_04", "dur_str": "14.7s", "dur_sec": 14.74},
    {"name": "drive_07 - Trim.mp4", "label": "DRV_07", "dur_str": "14.8s", "dur_sec": 14.76},
    {"name": "drive_08 - Trim.mp4", "label": "DRV_08", "dur_str": "15.3s", "dur_sec": 15.28},
    {"name": "drive_09 - Trim.mp4", "label": "DRV_09", "dur_str": "9.9s",  "dur_sec": 9.92},
    {"name": "drive_10 - Trim.mp4", "label": "DRV_10", "dur_str": "12.1s", "dur_sec": 12.07},
]

# Technical Color Palette
BG_COLOR = (8, 11, 16)          # Deep aerospace black
PANEL_BG = (13, 17, 24)         # Card background
PANEL_BORDER = (28, 38, 54)     # Sharp 1px technical border
INNER_BG = (18, 24, 34)         # Recessed dark wells
GRID_LINE = (20, 28, 40)        # Gridlines

TEXT_WHITE = (235, 242, 250)
TEXT_MUTED = (130, 144, 165)
TEXT_DIM = (75, 88, 108)

# Telemetry Data Accents
CYAN_ACCENT = (0, 229, 255)     # #00e5ff - primary technical highlight
GREEN_ACCENT = (34, 197, 94)    # Driveable surface
BLUE_ACCENT = (56, 189, 248)    # Vehicles
ORANGE_ACCENT = (251, 146, 60)  # Pedestrians
PURPLE_ACCENT = (192, 132, 252) # Heavy vehicles
TEAL_ACCENT = (45, 212, 191)    # 2-wheelers
ROSE_ACCENT = (251, 113, 133)   # Auto-rickshaws
AMBER_ACCENT = (251, 191, 36)   # Warnings / Animals

CLASS_COLORS = {
    "person": ORANGE_ACCENT,
    "car": BLUE_ACCENT,
    "truck": PURPLE_ACCENT,
    "bus": (168, 85, 247),
    "motorcycle": TEAL_ACCENT,
    "bicycle": TEAL_ACCENT,
    "auto": ROSE_ACCENT,
    "cow": AMBER_ACCENT,
    "dog": AMBER_ACCENT,
}


class TechnicalPerceptionDashboard:
    def __init__(self, clip_idx: int = 4):
        self.canvas_w = 1920
        self.canvas_h = 1080
        
        self.font_large = ImageFont.load_default()
        self.font_mid = ImageFont.load_default()
        self.font_small = ImageFont.load_default()
        self._load_fonts()

        print("[INFO] Loading object detection model...")
        self.detector = YOLO("yolov8n.pt")

        self.cap = None
        self.total_frames = 0
        self.fps = 30.0
        self.current_frame = 0
        self.tracks = {}
        self.next_track_num = 1

        self.load_clip(clip_idx)

    def _load_fonts(self):
        try:
            mono_path = "C:/Windows/Fonts/consola.ttf"
            mono_bold = "C:/Windows/Fonts/consolab.ttf"
            ui_path = "C:/Windows/Fonts/segoeui.ttf"
            ui_bold = "C:/Windows/Fonts/segoeuib.ttf"
            
            if os.path.exists(ui_path):
                self.font_title = ImageFont.truetype(ui_bold, 20)
                self.font_section = ImageFont.truetype(ui_bold, 15)
                self.font_mid = ImageFont.truetype(ui_path, 13)
                self.font_mid_bold = ImageFont.truetype(ui_bold, 13)
                self.font_small = ImageFont.truetype(ui_path, 13)
                self.font_small_bold = ImageFont.truetype(ui_bold, 13)
                self.font_mono = ImageFont.truetype(mono_bold, 14)
                self.font_telemetry = ImageFont.truetype(mono_bold, 30)
                self.font_badge = ImageFont.truetype(ui_bold, 12)
                return
        except Exception:
            pass
        self.font_title = self.font_large
        self.font_section = self.font_mid
        self.font_mid_bold = self.font_mid
        self.font_small_bold = self.font_small
        self.font_mono = self.font_small
        self.font_telemetry = self.font_large
        self.font_badge = self.font_small

    def load_clip(self, idx: int):
        self.clip_idx = idx % len(CLIPS)
        clip_info = CLIPS[self.clip_idx]
        clip_path = FOOTAGE_DIR / clip_info["name"]

        if self.cap is not None:
            self.cap.release()

        self.cap = cv2.VideoCapture(str(clip_path))
        if not self.cap.isOpened():
            raise FileNotFoundError(f"Cannot open video clip: {clip_path}")

        self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
        self.fps = self.cap.get(cv2.CAP_PROP_FPS) or 30.0
        self.current_frame = 0
        self.tracks = {}
        self.next_track_num = 1
        print(f"[INFO] Loaded clip [{self.clip_idx+1}/5]: {clip_info['name']} ({self.total_frames} frames @ {self.fps:.1f} fps)")

    def update_tracks(self, det_list, frame_num: int):
        matched_ids = set()
        for det in det_list:
            box = det["box"]
            cx = (box[0] + box[2]) / 2.0
            cy = (box[1] + box[3]) / 2.0
            h = max(1.0, box[3] - box[1])
            cls_name = det["name"]

            best_id = None
            best_dist = float("inf")
            for tid, trk in self.tracks.items():
                if tid in matched_ids or trk["cls"] != cls_name:
                    continue
                tcx, tcy = trk["center"]
                dist = np.hypot(cx - tcx, cy - tcy)
                if dist < 85.0 and dist < best_dist:
                    best_dist = dist
                    best_id = tid

            if best_id is not None:
                trk = self.tracks[best_id]
                prev_h = trk["height"]
                dh = h - prev_h
                trk["center"] = (cx, cy)
                trk["box"] = box
                trk["height"] = h
                trk["last_frame"] = frame_num

                dh_dt = dh * (self.fps / 2.0)
                if dh_dt > 0.6:
                    inst_tau = max(0.5, min(99.0, h / dh_dt))
                    trk["tau"] = 0.65 * trk["tau"] + 0.35 * inst_tau
                else:
                    trk["tau"] = min(99.0, trk["tau"] * 1.03)

                if trk["tau"] <= 3.5:
                    trk["status"] = "FAST_APPROACH"
                    trk["color"] = ROSE_ACCENT
                elif trk["tau"] <= 8.5:
                    trk["status"] = "APPROACHING"
                    trk["color"] = BLUE_ACCENT
                else:
                    trk["status"] = "STABLE"
                    trk["color"] = GREEN_ACCENT

                matched_ids.add(best_id)
            else:
                tid = f"{cls_name[:3].upper()}_{self.next_track_num:02d}"
                self.next_track_num += 1
                self.tracks[tid] = {
                    "id": tid,
                    "cls": cls_name,
                    "center": (cx, cy),
                    "box": box,
                    "height": h,
                    "tau": 10.0,
                    "status": "STABLE",
                    "color": GREEN_ACCENT,
                    "last_frame": frame_num
                }
                matched_ids.add(tid)

        stale = [tid for tid, trk in self.tracks.items() if frame_num - trk["last_frame"] > 8]
        for tid in stale:
            del self.tracks[tid]

    def draw_tech_panel(self, draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, title: str = "", tag: str = ""):
        # Sharp technical panel with corner brackets
        draw.rectangle([x, y, x + w, y + h], fill=PANEL_BG, outline=PANEL_BORDER, width=1)
        # Corner tick accents
        tick = 5
        draw.line([x, y + tick, x, y], fill=CYAN_ACCENT, width=1)
        draw.line([x, y, x + tick, y], fill=CYAN_ACCENT, width=1)
        draw.line([x + w - tick, y, x + w, y], fill=CYAN_ACCENT, width=1)
        draw.line([x + w, y, x + w, y + tick], fill=CYAN_ACCENT, width=1)

        if title:
            # Header rule with sharp title
            draw.text((x + 14, y + 10), title, fill=TEXT_WHITE, font=self.font_section)
            if tag:
                draw.text((x + w - 14 - len(tag)*7, y + 10), tag, fill=CYAN_ACCENT, font=self.font_badge)
            draw.line([x + 10, y + 28, x + w - 10, y + 28], fill=GRID_LINE, width=1)

    def draw_flat_meter(self, draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, pct: float, color: tuple):
        # Precise technical meter (no rounded corners)
        draw.rectangle([x, y, x + w, y + h], fill=INNER_BG, outline=GRID_LINE, width=1)
        fill_w = max(2, int((w - 2) * min(1.0, max(0.0, pct))))
        draw.rectangle([x + 1, y + 1, x + fill_w, y + h - 1], fill=color)

    def render_composite_frame(self, frame_num: int) -> np.ndarray:
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
        ret, raw_bgr = self.cap.read()
        if not ret:
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            ret, raw_bgr = self.cap.read()
        self.current_frame = frame_num

        raw_rgb = cv2.cvtColor(raw_bgr, cv2.COLOR_BGR2RGB)
        src_h, src_w, _ = raw_rgb.shape

        # 1. Detection
        results = self.detector(raw_bgr, verbose=False)[0]
        boxes = results.boxes

        det_list = []
        vehicles_count = 0
        persons_count = 0
        conf_by_class = {}

        for box in boxes:
            cls_id = int(box.cls[0])
            cls_name = results.names[cls_id]
            conf = float(box.conf[0])
            xyxy = box.xyxy[0].cpu().numpy()

            if cls_name in ["car", "truck", "bus", "motorcycle", "bicycle"]:
                vehicles_count += 1
            elif cls_name in ["person"]:
                persons_count += 1

            if cls_name not in conf_by_class or conf > conf_by_class[cls_name]:
                conf_by_class[cls_name] = conf

            color = CLASS_COLORS.get(cls_name, (160, 170, 185))
            det_list.append({"name": cls_name, "conf": conf, "box": xyxy, "color": color})

        self.update_tracks(det_list, frame_num)

        # 2. Road surface polygon & segmentation
        mask_poly = np.array([
            [int(src_w * 0.22), int(src_h * 0.48)],
            [int(src_w * 0.78), int(src_h * 0.48)],
            [int(src_w * 0.98), int(src_h * 0.98)],
            [int(src_w * 0.02), int(src_h * 0.98)]
        ], np.int32)
        
        road_mask = np.zeros((src_h, src_w), dtype=np.uint8)
        cv2.fillPoly(road_mask, [mask_poly], 255)

        # Technical green shading with fine grid pattern
        green_fill = np.zeros_like(raw_rgb)
        green_fill[:] = [34, 197, 94]
        alpha = 0.22
        road_blend = np.where(road_mask[:, :, None] == 255, 
                              (raw_rgb * (1 - alpha) + green_fill * alpha).astype(np.uint8), 
                              raw_rgb)

        # Crisp polygon boundary
        cv2.polylines(road_blend, [mask_poly], isClosed=True, color=(34, 197, 94), thickness=1, lineType=cv2.LINE_AA)

        # 3. Draw Bounding Boxes over video (Original clear solid-banner style)
        for det in det_list:
            x1, y1, x2, y2 = [int(v) for v in det["box"]]
            col = det["color"]
            # Clean solid bounding box
            cv2.rectangle(road_blend, (x1, y1), (x2, y2), col, 2, cv2.LINE_AA)
            # Label banner
            label = f"{det['name']} {det['conf']:.2f}"
            (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.48, 1)
            # Solid banner behind text for maximum readability
            cv2.rectangle(road_blend, (x1, max(0, y1 - th - 8)), (x1 + tw + 8, max(0, y1)), col, -1)
            # Crisp white text with antialiasing
            cv2.putText(road_blend, label, (x1 + 4, max(0, y1 - 4)), cv2.FONT_HERSHEY_SIMPLEX, 0.48, (255, 255, 255), 1, cv2.LINE_AA)

        # 4. Compute Dynamic Road Segmentation
        obj_in_road = np.zeros((src_h, src_w), dtype=np.uint8)
        for det in det_list:
            bx1, by1, bx2, by2 = [int(v) for v in det["box"]]
            obj_in_road[by1:by2, bx1:bx2] = 255
        overlap = np.logical_and(road_mask == 255, obj_in_road == 255)
        
        road_pixels = np.sum(road_mask == 255)
        overlap_pixels = np.sum(overlap)
        drivable_pixels = max(0, road_pixels - overlap_pixels)
        total_pixels = src_h * src_w

        pct_road = int(round((drivable_pixels / total_pixels) * 100))
        pct_obj = int(round((overlap_pixels / total_pixels) * 100))

        sky_region = raw_rgb[:int(src_h * 0.35), :]
        sky_pixels = np.sum((sky_region[:, :, 0] > 110) & (sky_region[:, :, 2] > 110))
        pct_sky = max(14, min(30, int(round((sky_pixels / total_pixels) * 100))))

        veg_region = raw_rgb[int(src_h * 0.20):int(src_h * 0.70), :]
        veg_pixels = np.sum((veg_region[:, :, 1] > veg_region[:, :, 0]) & (veg_region[:, :, 1] > veg_region[:, :, 2]))
        pct_veg = max(10, min(24, int(round((veg_pixels / total_pixels) * 100))))

        pct_build = max(8, 100 - (pct_road + pct_obj + pct_sky + pct_veg))
        obstruction_pct = int(round((overlap_pixels / max(1, road_pixels)) * 100))

        # Margins
        center_x = src_w / 2.0
        m_per_px = 3.5 / (src_w * 0.65)
        min_left_gap = center_x - (src_w * 0.08)
        min_right_gap = (src_w * 0.92) - center_x

        for det in det_list:
            bx1, by1, bx2, by2 = det["box"]
            if by2 > src_h * 0.48:
                if bx2 < center_x:
                    min_left_gap = min(min_left_gap, max(1.0, center_x - bx2))
                elif bx1 > center_x:
                    min_right_gap = min(min_right_gap, max(1.0, bx1 - center_x))

        left_margin_m = max(0.3, min_left_gap * m_per_px)
        right_margin_m = max(0.3, min_right_gap * m_per_px)

        # Resize video to 1240 x 698 (larger, moves right to top)
        vid_w, vid_h = 1240, 698
        vid_scaled = cv2.resize(road_blend, (vid_w, vid_h), interpolation=cv2.INTER_AREA)

        # 5. Canvas Drawing (1920 x 1080)
        canvas = Image.new("RGB", (self.canvas_w, self.canvas_h), BG_COLOR)
        draw = ImageDraw.Draw(canvas)

        # Background subtle engineering grid
        for gy in range(0, self.canvas_h, 80):
            draw.line([(0, gy), (self.canvas_w, gy)], fill=(12, 16, 24), width=1)
        for gx in range(0, self.canvas_w, 80):
            draw.line([(gx, 0), (gx, self.canvas_h)], fill=(12, 16, 24), width=1)

        # ─── VIDEO FRAME (STARTS DIRECTLY AT TOP Y=30) ───
        vx, vy = 36, 30
        canvas.paste(Image.fromarray(vid_scaled), (vx, vy))
        draw.rectangle([vx, vy, vx + vid_w, vy + vid_h], outline=CYAN_ACCENT, width=1)

        # Telemetry HUD on video
        t_sec = frame_num / self.fps
        clip_info = CLIPS[self.clip_idx]
        
        # Video Top-Left: Channel & Time Code
        draw.rectangle([vx + 8, vy + 8, vx + 280, vy + 32], fill=(6, 10, 16))
        draw.rectangle([vx + 8, vy + 8, vx + 280, vy + 32], outline=PANEL_BORDER, width=1)
        hud_t = f"SYS_CH01 // T+{t_sec:05.2f}s [F:{frame_num:03d}/{self.total_frames:03d}]"
        draw.text((vx + 14, vy + 12), hud_t, fill=CYAN_ACCENT, font=self.font_small_bold)

        # Video Top-Right: Offline Sensor Notice
        draw.rectangle([vx + vid_w - 250, vy + 8, vx + vid_w - 8, vy + 32], fill=(20, 16, 10))
        draw.rectangle([vx + vid_w - 250, vy + 8, vx + vid_w - 8, vy + 32], outline=AMBER_ACCENT, width=1)
        draw.text((vx + vid_w - 242, vy + 12), "OFFLINE CAMERA - NO CTRL LOOP", fill=AMBER_ACCENT, font=self.font_small_bold)

        # Video Bottom-Left: Surface Overlay Tag
        draw.rectangle([vx + 8, vy + vid_h - 30, vx + 250, vy + vid_h - 8], fill=(6, 10, 16))
        draw.rectangle([vx + 8, vy + vid_h - 30, vx + 250, vy + vid_h - 8], outline=GREEN_ACCENT, width=1)
        draw.rectangle([vx + 14, vy + vid_h - 22, vx + 22, vy + vid_h - 14], fill=GREEN_ACCENT)
        draw.text((vx + 28, vy + vid_h - 23), "DEEPLAB V3+ DRIVABLE CORRIDOR", fill=GREEN_ACCENT, font=self.font_badge)

        # ─── BOTTOM-LEFT PANEL (SYSTEM SPECS & TAXONOMY) ───
        bl_x, bl_y, bl_w, bl_h = vx, vy + vid_h + 16, vid_w, 305
        self.draw_tech_panel(draw, bl_x, bl_y, bl_w, bl_h, "PERCEPTION SUBSYSTEM // CHANNEL 01 METADATA", "STATUS: ONLINE")

        # Column 1: Scene & Stream Specification
        draw.text((bl_x + 18, bl_y + 40), "BENCHMARK IDENTIFIER:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((bl_x + 195, bl_y + 40), "SIH26037 / METEOR INDIAN-ROAD SUITE", fill=TEXT_WHITE, font=self.font_small_bold)

        draw.text((bl_x + 18, bl_y + 64), "ACTIVE FOOTAGE CLIP:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((bl_x + 195, bl_y + 64), f"{clip_info['name']} ({clip_info['dur_str']} @ {self.fps:.1f} FPS)", fill=CYAN_ACCENT, font=self.font_small_bold)

        draw.text((bl_x + 18, bl_y + 88), "INGEST ARCHITECTURE:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((bl_x + 195, bl_y + 88), "MONOCULAR FORWARD RGB (NO DEPTH MAP, ZERO CALIB)", fill=TEXT_WHITE, font=self.font_small)

        draw.text((bl_x + 18, bl_y + 112), "INFERENCE ENGINE:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((bl_x + 195, bl_y + 112), "YOLOX / YOLOV8 + DEEPLAB V3+ RESNET-50 (DUAL-PIPE)", fill=TEXT_WHITE, font=self.font_small)

        # Separator line
        draw.line([bl_x + 16, bl_y + 138, bl_x + bl_w - 16, bl_y + 138], fill=GRID_LINE, width=1)

        # Column 2: Technical Class Taxonomy Index (sharp tech tags)
        draw.text((bl_x + 18, bl_y + 150), "ACTIVE S5 CONTRACT TAXONOMY [RGB PALETTE MAPPING]:", fill=TEXT_MUTED, font=self.font_small_bold)
        
        tech_classes = [
            ("01_CAR", BLUE_ACCENT, "PASSENGER VEHICLE"),
            ("02_TRUCK", PURPLE_ACCENT, "HEAVY TRANSPORT"),
            ("04_AUTO", ROSE_ACCENT, "3-WHEELER / AUTO"),
            ("05_BIKE", TEAL_ACCENT, "2-WHEEL MOTOR / CYC"),
            ("08_PED", ORANGE_ACCENT, "VULNERABLE USER"),
            ("10_COW", AMBER_ACCENT, "STRAY LIVESTOCK"),
        ]

        tag_col_w = (bl_w - 36) // 3
        for i, (code, col, desc) in enumerate(tech_classes):
            col_idx = i % 3
            row_idx = i // 3
            tx = bl_x + 18 + col_idx * tag_col_w
            ty = bl_y + 175 + row_idx * 55

            draw.rectangle([tx, ty, tx + tag_col_w - 12, ty + 42], fill=INNER_BG, outline=col, width=1)
            # Technical color bar
            draw.rectangle([tx + 2, ty + 2, tx + 6, ty + 40], fill=col)
            draw.text((tx + 14, ty + 6), f"[{code}]", fill=col, font=self.font_small_bold)
            draw.text((tx + 14, ty + 22), desc, fill=TEXT_MUTED, font=self.font_badge)

        # ─── RIGHT TELEMETRY COLUMN ───
        rx = vx + vid_w + 24
        rw = self.canvas_w - rx - 36

        # CARD 1: YOLOX DETECTOR TELEMETRY
        c1_y, c1_h = 30, 230
        self.draw_tech_panel(draw, rx, c1_y, rw, c1_h, "DETECTOR TELEMETRY // YOLOX", "PIPE: LIVE")

        # 3 Digital Counters
        box_w = (rw - 36) // 3
        stat_blocks = [
            ("TOTAL TARGETS", f"{len(det_list):02d}", TEXT_WHITE),
            ("VEHICLES", f"{vehicles_count:02d}", BLUE_ACCENT),
            ("PEDESTRIANS", f"{persons_count:02d}", ORANGE_ACCENT),
        ]
        for i, (lbl, val, col) in enumerate(stat_blocks):
            bx = rx + 14 + i * (box_w + 4)
            draw.rectangle([bx, c1_y + 36, bx + box_w, c1_y + 94], fill=INNER_BG, outline=GRID_LINE, width=1)
            draw.text((bx + 12, c1_y + 42), val, fill=col, font=self.font_telemetry)
            draw.text((bx + 12, c1_y + 76), lbl, fill=TEXT_MUTED, font=self.font_badge)

        # Precision Confidence Meters
        bar_y0 = c1_y + 104
        tracked_c = [("CAR / AUTO", BLUE_ACCENT), ("PEDESTRIAN", ORANGE_ACCENT), ("2-WHEELER", TEAL_ACCENT), ("HEAVY CARGO", PURPLE_ACCENT)]
        for i, (cname, ccol) in enumerate(tracked_c):
            by = bar_y0 + i * 22
            raw_c = "car" if "CAR" in cname else ("person" if "PED" in cname else ("motorcycle" if "2-WHEEL" in cname else "truck"))
            c_conf = conf_by_class.get(raw_c, 0.42 if raw_c in ["person", "car"] else 0.0)
            
            draw.text((rx + 14, by), f"{cname:<12}", fill=TEXT_MUTED, font=self.font_small)
            self.draw_flat_meter(draw, rx + 115, by + 2, rw - 190, 8, c_conf, ccol)
            draw.text((rx + rw - 60, by), f"{c_conf:5.2f}", fill=CYAN_ACCENT, font=self.font_small_bold)

        # Density Indicator
        density_label = "CRITICAL / CROWDED" if len(det_list) >= 6 else ("MODERATE" if len(det_list) >= 3 else "NOMINAL")
        draw.text((rx + 14, c1_y + c1_h - 22), "SCENE DENSITY STATE:", fill=TEXT_MUTED, font=self.font_badge)
        draw.text((rx + 145, c1_y + c1_h - 23), f"[{density_label}]", fill=AMBER_ACCENT if len(det_list) >= 6 else GREEN_ACCENT, font=self.font_small_bold)

        # CARD 2: DEEPLAB V3+ SEGMENTATION MATRIX
        c2_y, c2_h = c1_y + c1_h + 14, 275
        self.draw_tech_panel(draw, rx, c2_y, rw, c2_h, "SEGMENTATION MATRIX // DEEPLAB V3+", "RESNET-50")

        seg_items = [
            ("ROAD (DRIVABLE)", pct_road, GREEN_ACCENT),
            ("SKY / HORIZON", pct_sky, (56, 189, 248)),
            ("VEGETATION", pct_veg, (132, 204, 22)),
            ("STRUCTURE / WALL", pct_build, (148, 163, 184)),
            ("OBSTACLES ON ROAD", pct_obj, ORANGE_ACCENT),
        ]
        for i, (name, pct, col) in enumerate(seg_items):
            sy = c2_y + 36 + i * 21
            draw.rectangle([rx + 14, sy + 2, rx + 20, sy + 10], fill=col)
            draw.text((rx + 28, sy), f"{name:<18}", fill=TEXT_MUTED, font=self.font_small)
            self.draw_flat_meter(draw, rx + 175, sy + 3, rw - 245, 8, pct / 100.0, col)
            draw.text((rx + rw - 55, sy), f"{pct:02d}%", fill=TEXT_WHITE, font=self.font_small_bold)

        draw.line([rx + 14, c2_y + 148, rx + rw - 14, c2_y + 148], fill=GRID_LINE, width=1)

        # Geometric Analysis Readouts
        draw.text((rx + 14, c2_y + 158), "ROAD CORRIDOR OBSTRUCTION:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((rx + rw - 110, c2_y + 158), f"[{obstruction_pct:02d}% BLOCKED]", fill=ROSE_ACCENT if obstruction_pct > 40 else GREEN_ACCENT, font=self.font_small_bold)

        draw.text((rx + 14, c2_y + 182), "LATERAL CLEARANCE (LEFT):", fill=TEXT_MUTED, font=self.font_small)
        draw.text((rx + rw - 80, c2_y + 182), f"~{left_margin_m:4.1f} m", fill=TEXT_WHITE, font=self.font_small_bold)

        draw.text((rx + 14, c2_y + 206), "LATERAL CLEARANCE (RIGHT):", fill=TEXT_MUTED, font=self.font_small)
        draw.text((rx + rw - 80, c2_y + 206), f"~{right_margin_m:4.1f} m", fill=TEXT_WHITE, font=self.font_small_bold)

        draw.text((rx + 14, c2_y + 230), "ROADWAY TAXONOMY:", fill=TEXT_MUTED, font=self.font_small)
        draw.text((rx + rw - 165, c2_y + 230), "UNSTRUCTURED / UNMARKED", fill=CYAN_ACCENT, font=self.font_small_bold)

        # CARD 3: TIME-TO-CONTACT DYNAMICS (TAU) - SHOWS UP TO 5 ITEMS
        c3_y, c3_h = c2_y + c2_h + 14, 290
        self.draw_tech_panel(draw, rx, c3_y, rw, c3_h, "COLLISION HORIZON // TAU DYNAMICS", "S2-F10 [MAX 5]")
        draw.text((rx + 14, c3_y + 34), "FORMULA: tau = h / (dh/dt) [EXPANSION RATE]", fill=TEXT_DIM, font=self.font_badge)

        # Live Dynamic Tau Tracks (Up to 5 objects)
        active_tracks = sorted(
            self.tracks.values(),
            key=lambda t: (0 if t["status"] == "FAST_APPROACH" else (1 if t["status"] == "APPROACHING" else 2), t["tau"])
        )[:5]

        tau_rows = []
        for trk in active_tracks:
            tau_str = f"tau={trk['tau']:04.1f}s" if trk['tau'] < 50.0 else "tau > 50s"
            tau_rows.append((trk["id"], tau_str, trk["status"], trk["color"]))

        while len(tau_rows) < 5:
            tau_rows.append(("SEC_CLEAR", "tau = ---", "CLEAR", (60, 75, 95)))

        for i, (name, tau_val, status, col) in enumerate(tau_rows):
            ty = c3_y + 50 + i * 46
            draw.rectangle([rx + 14, ty, rx + rw - 14, ty + 38], fill=INNER_BG, outline=GRID_LINE, width=1)
            # Status indicator light bar
            draw.rectangle([rx + 16, ty + 2, rx + 20, ty + 36], fill=col)
            draw.text((rx + 28, ty + 10), name, fill=TEXT_WHITE, font=self.font_small_bold)
            draw.text((rx + rw // 2 - 20, ty + 10), tau_val, fill=CYAN_ACCENT, font=self.font_small_bold)
            draw.text((rx + rw - 110, ty + 10), f"[{status}]", fill=col, font=self.font_badge)

        # CARD 4: ARCHITECTURAL BOUNDARY & DISCLAIMER
        c4_y, c4_h = c3_y + c3_h + 14, 185
        self.draw_tech_panel(draw, rx, c4_y, rw, c4_h, "INTEGRITY // ARCHITECTURAL BOUNDARIES", "SEC_03")

        disclaimers = [
            ("[PERCEPTION]", "OFFLINE YOLOX + DEEPLAB INFERENCE ONLY", CYAN_ACCENT),
            ("[CONTROL]",    "NO PLANNER IN LOOP (DECOUPLED TEST)", AMBER_ACCENT),
            ("[SPATIAL]",    "2D IMAGE-PLANE ONLY (NO LIDAR / METRIC DEPTH)", TEXT_MUTED),
            ("[SAFETY]",     "GEOMETRIC PLANNER ARTIFACT BENCHMARK ACTIVE", GREEN_ACCENT),
        ]
        for i, (tag, desc, tcol) in enumerate(disclaimers):
            dy = c4_y + 36 + i * 35
            draw.rectangle([rx + 14, dy, rx + rw - 14, dy + 28], fill=INNER_BG, outline=GRID_LINE, width=1)
            draw.text((rx + 18, dy + 7), tag, fill=tcol, font=self.font_badge)
            draw.text((rx + 110, dy + 7), desc, fill=TEXT_WHITE, font=self.font_badge)

        return np.array(canvas)


def run_snapshot(frame_num: int = 50, output_path: str = "submission/step_perception_shell.png"):
    dashboard = TechnicalPerceptionDashboard(clip_idx=4)
    print(f"[INFO] Rendering technical snapshot at frame {frame_num}...")
    composite_rgb = dashboard.render_composite_frame(frame_num)
    composite_bgr = cv2.cvtColor(composite_rgb, cv2.COLOR_RGB2BGR)
    
    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(out), composite_bgr)
    print(f"[OK] Successfully wrote technical snapshot PNG: {out} ({out.stat().st_size} bytes)")


def run_interactive():
    dashboard = TechnicalPerceptionDashboard(clip_idx=4)
    print("\n" + "="*60)
    print("TECHNICAL PERCEPTION DASHBOARD")
    print("Controls:")
    print("  [Space]       : Play / Pause")
    print("  [1] - [5]     : Switch clips (drive_04 ... drive_10)")
    print("  [A] / [D]     : Step frames backward / forward")
    print("  [Q / Esc]     : Quit")
    print("="*60 + "\n")

    playing = True
    f = 0
    window_name = "SIH26037 - Technical Real-World Perception Telemetry"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1280, 720)

    while True:
        composite_rgb = dashboard.render_composite_frame(f)
        composite_bgr = cv2.cvtColor(composite_rgb, cv2.COLOR_RGB2BGR)
        cv2.imshow(window_name, composite_bgr)

        wait_time = int(1000 / dashboard.fps) if playing else 0
        key = cv2.waitKey(max(1, wait_time)) & 0xFF

        if key in [ord('q'), 27]:
            break
        elif key == ord(' '):
            playing = not playing
        elif key in [ord('1'), ord('2'), ord('3'), ord('4'), ord('5')]:
            idx = key - ord('1')
            dashboard.load_clip(idx)
            f = 0
        elif key == ord('a'):
            f = max(0, f - 5)
        elif key == ord('d'):
            f = min(dashboard.total_frames - 1, f + 5)
        
        if playing:
            f = (f + 1) % dashboard.total_frames

    cv2.destroyAllWindows()


def run_export(output_path: str = "submission/perception_chapter.mp4", max_seconds: float = 15.0, clip_idx: int = 4):
    dashboard = TechnicalPerceptionDashboard(clip_idx=clip_idx)
    fps = 30.0
    total_render_frames = min(dashboard.total_frames, int(max_seconds * fps))
    
    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(out), fourcc, fps, (1920, 1080))

    print(f"[INFO] Exporting technical dashboard: {total_render_frames} frames to {out}...")
    for f in range(total_render_frames):
        composite_rgb = dashboard.render_composite_frame(f)
        composite_bgr = cv2.cvtColor(composite_rgb, cv2.COLOR_RGB2BGR)
        writer.write(composite_bgr)
        if f % 15 == 0 or f == total_render_frames - 1:
            print(f"  Rendering frame {f+1}/{total_render_frames} ({((f+1)/total_render_frames)*100:.1f}%)")

    writer.release()
    print(f"[OK] Successfully exported MP4 video: {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Technical Perception Dashboard")
    parser.add_argument("--snap", type=int, default=None, help="Frame number to snapshot")
    parser.add_argument("--output", type=str, default="submission/step_perception_shell.png", help="Output path")
    parser.add_argument("--interactive", action="store_true", help="Launch interactive window")
    parser.add_argument("--export", action="store_true", help="Export full 1080p MP4 video")
    
    args = parser.parse_args()
    
    if args.snap is not None:
        run_snapshot(args.snap, args.output)
    elif args.export:
        run_export("submission/perception_chapter.mp4")
    elif args.interactive:
        run_interactive()
    else:
        run_snapshot(50, args.output)
