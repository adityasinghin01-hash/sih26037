"""
train_deeplabv3.py - Train DeepLab v3+ ResNet-50 on IDD Segmentation (Model 4).

Features:
- Loads paired images and level3Id ground-truth masks.
- Maps IDD labels into 3 target classes: 0: drivable, 1: obstacle, 2: background.
- Uses torchvision.models.segmentation.deeplabv3_resnet50 with pretrained weights.
- Employs AMP mixed precision (fp16/bf16) for high-throughput A100 training.
- Evaluates per-class IoU (drivable, obstacle, background, mean IoU) on validation set.
- Exports best model to ONNX Opset 18 for seamless MATLAB R2024b import.
"""

import os
import glob
import time
import argparse
import numpy as np
from PIL import Image
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision.models.segmentation import deeplabv3_resnet50, DeepLabV3_ResNet50_Weights
import torchvision.transforms.functional as TF


class IDDSegmentationDataset(Dataset):
    def __init__(self, root_dir: str, split: str = 'train', img_size: tuple = (512, 512)):
        self.img_size = img_size
        self.samples = []

        mask_pattern = os.path.join(root_dir, 'gtFine', split, '*', '*_gtFine_labellevel3Ids.png')
        mask_files = sorted(glob.glob(mask_pattern))

        for m in mask_files:
            stem = os.path.basename(m).replace('_gtFine_labellevel3Ids.png', '')
            seq_dir = os.path.dirname(m)
            split_seq = os.path.relpath(seq_dir, os.path.join(root_dir, 'gtFine'))

            img_png = os.path.join(root_dir, 'leftImg8bit', split_seq, f'{stem}_leftImg8bit.png')
            img_jpg = os.path.join(root_dir, 'leftImg8bit', split_seq, f'{stem}_leftImg8bit.jpg')

            if os.path.exists(img_png):
                self.samples.append((img_png, m))
            elif os.path.exists(img_jpg):
                self.samples.append((img_jpg, m))

        print(f"[{split.upper()}] Found {len(self.samples)} valid image-mask pairs.")

        # Class lookup table (level3Id -> 3 classes)
        # 0: drivable (road=0, parking/drivable fallback=1)
        # 1: obstacle (vehicles, persons, animals, walls, fences, poles: 4..20)
        # 2: background (sidewalk=2, rail=3, buildings, vegetation, sky: 21..25)
        # 255: ignore (void, ego-vehicle, unlabeled)
        self.lut = np.full(256, 255, dtype=np.int64)
        for i in [0, 1]:
            self.lut[i] = 0
        for i in range(4, 21):
            self.lut[i] = 1
        for i in [2, 3, 21, 22, 23, 24, 25]:
            self.lut[i] = 2

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, mask_path = self.samples[idx]

        img = Image.open(img_path).convert('RGB')
        mask = Image.open(mask_path)

        img = img.resize(self.img_size, Image.Resampling.BILINEAR)
        mask = mask.resize(self.img_size, Image.Resampling.NEAREST)

        mask_np = np.array(mask, dtype=np.int64)
        mask_np = np.where(mask_np < 256, mask_np, 255)
        target = self.lut[mask_np]

        img_tensor = TF.to_tensor(img)
        img_tensor = TF.normalize(img_tensor, mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        target_tensor = torch.from_numpy(target).long()

        return img_tensor, target_tensor


def evaluate(model, loader, device):
    model.eval()
    conf_matrix = np.zeros((3, 3), dtype=np.int64)
    val_loss = 0.0
    criterion = nn.CrossEntropyLoss(ignore_index=255)

    with torch.no_grad():
        for images, targets in loader:
            images = images.to(device, non_blocking=True)
            targets = targets.to(device, non_blocking=True)

            with torch.cuda.amp.autocast():
                outputs = model(images)['out']
                loss = criterion(outputs, targets)
                val_loss += loss.item()

            preds = outputs.argmax(dim=1).cpu().numpy()
            t = targets.cpu().numpy()
            valid = (t >= 0) & (t < 3)
            conf_matrix += np.bincount(3 * t[valid] + preds[valid], minlength=9).reshape(3, 3)

    intersection = np.diag(conf_matrix)
    union = conf_matrix.sum(axis=1) + conf_matrix.sum(axis=0) - intersection
    ious = intersection / np.maximum(union, 1e-6)
    return val_loss / max(1, len(loader)), ious


def main():
    parser = argparse.ArgumentParser(description="Train DeepLab v3+ on IDD Segmentation (Model 4)")
    parser.add_argument("--data-dir", type=str, default="/home/jovyan/idd-segmentation/unified_dataset", help="Path to unified dataset")
    parser.add_argument("--epochs", type=int, default=10, help="Number of training epochs")
    parser.add_argument("--batch-size", type=int, default=16, help="Batch size (safe for A100 40GB)")
    parser.add_argument("--lr", type=float, default=3e-4, help="Initial learning rate")
    parser.add_argument("--output-dir", type=str, default="/home/jovyan", help="Directory to save model checkpoints and ONNX")
    args = parser.parse_args()

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Device: {device} ({torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'})")

    train_set = IDDSegmentationDataset(args.data_dir, split='train', img_size=(512, 512))
    val_set = IDDSegmentationDataset(args.data_dir, split='val', img_size=(512, 512))

    train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True, num_workers=8, pin_memory=True, drop_last=True)
    val_loader = DataLoader(val_set, batch_size=args.batch_size, shuffle=False, num_workers=8, pin_memory=True)

    print("Loading DeepLab v3+ ResNet-50...")
    model = deeplabv3_resnet50(weights=DeepLabV3_ResNet50_Weights.DEFAULT)
    model.classifier[4] = nn.Conv2d(256, 3, kernel_size=1)
    if model.aux_classifier is not None:
        model.aux_classifier[4] = nn.Conv2d(256, 3, kernel_size=1)
    model = model.to(device)

    class_weights = torch.tensor([1.0, 2.5, 0.5], device=device)
    criterion = nn.CrossEntropyLoss(weight=class_weights, ignore_index=255)

    optimizer = optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)
    scaler = torch.cuda.amp.GradScaler()

    best_drivable_iou = 0.0
    best_ckpt_path = os.path.join(args.output_dir, "best_deeplabv3_idd.pth")

    print(f"\n{'='*75}")
    print(f"Starting Training: {args.epochs} epochs on A100 | Batch Size {args.batch_size} | 512x512")
    print(f"{'='*75}")

    total_start = time.time()
    for epoch in range(1, args.epochs + 1):
        model.train()
        train_loss = 0.0
        t0 = time.time()

        for step, (images, targets) in enumerate(train_loader, 1):
            images = images.to(device, non_blocking=True)
            targets = targets.to(device, non_blocking=True)

            optimizer.zero_grad()
            with torch.cuda.amp.autocast():
                outputs = model(images)
                loss = criterion(outputs['out'], targets)
                if 'aux' in outputs:
                    loss += 0.5 * criterion(outputs['aux'], targets)

            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()

            train_loss += loss.item()
            if step % 50 == 0 or step == len(train_loader):
                print(f"Epoch [{epoch:02d}/{args.epochs:02d}] Step [{step:04d}/{len(train_loader):04d}] - Loss: {train_loss/step:.4f}", end='\r')

        scheduler.step()
        epoch_time = time.time() - t0

        val_loss, ious = evaluate(model, val_loader, device)
        drivable_iou, obstacle_iou, bg_iou = ious[0], ious[1], ious[2]
        miou = ious.mean()

        print(f"\nEpoch [{epoch:02d}/{args.epochs:02d}] Duration: {epoch_time:.1f}s | Train Loss: {train_loss/len(train_loader):.4f} | Val Loss: {val_loss:.4f}")
        print(f"  --> Drivable IoU: {drivable_iou:.4f} | Obstacle IoU: {obstacle_iou:.4f} | Background IoU: {bg_iou:.4f} | Mean IoU: {miou:.4f}")

        if drivable_iou > best_drivable_iou:
            best_drivable_iou = drivable_iou
            torch.save(model.state_dict(), best_ckpt_path)
            print(f"  [*] New Best Drivable IoU: {best_drivable_iou:.4f} (Saved to {best_ckpt_path})")

    print(f"\n{'='*75}")
    print(f"Training Completed in {(time.time() - total_start)/60:.1f} min! Best Drivable IoU: {best_drivable_iou:.4f}")
    print(f"{'='*75}")

    # --- ONNX Export ---
    print("\nExporting best model to ONNX (Opset 18)...")
    model.load_state_dict(torch.load(best_ckpt_path))
    model.eval()

    class DeeplabWrapper(nn.Module):
        def __init__(self, m):
            super().__init__()
            self.m = m
        def forward(self, x):
            return self.m(x)['out']

    wrapper = DeeplabWrapper(model)
    dummy_input = torch.randn(1, 3, 512, 512, device=device)
    onnx_path = os.path.join(args.output_dir, "road_segmenter_deeplabv3_opset18.onnx")

    torch.onnx.export(
        wrapper,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['logits'],
        dynamic_axes={'input': {0: 'batch'}, 'logits': {0: 'batch'}}
    )
    print(f"SUCCESS: Exported ONNX to {onnx_path} ({os.path.getsize(onnx_path)/1e6:.2f} MB)")


if __name__ == '__main__':
    main()
