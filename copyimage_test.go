package main

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestPNGImage(t *testing.T) {
	png := "\x89PNG\r\n\x1a\n" + "rest"
	got, err := pngImage(base64.StdEncoding.EncodeToString([]byte(png)))
	if err != nil || string(got) != png {
		t.Fatalf("%q %v", got, err)
	}
	for _, c := range []struct{ in, want string }{
		{"not base64!", "not base64"},
		{base64.StdEncoding.EncodeToString([]byte("GIF89a")), "not a PNG"},
		{strings.Repeat("A", maxImage/3*4+8), "larger"},
	} {
		if _, err := pngImage(c.in); err == nil || !strings.Contains(err.Error(), c.want) {
			t.Errorf("%.20q: %v, want %q", c.in, err, c.want)
		}
	}
}
