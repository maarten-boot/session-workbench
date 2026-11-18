// Package sharecheck checks a shared file system host (files = "shared"):
// is the remote prefix there on the agent host, is it a mounted share (NFS,
// SMB, virtiofs, 9p …) rather than a plain folder on the agent host's own
// disk, and does it hold the same entries as the local prefix (SPEC F2c).
// It also writes the steps that share a folder into a local KVM/libvirt VM
// (guide.go).
package sharecheck

import (
	"os"
	"sort"
	"strconv"
	"strings"

	"session-workbench/internal/remote"
)

// MaxNames is how many entries of each side are compared; a folder with
// more is not compared (the listing would be cut at different names).
const MaxNames = 5000

// Script is the /bin/sh script run on the agent host. It lists the folder
// first (that mounts an automounted share), then asks which mount holds it
// (findmnt's last line: the mount on top, e.g. NFS over its autofs trigger).
// Output: "exists 0|1", "writable 0|1", "findmnt KEY=\"v\" …" or "df …",
// then "names" and one entry per line.
func Script(remotePrefix string) string {
	return `p=` + remote.ShellPath(remotePrefix) + `
if ! cd "$p" 2>/dev/null; then echo 'exists 0'; exit 0; fi
echo 'exists 1'
if [ -w . ]; then echo 'writable 1'; else echo 'writable 0'; fi
n=$(ls -A | head -n ` + itoa(MaxNames+1) + `)
if command -v findmnt >/dev/null 2>&1; then
  printf 'findmnt %s\n' "$(findmnt -n -P -o FSTYPE,SOURCE,TARGET -T . 2>/dev/null | tail -n 1)"
else
  printf 'df %s\n' "$(df -P . 2>/dev/null | tail -n 1)"
fi
echo names
[ -n "$n" ] && printf '%s\n' "$n"
exit 0
`
}

func itoa(n int) string { return strconv.Itoa(n) }

// Level of one finding; the text says it in words too (no colour-only
// meaning).
const (
	OK   = "ok"
	Warn = "warn"
	Fail = "fail"
)

// Line is one finding.
type Line struct {
	Level string `json:"level"`
	Text  string `json:"text"`
}

// Result is the check of one host's path mapping.
type Result struct {
	Exists     bool   `json:"exists"`
	Writable   bool   `json:"writable"`
	FSType     string `json:"fstype"` // "" when unknown (no findmnt)
	Source     string `json:"source"`
	MountPoint string `json:"mount_point"`
	Lines      []Line `json:"lines"`
	OK         bool   `json:"ok"` // no Fail and no Warn line
}

func (r *Result) add(level, text string) { r.Lines = append(r.Lines, Line{level, text}) }

// shareTypes are file systems that bring another computer's (or the VM
// host's) files; localTypes are the agent host's own disks.
var shareTypes = map[string]string{
	"nfs": "NFS", "nfs4": "NFS", "cifs": "SMB", "smb3": "SMB", "smbfs": "SMB",
	"virtiofs": "virtiofs (VM share)", "9p": "9p (VM share)", "fuse.sshfs": "sshfs",
	"vboxsf": "VirtualBox share", "vmhgfs": "VMware share", "fuse.vmhgfs-fuse": "VMware share",
	"prl_fs": "Parallels share", "afpfs": "AFP", "ceph": "CephFS", "fuse.glusterfs": "GlusterFS",
}

var localTypes = map[string]bool{
	"ext2": true, "ext3": true, "ext4": true, "xfs": true, "btrfs": true, "zfs": true,
	"f2fs": true, "jfs": true, "bcachefs": true, "reiserfs": true, "apfs": true, "hfs": true,
	"tmpfs": true, "overlay": true, "ufs": true,
}

// LocalNames lists the local prefix (~ expanded) for Evaluate; nil when it
// cannot be read (the error says why).
func LocalNames(localPrefix string) ([]string, error) {
	ents, err := os.ReadDir(localPrefix)
	if err != nil {
		return nil, err
	}
	names := make([]string, 0, len(ents))
	for _, e := range ents {
		names = append(names, e.Name())
	}
	return names, nil
}

