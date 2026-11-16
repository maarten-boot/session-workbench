// Tags filter the sidebar's Active and Inactive lists (SPEC F5a). A
// session's tags are its own plus automatic ones: its host, its folder and
// its state (active or inactive, container, login, stopped, todo,
// warning). Tags compare ignoring case. No imports, so `node --test` can
// load it.

const key = t => t.trim().toLowerCase();

// parseTags reads the dialog's comma-separated text: trimmed, no empty
// or repeated ones (ignoring case; the first spelling stays).
export function parseTags(text) {
    const seen = new Set();
    const out = [];
    for (const t of String(text ?? '').split(',').map(t => t.trim())) {
        if (!t || seen.has(key(t))) continue;
        seen.add(key(t));
        out.push(t);
    }
    return out;
}

// STATES explain the automatic state tags (the filter's tooltips).
export const STATES = {
    active: 'Active sessions',
    inactive: 'Inactive sessions (kept for later)',
    container: 'Sessions in a container on this computer',
    login: 'Plain ssh logins (no local directory)',
    stopped: 'claude stopped after waiting for input (💤)',
    todo: 'Notes with a TODO line (▲)',
    warning: 'The repository check found hooks or settings (⚠)',
};

// sessionTags are a session's tags: [{tag, from}], from "" (its own),
// "host", "folder" or "state"; a tag that is both its own and automatic is
// listed once, as its own. state: {stopped, todo, warning} as the app
// knows them now.
export function sessionTags(d, state = {}) {
    const seen = new Set();
    const out = [];
    const add = (tag, from) => {
        if (!tag || seen.has(key(tag))) return;
        seen.add(key(tag));
        out.push({tag, from});
    };
    for (const t of d.tags ?? []) add(t, '');
    add(d.host, 'host');
    add(d.group, 'folder');
    add(d.inactive ? 'inactive' : 'active', 'state');
    if (d.files === 'container') add('container', 'state');
    if (d.plain) add('login', 'state');
    for (const k of ['stopped', 'todo', 'warning']) if (state[k]) add(k, 'state');
    return out;
}

// tagCounts lists every tag of the sessions with how many have it, by
// name: [{tag, count, from}] (from: as for sessionTags, of its first use).
// stateOf(d) gives a session's state for sessionTags.
export function tagCounts(sessions, stateOf = () => ({})) {
    const all = new Map();
    for (const d of sessions) {
        for (const t of sessionTags(d, stateOf(d))) {
            const k = key(t.tag);
            if (all.has(k)) all.get(k).count++;
            else all.set(k, {tag: t.tag, count: 1, from: t.from});
        }
    }
    return [...all.values()].sort((a, b) => a.tag.localeCompare(b.tag, undefined, {sensitivity: 'base', numeric: true}));
}

// matches: the session has all the selected tags (any: at least one);
// nothing selected matches every session. state: as for sessionTags.
export function matches(d, selected, any = false, state = {}) {
    if (!selected?.length) return true;
    const own = new Set(sessionTags(d, state).map(t => key(t.tag)));
    const has = t => own.has(key(t));
    return any ? selected.some(has) : selected.every(has);
}

// keepKnown drops selected tags no session has any more (a stored filter
// after a tag was removed).
export function keepKnown(selected, counts) {
    const known = new Set(counts.map(c => key(c.tag)));
    return (selected ?? []).filter(t => known.has(key(t)));
}

// toggleTag adds a tag to the selection or takes it out (ignoring case).
export function toggleTag(selected, tag) {
    const sel = selected ?? [];
    return sel.some(t => key(t) === key(tag)) ? sel.filter(t => key(t) !== key(tag)) : [...sel, tag];
}
