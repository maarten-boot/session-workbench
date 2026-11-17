// OSC 52 (SPEC T1a): a program in the terminal (claude's copy, tmux with
// set-clipboard) asks the terminal to put text on the clipboard:
// ESC ] 52 ; <targets> ; <base64> BEL. Only writing is allowed: a request
// to read the clipboard ("?") is ignored, so a remote program cannot see
// it. No imports, so `node --test` can load it.

// MAX is the largest text taken (characters of base64).
export const MAX = 1 << 20;

// osc52Text gives the text to copy from the sequence's data
// ("c;aGVsbG8="), or null: a read request, an empty or too large one, not
// base64, not UTF-8.
export function osc52Text(data) {
    const i = data.indexOf(';');
    if (i < 0) return null;
    const b64 = data.slice(i + 1).replace(/\s+/g, '');
    if (!b64 || b64 === '?' || b64.length > MAX || !/^[A-Za-z0-9+/]*={0,2}$/.test(b64)) return null;
    try {
        const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
        return new TextDecoder('utf-8', {fatal: true}).decode(bytes);
    } catch {
        return null;
    }
}
