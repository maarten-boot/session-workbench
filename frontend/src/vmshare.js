// Host dialog helpers for a shared file system (SPEC F2c): the lines of
// Check share and the sections of VM share setup…, as plain data; main.js
// draws them with textContent.

// LEVELS: the mark and word before each finding; the word says it, the
// colour of the mark only repeats it.
export const LEVELS = {
    ok: {mark: '✓', word: 'OK'},
    warn: {mark: '!', word: 'Warning'},
    fail: {mark: '✗', word: 'Problem'},
};

// shareLines turns a sharecheck.Result into {level, mark, text} rows and a
// summary line.
export function shareLines(r, target) {
    const lines = (r.lines ?? []).map(l => {
        const lv = LEVELS[l.level] ?? LEVELS.warn;
        return {level: l.level, mark: lv.mark, text: `${lv.word}: ${l.text}`};
    });
    const bad = lines.filter(l => l.level !== 'ok').length;
    const head = bad ? `On ${target}: ${bad} ${bad === 1 ? 'thing' : 'things'} to look at.` : `On ${target}: the share looks right.`;
    return {head, lines};
}

// guideSections lists what VM share setup… shows: title, text, and whether
// it gets a Copy button.
export function guideSections(g) {
    const s = [];
    if (g.problems?.length) s.push({title: 'First', text: g.problems.join('\n'), copy: false});
    s.push({title: 'In virt-manager (on this computer), the VM’s details', text: (g.steps ?? []).map((t, i) => `${i + 1}. ${t}`).join('\n'), copy: false});
    s.push({title: 'Or in the VM’s XML (virsh edit <vm>)', text: g.xml ?? '', copy: true});
    s.push({title: 'Then inside the VM (the agent host)', text: g.commands ?? '', copy: true});
    if (g.fstab) s.push({title: 'Mount it at every boot', text: g.fstab, copy: true});
    return s;
}
