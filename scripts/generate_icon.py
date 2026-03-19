#!/usr/bin/env python3
"""Generate MathInsert app icons in neobrutalist style."""

from PIL import Image, ImageDraw, ImageFont
import os

SIZES = [16, 32, 64, 128, 256, 512, 1024]
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "MathInsert", "Assets.xcassets", "AppIcon.appiconset")
README_DIR = os.path.join(os.path.dirname(__file__), "..")


def draw_icon(size: int) -> Image.Image:
    """Draw a neobrutalist math icon at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pad = max(1, size // 32)

    # Background - deep charcoal with full opacity
    bg_rect = [0, 0, size, size]
    draw.rounded_rectangle(bg_rect, radius=size // 5, fill=(30, 30, 35, 255))

    # Thick border - pink accent
    border_w = max(1, size // 20)
    draw.rounded_rectangle(
        bg_rect, radius=size // 5, fill=None,
        outline=(255, 115, 140, 255), width=border_w
    )

    # Inner filled box - slightly lighter
    inset = size // 6
    inner = [inset, inset, size - inset, size - inset]
    draw.rounded_rectangle(inner, radius=size // 10, fill=(50, 50, 58, 255))
    draw.rounded_rectangle(
        inner, radius=size // 10, fill=None,
        outline=(255, 255, 255, 60), width=max(1, border_w // 2)
    )

    # Draw the sigma symbol
    sigma = "\u03A3"  # Capital sigma
    # Try to find a good font
    font_size = int(size * 0.48)
    font = None
    for font_name in [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    ]:
        try:
            font = ImageFont.truetype(font_name, font_size)
            break
        except (OSError, IOError):
            continue

    if font is None:
        font = ImageFont.load_default()

    # Center the sigma
    bbox = draw.textbbox((0, 0), sigma, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) // 2 - bbox[0]
    ty = (size - th) // 2 - bbox[1] - size // 20

    # Shadow
    shadow_off = max(1, size // 60)
    draw.text((tx + shadow_off, ty + shadow_off), sigma, fill=(0, 0, 0, 120), font=font)

    # Main sigma in yellow accent
    draw.text((tx, ty), sigma, fill=(255, 217, 64, 255), font=font)

    # Small "png" label at bottom
    label_size = max(6, int(size * 0.12))
    for label_font_name in [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
    ]:
        try:
            label_font = ImageFont.truetype(label_font_name, label_size)
            break
        except (OSError, IOError):
            label_font = ImageFont.load_default()

    label = "PNG"
    lbox = draw.textbbox((0, 0), label, font=label_font)
    lw = lbox[2] - lbox[0]
    lx = (size - lw) // 2 - lbox[0]
    ly = size - inset - label_size + size // 20
    draw.text((lx, ly), label, fill=(255, 255, 255, 200), font=label_font)

    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # Generate each size
    for s in SIZES:
        icon = draw_icon(s)
        icon.save(os.path.join(OUT_DIR, f"icon_{s}x{s}.png"))
        # @2x variants
        if s <= 512:
            icon_2x = draw_icon(s * 2)
            icon_2x.save(os.path.join(OUT_DIR, f"icon_{s}x{s}@2x.png"))

    # Contents.json for asset catalog
    images = []
    icon_sizes = [16, 32, 128, 256, 512]
    for s in icon_sizes:
        images.append({
            "filename": f"icon_{s}x{s}.png",
            "idiom": "mac",
            "scale": "1x",
            "size": f"{s}x{s}"
        })
        images.append({
            "filename": f"icon_{s}x{s}@2x.png",
            "idiom": "mac",
            "scale": "2x",
            "size": f"{s}x{s}"
        })

    import json
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    with open(os.path.join(OUT_DIR, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

    # Generate a larger icon for the README
    readme_icon = draw_icon(256)
    readme_icon.save(os.path.join(README_DIR, "icon.png"))

    print(f"Generated {len(SIZES) + 5} icon files + Contents.json")


if __name__ == "__main__":
    main()
