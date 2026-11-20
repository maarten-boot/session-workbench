package main

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

// THIRD-PARTY-NOTICES.txt (shipped beside the binary) is made for the D2
// versions in go.mod: after updating D2, run `make notices`.
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
	// Part 4, the Apache-licensed modules: each listed version is go.mod's.
	listed := regexp.MustCompile(`(?m)^   - (\S+) (v\S+)$`).FindAllStringSubmatch(notices, -1)
	if len(listed) == 0 {
		t.Error("THIRD-PARTY-NOTICES.txt lists no Apache-licensed modules")
	}
	for _, l := range listed {
		if !regexp.MustCompile(`(?m)^\s*` + regexp.QuoteMeta(l[1]) + ` ` + regexp.QuoteMeta(l[2]) + `\b`).MatchString(string(mod)) {
			t.Errorf("THIRD-PARTY-NOTICES.txt lists %s %s, go.mod has another version: run make notices", l[1], l[2])
		}
	}
	for _, want := range []string{
		"Mozilla Public License Version 2.0", // D2
		"Eclipse Public License",             // ELK (elk-go)
		"Apache License",                     // part 4
		"--- go.yaml.in/yaml/v4 ",            // a NOTICE file
		"--- github.com/anthropics/anthropic-sdk-go/v2 ",
		"Source code: https://github.com/d2lang/d2/tree/",
	} {
		if !strings.Contains(notices, want) {
			t.Errorf("THIRD-PARTY-NOTICES.txt lacks %q", want)
		}
	}
}
