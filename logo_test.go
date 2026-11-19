package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image"
	"image/png"
	"os"
	"testing"
)

// TestLogoCopy: the About page's logo (frontend/src/assets/logo.png, which
// the frontend build can load) is the README's docs/logo.png (SPEC §4.6 About).
func TestLogoCopy(t *testing.T) {
	a, err := os.ReadFile("docs/logo.png")
	if err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile("frontend/src/assets/logo.png")
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(a, b) {
		t.Fatal("frontend/src/assets/logo.png differs from docs/logo.png: copy it again")
	}
}

func readPNG(t *testing.T, path string) image.Image {
	t.Helper()
	f, err := os.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	img, err := png.Decode(f)
	if err != nil {
		t.Fatalf("%s: %v", path, err)
	}
	return img
}

// blueAt: the logo's dark blue square, opaque.
func blueAt(img image.Image, x, y int) bool {
	r, g, b, a := img.At(x, y).RGBA()
	return a == 0xffff && b > r+0x4000 && b > g
}

// icoImage decodes one image of an .ico file: a PNG, or a 32-bit bitmap
// without file header (rows bottom up, BGRA, height counting the AND mask too).
func icoImage(b []byte, s int) (image.Image, error) {
	if bytes.HasPrefix(b, []byte("\x89PNG")) {
		return png.Decode(bytes.NewReader(b))
	}
	if len(b) < 40 {
		return nil, fmt.Errorf("short bitmap header")
	}
	hdr := binary.LittleEndian.Uint32(b)
	w, h := int(int32(binary.LittleEndian.Uint32(b[4:]))), int(int32(binary.LittleEndian.Uint32(b[8:])))
	if bpp := binary.LittleEndian.Uint16(b[14:]); bpp != 32 || w != s || h != 2*s {
		return nil, fmt.Errorf("bitmap %dx%d, %d bits, want %dx%d, 32 bits", w, h/2, bpp, s, s)
	}
	px := b[hdr:]
	if len(px) < 4*s*s {
		return nil, fmt.Errorf("bitmap cut short")
	}
	img := image.NewNRGBA(image.Rect(0, 0, s, s))
	for y := 0; y < s; y++ {
		row := px[4*s*(s-1-y):]
		for x := 0; x < s; x++ {
			p := row[4*x:]
			o := img.PixOffset(x, y)
			img.Pix[o], img.Pix[o+1], img.Pix[o+2], img.Pix[o+3] = p[2], p[1], p[0], p[3]
		}
	}
	return img, nil
}

func transparentAt(img image.Image, x, y int) bool {
	_, _, _, a := img.At(x, y).RGBA()
	return a == 0
}

// TestAppIcon: the app icon is the logo's rounded square (SPEC §4.6 About,
// app icon): 1024px, transparent at the corners, the blue square near the
// bottom middle (below the prompt); the smaller icons of the Linux packages
// and Windows are made from it by `make icons`.
func TestAppIcon(t *testing.T) {
	img := readPNG(t, "build/appicon.png")
	if b := img.Bounds(); b.Dx() != 1024 || b.Dy() != 1024 {
		t.Fatalf("build/appicon.png is %dx%d, want 1024x1024", b.Dx(), b.Dy())
	}
	if !transparentAt(img, 0, 0) || !blueAt(img, 512, 900) {
		t.Error("build/appicon.png is not the logo's rounded square on a transparent background")
	}
	for _, s := range []int{256, 128, 48} {
		p := fmt.Sprintf("packaging/icons/%d.png", s)
		small := readPNG(t, p)
		if b := small.Bounds(); b.Dx() != s || b.Dy() != s {
			t.Errorf("%s is %dx%d", p, b.Dx(), b.Dy())
			continue
		}
		if !transparentAt(small, 0, 0) || !blueAt(small, s/2, s*88/100) {
			t.Errorf("%s is not made from build/appicon.png: run make icons", p)
		}
	}

	// icon.ico: a directory of 16-byte entries (width 0 means 256), each image
	// a 32-bit BGRA bitmap as `make icons` writes it (or a PNG).
	ico, err := os.ReadFile("build/windows/icon.ico")
	if err != nil {
		t.Fatal(err)
	}
	if len(ico) < 6 || binary.LittleEndian.Uint16(ico[2:]) != 1 {
		t.Fatal("build/windows/icon.ico is not an icon file")
	}
	n := int(binary.LittleEndian.Uint16(ico[4:]))
	if len(ico) < 6+16*n {
		t.Fatal("build/windows/icon.ico is cut short")
	}
	sizes := map[int]bool{}
	for i := 0; i < n; i++ {
		e := ico[6+16*i:]
		s := int(e[0])
		if s == 0 {
			s = 256
		}
		sizes[s] = true
		size, off := binary.LittleEndian.Uint32(e[8:]), binary.LittleEndian.Uint32(e[12:])
		if uint64(off)+uint64(size) > uint64(len(ico)) {
			t.Fatalf("build/windows/icon.ico: the %d image is cut short", s)
		}
		img, err := icoImage(ico[off:off+size], s)
		if err != nil {
			t.Fatalf("build/windows/icon.ico %d: %v", s, err)
		}
		if s >= 32 && (!transparentAt(img, 0, 0) || !blueAt(img, s/2, s*88/100)) {
			t.Errorf("build/windows/icon.ico %d is not made from build/appicon.png: run make icons", s)
		}
	}
	for _, s := range []int{256, 48, 32, 16} {
		if !sizes[s] {
			t.Errorf("build/windows/icon.ico has no %dx%d image: run make icons", s, s)
		}
	}
}
