package sharecheck

import (
	"fmt"
	"path"
	"strings"

	"session-workbench/internal/remote"
)

// Guide is what shares the local prefix into a KVM/libvirt VM whose agent
// host mounts it at the remote prefix (Settings helper of the host dialog,
// the same steps as docs/TUTORIAL.md "KVM: a virtiofs share").
type Guide struct {
	Driver   string   `json:"driver"` // virtiofs | 9p
	Tag      string   `json:"tag"`    // the target dir: the name the VM mounts
	Steps    []string `json:"steps"`  // in virt-manager
	XML      string   `json:"xml"`    // for virsh edit
	Commands string   `json:"commands"`
	Fstab    string   `json:"fstab"`    // "" when the mount point is not absolute
	Problems []string `json:"problems"` // why the guide cannot be used as is
}

// tag makes the target name: the folder's name, kept to what mount accepts everywhere.
func tag(dir string) string {
	var b strings.Builder
	for _, c := range strings.ToLower(path.Base(dir)) {
		switch {
		case c >= 'a' && c <= 'z', c >= '0' && c <= '9', c == '-', c == '_':
			b.WriteRune(c)
		case b.Len() > 0 && !strings.HasSuffix(b.String(), "-"):
			b.WriteByte('-')
		}
		if b.Len() >= 36 {
			break
		}
	}
	t := strings.Trim(b.String(), "-")
	if t == "" || t == "/" {
		return "share"
	}
	return t
}

// xmlAttr escapes a value for a single-quoted XML attribute.
func xmlAttr(s string) string {
	return strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;", "'", "&apos;", `"`, "&quot;").Replace(s)
}

// fstabField escapes spaces and tabs the way fstab reads them.
func fstabField(s string) string {
	return strings.NewReplacer(`\`, `\134`, " ", `\040`, "\t", `\011`).Replace(s)
}

// MakeGuide writes the guide. source is the local prefix with ~ expanded
// (the folder libvirt shares), mount the remote prefix, uid the local user
// id (-1: unknown).
func MakeGuide(source, mount, driver string, uid int) Guide {
	if driver != "9p" {
		driver = "virtiofs"
	}
	g := Guide{Driver: driver}
	if source == "" || !strings.HasPrefix(source, "/") {
		g.Problems = append(g.Problems, "The local prefix must be an absolute Linux path: libvirt/KVM shares a folder of a Linux computer.")
	}
	if mount == "" {
		g.Problems = append(g.Problems, "Give the remote prefix: where the VM mounts the folder (e.g. /mnt/share).")
		mount = "/mnt/share"
	}
	if source == "" {
		source = "/home/me/share"
	}
	source = path.Clean(source)
	g.Tag = tag(source)

	devDriver, mountOpts, fsType := "virtiofs", "", "virtiofs"
	if driver == "9p" {
		devDriver, mountOpts, fsType = "path", "trans=virtio,version=9p2000.L", "9p"
	}
	var x strings.Builder
	if driver == "virtiofs" {
		x.WriteString("<memoryBacking>\n  <source type='memfd'/>\n  <access mode='shared'/>\n</memoryBacking>\n...\n")
	}
	fmt.Fprintf(&x, "<devices>\n  <filesystem type='mount' accessmode='passthrough'>\n    <driver type='%s'/>\n"+
		"    <source dir='%s'/>\n    <target dir='%s'/>\n  </filesystem>\n</devices>\n", devDriver, xmlAttr(source), g.Tag)
	g.XML = x.String()

	if driver == "virtiofs" {
		g.Steps = append(g.Steps, "Memory: tick “Enable shared memory”.")
	}
	g.Steps = append(g.Steps,
		"Add Hardware → Filesystem: driver “"+map[string]string{"virtiofs": "virtiofs", "9p": "virtio-9p"}[driver]+
			"”, source path “"+source+"”, target path “"+g.Tag+"”.",
		"Shut the VM down and start it again (a reboot inside the VM does not add the device).")

	mp := remote.ShellPath(mount)
	opt := ""
	if mountOpts != "" {
		opt = " -o " + mountOpts
	}
	g.Commands = "sudo mkdir -p " + mp + "\nsudo mount -t " + fsType + opt + " " + g.Tag + " " + mp + "\n"
	if strings.HasPrefix(mount, "/") {
		o := "defaults"
		if mountOpts != "" {
			o = mountOpts + ",_netdev"
		}
		line := g.Tag + " " + fstabField(path.Clean(mount)) + " " + fsType + " " + o + " 0 0"
		g.Fstab = "echo " + remote.Quote(line) + " | sudo tee -a /etc/fstab\n"
	} else {
		g.Problems = append(g.Problems, "/etc/fstab needs an absolute mount point: write the remote prefix without ~ to get its line.")
	}
	if uid >= 0 {
		g.Commands += fmt.Sprintf("id -u    # must print %d, your user id here: files keep their owner's number\n", uid)
	}
	return g
}
