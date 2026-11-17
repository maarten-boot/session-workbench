package main

import "session-workbench/internal/diagram"

// DrawD2 draws a ```d2 block of Notes or a Q&A answer as SVG (SPEC N1d);
// dark: the app's dark theme. The error is D2's message.
func (a *App) DrawD2(source string, dark bool) (string, error) {
	svg, err := diagram.SVG(source, dark)
	return string(svg), err
}
