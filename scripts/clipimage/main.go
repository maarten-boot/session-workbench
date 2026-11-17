// clipimage writes the clipboard's image (PNG) to a file, for the GUI
// tests (scripts/gui-smoke-d2.sh); it exits non-zero without one. With
// -text it writes the clipboard's text instead.
// usage: go run ./scripts/clipimage [-text] <out>
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"golang.design/x/clipboard"
)

func main() {
	format, args := clipboard.FmtImage, os.Args[1:]
	if len(args) == 2 && args[0] == "-text" {
		format, args = clipboard.FmtText, args[1:]
	}
	if len(args) != 1 {
		fmt.Fprintln(os.Stderr, "usage: clipimage [-text] <out>")
		os.Exit(2)
	}
	if err := clipboard.Init(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	data, err := clipboard.Read(ctx, format)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if err := os.WriteFile(args[0], data, 0o644); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
