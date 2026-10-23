#!/usr/bin/env python3
"""Prepare the oversized Angel Island PNG/Sparrow atlases for Android GPUs."""
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image

MOD = Path("example_mods/Sonic the Hedgehog 3 (FNF Port)")
MAX_TEXTURE = 4096
TARGETS = [
    ("images/angelstage/water_bg.png", None),
    ("images/angelstage/AIZFloorNormal.png", "images/angelstage/AIZFloorNormal.xml"),
    ("images/angelstage/aizBGFire.png", "images/angelstage/aizBGFire.xml"),
    ("images/angelstage/AIZFloorFire.png", "images/angelstage/AIZFloorFire.xml"),
]

def rounded_px(value):
    return str(int(round(value)))

for image_rel, xml_rel in TARGETS:
    image_path = MOD / image_rel
    if not image_path.is_file():
        raise SystemExit(f"Required texture missing: {image_path}")

    with Image.open(image_path) as source:
        original_w, original_h = source.size
        factor = min(1.0, MAX_TEXTURE / max(original_w, original_h))
        if factor == 1.0:
            print(f"Already GPU-safe: {image_path} ({original_w}x{original_h})")
            continue
        new_size = (max(1, round(original_w * factor)), max(1, round(original_h * factor)))
        resized = source.convert("RGBA").resize(new_size, Image.Resampling.LANCZOS)
        resized.save(image_path, format="PNG", optimize=True)

    if xml_rel:
        xml_path = MOD / xml_rel
        if not xml_path.is_file():
            raise SystemExit(f"Required Sparrow XML missing: {xml_path}")
        tree = ET.parse(xml_path)
        root = tree.getroot()
        attrs = ("x", "y", "width", "height", "frameX", "frameY", "frameWidth", "frameHeight")
        for frame in root.findall(".//SubTexture"):
            for attr in attrs:
                raw = frame.get(attr)
                if raw is not None:
                    frame.set(attr, rounded_px(float(raw) * factor))
        tree.write(xml_path, encoding="utf-8", xml_declaration=True)

    print(f"ANDROID_TEXTURE {image_rel}: {original_w}x{original_h} -> {new_size[0]}x{new_size[1]}; compensation={1.0/factor:.9f}")

# Modify only the CI checkout. The checked-in stage and desktop assets remain untouched.
stage_path = MOD / "stages/angelIsland.lua"
stage = stage_path.read_text(encoding="utf-8")
if "ANDROID_TEXTURE_SCALE_COMPENSATION" not in stage:
    stage = stage.replace(
        "\t-- Normal Angel Island layers\n",
        "\t-- ANDROID_TEXTURE_SCALE_COMPENSATION (generated in Android CI only)\n"
        "\tscaleObject('bg', 4.370117188, 4.370117188)\n"
        "\n\t-- Normal Angel Island layers\n",
        1)
    replacements = [
        ("createAnimatedStageSprite('ground', 'angelstage/AIZFloorNormal', 0, -20, 'idle', 24, true, true, 'sparrow')",
         "createAnimatedStageSprite('ground', 'angelstage/AIZFloorNormal', 0, -20, 'idle', 24, true, true, 'sparrow')\n\tscaleObject('ground', 4.37109375, 4.37109375)"),
        ("createAnimatedStageSprite('bgFire', 'angelstage/aizBGFire', 70, 100, 'idle', 24, true, false, 'sparrow')",
         "createAnimatedStageSprite('bgFire', 'angelstage/aizBGFire', 70, 100, 'idle', 24, true, false, 'sparrow')\n\tscaleObject('bgFire', 4.37109375, 4.37109375)"),
        ("createAnimatedStageSprite('groundFire', 'angelstage/AIZFloorFire', 0, -20, 'idle', 24, true, false, 'sparrow')",
         "createAnimatedStageSprite('groundFire', 'angelstage/AIZFloorFire', 0, -20, 'idle', 24, true, false, 'sparrow')\n\tscaleObject('groundFire', 4.37109375, 4.37109375)"),
    ]
    for old, new in replacements:
        if old not in stage:
            raise SystemExit("Could not locate expected stage sprite line: " + old)
        stage = stage.replace(old, new, 1)
    if "scaleObject('bg', 4.370117188" not in stage:
        raise SystemExit("Failed to add static background scale compensation.")
    stage_path.write_text(stage, encoding="utf-8")
