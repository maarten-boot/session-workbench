package sharecheck

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func levels(r Result) string {
	var l []string
	for _, x := range r.Lines {
		l = append(l, x.Level)
	}
	return strings.Join(l, ",")
}

func TestEvaluateShare(t *testing.T) {
	out := "exists 1\nwritable 1\n" +
		`findmnt FSTYPE="virtiofs" SOURCE="share" TARGET="/mnt/my\x20share"` + "\nnames\na\nb\n"
	r := Evaluate(out, []string{"b", "a"}, "~/share", "/mnt/my share")
	if !r.OK || r.FSType != "virtiofs" || r.MountPoint != "/mnt/my share" || levels(r) != "ok,ok,ok,ok" {
		t.Fatalf("%+v", r)
	}
	if !strings.Contains(r.Lines[1].Text, "virtiofs (VM share)") || !strings.Contains(r.Lines[3].Text, "same 2 entries") {
		t.Fatalf("%+v", r.Lines)
	}
}

func TestEvaluateProblems(t *testing.T) {
	r := Evaluate("exists 0\n", []string{"a"}, "/l", "/r")
	if r.OK || r.Exists || levels(r) != "fail" {
		t.Fatalf("missing: %+v", r)
	}
	// A plain folder on the VM's own disk, not writable, other entries.
	r = Evaluate("exists 1\r\nwritable 0\r\n"+`findmnt FSTYPE="ext4" SOURCE="/dev/vda2" TARGET="/"`+"\r\nnames\r\nx\r\na\r\n",
		[]string{"a", "b", "c", "d", "e", "f", "g"}, "/l", "/r")
	if r.OK || levels(r) != "ok,warn,fail,fail" {
		t.Fatalf("local disk: %+v", r)
	}
	if want := "(1 of 7 found there)"; !strings.Contains(r.Lines[3].Text, want) ||
		!strings.Contains(r.Lines[3].Text, "Only here: b, c, d, e, f and 1 more. Only there: x.") {
		t.Fatalf("diff text: %q", r.Lines[3].Text)
	}
	// No findmnt (macOS): df; both empty; no local listing at all.
	r = Evaluate("exists 1\nwritable 1\ndf map auto_home 0 0 0 100% /Volumes/My Share\nnames\n", []string{}, "/l", "/r")
	if r.MountPoint != "/Volumes/My Share" || r.Source != "map auto_home" || levels(r) != "ok,ok,ok,warn" {
		t.Fatalf("df: %+v", r)
	}
	r = Evaluate("exists 1\nwritable 1\ndf /dev/disk1 9 9 9 9% /\nnames\na\n", nil, "", "/r")
	if levels(r) != "ok,warn,ok" {
		t.Fatalf("root fs: %+v", r)
	}
}

// TestScript runs the agent host script here under /bin/sh.
func TestScript(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("needs /bin/sh")
	}
	dir := t.TempDir()
	for _, n := range []string{"a b", ".hidden", "c"} {
		if err := os.WriteFile(filepath.Join(dir, n), nil, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	run := func(p string) string {
		out, err := exec.Command("/bin/sh", "-c", Script(p)).Output()
		if err != nil {
			t.Fatalf("%v: %s", err, out)
		}
		return string(out)
	}
	local, err := LocalNames(dir)
	if err != nil {
		t.Fatal(err)
	}
	r := Evaluate(run(dir), local, dir, dir)
	if !r.Exists || !r.Writable || r.MountPoint == "" || !strings.Contains(r.Lines[len(r.Lines)-1].Text, "same 3 entries") {
		t.Fatalf("%+v", r)
	}
	if r = Evaluate(run(filepath.Join(dir, "it's gone")), local, dir, "x"); r.Exists {
		t.Fatalf("missing dir: %+v", r)
	}
}

func TestGuide(t *testing.T) {
	g := MakeGuide("/home/me/My Share/", "/mnt/my share", "virtiofs", 1000)
	if g.Tag != "my-share" || len(g.Problems) != 0 || len(g.Steps) != 3 {
		t.Fatalf("%+v", g)
	}
	for _, want := range []string{"<access mode='shared'/>", "<driver type='virtiofs'/>",
		"<source dir='/home/me/My Share'/>", "<target dir='my-share'/>"} {
		if !strings.Contains(g.XML, want) {
			t.Errorf("XML lacks %s:\n%s", want, g.XML)
		}
	}
	if g.Commands != "sudo mkdir -p '/mnt/my share'\nsudo mount -t virtiofs my-share '/mnt/my share'\n"+
		"id -u    # must print 1000, your user id here: files keep their owner's number\n" {
		t.Errorf("commands:\n%s", g.Commands)
	}
	if g.Fstab != `echo 'my-share /mnt/my\040share virtiofs defaults 0 0' | sudo tee -a /etc/fstab`+"\n" {
		t.Errorf("fstab: %s", g.Fstab)
	}

	g = MakeGuide("/srv/it's", "~/share", "9p", -1)
	if strings.Contains(g.XML, "memoryBacking") || !strings.Contains(g.XML, "<driver type='path'/>") ||
		!strings.Contains(g.XML, "<source dir='/srv/it&apos;s'/>") || g.Tag != "it-s" {
		t.Errorf("9p XML:\n%s", g.XML)
	}
	if g.Commands != "sudo mkdir -p \"$HOME\"/'share'\nsudo mount -t 9p -o trans=virtio,version=9p2000.L it-s \"$HOME\"/'share'\n" ||
		g.Fstab != "" || len(g.Problems) != 1 || len(g.Steps) != 2 {
		t.Errorf("9p: %+v", g)
	}

	g = MakeGuide(`C:\share`, "", "virtiofs", -1)
	if len(g.Problems) != 2 || g.Tag != "c-share" {
		t.Errorf("windows: %+v", g)
	}
}
