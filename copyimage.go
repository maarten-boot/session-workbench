package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"sync"
	"time"

	"golang.design/x/clipboard"
)

// maxImage limits an image put on the clipboard (bytes of PNG).
const maxImage = 32 << 20

var (
	clipOnce sync.Once
	clipErr  error
)

// pngImage checks the frontend's base64 PNG: a PNG, not too large.
func pngImage(b64 string) ([]byte, error) {
	if len(b64) > maxImage/3*4+4 {
		return nil, fmt.Errorf("the image is larger than %d MB", maxImage>>20)
	}
	png, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return nil, errors.New("the image is not base64")
	}
	if !bytes.HasPrefix(png, []byte("\x89PNG\r\n\x1a\n")) {
		return nil, errors.New("the image is not a PNG")
	}
	return png, nil
}

// CopyImage puts a PNG (base64, drawn by the frontend from a diagram or
// picture) on the clipboard (SPEC N1c): Wails copies text only.
func (a *App) CopyImage(b64 string) error {
	png, err := pngImage(b64)
	if err != nil {
		return err
	}
	clipOnce.Do(func() { clipErr = clipboard.Init() })
	if clipErr != nil {
		return fmt.Errorf("no clipboard for images: %w", clipErr)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := clipboard.Write(ctx, clipboard.FmtImage, png); err != nil {
		return fmt.Errorf("copying the image: %w", err)
	}
	return nil
}
