package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// TestChangesScript runs scripts/changes.sh (SPEC §4.6 About, release notes)
// in a new git repository: sections per tag, newest first; the commits since
// the last tag; a tag build without them; the release notes of one tag; more
// commits than a section shows (no SIGPIPE failure).
func TestChangesScript(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("bash script; CI runs it on Linux and macOS")
	}
	for _, tool := range []string{"bash", "git"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Skip(tool + " not found")
		}
	}
	script, err := filepath.Abs("scripts/changes.sh")
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	run := func(name string, args ...string) string {
		t.Helper()
		c := exec.Command(name, args...)
		c.Dir = dir
		c.Env = append(os.Environ(), "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_NOSYSTEM=1",
			"GIT_AUTHOR_NAME=t", "GIT_AUTHOR_EMAIL=t@example.com",
			"GIT_COMMITTER_NAME=t", "GIT_COMMITTER_EMAIL=t@example.com")
		out, err := c.CombinedOutput()
		if err != nil {
			t.Fatalf("%s %v: %v\n%s", name, args, err, out)
		}
		return string(out)
	}
	commit := func(msg string) { run("git", "commit", "-q", "--allow-empty", "-m", msg+"\n\nbody line") }
	changes := func(args ...string) string { return run("bash", append([]string{script}, args...)...) }

	run("git", "init", "-q", "-b", "main")
	commit("first")
	run("git", "tag", "v1.0.0")
	commit("second")
	commit("third")
	run("git", "tag", "-a", "-m", "release", "v1.0.10") // annotated; sorts after v1.0.9
	run("git", "tag", "v1.0.9", "HEAD~1")

	want := "## v1.0.10 (DATE)\n- third\n\n## v1.0.9 (DATE)\n- second\n\n## v1.0.0 (DATE)\n- first\n\n"
	day := strings.TrimSpace(run("git", "log", "-1", "--format=%cs"))
	want = strings.ReplaceAll(want, "DATE", day)
	if got := changes(); got != want {
		t.Errorf("tag build:\n%s\nwant:\n%s", got, want)
	}
	if got, w := changes("--release", "v1.0.10"), "## Changes since v1.0.9\n\n- third\n"; got != w {
		t.Errorf("release v1.0.10: %q, want %q", got, w)
	}
	if got, w := changes("--release", "v1.0.0"), "## Changes\n\n- first\n"; got != w {
		t.Errorf("release v1.0.0: %q, want %q", got, w)
	}

	for i := 0; i < 70; i++ {
		commit(fmt.Sprintf("work %d", i))
	}
	got := changes()
	if !strings.HasPrefix(got, "## Since v1.0.10 (not released)\n- work 69\n") {
		t.Errorf("between releases: %.80q", got)
	}
	if n := strings.Count(got, "- work "); n != 60 {
		t.Errorf("between releases: %d commits listed, want 60", n)
	}
	if strings.Contains(got, "body line") {
		t.Error("only subject lines belong in the list")
	}
}
