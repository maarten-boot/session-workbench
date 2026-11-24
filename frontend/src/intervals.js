// How often the app checks, how long messages stay and the gap between
// desktop notifications: the settings of Settings → Checks, Appearance and
// Terminals (SPEC §4.6), set by main.js on every reload.

const UNIT = {h: 3600000, m: 60000, s: 1000, ms: 1};

// durationMs reads a Go duration ("2m", "1m30s", "15s", "0s") as
// milliseconds; NaN when it is not one.
export function durationMs(s) {
    if (typeof s !== 'string' || !/^(\d+(\.\d+)?(h|ms|m|s))+$/.test(s)) return NaN;
    let ms = 0;
    for (const [, n, , u] of s.matchAll(/(\d+(\.\d+)?)(h|ms|m|s)/g)) ms += Number(n) * UNIT[u];
    return ms;
}

let ui = {};

// setIntervals takes the settings ([ui] of the config).
export function setIntervals(u) {
    ui = u ?? {};
}

// The defaults: the config fills them in, these are for a config without.
const DEFAULT = {repo_check_every: 120000, web_runs_every: 120000, web_runs_active_every: 15000, notify_every: 60000};

// every is the interval of a setting in milliseconds.
export function every(key) {
    const ms = durationMs(ui[key]);
    return Number.isFinite(ms) ? ms : DEFAULT[key];
}

// messageMs is how long a message stays on screen: the setting (2 to 60
// seconds, else 4); an error twice as long; one with a button at least 15 s.
export function messageMs(kind = 'info') {
    const s = Number.isInteger(ui.message_seconds) && ui.message_seconds >= 2 && ui.message_seconds <= 60 ? ui.message_seconds : 4;
    if (kind === 'error') return 2 * s * 1000;
    if (kind === 'button') return Math.max(15, 2 * s) * 1000;
    return s * 1000;
}
