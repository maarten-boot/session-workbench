// Package diagram draws D2 diagrams (```d2 blocks in Notes and Q&A,
// SPEC N1c) as SVG, in the app: no d2 program needed. Only the free layout
// engines (dagre, the default, and elk); imports read nothing from disk.
package diagram

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"log/slog"
	"regexp"
	"strings"
	"sync"
	"time"

	"oss.terrastruct.com/d2/d2graph"
	"oss.terrastruct.com/d2/d2layouts/d2dagrelayout"
	"oss.terrastruct.com/d2/d2layouts/d2elklayout"
	"oss.terrastruct.com/d2/d2lib"
	"oss.terrastruct.com/d2/d2renderers/d2svg"
	"oss.terrastruct.com/d2/d2target"
	"oss.terrastruct.com/d2/lib/log"
	"oss.terrastruct.com/d2/lib/textmeasure"
	"oss.terrastruct.com/util-go/go2"
)

// MaxSource is the largest diagram text drawn (bytes).
const MaxSource = 64 << 10

// Timeout limits one drawing.
var Timeout = 15 * time.Second

// The themes: D2's default and, for the app's dark look, Dark Mauve; their
// text is made black (white) in draw.
const (
	lightTheme int64 = 0
	darkTheme  int64 = 200
)

var (
	mu    sync.Mutex // the ruler and the layout engines are not safe to share
	ruler *textmeasure.Ruler
)

// noFiles is an empty file system: an import (`...@file`) finds nothing,
// so a diagram (also one in a Q&A answer) cannot read local files.
type noFiles struct{}

func (noFiles) Open(name string) (fs.File, error) {
	return nil, &fs.PathError{Op: "open", Path: name, Err: fs.ErrNotExist}
}

func layout(engine string) (d2graph.LayoutGraph, error) {
	switch engine {
	case "", "dagre":
		return func(ctx context.Context, g *d2graph.Graph) error { return d2dagrelayout.Layout(ctx, g, nil) }, nil
	case "elk":
		return func(ctx context.Context, g *d2graph.Graph) error { return d2elklayout.Layout(ctx, g, nil) }, nil
	}
	return nil, fmt.Errorf("layout engine %q is not available (dagre or elk)", engine)
}

// SVG draws D2 source as an SVG document; dark picks the dark theme. An
// error is D2's message (with its line and column) or a limit.
func SVG(source string, dark bool) ([]byte, error) {
	if strings.TrimSpace(source) == "" {
		return nil, errors.New("the diagram is empty")
	}
	if len(source) > MaxSource {
		return nil, fmt.Errorf("the diagram is larger than %d KB", MaxSource>>10)
	}
	type result struct {
		svg []byte
		err error
	}
	done := make(chan result, 1)
	ctx, cancel := context.WithTimeout(context.Background(), Timeout)
	defer cancel()
	// D2 logs (with a stack trace) when it has no logger: give it one that
	// says nothing.
	ctx = log.With(ctx, slog.New(slog.DiscardHandler))
	go func() {
		svg, err := draw(ctx, source, dark)
		done <- result{svg, err}
	}()
	select {
	case r := <-done:
		return r.svg, r.err
	case <-ctx.Done():
		return nil, fmt.Errorf("drawing took longer than %s", Timeout)
	}
}

func draw(ctx context.Context, source string, dark bool) (svg []byte, err error) {
	mu.Lock()
	defer mu.Unlock()
	defer func() {
		if r := recover(); r != nil { // a D2 bug must not end the app
			svg, err = nil, fmt.Errorf("d2 failed: %v", r)
		}
	}()
	if ruler == nil {
		if ruler, err = textmeasure.NewRuler(); err != nil {
			return nil, err
		}
	}
	// Text in black (white when dark), not D2's grey: N1 is labels, N2
	// edge labels.
	theme, text := lightTheme, "#000000"
	if dark {
		theme, text = darkTheme, "#FFFFFF"
	}
	colours := &d2target.ThemeOverrides{N1: &text, N2: &text}
	// The app's theme, not the screen's: no dark stylesheet unless the
	// diagram asks for one (its own d2-config wins only there).
	render := &d2svg.RenderOpts{
		Pad:            go2.Pointer(int64(16)),
		Scale:          go2.Pointer(1.0), // its own size (not the page width); the page shrinks a wide one
		ThemeID:        &theme,
		ThemeOverrides: colours,
		NoXMLTag:       go2.Pointer(true),
		OmitVersion:    go2.Pointer(true),
	}
	diagram, _, err := d2lib.Compile(ctx, source, &d2lib.CompileOptions{
		FS:             noFiles{},
		Ruler:          ruler,
		LayoutResolver: layout, // dagre unless the diagram's vars pick elk
	}, render)
	if err != nil {
		return nil, err
	}
	svg, err = d2svg.Render(diagram, render)
	if err != nil {
		return nil, err
	}
	return systemFonts(svg), nil
}

var (
	fontFace   = regexp.MustCompile(`(?s)@font-face\s*\{.*?\}`)
	fontFamily = regexp.MustCompile(`font-family:\s*"?[\w-]+-font-(regular|semibold|bold|italic|mono-bold|mono-italic|mono)"?\s*;`)
)

const (
	sans = `"Source Sans Pro", "Noto Sans", "DejaVu Sans", "Segoe UI", Helvetica, Arial, sans-serif`
	mono = `"Source Code Pro", "DejaVu Sans Mono", "Cascadia Mono", Menlo, monospace`
)

// systemFonts drops D2's embedded fonts for the system's: the web view
// draws no text with fonts embedded in an SVG shown as an image. Bold and
// italic stay.
func systemFonts(svg []byte) []byte {
	svg = fontFace.ReplaceAll(svg, nil)
	return fontFamily.ReplaceAllFunc(svg, func(m []byte) []byte {
		kind := string(fontFamily.FindSubmatch(m)[1])
		family := sans
		if strings.HasPrefix(kind, "mono") {
			family = mono
		}
		css := "font-family: " + family + ";"
		switch {
		case strings.HasSuffix(kind, "semibold"):
			css += " font-weight: 600;"
		case strings.HasSuffix(kind, "bold"):
			css += " font-weight: bold;"
		case strings.HasSuffix(kind, "italic"):
			css += " font-style: italic;"
		}
		return []byte(css)
	})
}
