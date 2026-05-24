"""
APK icon (1024x1024) generator — mor gradient arka plan + beyaz mezuniyet kepi.
Çıktı: assets/icon/app_icon.png

Çalıştırmak:
  python make_icon.py
"""
from PIL import Image, ImageDraw, ImageFilter
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon', 'app_icon.png')

# Mor gradient (sol üst → sağ alt)
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Gradient (#4F46E5 → #7C3AED)
c1 = (79, 70, 229)
c2 = (124, 58, 237)
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * SIZE)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        img.putpixel((x, y), (r, g, b, 255))

draw = ImageDraw.Draw(img)

# Mezuniyet kepi (beyaz)
cx = SIZE // 2
cy = SIZE // 2 + 20

# 1) Üst kare (mortarboard) — eşkenar dörtgen perspektif
top_w = 620
top_h = 180
top_y = cy - 220
# Eşkenar dörtgen: sol-üst, sağ, sağ-alt, sol
mortar = [
    (cx, top_y),
    (cx + top_w // 2, top_y + top_h // 2),
    (cx, top_y + top_h),
    (cx - top_w // 2, top_y + top_h // 2),
]
draw.polygon(mortar, fill=(255, 255, 255, 255))

# 2) Kafa bandı (alt) — yamuk
band_top_y = cy - 30
band_bot_y = cy + 160
band_top_w = 320
band_bot_w = 380
band = [
    (cx - band_top_w // 2, band_top_y),
    (cx + band_top_w // 2, band_top_y),
    (cx + band_bot_w // 2, band_bot_y),
    (cx - band_bot_w // 2, band_bot_y),
]
draw.polygon(band, fill=(255, 255, 255, 255))

# 3) Bant ile mortarboard arasındaki köprü (küçük dikdörtgen)
draw.rectangle(
    [(cx - band_top_w // 2, top_y + top_h - 10),
     (cx + band_top_w // 2, band_top_y + 10)],
    fill=(255, 255, 255, 0),
)

# 4) Tassel (püskül) — sağ tarafa sarkar
tassel_start = (cx + top_w // 2 - 30, top_y + top_h // 2)
# İnce çizgi
draw.line(
    [tassel_start, (tassel_start[0] + 20, tassel_start[1] + 140)],
    fill=(255, 255, 255, 255), width=10,
)
# Püskül topu (sarı/altın)
draw.ellipse(
    [(tassel_start[0], tassel_start[1] + 130),
     (tassel_start[0] + 40, tassel_start[1] + 200)],
    fill=(255, 200, 80, 255),
)

# Köşeleri yuvarla (super-ellipse mask değil, basit rounded mask)
mask = Image.new('L', (SIZE, SIZE), 0)
mdraw = ImageDraw.Draw(mask)
mdraw.rounded_rectangle([(0, 0), (SIZE, SIZE)], radius=200, fill=255)
out = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
out.paste(img, (0, 0), mask)

out.save(OUT, 'PNG')
print(f'OK: {OUT}')
