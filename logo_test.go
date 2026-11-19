package main

import (
	"bytes"
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
