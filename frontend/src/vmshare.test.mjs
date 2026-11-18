import test from 'node:test';
import assert from 'node:assert/strict';
import {guideSections, shareLines} from './vmshare.js';

test('shareLines words every level and counts what is not OK', () => {
    const r = shareLines({lines: [{level: 'ok', text: 'a'}, {level: 'warn', text: 'b'}, {level: 'fail', text: 'c'}]}, 'vm');
    assert.equal(r.head, 'On vm: 2 things to look at.');
    assert.deepEqual(r.lines.map(l => l.text), ['OK: a', 'Warning: b', 'Problem: c']);
    assert.deepEqual(r.lines.map(l => l.mark), ['✓', '!', '✗']);
    assert.equal(shareLines({lines: [{level: 'ok', text: 'a'}]}, 'vm').head, 'On vm: the share looks right.');
    assert.equal(shareLines({lines: [{level: 'fail', text: 'x'}]}, 'vm').head, 'On vm: 1 thing to look at.');
});

test('guideSections: problems first, fstab only when there is a line', () => {
    const g = {steps: ['one', 'two'], xml: '<x/>', commands: 'sudo mount', fstab: '', problems: ['fix it']};
    const s = guideSections(g);
    assert.deepEqual(s.map(x => x.title.split(' ')[0]), ['First', 'In', 'Or', 'Then']);
    assert.equal(s[1].text, '1. one\n2. two');
    assert.deepEqual(s.map(x => x.copy), [false, false, true, true]);
    assert.equal(guideSections({...g, problems: [], fstab: 'echo'}).at(-1).title, 'Mount it at every boot');
});
