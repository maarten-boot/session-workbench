// The limit on active sessions (SPEC F19): Settings → Terminals sets how
// many sessions may be active (the sidebar's Active list: every session not
// marked inactive); going over it is allowed, with a warning dialog first and
// a mark in the top bar while it lasts.

// activeCount counts the sessions not marked inactive.
export function activeCount(sessions) {
    return (sessions ?? []).filter(s => !s.inactive).length;
}

// activeLimit is the limit set (0: none; a value that cannot be one is none).
export function activeLimit(ui) {
    const n = Number(ui?.max_active_sessions);
    return Number.isInteger(n) && n > 0 ? n : 0;
}

// addWarning is the warning dialog's title and text when one more session
// becomes active (how: "create", "activate" or "import"), or null when it
// stays within the limit (or there is none).
export function addWarning(sessions, ui, how, name = '') {
    const limit = activeLimit(ui);
    const n = activeCount(sessions);
    if (!limit || n + 1 <= limit) return null;
    const what = {
        create: 'A new session',
        activate: name ? `Activating “${name}”` : 'Activating this session',
        import: 'The imported session',
    }[how] ?? 'Another active session';
    return {
        title: `More than ${limit} active session${limit === 1 ? '' : 's'}`,
        text: `${n} session${n === 1 ? ' is' : 's are'} active and your limit is ${limit}. ` +
            `${what} makes ${n + 1}. You can go ahead; the top bar shows ⚠ while there are more than ${limit}. ` +
            'Deactivate a session you do not need now (session menu → Deactivate session…) to get back under it, ' +
            'or change the limit in Settings → Terminals.',
        ok: {create: 'Add anyway', activate: 'Activate anyway', import: 'Import anyway'}[how] ?? 'Go ahead',
    };
}

// limitMark is the top bar's mark while more sessions are active than the
// limit ({text, title}), else null.
export function limitMark(sessions, ui) {
    const limit = activeLimit(ui);
    const n = activeCount(sessions);
    if (!limit || n <= limit) return null;
    return {
        text: `⚠ ${n} active (limit ${limit})`,
        title: `${n} sessions are active, more than your limit of ${limit}. Deactivate one you do not need now ` +
            '(session menu → Deactivate session…). Click to change the limit (Settings → Terminals).',
    };
}
