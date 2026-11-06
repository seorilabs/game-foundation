#!/usr/bin/env python3
"""그린 스킨 생성 원본(raw)을 최종 9분할 PNG로 만든다.

game-asset-pipeline으로 만든 raw(마젠타 배경)를 manifest의 postprocess 순서대로 처리한다.
  1. chroma_key: 순수 마젠타 배경을 알파로 바꾸고 가장자리 색 번짐을 줄인다(이미 알파가 있으면 같은 결과).
  2. crop_to: 생성 비율(16:9)에서 최종 비율로 가운데를 자른다.
  3. final_canvas: 크기 맞춤(LANCZOS). 아이콘은 alpha bbox로 잘라 정사각 캔버스 가운데에 둔다.
  4. trim_alpha: 투명 여백을 잘라 9분할이 그린 판만 덮게 한다.
  5. tileable: 타일로 반복할 축의 늘어나는 구간 시작을 구간 끝 너머 픽셀과 섞어 이음매를 없앤다.
     margins는 최종 픽셀 기준이며 skin.json의 margins와 같아야 한다.
사용: python3 tools/skin_postprocess.py --manifest art/skins/soft_adventure/asset-manifest.json --raw <raw 폴더> --out godot/addons/seorilabs_game/skins/soft_adventure
"""
import argparse
import json
from pathlib import Path
from PIL import Image

def chroma_key(im):
    im = im.convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            # 이미 처리된 픽셀(알파 < 255)은 건드리지 않는다. 생성 출력은 전부 불투명이라 두 번 적용해도 같다.
            if a < 255:
                continue
            m = min(r, b) - g
            if m > 120 and g < 90:
                px[x, y] = (r, g, b, 0)
            elif m > 40:
                t = max(0.0, min(1.0, (m - 40) / 80.0))
                px[x, y] = (int(r - (r - g) * t * 0.8), g, int(b - (b - g) * t * 0.8), min(a, int(255 * (1 - t))))
    return im

def crop_to(im, size):
    w, h = size
    l, t = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((l, t, l + w, t + h))

def fit_icon(im, size, margin=0.04):
    bbox = im.getchannel('A').getbbox()
    if bbox:
        im = im.crop(bbox)
    inner = max(1, int(size * (1 - 2 * margin)))
    im.thumbnail((inner, inner), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    return canvas

def trim_alpha(im):
    bbox = im.getchannel('A').getbbox()
    return im.crop(bbox) if bbox else im

def _lerp(a, b, t):
    return tuple(int(round(a[i] * (1 - t) + b[i] * t)) for i in range(4))

def tileable(im, margins, axes, band=0, k_band=4, k_face=12):
    """axes에 'h'가 있으면 가로 반복 구간 [l, W-r), 'v'가 있으면 세로 반복 구간 [t, H-b)의 시작 k픽셀을
    구간 끝 바로 뒤(오른쪽·아래 모서리 조각의 첫 픽셀들)와 섞는다. 반복하면 끝 → 시작이 원래 이웃 픽셀로 이어진다.
    band는 바깥 띠 두께(가죽 띠처럼 장식이 끝 너머 가까이 있는 줄)로, 그 줄에는 짧은 k_band를 쓴다."""
    im = im.copy()
    px = im.load()
    W, H = im.size
    l, t, r, b = margins
    if 'h' in axes:
        for y in range(H):
            k = min(k_band if (y < band or y >= H - band) else k_face, r, l)
            # 왼쪽 모서리 조각의 끝을 구간 끝(타일 끝) 쪽으로 섞어 모서리 → 첫 타일 경계도 타일 → 타일과 같게 만든다.
            for i in range(k):
                x = l - k + i
                px[x, y] = _lerp(px[x, y], px[W - r - k + i, y], (i + 1) / k)
            for x in range(k):
                px[l + x, y] = _lerp(px[W - r + x, y], px[l + x, y], x / k)
    if 'v' in axes:
        for x in range(W):
            k = min(k_band if (x < band or x >= W - band) else k_face, b, t)
            for i in range(k):
                y = t - k + i
                px[x, y] = _lerp(px[x, y], px[x, H - b - k + i], (i + 1) / k)
            for y in range(k):
                px[x, t + y] = _lerp(px[x, H - b + y], px[x, t + y], y / k)
    return im

def process(asset, raw_dir, out_dir):
    spec = asset.get('postprocess', {})
    im = Image.open(Path(raw_dir) / (asset['name'] + '.png')).convert('RGBA')
    if spec.get('chroma_key'):
        im = chroma_key(im)
    if spec.get('crop_to'):
        im = crop_to(im, spec['crop_to'])
    if asset.get('final_canvas'):
        fc = asset['final_canvas']
        if im.width * fc['height'] != im.height * fc['width']:
            raise ValueError('%s: aspect mismatch %sx%s -> %sx%s' % (asset['name'], im.width, im.height, fc['width'], fc['height']))
        im = im.resize((fc['width'], fc['height']), Image.Resampling.LANCZOS)
    elif asset.get('size'):
        im = fit_icon(im, asset['size'])
    if spec.get('trim_alpha'):
        im = trim_alpha(im)
    if spec.get('expect_size') and list(im.size) != spec['expect_size']:
        raise ValueError('%s: size %s != expected %s (skin.json margins assume it)' % (asset['name'], list(im.size), spec['expect_size']))
    if spec.get('tileable'):
        tl = spec['tileable']
        im = tileable(im, tl['margins'], tl['axes'], tl.get('band', 0), tl.get('k_band', 4), tl.get('k_face', 12))
    out = Path(out_dir) / (asset['name'] + '.png')
    im.save(out, optimize=True)
    return out, im.size

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--manifest', type=Path, required=True)
    p.add_argument('--raw', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--only', nargs='*')
    a = p.parse_args()
    manifest = json.loads(a.manifest.read_text())
    for asset in manifest['assets']:
        if a.only and asset['name'] not in a.only:
            continue
        out, size = process(asset, a.raw, a.out)
        print('%s %dx%d' % (out.name, *size))

if __name__ == '__main__':
    main()
