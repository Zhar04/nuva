"""
Generate Nuva app icon — concentric Liquid Glass ripples on blue gradient.
Output: assets/images/icon.png (1024x1024) + icon_foreground.png (adaptive).
Run: python tool/make_icon.py
"""
from PIL import Image, ImageDraw, ImageFilter
import os, math

SIZE = 1024
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
os.makedirs(OUT_DIR, exist_ok=True)


def make_gradient(w, h, start, end):
    base = Image.new('RGB', (w, h), start)
    top = Image.new('RGB', (w, h), end)
    mask = Image.new('L', (w, h))
    for y in range(h):
        for x in range(w):
            d = ((x - w * 0.3) ** 2 + (y - h * 0.3) ** 2) ** 0.5
            t = min(255, int(d / (w * 1.1) * 255))
            mask.putpixel((x, y), t)
    base.paste(top, (0, 0), mask)
    return base


def rounded_mask(size, radius):
    m = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return m


def draw_ripples(img, center, max_radius, ring_count, ring_width, color):
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    cx, cy = center
    for i in range(ring_count):
        r = max_radius * (i + 1) / ring_count
        bbox = (cx - r, cy - r, cx + r, cy + r)
        # Fade outer rings slightly
        alpha = int(255 * (0.55 + 0.45 * (1 - i / ring_count)))
        d.ellipse(bbox, outline=color + (alpha,), width=int(ring_width))
    # Slight glow on rings
    overlay = overlay.filter(ImageFilter.GaussianBlur(1.2))
    img.paste(overlay, (0, 0), overlay)


def make_icon_full(size=SIZE):
    bg = make_gradient(size, size, (94, 160, 240), (54, 201, 182))
    bg = bg.convert('RGBA')

    # Soft white inner highlight
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-size * 0.2, -size * 0.4, size * 0.7, size * 0.4),
              fill=(255, 255, 255, 60))
    overlay = overlay.filter(ImageFilter.GaussianBlur(60))
    bg = Image.alpha_composite(bg, overlay)

    # Concentric ripples
    cx, cy = size // 2, size // 2
    draw_ripples(bg,
                 center=(cx, cy),
                 max_radius=size * 0.36,
                 ring_count=5,
                 ring_width=size * 0.038,
                 color=(255, 255, 255))

    # Inner solid dot
    d2 = ImageDraw.Draw(bg)
    r = size * 0.05
    d2.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 255))

    # Round corners (iOS-style superellipse approximated with radius)
    corner_radius = int(size * 0.22)
    mask = rounded_mask(size, corner_radius)
    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final.paste(bg, (0, 0), mask)
    return final


def make_icon_foreground(size=SIZE):
    """Transparent background — the ripples + dot only. For Android adaptive."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cx, cy = size // 2, size // 2
    # Slightly smaller so it doesn't clip in adaptive mask
    draw_ripples(img,
                 center=(cx, cy),
                 max_radius=size * 0.28,
                 ring_count=5,
                 ring_width=size * 0.030,
                 color=(255, 255, 255))
    d = ImageDraw.Draw(img)
    r = size * 0.04
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 255))
    return img


def make_splash(size=SIZE):
    """Flat colored splash logo for native_splash."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cx, cy = size // 2, size // 2
    draw_ripples(img,
                 center=(cx, cy),
                 max_radius=size * 0.3,
                 ring_count=5,
                 ring_width=size * 0.034,
                 color=(94, 160, 240))
    d = ImageDraw.Draw(img)
    r = size * 0.045
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(54, 123, 213, 255))
    return img


if __name__ == '__main__':
    icon = make_icon_full()
    icon.save(os.path.join(OUT_DIR, 'icon.png'), 'PNG')
    print('Wrote icon.png')

    fg = make_icon_foreground()
    fg.save(os.path.join(OUT_DIR, 'icon_foreground.png'), 'PNG')
    print('Wrote icon_foreground.png')

    splash = make_splash()
    splash.save(os.path.join(OUT_DIR, 'splash_logo.png'), 'PNG')
    print('Wrote splash_logo.png')
