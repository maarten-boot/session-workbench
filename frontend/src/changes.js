// What changed per release (SPEC §4.6 About): scripts/changes.sh writes
// frontend/public/changes.txt at build time from the git history; the
// build carries it as /changes.txt. A build without it (wails dev, a build
// outside git) has no list.

// parseChanges reads "## heading" and "- item" lines into
// [{title, items: [...]}]; other lines are left out.
export function parseChanges(text) {
    const sections = [];
    for (const raw of String(text ?? '').split(/\r?\n/)) {
        const line = raw.trimEnd();
        if (line.startsWith('## ')) sections.push({title: line.slice(3).trim(), items: []});
        else if (line.startsWith('- ') && sections.length) sections.at(-1).items.push(line.slice(2).trim());
    }
    return sections.filter(s => s.title);
}

// released tells a release build's version (v1.2.3) from a build between
// releases (v1.2.3-4-gabcdef, -dirty) or a development build (dev).
export function released(version) {
    return /^v\d+\.\d+\.\d+$/.test(version ?? '');
}

// newVersion tells whether the app runs a release other than the one seen
// last (seen: the version stored at the previous start, or nothing).
export function newVersion(version, seen) {
    return released(version) && seen !== version;
}

let cached;

// loadChanges fetches the list once; null when the build has none.
export async function loadChanges() {
    if (cached !== undefined) return cached;
    try {
        const r = await fetch('/changes.txt', {cache: 'no-store'});
        const sections = r.ok ? parseChanges(await r.text()) : [];
        cached = sections.length ? sections : null;
    } catch {
        cached = null;
    }
    return cached;
}