// Evaluate reads Script's output. local is the local prefix's entries (nil:
// not compared, e.g. no local prefix); localPrefix and remotePrefix are only
// used in the texts.
func Evaluate(out string, local []string, localPrefix, remotePrefix string) Result {
	var r Result
	var remoteNames []string
	inNames := false
	for _, ln := range strings.Split(strings.ReplaceAll(out, "\r\n", "\n"), "\n") {
		if inNames {
			if ln != "" {
				remoteNames = append(remoteNames, ln)
			}
			continue
		}
		key, val, _ := strings.Cut(ln, " ")
		switch key {
		case "exists":
			r.Exists = val == "1"
		case "writable":
			r.Writable = val == "1"
		case "findmnt":
			kv := pairs(val)
			r.FSType, r.Source, r.MountPoint = kv["FSTYPE"], kv["SOURCE"], kv["TARGET"]
		case "df":
			// Filesystem 1024-blocks Used Available Capacity Mounted-on
			// The source ("map auto_home") and mount point may hold
			// spaces: the capacity field (n%) is between the numbers.
			f := strings.Fields(val)
			for i := 4; i < len(f); i++ {
				if strings.HasSuffix(f[i], "%") {
					r.Source = strings.Join(f[:i-3], " ")
					_, r.MountPoint, _ = strings.Cut(val, " "+f[i]+" ")
					break
				}
			}
		case "names":
			inNames = true
		}
	}
	if !r.Exists {
		r.add(Fail, "The remote prefix "+remotePrefix+" does not exist on the agent host (or cannot be opened): "+
			"the share is not mounted there, or the path is wrong.")
		return r
	}
	r.add(OK, "The remote prefix "+remotePrefix+" exists on the agent host.")
	where := ""
	if r.MountPoint != "" {
		where = " mounted on " + r.MountPoint
		if r.Source != "" {
			where += " from " + r.Source
		}
	}
	switch {
	case shareTypes[r.FSType] != "":
		r.add(OK, "It is on a "+shareTypes[r.FSType]+" share,"+where+".")
	case localTypes[r.FSType]:
		r.add(Warn, "It is on the agent host's own disk ("+r.FSType+","+where+"), not on a share: "+
			"is the share mounted? Files written there are not on your computer.")
	case r.FSType != "":
		r.add(Warn, "It is on file system type "+r.FSType+","+where+"; not known as a share.")
	case r.MountPoint == "/":
		r.add(Warn, "It is on the agent host's root file system ("+r.Source+"), not on a share of its own: is the share mounted?")
	case r.MountPoint != "":
		r.add(OK, "It is"+where+" (file system type unknown: no findmnt on the agent host).")
	}
	if r.Writable {
		r.add(OK, "It is writable for your login there.")
	} else {
		r.add(Fail, "It is not writable for your login there: check the user id (id -u) on both sides and the export or mount options.")
	}
	switch {
	case local == nil:
	case len(local) > MaxNames || len(remoteNames) > MaxNames:
		r.add(Warn, "More than "+itoa(MaxNames)+" entries: the contents were not compared.")
	case len(local) == 0 && len(remoteNames) == 0:
		r.add(Warn, "Both "+localPrefix+" and "+remotePrefix+" are empty: cannot tell whether they are the same folder. "+
			"Put a file in "+localPrefix+" and check again.")
	default:
		only := func(a, b []string) []string {
			in := map[string]bool{}
			for _, n := range b {
				in[n] = true
			}
			var d []string
			for _, n := range a {
				if !in[n] {
					d = append(d, n)
				}
			}
			sort.Strings(d)
			return d
		}
		here, there := only(local, remoteNames), only(remoteNames, local)
		if len(here) == 0 && len(there) == 0 {
			r.add(OK, "It holds the same "+itoa(len(local))+" entries as "+localPrefix+" here: the paths map to the same folder.")
			break
		}
		text := "Its entries differ from " + localPrefix + " here (" + itoa(len(local)-len(here)) + " of " +
			itoa(len(local)) + " found there): the prefixes may not point to the same folder."
		if len(here) > 0 {
			text += " Only here: " + some(here) + "."
		}
		if len(there) > 0 {
			text += " Only there: " + some(there) + "."
		}
		r.add(Fail, text)
	}
	r.OK = true
	for _, l := range r.Lines {
		if l.Level != OK {
			r.OK = false
		}
	}
	return r
}

// some lists up to 5 names.
func some(names []string) string {
	if len(names) > 5 {
		return strings.Join(names[:5], ", ") + " and " + itoa(len(names)-5) + " more"
	}
	return strings.Join(names, ", ")
}

// pairs reads findmnt -P output: KEY="value" … (findmnt writes unusual bytes
// as \xHH).
func pairs(s string) map[string]string {
	m := map[string]string{}
	for s != "" {
		s = strings.TrimLeft(s, " ")
		k, rest, ok := strings.Cut(s, `="`)
		if !ok {
			break
		}
		end := strings.IndexByte(rest, '"')
		if end < 0 {
			break
		}
		m[k] = unhex(rest[:end])
		s = rest[end+1:]
	}
	return m
}

func unhex(s string) string {
	if !strings.Contains(s, `\x`) {
		return s
	}
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		if s[i] == '\\' && i+3 < len(s) && s[i+1] == 'x' {
			if v, ok := hexByte(s[i+2 : i+4]); ok {
				b.WriteByte(v)
				i += 3
				continue
			}
		}
		b.WriteByte(s[i])
	}
	return b.String()
}

func hexByte(h string) (byte, bool) {
	var v byte
	for _, c := range []byte(h) {
		switch {
		case c >= '0' && c <= '9':
			v = v<<4 | (c - '0')
		case c >= 'a' && c <= 'f':
			v = v<<4 | (c - 'a' + 10)
		case c >= 'A' && c <= 'F':
			v = v<<4 | (c - 'A' + 10)
		default:
			return 0, false
		}
	}
	return v, true
}
