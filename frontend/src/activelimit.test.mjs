import test from 'node:test';
import assert from 'node:assert/strict';
import {activeCount, activeLimit, addWarning, limitMark} from './activelimit.js';

const list = (active, inactive = 0) => [
    ...Array.from({length: active}, (_, i) => ({id: `a${i}`})),
    ...Array.from({length: inactive}, (_, i) => ({id: `i${i}`, inactive: true})),
];

test('the active sessions are those not marked inactive', () => {
    assert.equal(activeCount(list(3, 2)), 3);
    assert.equal(activeCount([]), 0);
    assert.equal(activeCount(undefined), 0);
});

test('the limit: a whole number above 0, else none', () => {
    assert.equal(activeLimit({max_active_sessions: 5}), 5);
    for (const v of [0, -1, 2.5, 'x', null, undefined]) assert.equal(activeLimit({max_active_sessions: v}), 0, String(v));
    assert.equal(activeLimit(undefined), 0);
});

test('a warning only when one more goes over the limit', () => {
    const ui = {max_active_sessions: 3};
    assert.equal(addWarning(list(2, 4), ui, 'create'), null); // 3 of 3: still within (inactive ones do not count)
    const w = addWarning(list(3), ui, 'create');
    assert.equal(w.title, 'More than 3 active sessions');
    assert.match(w.text, /^3 sessions are active and your limit is 3\. A new session makes 4\./);
    assert.equal(w.ok, 'Add anyway');
    assert.match(addWarning(list(5), ui, 'activate', 'blog').text, /Activating “blog” makes 6/);
    assert.equal(addWarning(list(5), ui, 'activate', 'blog').ok, 'Activate anyway');
    assert.equal(addWarning(list(5), ui, 'import').ok, 'Import anyway');
    assert.equal(addWarning(list(9), {}, 'create'), null); // no limit
    const one = addWarning(list(1), {max_active_sessions: 1}, 'create');
    assert.equal(one.title, 'More than 1 active session');
    assert.match(one.text, /^1 session is active/);
});

test('the top bar mark while over the limit', () => {
    const ui = {max_active_sessions: 3};
    assert.equal(limitMark(list(3, 5), ui), null);
    assert.deepEqual(limitMark(list(4), ui).text, '⚠ 4 active (limit 3)');
    assert.match(limitMark(list(4), ui).title, /more than your limit of 3/);
    assert.equal(limitMark(list(40), {}), null);
});
