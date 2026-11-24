// SPEC §4.6 Checks: the interval settings as milliseconds.
import test from 'node:test';
import assert from 'node:assert/strict';
import {durationMs, setIntervals, every, messageMs} from './intervals.js';

test('durationMs reads Go durations', () => {
    assert.equal(durationMs('2m'), 120000);
    assert.equal(durationMs('15s'), 15000);
    assert.equal(durationMs('1m30s'), 90000);
    assert.equal(durationMs('1h'), 3600000);
    assert.equal(durationMs('0s'), 0);
    assert.equal(durationMs('500ms'), 500);
    for (const bad of ['', '2', 'm', '2 m', '-1m', 'abc', undefined, 5]) assert.ok(Number.isNaN(durationMs(bad)), String(bad));
});

test('every: the setting, else the default', () => {
    setIntervals({repo_check_every: '5m', web_runs_every: 'x', notify_every: '0s'});
    assert.equal(every('repo_check_every'), 300000);
    assert.equal(every('web_runs_every'), 120000);
    assert.equal(every('web_runs_active_every'), 15000);
    assert.equal(every('notify_every'), 0);
    setIntervals(null);
    assert.equal(every('repo_check_every'), 120000);
});

test('messageMs: info, error twice as long, button at least 15 s', () => {
    setIntervals({});
    assert.deepEqual([messageMs(), messageMs('error'), messageMs('button')], [4000, 8000, 15000]);
    setIntervals({message_seconds: 10});
    assert.deepEqual([messageMs(), messageMs('error'), messageMs('button')], [10000, 20000, 20000]);
    setIntervals({message_seconds: 1});
    assert.equal(messageMs(), 4000);
});
