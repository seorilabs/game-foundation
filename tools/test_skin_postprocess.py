import unittest
from PIL import Image
import skin_postprocess as sp

class SkinPostprocessTests(unittest.TestCase):
    def test_chroma_key_is_idempotent_and_keys_magenta(self):
        im = Image.new('RGBA', (8, 8), (255, 0, 255, 255))
        im.putpixel((3, 3), (120, 80, 40, 255))
        im.putpixel((5, 5), (200, 60, 190, 255))  # 가장자리 번짐 픽셀
        once = sp.chroma_key(im)
        self.assertEqual(0, once.getpixel((0, 0))[3])
        self.assertEqual((120, 80, 40, 255), once.getpixel((3, 3)))
        self.assertEqual(list(once.getdata()), list(sp.chroma_key(once).getdata()))

    def test_tileable_wraps_end_into_start(self):
        # 가로 그라데이션: 반복 구간 끝(열 W-r-1)과 다음 반복의 시작(열 l)이 이어져야 한다.
        W, H, l, r = 40, 10, 8, 8
        im = Image.new('RGBA', (W, H))
        for x in range(W):
            for y in range(H):
                im.putpixel((x, y), (x * 6, 0, 0, 255))
        out = sp.tileable(im, [l, 0, r, 0], ['h'], k_face=6)
        end = out.getpixel((W - r - 1, 5))[0]
        start = out.getpixel((l, 5))[0]
        self.assertLessEqual(abs(start - end), 12)
        # 모서리 조각 → 첫 타일 경계도 이어진다
        self.assertLessEqual(abs(out.getpixel((l - 1, 5))[0] - start), 12)
        # 모서리 조각의 바깥쪽과 오른쪽 모서리 조각은 바뀌지 않는다
        self.assertEqual(im.getpixel((0, 5)), out.getpixel((0, 5)))
        self.assertEqual(im.getpixel((W - r, 5)), out.getpixel((W - r, 5)))

    def test_trim_alpha_removes_transparent_padding(self):
        im = Image.new('RGBA', (20, 10), (0, 0, 0, 0))
        for x in range(3, 15):
            for y in range(2, 8):
                im.putpixel((x, y), (10, 10, 10, 255))
        self.assertEqual((12, 6), sp.trim_alpha(im).size)

if __name__ == '__main__': unittest.main()
