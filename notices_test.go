package main

import (
	"encoding/json"
	"os"
	"regexp"
	"strings"
	"testing"
)

// THIRD-PARTY-NOTICES.txt (shipped beside the binary) is made for the module
// versions in go.mod and frontend/package-lock.json: after updating a module
// or package, run `make notices`.
func TestThirdPartyNotices(t *testing.T) {
	mod, err := os.ReadFile("go.mod")
	if err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile("THIRD-PARTY-NOTICES.txt")
	if err != nil {
		t.Fatal(err)
	}
	notices := strings.ReplaceAll(string(b), "\r\n", "\n")
	for _, m := range []string{"github.com/d2lang/d2", "github.com/d2lang/util-go"} {
		v := regexp.MustCompile(`(?m)^\s*` + regexp.QuoteMeta(m) + ` (v\S+)`).FindStringSubmatch(string(mod))
		if v == nil {
			t.Fatalf("%s not in go.mod", m)
		}
		if !strings.Contains(notices, " "+m+" "+v[1]+"\n") {
			t.Errorf("THIRD-PARTY-NOTICES.txt is not for %s %s: run make notices", m, v[1])
		}
	}
	// Part 4, the Go modules: each listed version is go.mod's.
	gomods := regexp.MustCompile(`(?m)^   - (\S+) (v\S+) \(.+\)$`).FindAllStringSubmatch(notices, -1)
	if len(gomods) < 10 {
		t.Errorf("THIRD-PARTY-NOTICES.txt lists %d Go modules", len(gomods))
	}
	for _, l := range gomods {
		if !regexp.MustCompile(`(?m)^\s*` + regexp.QuoteMeta(l[1]) + ` ` + regexp.QuoteMeta(l[2]) + `\b`).MatchString(string(mod)) {
			t.Errorf("THIRD-PARTY-NOTICES.txt lists %s %s, go.mod has another version: run make notices", l[1], l[2])
		}
	}
	// Part 6, the JavaScript packages: each listed version is the lock file's.
	lb, err := os.ReadFile("frontend/package-lock.json")
	if err != nil {
		t.Fatal(err)
	}
	var lock struct {
		Packages map[string]struct {
			Version string
			Dev     bool
		} `json:"packages"`
	}
	if err := json.Unmarshal(lb, &lock); err != nil {
		t.Fatal(err)
	}
	jsmods := regexp.MustCompile(`(?m)^   - (\S+) ([0-9]\S*) \(.+\)$`).FindAllStringSubmatch(notices, -1)
	if len(jsmods) < 10 {
		t.Errorf("THIRD-PARTY-NOTICES.txt lists %d JavaScript packages", len(jsmods))
	}
	listed := map[string]bool{}
	for _, l := range jsmods {
		listed[l[1]] = true
		if v := lock.Packages["node_modules/"+l[1]].Version; v != l[2] {
			t.Errorf("THIRD-PARTY-NOTICES.txt lists %s %s, package-lock.json has %q: run make notices", l[1], l[2], v)
		}
	}
	// Every package the frontend is built from is listed (a Go module that
	// is missing is caught in CI: scripts/notices.sh must not change the file).
	for k, p := range lock.Packages {
		i := strings.LastIndex(k, "node_modules/")
		if i < 0 || p.Dev {
			continue // the project itself, or only for building and testing
		}
		if name := k[i+len("node_modules/"):]; !listed[name] {
			t.Errorf("THIRD-PARTY-NOTICES.txt does not list %s %s (package-lock.json): run make notices", name, p.Version)
		}
	}
	for _, want := range []string{
		"Mozilla Public License Version 2.0", // D2
		"Eclipse Public License",             // ELK (elk-go)
		"Apache License",                     // part 4
		"--- go.yaml.in/yaml/v4 ",            // a NOTICE file
		"--- github.com/anthropics/anthropic-sdk-go/v2 ",
		"--- github.com/wailsapp/wails/v2 ", // MIT
		"--- golang.org/x/sys ",             // BSD
		"=== 5. Go ===",
		"--- @xterm/xterm ",
		"=== 7. Spelling dictionary ===",
		"Source code: https://github.com/d2lang/d2/tree/",
	} {
		if !strings.Contains(notices, want) {
			t.Errorf("THIRD-PARTY-NOTICES.txt lacks %q", want)
		}
	}
}
