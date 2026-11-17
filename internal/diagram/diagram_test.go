package diagram

import (
	"strings"
	"testing"
)

func TestSVG(t *testing.T) {
	svg, err := SVG("web -> api: REST\napi -> db", false)
	if err != nil {
		t.Fatal(err)
	}
	s := string(svg)
	if !strings.HasPrefix(s, "<svg") || !strings.Contains(s, "REST") || !strings.Contains(s, ">web<") {
		t.Fatalf("not the diagram: %.200s", s)
	}
	if strings.Contains(s, "@font-face") || strings.Contains(s, "-font-bold") {
		t.Error("embedded fonts left")
	}
	if !strings.Contains(s, "font-weight: bold") || !strings.Contains(s, "sans-serif") {
		t.Error("no system font for bold text")
	}
	if strings.Contains(s, "#676C7E") || strings.Contains(s, "#0A0F25") || !strings.Contains(s, `fill="#000000"`) {
		t.Error("text not black")
	}
	if strings.Contains(s, "<?xml") {
		t.Error("an XML declaration")
	}
	dark, err := SVG("web -> api", true)
	if err != nil {
		t.Fatal(err)
	}
	light, _ := SVG("web -> api", false)
	if string(dark) == string(light) {
		t.Error("dark is the same as light")
	}
}

func TestSVGErrors(t *testing.T) {
	for _, c := range []struct{ src, want string }{
		{"", "empty"},
		{"a -> b\nc: {", "2:"}, // D2's line and column
		{"vars: {d2-config: {layout-engine: tala}}\na -> b", "tala"}, // the paid engine
		{"...@/etc/passwd\na -> b", "passwd"},                        // no files read
		{strings.Repeat("a", MaxSource+1), "larger"},
	} {
		_, err := SVG(c.src, false)
		if err == nil || !strings.Contains(err.Error(), c.want) {
			t.Errorf("%q: %v, want %q", c.src[:min(len(c.src), 30)], err, c.want)
		}
	}
}

func TestSVGElk(t *testing.T) {
	if _, err := SVG("vars: {d2-config: {layout-engine: elk}}\na -> b", false); err != nil {
		t.Fatal(err)
	}
}

func TestSystemFonts(t *testing.T) {
	in := `@font-face {
	font-family: d2-1-font-bold;
	src: url("data:x");
}
.a { font-family: "d2-1-font-bold"; }
.b { font-family: "d2-1-font-mono-italic"; }
.c { font-family: "d2-1-font-semibold"; }`
	out := string(systemFonts([]byte(in)))
	for _, want := range []string{
		`.a { font-family: "Source Sans Pro"`, `sans-serif; font-weight: bold; }`,
		`.b { font-family: "Source Code Pro"`, `monospace; font-style: italic; }`,
		`font-weight: 600; }`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("no %q in\n%s", want, out)
		}
	}
	if strings.Contains(out, "@font-face") || strings.Contains(out, "data:") {
		t.Errorf("font face left:\n%s", out)
	}
}
