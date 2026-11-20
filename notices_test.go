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
	for _, want := range []string{
		"Mozilla Public License Version 2.0", // D2
		"Eclipse Public License",             // ELK (elk-go)
		"Source code: https://github.com/d2lang/d2/tree/",
	} {
		if !strings.Contains(notices, want) {
			t.Errorf("THIRD-PARTY-NOTICES.txt lacks %q", want)
		}
	}
}
